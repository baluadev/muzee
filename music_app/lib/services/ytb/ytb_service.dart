import 'dart:isolate';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:muzee/configs/const.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/models/category_model.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/services/database/local_store.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'cryptojs_aes_encryption_helper.dart';
import 'ytb_helper.dart';

class YoutubeExplodeManager {
  static final YoutubeExplode _instance = YoutubeExplode();

  static YoutubeExplode get instance => _instance;
}

class YtbService {
  static const String baseUrl = "/youtube/v3";
  static const String search = "$baseUrl/search";
  static const String videos = "$baseUrl/videos";
  static const String channels = "$baseUrl/channels";
  static const String playlists = "$baseUrl/playlists";
  static const String playlistItems = "$baseUrl/playlistItems";
// Hàm chính để gọi từ app
  static Future<String?> getUrl(
    String id, {
    bool audioOnly = false,
  }) async {
    final receivePort = ReceivePort();
    await Isolate.spawn<_IsolateParams>(
      _isolateEntry,
      _IsolateParams(receivePort.sendPort, id),
    );

    final result = await receivePort.first;
    if (result is String) return result;
    return null;
  }

  // Hàm isolate entry
  static Future<void> _isolateEntry(_IsolateParams params) async {
    final sendPort = params.sendPort;
    final id = params.videoId;

    final yt = YoutubeExplodeManager.instance;

    try {
      final manifest =
          await yt.videos.streamsClient.getManifest(id, ytClients: [
        YoutubeApiClient.ios,
        YoutubeApiClient.androidVr,
      ]);

      final url = manifest.muxed.withHighestBitrate().url.toString();

      sendPort?.send(url);
    } catch (e) {
      sendPort?.send(null);
    } finally {
      yt.close();
    }
  }

  // Hàm prefetch ở background (ví dụ gọi trong init app hoặc preload queue)
  static void prefetchInBackground(String id, {bool audioOnly = false}) {
    Isolate.spawn<_IsolateParams>(
      _isolateEntry,
      _IsolateParams(null, id),
    );
  }

  static Future<({Map<String, String>? headers, Uri url})> _getInfoAuth({
    required String baseUrl,
    required Map<String, String> queryParams,
  }) async {
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      // Dùng API_KEY nếu không đăng nhập
      final newParams = Map<String, String>.from(queryParams)
        ..putIfAbsent('key', () => Const.API_KEY);

      return (
        url: Uri.https('www.googleapis.com', baseUrl, newParams),
        headers: null,
      );
    } else {
      // Dùng accessToken nếu đã đăng nhập
      return (
        url: Uri.https('www.googleapis.com', baseUrl, queryParams),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
    }
  }

  ///
  ///SEARCH
  ///

  static YoutubeExplode? yt;
  static void openYoutubeExplode() {
    closeYoutubeExplode();
    yt = YoutubeExplode();
  }

  static void closeYoutubeExplode() {
    yt?.close();
  }

  static VideoSearchList? searchList;

  static Future<List<SongModel>> searchVideos(String keySearch) async {
    openYoutubeExplode();
    try {
      searchList = ((await yt?.search.search(keySearch)) as VideoSearchList);
      List<SongModel> values = [];
      for (var e in searchList!) {
        final value = YtHelper.videoToSong(e);
        if (value != null) values.add(value);
      }
      return values;
    } catch (e) {
      return [];
    }
  }

  static Future<List<SongModel>> searchMoreVideos() async {
    final nextser = await searchList?.nextPage();
    List<SongModel> values = [];
    for (var e in nextser!) {
      final value = YtHelper.videoToSong(e);
      if (value != null) values.add(value);
    }
    return values;
  }

  ///
  ///PLAYLIST
  ///
  static Future<List<PlaylistModel>> getPlaylistsFromChannel({
    required String channelId,
    int maxResults = 5,
  }) async {
    final info = await _getInfoAuth(
      baseUrl: playlists,
      queryParams: {
        'part': 'snippet',
        'channelId': channelId,
        'maxResults': maxResults.toString(),
      },
    );

    final res = await http.get(
      info.url,
      headers: info.headers,
    );

    if (res.statusCode != 200) {
      // print('Failed to fetch playlists: ${res.body}');
      return [];
    }

    final data = json.decode(res.body);
    final items = data['items'] as List;

    return items
        .map((item) => PlaylistModel(
              playlistId: item['id'],
              title: item['snippet']['title'],
              thumbnailUrl: item['snippet']['thumbnails']['high']['url'],
            ))
        .toList();
  }

