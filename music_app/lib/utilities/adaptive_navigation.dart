import 'package:flutter/material.dart';
import 'package:muzee/screens/artist_details_page.dart';
import 'package:muzee/screens/playlist_folder_page.dart';
import 'package:muzee/screens/playlist_page.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/utilities/responsive_layout.dart';
import 'package:muzee/utilities/tablet_detail_manager.dart';

class AdaptiveNavigation {
  /// Navigates to the playlist page. On tablets, displays it in the detail pane.
  static void pushPlaylist(
    BuildContext context, {
    String? playlistId,
    Map? playlistData,
    String? baseRoute = '/home',
  }) {
    if (ResponsiveLayout.isTablet(context)) {
      TabletDetailManager.instance.show(
        PlaylistPage(playlistId: playlistId, playlistData: playlistData),
      );
    } else {
      if (playlistData != null) {
        NavigationManager.router.push(
          '$baseRoute/playlist',
          extra: playlistData,
        );
      } else if (playlistId != null) {
        NavigationManager.router.push('$baseRoute/playlist/$playlistId');
      }
    }
  }

  /// Navigates to the artist details page. On tablets, displays it in the detail pane.
  static void pushArtist(
    BuildContext context, {
    required String artistId,
    String? baseRoute = '/home',
  }) {
    if (ResponsiveLayout.isTablet(context)) {
      TabletDetailManager.instance.show(ArtistDetailsPage(artistId: artistId));
    } else {
      final encodedId = Uri.encodeComponent(artistId);
      NavigationManager.router.push('$baseRoute/artist/$encodedId');
    }
  }

  /// Navigates to the playlist folder page. On tablets, displays it in the detail pane.
  static void pushFolder(
    BuildContext context, {
    required String folderId,
    required String folderName,
    Map? folderData,
    String? baseRoute = '/library',
  }) {
    if (ResponsiveLayout.isTablet(context)) {
      TabletDetailManager.instance.show(
        PlaylistFolderPage(folderId: folderId, folderName: folderName),
      );
    } else {
      if (folderData != null) {
        NavigationManager.router.push('$baseRoute/folder', extra: folderData);
      } else {
        NavigationManager.router.push(
          '$baseRoute/folder/$folderId/$folderName',
        );
      }
    }
  }
}
