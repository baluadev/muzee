import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/lyrics_manager.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/services/proxy_manager.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/app_utils.dart';
import 'package:muzee/utilities/formatter.dart';
import 'package:muzee/utilities/song_filtering.dart';
import 'package:tuber_playback/tuber_playback.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

List globalSongs = [];

List userLikedSongsList = Hive.box('user').get('likedSongs', defaultValue: []);

List userRecentlyPlayed = Hive.box(
  'user',
).get('recentlyPlayedSongs', defaultValue: []);
List userOfflineSongs = Hive.box(
  'userNoBackup',
).get('offlineSongs', defaultValue: []);

final currentLikedSongsLength = ValueNotifier<int>(userLikedSongsList.length);
final currentOfflineSongsLength = ValueNotifier<int>(userOfflineSongs.length);
final currentRecentlyPlayedLength = ValueNotifier<int>(
  userRecentlyPlayed.length,
);
final recentlyPlayedVersion = ValueNotifier<int>(0);

// Timeouts and durations used across manifest fetching and cache validation.
const Duration _manifestTimeout = Duration(seconds: 30);
const Duration _cacheValidationDuration = Duration(hours: 1);

/// Resolves stream URLs; see [StreamManifestResolver] for the lookup order.
final streamManifestResolver = StreamManifestResolver(
  () => ytClient,
  log: logger.log,
);

/// Fetches a stream manifest for a song, honoring proxy settings.
Future<StreamManifest?> _fetchStreamManifest(String songId) async {
  if (useProxy.value) {
    return ProxyManager().getSongManifest(songId).timeout(_manifestTimeout);
  }

  final result = await streamManifestResolver
      .resolve(songId)
      .timeout(_manifestTimeout);
  return result.manifest;
}

/// Returns a cached song URL if present and still valid.
Future<String?> _getCachedSongUrl(
  String cacheKey,
  Duration cacheDuration,
) async {
  final cachedUrl = await getData(
    'cache',
    cacheKey,
    cachingDuration: cacheDuration,
  );

  if (cachedUrl is! String || cachedUrl.isEmpty) {
    return null;
  }

  final cacheBox = await Hive.openBox('cache');
  final cacheDate = cacheBox.get('${cacheKey}_date') as DateTime?;
  final now = DateTime.now();
  final isOld =
      cacheDate != null && now.difference(cacheDate) > _cacheValidationDuration;

  if (!isOld) {
    return cachedUrl;
  }

  if (await _validateCachedUrl(cachedUrl)) {
    return cachedUrl;
  }

  await deleteData('cache', cacheKey);
  await deleteData('cache', '${cacheKey}_date');
  return null;
}

