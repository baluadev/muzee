import 'dart:async';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/song_filtering.dart';
import 'package:muzee/utilities/sort_utils.dart';

enum PlaylistSortType { default_, title, artist }

class PlaylistController {
  PlaylistController({
    required this.context,
    this.playlistId,
    this.initialPlaylistData,
    this.cubeIcon = Icons.list,
    this.isArtist = false,
  }) {
    playlistLikeStatus.value = isPlaylistAlreadyLiked(playlistId);
    sortType.value = PlaylistSortType.values.firstWhere(
      (e) => e.name == playlistSortSetting,
      orElse: () => PlaylistSortType.default_,
    );
  }
  final String? playlistId;
  final dynamic initialPlaylistData;
  final IconData cubeIcon;
  final bool isArtist;
  final BuildContext context;

  final ValueNotifier<dynamic> playlistData = ValueNotifier(null);

  /// True when the songs couldn't be fetched (as opposed to an empty playlist).
  final ValueNotifier<bool> loadFailed = ValueNotifier(false);
  final ValueNotifier<bool> playlistLikeStatus = ValueNotifier(false);
  final ValueNotifier<PlaylistSortType> sortType = ValueNotifier(
    PlaylistSortType.default_,
  );
  final ValueNotifier<String> searchQueryNotifier = ValueNotifier('');

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  List<dynamic> _originalPlaylistList = [];

  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    playlistData.dispose();
    loadFailed.dispose();
    playlistLikeStatus.dispose();
    sortType.dispose();
    searchQueryNotifier.dispose();
  }

  Future<void> initializePlaylist() async {
    try {
      final resolvedId = initialPlaylistData?['ytid']?.toString() ?? playlistId;
      dynamic playlist;

      if (initialPlaylistData != null) {
        playlist = initialPlaylistData;
        final playlistList = playlist?['list'] as List?;
        if ((playlistList == null || playlistList.isEmpty) &&
            resolvedId != null) {
          playlist =
              await getPlaylistInfoForWidget(resolvedId, isArtist: isArtist) ??
              initialPlaylistData;
        }
      } else {
        playlist = await getPlaylistInfoForWidget(
          resolvedId,
          isArtist: isArtist,
        );
      }

      if (playlist != null && playlist['list'] != null) {
        _originalPlaylistList = List<dynamic>.from(playlist['list'] as List);
        playlistData.value = playlist;
        sortPlaylist(sortType.value);
      } else {
        playlistData.value = playlist;
      }
    } catch (e, stackTrace) {
      logger.log(
        'Error initializing playlist:',
        error: e,
        stackTrace: stackTrace,
      );
      // Keep the header (title, artwork) we already have; the page shows the
      // error with a Retry below it.
      final fallback = initialPlaylistData;
      if (playlistData.value == null && fallback is Map) {
        playlistData.value = {...fallback, 'list': fallback['list'] ?? []};
      }
      loadFailed.value = true;
    }
  }

  /// Loads the playlist again after a failure, showing the page spinner.
  Future<void> retryLoad() async {
    loadFailed.value = false;
    playlistData.value = null;
    await initializePlaylist();
  }

  List<dynamic> getSourceList() {
    final list = playlistData.value?['list'] as List<dynamic>? ?? [];
    return filterSongsByQuery(list, searchQueryNotifier.value);
  }

  void onSearchChanged(String value) {
    searchQueryNotifier.value = value;
  }

  void sortPlaylist(PlaylistSortType type) {
    if (playlistData.value == null || playlistData.value['list'] == null)
      return;
    final playlist = playlistData.value;

    switch (type) {
      case PlaylistSortType.default_:
        playlist['list'] = List<dynamic>.from(_originalPlaylistList);
        break;
      case PlaylistSortType.title:
        final list = List<dynamic>.from(playlist['list']);
        sortSongsByKey(list, 'title');
        playlist['list'] = list;
        break;
      case PlaylistSortType.artist:
        final list = List<dynamic>.from(playlist['list']);
        sortSongsByKey(list, 'artist');
        playlist['list'] = list;
        break;
    }

    playlistData.value = Map.from(playlist);
  }

  void setSortType(PlaylistSortType type) {
    sortType.value = type;
    addOrUpdateData('settings', 'playlistSortType', type.name);
    playlistSortSetting = type.name;
    sortPlaylist(type);
  }

  void toggleLikeStatus() {
    playlistLikeStatus.value = !playlistLikeStatus.value;
    unawaited(
      updatePlaylistLikeStatus(
        playlistData.value['ytid'],
        playlistLikeStatus.value,
      ),
    );
    if (playlistLikeStatus.value) {
      currentLikedPlaylistsLength.value++;
    } else {
      currentLikedPlaylistsLength.value--;
    }
  }

  Future<void> syncPlaylist() async {
    final id = playlistData.value?['ytid']?.toString();
    if (id == null || id.isEmpty) return;

    final updated = await updatePlaylistList(context, id);
    if (updated != null) {
      playlistData.value = updated;
      if (updated['list'] != null) {
        _originalPlaylistList = List<dynamic>.from(updated['list'] as List);
      }
    }
  }

  void shufflePlay() async {
    final songs = playlistData.value?['list'] as List? ?? [];
    if (songs.isEmpty) return;
    final shuffled = List<Map>.from(songs.whereType<Map>())..shuffle();
    await audioHandler.addPlaylistToQueue(
      shuffled,
      replace: true,
      startIndex: 0,
    );
  }

  void playSong(int index) {
    audioHandler.playPlaylistSong(
      playlist: playlistData.value,
      songIndex: index,
    );
  }

  void removeSong(int index, dynamic songToRemove) {
    if (removeSongFromPlaylist(
      playlistData.value,
      songToRemove,
      removeOneAtIndex: index,
    )) {
      _originalPlaylistList.removeWhere(
        (s) => s['ytid'] == songToRemove['ytid'],
      );
      final id = playlistData.value['ytid'];

      // Update value notifier to trigger rebuild
      playlistData.value = Map.from(playlistData.value);

      if (context.mounted) {
        showToastWithButton(
          context,
          context.l10n!.songRemoved,
          context.l10n!.undo,
          () {
            addSongInCustomPlaylist(
              context,
              id,
              songToRemove,
              indexToInsert: index,
            );
            // After undo, wait a tick and re-initialize or add back manually
            // Re-initializing is easiest
            initializePlaylist();
          },
        );
      }
    }
  }

  void onSongRenamed() {
    playlistData.value = Map.from(playlistData.value);
  }
}
