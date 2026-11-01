import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/library/library_controller.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/async_loader.dart';
import 'package:muzee/widgets/confirmation_dialog.dart';
import 'package:muzee/widgets/monetization/banner_ad_widget.dart';
import 'package:muzee/widgets/muzee_artwork.dart';
import 'package:muzee/widgets/page_title.dart';
import 'package:muzee/widgets/section_header.dart';

class LibraryMobileView extends StatelessWidget {
  const LibraryMobileView({super.key, required this.controller});
  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTitle(
              l10n.library,
              trailing: IconButton(
                tooltip: l10n.createNew,
                icon: const Icon(FluentIcons.add_24_regular),
                onPressed: () => _showCreateSheet(context),
              ),
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.multiListenable,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStaticGroup(context),
              _buildPinnedPlaylistsGroup(context),
              _buildUserPlaylistsGroup(context),
              _buildAddedPlaylistsGroup(context),
              // After the library itself, never in front of it.
              const BannerAdWidget(placement: AdBannerPlacement.library),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaticGroup(BuildContext context) {
    final l10n = context.l10n!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.neo.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _StaticTile(
            title: l10n.recentlyPlayed,
            icon: FluentIcons.history_24_regular,
            onTap: controller.openRecentlyPlayed,
          ),
          Divider(height: 1, color: context.neo.hairline, indent: 56),
          _StaticTile(
            title: l10n.likedSongs,
            icon: FluentIcons.heart_24_filled,
            onTap: controller.openLikedSongs,
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedPlaylistsGroup(BuildContext context) {
    final ids = controller.pinnedPlaylistIdsNotifier.value;
    if (ids.isEmpty) return const SizedBox.shrink();
    final items = resolvePinnedPlaylists(ids);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        SectionHeader(
          title: context.l10n!.pinnedPlaylists,
          icon: FluentIcons.pin_24_filled,
        ),
        _buildGroupCard(context, items),
      ],
    );
  }

  Widget _buildUserPlaylistsGroup(BuildContext context) {
    final items = [
      ...controller.userPlaylistFoldersNotifier.value,
      ...getPlaylistsNotInFolders(),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _buildGroupCard(context, items),
    );
  }

  Widget _buildAddedPlaylistsGroup(BuildContext context) {
    if (!controller.hasAddedPlaylists) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AsyncLoader<List<dynamic>>(
        future: controller.getAddedPlaylists(),
        emptyWidget: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              context.l10n!.noPlaylistsAdded,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.neo.onSurfaceMuted,
              ),
            ),
          ),
        ),
        builder: _buildGroupCard,
      ),
    );
  }

  /// "Danh sách phát · 12 bài hát" (or "Album · …"). A YouTube playlist
  /// added by link has no songs until it is opened, so it is just labelled
  /// a playlist.
  String _subtitle(BuildContext context, Map item) {
    final l10n = context.l10n!;
    if (item['playlists'] != null) {
      return '${l10n.playlists} · ${(item['playlists'] as List).length}';
    }
    final songs = item['list'];
    if (item['isAlbum'] == true) {
      return songs is List && songs.isNotEmpty
          ? '${l10n.album} · ${l10n.songCount(songs.length)}'
          : l10n.album;
    }
    return songs is List && songs.isNotEmpty
        ? l10n.playlistSongCount(songs.length)
        : l10n.playlist;
  }

  Widget _buildGroupCard(BuildContext context, List items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: items.map((item) {
          final isFolder = item['playlists'] != null;
          return _PlaylistTile(
            title: item['loadFailed'] == true
                ? context.l10n!.playlistFetchFailed
                : (item['title'] ?? item['name'] ?? '').toString(),
            subtitle: _subtitle(context, item),
            artworkUrl: item['image']?.toString(),
            isFolder: isFolder,
            onTap: () => isFolder
                ? controller.openFolder(context, item)
                : controller.openPlaylist(context, item),
            onMore: () => _showActions(context, item, isFolder: isFolder),
          );
        }).toList(),
      ),
    );
  }

  /// The "⋮" menu of a library row: pin and remove (destructive, last).
  void _showActions(BuildContext context, Map item, {required bool isFolder}) {
    final l10n = context.l10n!;
    final id = item['ytid']?.toString();
    final pinned = id != null && isPlaylistPinned(id);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isFolder
                    ? FluentIcons.folder_open_24_regular
                    : FluentIcons.open_24_regular,
              ),
              title: Text(l10n.open),
              onTap: () {
                Navigator.pop(sheetContext);
                isFolder
                    ? controller.openFolder(context, item)
                    : controller.openPlaylist(context, item);
              },
            ),
            if (!isFolder && id != null)
              ListTile(
                leading: Icon(
                  pinned
                      ? FluentIcons.pin_off_24_regular
                      : FluentIcons.pin_24_regular,
                ),
                title: Text(pinned ? l10n.unpinFromLibrary : l10n.pinToLibrary),
                onTap: () {
                  Navigator.pop(sheetContext);
                  togglePinnedPlaylist(id, context);
                },
              ),
            ListTile(
              leading: Icon(
                FluentIcons.delete_24_regular,
                color: context.neo.danger,
              ),
              title: Text(
                isFolder ? l10n.deleteFolder : l10n.removePlaylist,
                style: TextStyle(color: context.neo.danger),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                isFolder
                    ? _showDeleteFolderDialog(context, item)
                    : _showRemovePlaylistDialog(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// "+": a new playlist (own, or a YouTube playlist by link) or folder.
  void _showCreateSheet(BuildContext context) {
    final l10n = context.l10n!;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(FluentIcons.album_add_24_regular),
              title: Text(l10n.createPlaylist),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.createPlaylist(context);
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.folder_add_24_regular),
              title: Text(l10n.createFolder),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateFolderDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemovePlaylistDialog(BuildContext context, Map playlist) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => ConfirmationDialog(
          confirmationMessage: context.l10n!.removePlaylistQuestion,
          submitMessage: context.l10n!.remove,
          isDangerous: true,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onSubmit: () {
            Navigator.of(dialogContext).pop();
            controller.removePlaylist(context, playlist);
          },
        ),
      );

  void _showCreateFolderDialog(BuildContext context) {
    final l10n = context.l10n!;
    var folderName = '';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createFolder),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.folderName),
          onChanged: (value) => folderName = value,
          onSubmitted: (_) {
            Navigator.pop(dialogContext);
            controller.createFolder(context, folderName);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              controller.createFolder(context, folderName);
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(BuildContext context, Map folder) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => ConfirmationDialog(
          confirmationMessage: context.l10n!.deleteFolderQuestion,
          submitMessage: context.l10n!.delete,
          isDangerous: true,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onSubmit: () {
            Navigator.of(dialogContext).pop();
            controller.deleteFolder(context, folder);
          },
        ),
      );
}

class _StaticTile extends StatelessWidget {
  const _StaticTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: context.neo.onSurface, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                FluentIcons.chevron_right_24_regular,
                color: context.neo.onSurfaceMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.title,
    required this.subtitle,
    this.artworkUrl,
    required this.isFolder,
    required this.onTap,
    required this.onMore,
  });
  final String title;
  final String subtitle;
  final String? artworkUrl;
  final bool isFolder;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            if (isFolder)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.neo.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FluentIcons.folder_24_filled,
                  color: context.neo.onSurface,
                  size: 28,
                ),
              )
            else
              MuzeeArtwork(url: artworkUrl, width: 56, height: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: text.bodyMedium?.copyWith(
                      color: context.neo.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n!.moreOptions,
              icon: Icon(
                FluentIcons.more_vertical_24_regular,
                color: context.neo.onSurfaceMuted,
              ),
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}