/// Checks if a cached URL still responds successfully.
Future<bool> _validateCachedUrl(String cachedUrl) async {
  try {
    final response = await http.head(Uri.parse(cachedUrl));
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (_) {
    return false;
  }
}

/// Searches YouTube for songs. Throws when the search can't be done (no
/// network, quota, YouTube error), so callers can tell that apart from
/// "no results".
Future<List> fetchSongsList(String searchQuery) async {
  try {
    final List<Video> searchResults = await ytClient.search.search(searchQuery);
    final songsList = searchResults
        .where((video) => !video.isLive && looksLikeSong(video.duration))
        .map((video) => returnSongLayout(0, video))
        .toList();

    return songsList;
  } catch (e, stackTrace) {
    logger.log('Error in fetchSongsList', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

Future<List> getRecommendedSongs() async {
  try {
    if (externalRecommendations.value && userRecentlyPlayed.isNotEmpty) {
      return await _getRecommendationsFromRecentlyPlayed();
    } else {
      return await _getRecommendationsFromMixedSources();
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error in getRecommendedSongs',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

Future<List> _getRecommendationsFromRecentlyPlayed() async {
  final recent = (List.from(userRecentlyPlayed)..shuffle()).take(3).toList();

  final futures = recent.map((songData) async {
    try {
      final song = await ytClient.videos.get(songData['ytid']);
      final relatedSongs = await ytClient.videos.getRelatedVideos(song) ?? [];
      return relatedSongs
          .where((s) => !s.isLive)
          .take(3)
          .map((s) => returnSongLayout(0, s))
          .toList();
    } catch (e, stackTrace) {
      logger.log(
        'Error getting related videos for ${songData['ytid']}',
        error: e,
        stackTrace: stackTrace,
      );
      return <Map>[];
    }
  }).toList();

  final results = await Future.wait(futures);
  // Limit to 15 items max for performance
  final playlistSongs = results.expand((list) => list).take(15).toList()
    ..shuffle();
  return playlistSongs;
}

Future<List> _getRecommendationsFromMixedSources() async {
  final playlistSongs = [...userLikedSongsList, ...userRecentlyPlayed];

  if (globalSongs.isEmpty) {
    const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';
    globalSongs = await getSongsFromPlaylist(playlistId);
  }
  playlistSongs.addAll(globalSongs.take(10));

  if (userCustomPlaylists.value.isNotEmpty) {
    for (final userPlaylist in userCustomPlaylists.value) {
      final _list = List.from(userPlaylist['list'] as List)..shuffle();
      playlistSongs.addAll(_list.take(5));
    }
  }

  return _deduplicateAndShuffle(playlistSongs);
}

List _deduplicateAndShuffle(List playlistSongs) {
  final seenYtIds = <String>{};
  final uniqueSongs = <Map>[];

  playlistSongs.shuffle();

  for (final song in playlistSongs) {
    if (song['ytid'] != null &&
        song['isLive'] != true &&
        seenYtIds.add(song['ytid'])) {
      uniqueSongs.add(song);
      // Early exit when we have enough songs
      if (uniqueSongs.length >= 15) break;
    }
  }

  return uniqueSongs;
}

Future<void> updateSongLikeStatus(dynamic songId, bool add) async {
  try {
    if (add) {
      if (!userLikedSongsList.any((song) => song['ytid'] == songId)) {
        final songDetails = await getSongDetails(
          userLikedSongsList.length,
          songId,
        );
        userLikedSongsList.add(songDetails);
      }
    } else {
      userLikedSongsList.removeWhere((song) => song['ytid'] == songId);
    }

    currentLikedSongsLength.value = userLikedSongsList.length;
    unawaited(addOrUpdateData('user', 'likedSongs', userLikedSongsList));
  } catch (e, stackTrace) {
    logger.log(
      'Error updating song like status',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

void moveLikedSong(int oldIndex, int newIndex) {
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }
  final _song = userLikedSongsList.removeAt(oldIndex);
  userLikedSongsList.insert(newIndex, _song);
  currentLikedSongsLength.value = userLikedSongsList.length;
  unawaited(addOrUpdateData('user', 'likedSongs', userLikedSongsList));
}

Future<void> renameSongInLikedSongs(
  dynamic songId,
  String newTitle,
  String newArtist,
) async {
  try {
    final songIndex = userLikedSongsList.indexWhere(
      (song) => song['ytid'] == songId,
    );

    if (songIndex != -1) {
      userLikedSongsList[songIndex]['title'] = newTitle;
      userLikedSongsList[songIndex]['artist'] = newArtist;

      currentLikedSongsLength.value = userLikedSongsList.length;
      unawaited(addOrUpdateData('user', 'likedSongs', userLikedSongsList));
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error renaming song in liked songs',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

bool isSongAlreadyLiked(songIdToCheck) =>
    userLikedSongsList.any((song) => song['ytid'] == songIdToCheck);

bool isPlaylistAlreadyLiked(playlistIdToCheck) =>
    userLikedPlaylists.any((playlist) => playlist['ytid'] == playlistIdToCheck);

bool isSongAlreadyOffline(songIdToCheck) =>
    userOfflineSongs.any((song) => song['ytid'] == songIdToCheck);

bool isPlaylistFullyOffline(List songs) {
  if (songs.isEmpty) return false;
  final offlineIds = userOfflineSongs.map((s) => s['ytid']).toSet();
  return songs.every((s) => offlineIds.contains(s['ytid']));
}

Map<String, dynamic> getOfflineSongByYtid(String ytid) {
  try {
    final song = userOfflineSongs.firstWhere(
      (s) => s['ytid'] == ytid,
      orElse: () => <String, dynamic>{},
    );
    return Map<String, dynamic>.from(song);
  } catch (_) {
    return <String, dynamic>{};
  }
}

Future<List<String>> getSearchSuggestions(String query) async {
  // Custom implementation:

  // const baseUrl = 'https://suggestqueries.google.com/complete/search';
  // final parameters = {
  //   'client': 'firefox',
  //   'ds': 'yt',
  //   'q': query,
  // };

  // final uri = Uri.parse(baseUrl).replace(queryParameters: parameters);

  // try {
  //   final response = await http.get(
  //     uri,
  //     headers: {
  //       'User-Agent':
  //           'Mozilla/5.0 (Windows NT 10.0; rv:96.0) Gecko/20100101 Firefox/96.0',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final suggestions = jsonDecode(response.body)[1] as List<dynamic>;
  //     final suggestionStrings = suggestions.cast<String>().toList();
  //     return suggestionStrings;
  //   }
  // } catch (e, stackTrace) {
  //   logger.log('Error in getSearchSuggestions:$e\n$stackTrace');
  // }

  // Built-in implementation:

  try {
    return await ytClient.search.getQuerySuggestions(query);
  } catch (e, stackTrace) {
    // Suggestions are optional; offline or rate-limited just means none.
    logger.log(
      'Error in getSearchSuggestions',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

Future<List<Map<String, int>>> getSkipSegments(String id) async {
  try {
    final res = await ProxyManager().getProxiedResponse(
      Uri(
        scheme: 'https',
        host: 'sponsor.ajay.app',
        path: '/api/skipSegments',
        queryParameters: {
          'videoID': id,
          'category': [
            'sponsor',
            'selfpromo',
            'interaction',
            'intro',
            'outro',
            'music_offtopic',
          ],
          'actionType': 'skip',
        },
      ),
    );
    if (res.statusCode == 200 && res.body != 'Not Found') {
      final data = jsonDecode(res.body);
      final segments = data.map((obj) {
        return Map.castFrom<String, dynamic, String, int>({
          'start': obj['segment'].first.toInt(),
          'end': obj['segment'].last.toInt(),
        });
      }).toList();
      return List.castFrom<dynamic, Map<String, int>>(segments);
    } else {
      return [];
    }
  } catch (e, stackTrace) {
    logger.log('Error in getSkipSegments', error: e, stackTrace: stackTrace);
    return [];
  }
}

/// A related song to autoplay after [songYtId], or null.
Future<Map?> getSimilarSong(String songYtId) async {
  try {
    final song = await ytClient.videos.get(songYtId);
    final relatedSongs = await ytClient.videos.getRelatedVideos(song) ?? [];

    final nonLive = relatedSongs
        .where((v) => !v.isLive)
        .toList(growable: false);
    if (nonLive.isNotEmpty) return returnSongLayout(0, nonLive.first);
    logger.log(
      'No non-live related songs found for $songYtId '
      '(had ${relatedSongs.length} related)',
    );
  } catch (e, stackTrace) {
    logger.log(
      'Error while fetching next similar song:',
      error: e,
      stackTrace: stackTrace,
    );
  }
  return null;
}

/// Fetches the best available audio stream for a song.
Future<AudioOnlyStreamInfo?> fetchBestAudioStream(String? songId) async {
  try {
    if (songId == null || songId.isEmpty) {
      logger.log('fetchBestAudioStream: songId is null or empty');
      return null;
    }

    final manifest = await _fetchStreamManifest(songId);
    final audioStream = manifest?.audioOnly;
    if (audioStream == null || audioStream.isEmpty) {
      logger.log('fetchBestAudioStream: no audio streams for $songId');
      return null;
    }
    return selectAudioOnlyStreamForQuality(audioStream.sortByBitrate());
  } on TimeoutException catch (_) {
    logger.log('fetchBestAudioStream request timed out for $songId');
    return null;
  } catch (e, stackTrace) {
    logger.log(
      'Error while fetching best audio stream',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}

/// Resolves a playable stream URL for a song (cached when possible).
Future<StreamPlaybackInfo?> fetchSongStreamInfo(
  String songId,
  bool isLive,
) async {
  try {
    if (songId.isEmpty) {
      logger.log('fetchSongStreamInfo: songId is empty');
      return null;
    }
    if (isLive) {
      final streamInfo = await ytClient.videos.streamsClient
          .getHttpLiveStreamUrl(VideoId(songId));
      unawaited(updateRecentlyPlayed(songId));
      return StreamPlaybackInfo(
        url: streamInfo,
        isVideo: true,
        cacheKey: 'song_${songId}_live_url',
      );
    }

    const _cacheDuration = Duration(hours: 3);
    final muxedCacheKey = StreamPlaybackInfo.cacheKeyFor(songId, isVideo: true);
    final audioCacheKey = StreamPlaybackInfo.cacheKeyFor(
      songId,
      isVideo: false,
    );

    // Try muxed cache first.
    final cachedMuxedUrl = await _getCachedSongUrl(
      muxedCacheKey,
      _cacheDuration,
    );
    if (cachedMuxedUrl != null) {
      unawaited(updateRecentlyPlayed(songId));
      return StreamPlaybackInfo(
        url: cachedMuxedUrl,
        isVideo: true,
        cacheKey: muxedCacheKey,
      );
    }

    // Then audio fallback cache.
    final cachedAudioUrl = await _getCachedSongUrl(
      audioCacheKey,
      _cacheDuration,
    );
    if (cachedAudioUrl != null) {
      unawaited(updateRecentlyPlayed(songId));
      return StreamPlaybackInfo(
        url: cachedAudioUrl,
        isVideo: false,
        cacheKey: audioCacheKey,
      );
    }

    // Get fresh URL
    final manifest = await _fetchStreamManifest(songId);

    final muxedStreams = manifest?.muxed;
    if (muxedStreams != null && muxedStreams.isNotEmpty) {
      final selectedMuxed = selectMuxedStreamForQuality(muxedStreams.toList());
      final url = selectedMuxed.url.toString();
      unawaited(addOrUpdateData('cache', muxedCacheKey, url));
      unawaited(updateRecentlyPlayed(songId));
      return StreamPlaybackInfo(
        url: url,
        isVideo: true,
        cacheKey: muxedCacheKey,
      );
    }

    final audioStreams = manifest?.audioOnly;
    if (audioStreams == null || audioStreams.isEmpty) {
      logger.log('fetchSongStreamInfo: no muxed/audio streams for $songId');
      return null;
    }

    final selectedAudio = selectAudioOnlyStreamForQuality(
      audioStreams.sortByBitrate(),
    );
    final audioUrl = selectedAudio.url.toString();
    unawaited(addOrUpdateData('cache', audioCacheKey, audioUrl));
    unawaited(updateRecentlyPlayed(songId));
    return StreamPlaybackInfo(
      url: audioUrl,
      isVideo: false,
      cacheKey: audioCacheKey,
    );
  } on TimeoutException catch (_) {
    logger.log('fetchSongStreamInfo request timed out for $songId');
    return null;
  } catch (e, stackTrace) {
    logger.log(
      'Error in fetchSongStreamInfo for $songId:',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}

Future<String?> fetchSongStreamUrl(String songId, bool isLive) async {
  final info = await fetchSongStreamInfo(songId, isLive);
  return info?.url;
}

Future<Map<String, dynamic>> getSongDetails(
  int songIndex,
  String songId,
) async {
  try {
    final song = await ytClient.videos.get(songId);
    return returnSongLayout(songIndex, song);
  } catch (e, stackTrace) {
    logger.log(
      'Error while getting song details',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// Lyrics lookups by song, shared so the player rebuilding doesn't ask the
/// network again. A miss is looked up again after [_lyricsMissRetry].
final _lyricsCache = <String, _LyricsLookup>{};
const _lyricsMissRetry = Duration(minutes: 2);
const _lyricsCacheSize = 30;

class _LyricsLookup {
  _LyricsLookup(this.lyrics) {
    lyrics.then((text) => missed = text == null).ignore();
  }

  final Future<String?> lyrics;
  final DateTime at = DateTime.now();
  bool missed = false;
}

/// Lyrics for a song (see [LyricsManager]), or null if no source has them.
Future<String?> getSongLyrics({
  String? videoId,
  required String? artist,
  required String title,
  Duration? duration,
}) {
  final key = videoId ?? '$artist - $title';
  final cached = _lyricsCache[key];
  if (cached != null &&
      !(cached.missed &&
          DateTime.now().difference(cached.at) > _lyricsMissRetry)) {
    return cached.lyrics;
  }

  final lookup = _LyricsLookup(
    LyricsManager().fetchLyrics(
      videoId: videoId,
      artist: artist,
      title: title,
      duration: duration,
    ),
  );
  _lyricsCache
    ..remove(key)
    ..[key] = lookup;
  if (_lyricsCache.length > _lyricsCacheSize) {
    _lyricsCache.remove(_lyricsCache.keys.first);
  }
  return lookup.lyrics;
}

const recentlyPlayedSongsLimit = 250;

Future<void> updateRecentlyPlayed(dynamic songId) async {
  try {
    if (userRecentlyPlayed.isNotEmpty &&
        userRecentlyPlayed[0]['ytid'] == songId) {
      final existing = userRecentlyPlayed[0] as Map;
      existing['listeningCount'] = (existing['listeningCount'] ?? 0) + 1;
      existing['lastPlayed'] = DateTime.now();
      recentlyPlayedVersion.value++;
      unawaited(
        addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed),
      );
      return;
    }

    final existingIndex = userRecentlyPlayed.indexWhere(
      (song) => song['ytid'] == songId,
    );

    if (existingIndex == -1 &&
        userRecentlyPlayed.length >= recentlyPlayedSongsLimit) {
      userRecentlyPlayed.removeLast();
    }

    if (existingIndex != -1) {
      final song = userRecentlyPlayed.removeAt(existingIndex) as Map;
      song['listeningCount'] = (song['listeningCount'] ?? 0) + 1;
      song['lastPlayed'] = DateTime.now();
      userRecentlyPlayed.insert(0, song);
    } else {
      final newSongDetails = await getSongDetails(0, songId);
      newSongDetails['listeningCount'] = 1;
      newSongDetails['lastPlayed'] = DateTime.now();
      userRecentlyPlayed.insert(0, newSongDetails);
    }

    currentRecentlyPlayedLength.value = userRecentlyPlayed.length;
    recentlyPlayedVersion.value++;
    unawaited(
      addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed),
    );
  } catch (e, stackTrace) {
    logger.log(
      'Error updating recently played',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

Future<void> removeFromRecentlyPlayed(dynamic songId) async {
  if (userRecentlyPlayed.any((song) => song['ytid'] == songId)) {
    userRecentlyPlayed.removeWhere((song) => song['ytid'] == songId);
    currentRecentlyPlayedLength.value = userRecentlyPlayed.length;
    recentlyPlayedVersion.value++;
    unawaited(
      addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed),
    );
  }
}

/// Returns the most-played songs, ordered by `listeningCount` desc and
/// `lastPlayed` desc as a tiebreaker. Does not mutate the persisted list.
List<Map> getMostPlayed({int limit = 20, bool deduplicate = true}) {
  final copy = List<Map>.from(userRecentlyPlayed);

  if (deduplicate) {
    final seen = <String>{};
    copy.removeWhere((m) {
      final id = m['ytid']?.toString();
      if (id == null) return true;
      if (seen.contains(id)) return true;
      seen.add(id);
      return false;
    });
  }

  copy.sort((a, b) {
    final ai = (a['listeningCount'] is int)
        ? a['listeningCount'] as int
        : int.tryParse(a['listeningCount']?.toString() ?? '') ?? 0;
    final bi = (b['listeningCount'] is int)
        ? b['listeningCount'] as int
        : int.tryParse(b['listeningCount']?.toString() ?? '') ?? 0;
    if (ai != bi) return bi.compareTo(ai);

    final ad = a['lastPlayed'] is DateTime
        ? a['lastPlayed'] as DateTime
        : DateTime.tryParse(a['lastPlayed']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b['lastPlayed'] is DateTime
        ? b['lastPlayed'] as DateTime
        : DateTime.tryParse(b['lastPlayed']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });

  return copy.take(limit).toList();
}