  static Future<PlaylistModel?> getPlaylistFromYtbId(String playlistId) async {
    var ytPlugin = YoutubeExplode();
    try {
      var playlistData = await ytPlugin.playlists.get(playlistId);
      ytPlugin.close;
      return PlaylistModel(
        title: playlistData.title,
        artist: playlistData.author,
        playlistId: playlistData.id.value,
        thumbnailUrl: playlistData.thumbnails.maxResUrl,
        isYoutube: true,
      );
    } catch (e) {
      ytPlugin.close();
      return null;
    }
  }

  static Future<List<SongModel>> getSongOfPlaylistFromYtbId(
      String playlistId) async {
    var ytPlugin = YoutubeExplode();
    List<SongModel> tempSongs = [];
    try {
      await for (var video in ytPlugin.playlists.getVideos(playlistId)) {
        tempSongs.add(SongModel(
          songId: video.id.value,
          title: video.title,
          thumbnailUrl: video.thumbnails.maxResUrl,
          artist: video.author,
          artistId: video.channelId.value,
        ));
      }
      return tempSongs;
    } catch (e) {
      return tempSongs;
    }
  }

  ///
  ///ARTIST
  ///
  static Future<ArtistModel> getInfoArtist(
      {String? songId, String? channelId}) async {
    if (songId == null && channelId == null) {
      return ArtistModel();
    }

    String? id = channelId;
    if (channelId == null && songId != null) {
      final song = await getInfoSong(songId);
      id = song?.artistId;
    }

    final info = await _getInfoAuth(
      baseUrl: channels,
      queryParams: {
        'part': 'snippet,statistics',
        'id': id!,
      },
    );
    final videoRes = await http.get(
      info.url,
      headers: info.headers,
    );

    if (videoRes.statusCode != 200) {
      // print('Failed to fetch latest videos: ${videoRes.body}');
      return ArtistModel();
    }

    final videoData = json.decode(videoRes.body);
    final items = videoData['items'] as List;
    final item = items[0];
    final idChannel = item['id'];
    final snippet = item['snippet'];
    final statistics = item['statistics'];
    final title = snippet['title'];
    final country = snippet['country'];
    final thumb = snippet['thumbnails']['high']['url'];
    final subscriberCount = statistics['subscriberCount'];
    final videoCount = statistics['subscriberCount'];
    return ArtistModel(
      name: title as String,
      channelId: idChannel as String,
      country: country,
      imgPath: thumb as String,
      subscriberCount: subscriberCount as String,
      videoCount: videoCount as String,
    );
    // }
  }

  static Future<List<ArtistModel>> getTrendingArtistsFromYouTube(
      {int count = 1}) async {
    //randome lay danh sach
    List<int> randomes = [10, 15, 20];
    randomes.shuffle();
    final info = await _getInfoAuth(
      baseUrl: videos,
      queryParams: {
        'part': 'snippet',
        'chart': 'mostPopular',
        'regionCode': LocalStore.inst.getCountryCode,
        'videoCategoryId': '10',
        'maxResults': randomes.first.toString(),
      },
    );
    final videoRes = await http.get(
      info.url,
      headers: info.headers,
    );

    if (videoRes.statusCode != 200) {
      // print('Error getTrendingArtistsFromYouTube: ${videoRes.body}');
      if (count == 2) return [];
      await getTrendingArtistsFromYouTube(count: 2);
    }

    final videoData = json.decode(videoRes.body);
    final items = videoData['items'] as List;

    final channelIds = items
        .map((item) => item['snippet']['channelId'] as String)
        .toSet()
        .toList();

    // Lấy thông tin chi tiết của channel
    final info2 = await _getInfoAuth(
      baseUrl: channels,
      queryParams: {
        'part': 'snippet,statistics',
        'id': channelIds.join(","),
      },
    );
    final channelRes = await http.get(
      info2.url,
      headers: info2.headers,
    );

    if (channelRes.statusCode != 200) {
      // print('Error getTrendingArtistsFromYouTube2: ${channelRes.body}');
      return [];
    }

    final channelData = json.decode(channelRes.body);
    final channels1 = channelData['items'] as List;

    final artistList = <ArtistModel>[];

    for (var c in channels1) {
      final snippet = c['snippet'];
      final statistics = c['statistics'];

      artistList.add(ArtistModel(
        country: snippet['country'],
        name: snippet['title'],
        imgPath: snippet['thumbnails']['high']['url'],
        channelId: c['id'],
        subscriberCount: statistics['subscriberCount'],
        videoCount: statistics['videoCount'],
      ));
    }

    return artistList;
  }

