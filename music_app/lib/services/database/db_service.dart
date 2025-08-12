import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/related_video_cache.dart';
import 'package:muzee/models/search_history_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/services/ytb/ytb_service.dart';

// constants
const String likedSongs = 'likedSong';
const String recentlyPlayed = 'searchRecentlyPlayed';

class DBService {
  static DBService get inst => _instance;
  static final DBService _instance = DBService._internal();
  DBService._internal();

  late Isar isar;

  Future<void> openDB(String dirPath) async {
    isar = await Isar.open(
      [
        PlaylistModelSchema,
        SongModelSchema,
        SearchHistoryModelSchema,
        ArtistModelSchema,
        RelatedVideoCacheSchema,
      ],
      directory: dirPath,
    );
  }

  ///
  ///
  ///PLAYLIST
  ///

  Future<bool> playlistExists(String name) async {
    return await isar.playlistModels.filter().titleEqualTo(name).isNotEmpty();
  }

  Future<int?> createPlaylistIfNotExists(String name) async {
    final exists = await playlistExists(name);
    if (exists) return null;

    final playlist = PlaylistModel()
      ..title = name
      ..createdAt = DateTime.now();
    return await isar
        .writeTxn(() async => await isar.playlistModels.put(playlist));
  }

  Future<int> importPlaylistModel(PlaylistModel playlistModel) async {
    playlistModel.createdAt = DateTime.now();
    return await isar
        .writeTxn(() async => await isar.playlistModels.put(playlistModel));
  }

  /// Helper: Create or Get
  Future<PlaylistModel> getOrCreatePlaylist(String name) async {
    final playlist = await getPlaylistByName(name);
    if (playlist != null) return playlist;

    await createPlaylistIfNotExists(name);
    return await getPlaylistByName(name) ?? PlaylistModel()
      ..title = name;
  }

  Future<PlaylistModel?> getPlaylistByName(String name) async {
    return await isar.playlistModels.filter().titleEqualTo(name).findFirst();
  }

  Future<PlaylistModel?> getPlaylistById(int id) async {
    return await isar.playlistModels.filter().idEqualTo(id).findFirst();
  }

  Future<void> deletePlaylist(int id) async {
    await isar.writeTxn(() async => await isar.playlistModels.delete(id));
  }

  Future<void> renamePlaylist(int id, String newName) async {
    await isar.writeTxn(() async {
      final exists = await playlistExists(newName);
      if (exists) return;

      final playlist = await isar.playlistModels.get(id);
      if (playlist != null) {
        playlist.title = newName;
        await isar.playlistModels.put(playlist);
      }
    });
  }

  Future<List<PlaylistModel>> getAllPlaylists() async {
    return await isar.playlistModels.where().findAll();
  }

  Future<List<PlaylistModel>> getYtbPlaylists() async {
    return await isar.playlistModels.filter().isYoutubeEqualTo(true).findAll();
  }

  Future<void> addSongToPlaylist(
    int playlistId,
    SongModel song, {
    int listenedSeconds = 0,
  }) async {
    await isar.writeTxn(() async {
      final playlist = await isar.playlistModels.get(playlistId);
      if (playlist != null) {
        // Kiểm tra bài hát đã tồn tại trong DB chưa
        var existingSong = await isar.songModels
            .filter()
            .songIdEqualTo(song.songId)
            .findFirst();

        if (existingSong == null) {
          final newId = await isar.songModels.put(song);
          existingSong = song..id = newId;
        }

        // cập nhật lịch sử nghe
        existingSong.playCount += 1;
        existingSong.totalListenSeconds += listenedSeconds;
        existingSong.lastPlayedAt = DateTime.now();
        await isar.songModels.put(existingSong);

        // Kiểm tra xem bài hát đã nằm trong playlist chưa
        final isInPlaylist = await playlist.songs
            .filter()
            .songIdEqualTo(song.songId)
            .findFirst();

        if (isInPlaylist == null) {
          playlist.songs.add(existingSong);
          await playlist.songs.save();
        }
      }
    });
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await isar.writeTxn(() async {
      final playlist = await isar.playlistModels.get(playlistId);
      final song = await isar.songModels.get(songId);
      if (playlist != null && song != null) {
        playlist.songs.remove(song);
        await playlist.songs.save();
      }
    });
  }

  Future<List<SongModel>> getSongsInPlaylist(int playlistId) async {
    final playlist = await isar.playlistModels.get(playlistId);
    if (playlist != null) {
      return playlist.songs.toList();
    }
    return [];
  }

  Future<int?> addOrGetSong(SongModel song) async {
    final existing =
        await isar.songModels.filter().songIdEqualTo(song.songId).findFirst();
    if (existing != null) return existing.id;
    return await isar.writeTxn(() async => await isar.songModels.put(song));
  }

  Future<bool> isSongInPlaylist(int playlistId, String videoId) async {
    final playlist = await isar.playlistModels.get(playlistId);
    if (playlist != null) {
      final exists =
          await playlist.songs.filter().songIdEqualTo(videoId).findFirst();
      return exists != null;
    }
    return false;
  }

  /// Liked Songs
  ///
  ///
  Future<PlaylistModel> getLikedPlaylist() async {
    return await getOrCreatePlaylist(likedSongs);
  }

  Future<void> addToLiked(SongModel song) async {
    final playlist = await getOrCreatePlaylist(likedSongs);
    await addSongToPlaylist(playlist.id, song);
  }

