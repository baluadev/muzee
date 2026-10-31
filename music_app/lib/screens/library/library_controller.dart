import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/adaptive_navigation.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/playlist_dialogs.dart';

class LibraryController {
  // Expose global observables for the view to listen to
  ValueListenable<bool> get offlineModeNotifier => offlineMode;
  ValueListenable<List> get userPlaylistFoldersNotifier => userPlaylistFolders;
  ValueListenable<List> get userPlaylistsNotifier => userPlaylists;
  ValueListenable<List> get userCustomPlaylistsNotifier => userCustomPlaylists;
  ValueListenable<int> get currentOfflineSongsLengthNotifier =>
      currentOfflineSongsLength;
  ValueListenable<List<String>> get pinnedPlaylistIdsNotifier =>
      pinnedPlaylistIds;

  // The view can use a Listenable.merge to trigger rebuilds
  Listenable get multiListenable => Listenable.merge([
    pinnedPlaylistIds,
    userCustomPlaylists,
    userPlaylistFolders,
    currentLikedPlaylistsLength,
    onlinePlaylists,
    userPlaylists,
  ]);

  /// Playlists added by link plus those saved from a playlist page.
  bool get hasAddedPlaylists =>
      userPlaylists.value.isNotEmpty || userLikedPlaylists.isNotEmpty;

  Future<List<dynamic>> getAddedPlaylists() async {
    final added = await getUserPlaylistsNotInFolders();
    final ids = added.map((p) => p['ytid']).toSet();
    return [
      ...added,
      ...userLikedPlaylists.where((p) => !ids.contains(p['ytid'])),
    ];
  }

  void openRecentlyPlayed() {
    NavigationManager.router.go('/library/userSongs/recents');
  }

  void openLikedSongs() {
    NavigationManager.router.go('/library/userSongs/liked');
  }

  void openFolder(BuildContext context, Map folder) {
    AdaptiveNavigation.pushFolder(
      context,
      folderId: folder['id']?.toString() ?? '',
      folderName: folder['name']?.toString() ?? '',
      folderData: folder,
    );
  }

  void openPlaylist(BuildContext context, Map playlist) {
    AdaptiveNavigation.pushPlaylist(
      context,
      playlistData: playlist,
      baseRoute: '/library',
    );
  }

  void createPlaylist(BuildContext context) {
    showCreatePlaylistDialog(context);
  }

  void createFolder(BuildContext context, String folderName) {
    if (folderName.trim().isNotEmpty) {
      final result = createPlaylistFolder(folderName.trim(), context);
      showToast(context, result);
    } else {
      showToast(context, context.l10n!.enterFolderName);
    }
  }

  void deleteFolder(BuildContext context, Map folder) {
    final result = deletePlaylistFolder(folder['id'], context);
    showToast(context, result);
  }

  void removePlaylist(BuildContext context, Map playlist) {
    final playlistId = playlist['ytid']?.toString() ?? '';

    if (playlistId.isEmpty) {
      logger.log('Playlist ID is missing, cannot remove playlist.');
      showToast(context, context.l10n!.error);
      return;
    }

    removeUserPlaylistEntry(playlist);
  }
}
