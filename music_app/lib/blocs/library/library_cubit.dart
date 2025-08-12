import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/services/database/db_service.dart';
import 'package:muzee/services/ytb/ytb_service.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(LibraryInitial()) {
    initDefaultPlaylists();
  }

  Future<void> initDefaultPlaylists() async {
    await DBService.inst.createPlaylistIfNotExists(likedSongs);
    await DBService.inst.createPlaylistIfNotExists(recentlyPlayed);
    await getSongsRecently();
  }

  Future<void> createDefaultPlaylist(String name) async {
    await DBService.inst.createPlaylistIfNotExists(name);
    getAllPlaylist();
  }

  ///
  ///
  /// PLAYLIST
  ///
  Future getAllPlaylist() async {
    final playlists = await DBService.inst.getAllPlaylists();
    playlists.removeWhere((element) =>
        element.title == likedSongs || element.title == recentlyPlayed || element.isYoutube);
    emit(PlaylistListUpdate(playlists: playlists));
  }

  Future getYtbPlaylists() async {
    final playlists = await DBService.inst.getYtbPlaylists();
    emit(YtbPlaylistListUpdate(playlists: playlists));
  }

  Future<bool> existSongInLikedPlaylist(String songId) async {
    final playlist = await DBService.inst.getPlaylistByName(likedSongs);
    if (playlist != null) {
      return await DBService.inst.isSongInPlaylist(playlist.id, songId);
    }
    return false;
  }

  Future<bool> existSongInPlaylist(int playlistId, String songId) async {
    // final playlist = await DBService.inst.getPlaylistById(playlistId);
    return await DBService.inst.isSongInPlaylist(playlistId, songId);
  }

  Future<void> addSongFromPlaylist(
    PlaylistModel playlist,
    SongModel song,
  ) async {
    await DBService.inst.addSongToPlaylist(playlist.id, song);
    final playlistUpdated = await DBService.inst.getPlaylistById(playlist.id);
    emit(PlaylistUpdate(playlist: playlistUpdated));
  }

  Future<void> removeSongFromPlaylist(
    PlaylistModel playlist,
    SongModel song,
  ) async {
    await DBService.inst.removeSongFromPlaylist(playlist.id, song.id);
    final playlistUpdated = await DBService.inst.getPlaylistById(playlist.id);
    emit(PlaylistUpdate(playlist: playlistUpdated));
  }

  Future<void> renamePlaylist(
    int playlistId,
    String newName,
  ) async {
    await DBService.inst.renamePlaylist(playlistId, newName);
    final playlistUpdated = await DBService.inst.getPlaylistById(playlistId);
    await getAllPlaylist();
    emit(PlaylistUpdate(playlist: playlistUpdated));
  }

  Future<void> removePlaylist(
    int playlistId,
  ) async {
    await DBService.inst.deletePlaylist(playlistId);
    getAllPlaylist();
  }

  ///
  ///IMPORT YOUTUBE PLAYLIST
  ///

  Future<void> importYtbPlaylistFromId(String playlistId) async {
         print('importYtbPlaylistFromId');
    final playlist = await YtbService.getPlaylistFromYtbId(playlistId);
    print(playlist);
    if (playlist != null) {
      final idP = await DBService.inst.importPlaylistModel(playlist);
      final songs = await YtbService.getSongOfPlaylistFromYtbId(playlistId);
      for (var song in songs) {
        await DBService.inst.addSongToPlaylist(idP, song);
      }
      final playlists = await DBService.inst.getYtbPlaylists();
      emit(YtbPlaylistListUpdate(playlists: playlists));
    }
  }

  ///
  /// Liked Songs
  ///
  Future<void> addToLiked(SongModel song) async {
    await DBService.inst.addToLiked(song);
    await getLikedSongs();
  }

  Future<void> removeFromLiked(String videoId) async {
    await DBService.inst.removeFromLiked(videoId);
    await getLikedSongs();
  }

  Future<void> getLikedSongs() async {
    final songs = await DBService.inst.getLikedSongs();
    emit(PlaylistLikedUpdate(songs: songs));
  }

  Future<bool> isLiked(String videoId) async {
    return await DBService.inst.isLiked(videoId);
  }

  ///
  /// Recently Played
  ///

  Future<void> followArtist(ArtistModel artist, {bool add = true}) async {
    if (add) {
      await DBService.inst.addArtist(artist);
    } else {
      await DBService.inst.deleteArtistById(artist.id);
    }
    final artists = await DBService.inst.getAllArtists();
    emit(ArtistFollowState(artists: artists));
  }

  ///
  /// Recently Played
  ///
  Future<void> addSongRecently(
    SongModel song, {
    int listenedSeconds = 0,
  }) async {
    await DBService.inst.addToRecentlyPlayed(
      song,
      listenedSeconds: listenedSeconds,
    );
    await getSongsRecently();
  }

  Future<void> getSongsRecently() async {
    final songs = await DBService.inst.getRecentlyPlayedSongs();
    emit(PlaylistRecentlyUpdate(songs: songs));
  }

  double computeSongScore(SongModel song) {
    final now = DateTime.now();
    final daysSinceLastPlayed = now.difference(song.lastPlayedAt ?? now).inDays;

    return song.playCount * 2 +
        song.totalListenSeconds / 60 +
        (30 - daysSinceLastPlayed).clamp(0, 30) * 0.5;
  }

  Future<List<SongModel>> getSuggestedNextSongs({int limit = 10}) async {
    final allSongs = await DBService.inst.getRecentlyPlayedSongs();

    final scoredSongs =
        allSongs.map((song) => MapEntry(song, computeSongScore(song))).toList();

    scoredSongs.sort((a, b) => b.value.compareTo(a.value));

    return scoredSongs.map((e) => e.key).take(limit).toList();
  }

  Future<List<PlaylistModel>> generateMultipleSuggestedPlaylists({
    int numPlaylists = 5,
    int songsPerPlaylist = 10,
  }) async {
    final recentlyPlayed = await DBService.inst.getRecentlyPlayedSongs();
    final trendingSongs = await YtbService.fetchTrendingMusicSongs();
    final allSongs = mergeAndRemoveDuplicates(
      listA: recentlyPlayed,
      listB: trendingSongs,
    );
    // Tính điểm cho tất cả bài hát
    final scoredSongs = allSongs
        .map((song) => MapEntry(song, computeSongScore(song)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Lấy đủ số lượng bài hát cần
    final totalNeeded = numPlaylists * songsPerPlaylist;
    final selectedSongs =
        scoredSongs.take(totalNeeded).map((e) => e.key).toList();

    // Chia đều thành các playlist, không trùng nhau
    List<PlaylistModel> playlists = [];

    for (int i = 0; i < numPlaylists; i++) {
      final start = i * songsPerPlaylist;
      final end = (start + songsPerPlaylist).clamp(0, selectedSongs.length);
      if (start < end) {
        final songsChunk = selectedSongs.sublist(start, end);

        final fakeList = songsChunk[Random().nextInt(songsChunk.length)];
        final playlist = PlaylistModel(
          title: 'Mix ${i + 1}',
          thumbnailUrl: Utils.thumbM(fakeList.songId),
          artist: 'Nhiều nghệ sỹ',
        );
        playlist.tempSongs = songsChunk;
        playlists.add(playlist);
      }
    }
    return playlists.reversed.toList();
  }

  List<SongModel> mergeAndRemoveDuplicates({
    required List<SongModel> listA,
    required List<SongModel> listB,
  }) {
    final seenSongIds = <String>{};
    final merged = <SongModel>[];

    for (final song in [...listA, ...listB]) {
      if (!seenSongIds.contains(song.songId)) {
        seenSongIds.add(song.songId);
        merged.add(song);
      }
    }

    return merged;
  }
}