  Future<void> removeFromLiked(String videoId) async {
    final playlist = await getPlaylistByName(likedSongs);
    if (playlist != null) {
      final song =
          await playlist.songs.filter().songIdEqualTo(videoId).findFirst();
      if (song != null) {
        await removeSongFromPlaylist(playlist.id, song.id);
      }
    }
  }

  Future<List<SongModel>> getLikedSongs() async {
    final playlist = await getPlaylistByName(likedSongs);
    return playlist?.songs.toList() ?? [];
  }

  Future<bool> isLiked(String videoId) async {
    final playlist = await getPlaylistByName(likedSongs);
    if (playlist != null) {
      return await isSongInPlaylist(playlist.id, videoId);
    }
    return false;
  }

  /// Recently Played
  ///
  ///

  Future<PlaylistModel> getRecentlyPlaylist() async {
    return await getOrCreatePlaylist(recentlyPlayed);
  }

  Future<void> addToRecentlyPlayed(
    SongModel song, {
    int listenedSeconds = 0,
  }) async {
    final playlist = await getOrCreatePlaylist(recentlyPlayed);
    await addSongToPlaylist(
      playlist.id,
      song,
      listenedSeconds: listenedSeconds,
    );
  }

  Future<List<SongModel>> getRecentlyPlayedSongs() async {
    final playlist = await getPlaylistByName(recentlyPlayed);
    if (playlist != null) {
      await playlist.songs.load(); // Đảm bảo dữ liệu được load từ Isar
      final songs = playlist.songs.toList();
      songs.sort((a, b) => (b.lastPlayedAt ?? DateTime(1970))
          .compareTo(a.lastPlayedAt ?? DateTime(1970)));
      return songs;
    }
    return [];
  }

  ///
  ///
  ///SEARCH
  ///

  Future<void> addSearchHistory({
    required String keyword,
    required String type,
    String? subtitle,
    String? imageUrl,
  }) async {
    final existing = await isar.searchHistoryModels
        .filter()
        .keywordEqualTo(keyword)
        .typeEqualTo(type)
        .findFirst();

    await isar.writeTxn(() async {
      if (existing != null) {
        // Nếu đã tồn tại, cập nhật createdAt về thời gian hiện tại
        existing.createdAt = DateTime.now();
        existing.searchCount += 1;
        await isar.searchHistoryModels.put(existing);
      } else {
        // Nếu chưa có, tạo mới
        final history = SearchHistoryModel()
          ..keyword = keyword
          ..type = type
          ..searchCount = 1
          ..createdAt = DateTime.now();
        await isar.searchHistoryModels.put(history);
      }
    });
  }

  Future<List<SearchHistoryModel>> getRecentSearches({int limit = 10}) async {
    return await isar.searchHistoryModels
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  Future<void> deleteSearchHistory(int id) async {
    await isar.writeTxn(() async => await isar.searchHistoryModels.delete(id));
  }

  Future<void> clearAllSearchHistory() async {
    await isar.writeTxn(() async => await isar.searchHistoryModels.clear());
  }

  Future<List<SongModel?>> getSongsByIds(List<String> songIds) async {
    return await isar.songModels.getAllBySongId(songIds);
  }

  ///
  ///Artist
  ///
  Future<void> addArtist(ArtistModel artist) async {
    await isar.writeTxn(() async {
      await isar.artistModels.put(artist); // tự động sinh id nếu null
    });
  }

  Future<void> deleteArtistById(int id) async {
    await isar.writeTxn(() async {
      await isar.artistModels.delete(id);
    });
  }

  Future<ArtistModel?> getArtistById(int id) async {
    return await isar.artistModels.get(id);
  }

  Future<List<ArtistModel>> getAllArtists() async {
    return await isar.artistModels.where().findAll();
  }

  Future<void> deleteAllArtists() async {
    await isar.writeTxn(() async {
      await isar.artistModels.clear();
    });
  }

  Future<bool> existsArtistById(int id) async {
    return await isar.artistModels.get(id) != null;
  }

  Future<bool> existsArtistByName(String name) async {
    final count = await isar.artistModels.filter().nameEqualTo(name).count();

    return count > 0;
  }

  Future<List<SongModel>> getRelatedVideosWithCache({
    required String videoId,
    required String userId,
  }) async {
    final cache = await isar.relatedVideoCaches
        .filter()
        .videoIdEqualTo(videoId)
        .userIdEqualTo(userId)
        .findFirst();

    // Nếu có cache và chưa hết hạn (ví dụ TTL = 1 ngày)
    if (cache != null &&
        DateTime.now().difference(cache.cachedAt) < const Duration(days: 5)) {
      return decodeRelatedVideos(cache.relatedVideosJson);
    }

    // Nếu không có hoặc hết hạn → gọi API
    final relatedVideos = await YtbService.getRelatedVideos(
      videoId: videoId,
    );

    // Lưu lại cache
    await isar.writeTxn(() async {
      await isar.relatedVideoCaches.put(
        RelatedVideoCache()
          ..videoId = videoId
          ..userId = userId
          ..cachedAt = DateTime.now()
          ..relatedVideosJson = encodeRelatedVideos(relatedVideos),
      );
    });

    return relatedVideos;
  }

  //UTILS
  String encodeRelatedVideos(List<SongModel> songs) {
    return jsonEncode(songs.map((e) => e.toJson()).toList());
  }

  List<SongModel> decodeRelatedVideos(String jsonString) {
    final list = jsonDecode(jsonString) as List;
    return list.map((e) => SongModel.fromJson(e)).toList();
  }
}