  static Future<List<SongModel>> getRelatedVideos({
    required String videoId,
  }) async {
    final list = await getRelatedVideosUsingToken(videoId: videoId);
    if (list.isNotEmpty) return list;
    return await getRelatedVideosUsingYtb(videoId: videoId);
  }

  static final yt2 = YoutubeExplode();
  static Future<List<SongModel>> getRelatedVideosUsingYtb({
    required String videoId,
  }) async {
    yt = YoutubeExplode();
    var video = await yt2.videos.get('https://youtube.com/watch?v=$videoId');
    var relatedVideos = await yt2.videos.getRelatedVideos(video);

    return relatedVideos
            ?.map((p) => SongModel(
                  songId: p.id.value,
                  title: p.title,
                  artist: p.author,
                  artistId: p.channelId.value,
                ))
            .toList() ??
        [];
  }

  static Future<List<SongModel>> getRelatedVideosUsingToken({
    required String videoId,
  }) async {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      return [];
    }

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet'
      '&relatedToVideoId=$videoId'
      '&type=video'
      '&maxResults=10',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      // print('Failed to fetch related videos: ${response.body}');
      return [];
    }

    final data = json.decode(response.body);
    final items = data['items'] as List;

    return items.map((item) {
      final snippet = item['snippet'];
      final videoId = item['id']['videoId'];

      return SongModel(
        songId: videoId,
        title: snippet['title'],
        thumbnailUrl: snippet['thumbnails']['high']['url'],
        artistId: snippet['channelId'],
        artist: snippet['channelTitle'],
        duration: 0,
      );
    }).toList();
  }

  ///
  ///SONGS
  ///

  static Future<List<SongModel>> getLatestVideosFromChannel(String channelId,
      {int count = 1}) async {
    // get token if has
    final info = await _getInfoAuth(
      baseUrl: channels,
      queryParams: {
        'part': 'contentDetails',
        'id': channelId,
      },
    );
    // Bước 1: Lấy uploads playlist ID từ channel
    final channelRes = await http.get(
      info.url,
      headers: info.headers,
    );

    if (channelRes.statusCode != 200) {
      // print('Failed to get uploads playlist ID: ${channelRes.body}');
      if (count == 2) return [];
      await getRefreshToken();
      getLatestVideosFromChannel(channelId, count: 2);
      return [];
    }

    final channelData = json.decode(channelRes.body);
    final uploadsPlaylistId = channelData['items'][0]['contentDetails']
        ['relatedPlaylists']['uploads'];

    // Bước 2: Lấy 5 video mới nhất từ uploads playlist

    final info2 = await _getInfoAuth(
      baseUrl: playlistItems,
      queryParams: {
        'part': 'snippet',
        'playlistId': uploadsPlaylistId,
        'maxResults': '5'
      },
    );
    final videoRes = await http.get(
      info2.url,
      headers: info2.headers,
    );

    if (videoRes.statusCode != 200) {
      // print('Failed to fetch latest videos: ${videoRes.body}');
      return [];
    }

    final videoData = json.decode(videoRes.body);
    final items = videoData['items'] as List;

    return items.map((item) {
      final snippet = item['snippet'];
      return SongModel(
        songId: snippet['resourceId']['videoId'],
        title: snippet['title'],
        thumbnailUrl: snippet['thumbnails']['high']['url'],
        artistId: snippet['channelId'],
        artist: snippet['channelTitle'],
        duration: 0,
      );
    }).toList();
  }

  static Future<List<SongModel>> fetchTrendingMusicSongs({
    int maxResults = 20,
  }) async {
    final info = await _getInfoAuth(
      baseUrl: videos,
      queryParams: {
        'part': 'snippet,contentDetails',
        'chart': 'mostPopular',
        'regionCode': LocalStore.inst.getCountryCode,
        'videoCategoryId': '10',
        'maxResults': maxResults.toString(),
      },
    );

    final response = await http.get(info.url, headers: info.headers);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch videos: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final List<dynamic> items = data['items'];

    return items.map<SongModel>((item) {
      final snippet = item['snippet'];
      return SongModel(
        songId: item['id'],
        title: snippet['title'],
        thumbnailUrl: snippet['thumbnails']['high']?['url'] ??
            snippet['thumbnails']['default']?['url'],
        artist: snippet['channelTitle'],
        artistId: snippet['channelId'],
      );
    }).toList();
  }

  static Future<SongModel?> getInfoSong(String songId) async {
    final info = await _getInfoAuth(
      baseUrl: videos,
      queryParams: {
        'part': 'snippet,statistics',
        'id': songId,
      },
    );

    final videoRes = await http.get(
      info.url,
      headers: info.headers,
    );
    final videoData = json.decode(videoRes.body);
    final items = videoData['items'] as List;
    final item = items[0];
    final id = item['id'];
    final snippet = item['snippet'];

    final title = snippet['title'];
    final channelTitle = snippet['channelTitle'];
    final channelId = snippet['channelId'];
    final thumb = snippet['thumbnails']['high']['url'];

    return SongModel(
      songId: id as String,
      title: title as String,
      artist: channelTitle as String,
      artistId: channelId as String,
      thumbnailUrl: thumb as String,
    );
  }

  static Future<List<SongModel>> getMusicsFromCategory(
      String? genreCode) async {
    try {
      var url = 'https://api-upbeat.famtechvn.com/genre/videos?';
      url += 'genre_code=$genreCode&region_code=US';
      // print(url);
      final resp = await http.get(
        Uri.parse(url),
        headers: {'x-app': 'upbeat', 'Content-Type': 'application/json'},
      );
      final jsonResp = json.decode(resp.body);
      if (jsonResp.containsKey('data')) {
        // print(decryptAESCrypto(data));
        final dataPlain = decryptAESCrypto(jsonResp['data'] as String) as List;
        // final data = jsonResp['data'] as List;

        return dataPlain
            .map(
              (v) => SongModel(
                songId: v['video_id'],
                title: Utils.escape(v['name'] as String),
                artist: Utils.escape(v['channel'] as String),
              ),
            )
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<CategoryModel>> getMood() async {
    try {
      final resp = await http.get(
        Uri.parse('https://stg-upbeat.famtechvn.com/api/mood/categories'),
        headers: {'x-app': 'upbeat', 'Content-Type': 'application/json'},
      );

      final jsonResp = json.decode(resp.body) as Map;

      if (jsonResp.containsKey('data')) {
        final data = decryptAESCrypto(jsonResp['data'] as String) as List;
        List<CategoryModel>? list = await compute(CategoryModel.parses, data);
        return list ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<PlaylistModel>> getMoodDetail(String moodId) async {
    try {
      final resp = await http.get(
        Uri.parse(
            'https://stg-upbeat.famtechvn.com/api/mood/playlists?params=$moodId'),
        headers: {'x-app': 'upbeat', 'Content-Type': 'application/json'},
      );

      final jsonResp = json.decode(resp.body) as Map;
      if (jsonResp.containsKey('data')) {
        final data = decryptAESCrypto(jsonResp['data'] as String) as List;
        debugPrint('getMoodDetail data: $data');
        List<PlaylistModel>? list = await compute(PlaylistModel.parses, data);
        return list ?? [];
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('getMoodDetail $e, $stackTrace');
      return [];
    }
  }

  static Future<List<SongModel>> getMoodPlayList(String? playListId) async {
    try {
      final resp = await http.get(
        Uri.parse(
            'https://stg-upbeat.famtechvn.com/api/mood/playlists/$playListId'),
        headers: {'x-app': 'upbeat', 'Content-Type': 'application/json'},
      );
      final jsonResp = json.decode(resp.body) as Map;
      if (jsonResp.containsKey('data')) {
        final data = decryptAESCrypto(jsonResp['data'] as String);
        debugPrint('getMoodPlayList data: $data');
        List? listTrack = data['tracks'];
        if (listTrack != null) {
          List<SongModel>? list = await compute(SongModel.parses, listTrack);
          return list ?? [];
        }
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('getMoodPlayList $e, $stackTrace');
      return [];
    }
  }

  static dynamic decryptAESCrypto(String data) {
    final textPlain = decryptAESCryptoJS(data, 'OJoirofre34924wierhjkf');
    return json.decode(textPlain);
  }
}

// Class dùng để đóng gói tham số cho isolate
class _IsolateParams {
  final SendPort? sendPort;
  final String videoId;

  _IsolateParams(this.sendPort, this.videoId);
}
