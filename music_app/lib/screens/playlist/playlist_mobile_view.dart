import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/screens/playlist/playlist_controller.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/app_utils.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/playlist_utils.dart';
import 'package:muzee/widgets/load_error_view.dart';
import 'package:muzee/widgets/monetization/native_ad_tile.dart';
import 'package:muzee/widgets/playlist_cube.dart';
import 'package:muzee/widgets/playlist_page/empty_playlist_state.dart';
import 'package:muzee/widgets/playlist_page/play_shuffle_buttons.dart';
import 'package:muzee/widgets/playlist_page/playlist_header.dart';
import 'package:muzee/widgets/song_bar.dart';
import 'package:muzee/widgets/spinner.dart';

class PlaylistMobileView extends StatelessWidget {
  const PlaylistMobileView({super.key, required this.controller});
  final PlaylistController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<dynamic>(
      valueListenable: controller.playlistData,
      builder: (context, playlist, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                icon: Icon(
                  FluentIcons.arrow_left_24_regular,
                  color: context.neo.onSurface,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(
                  context,
                  controller.initialPlaylistData == playlist,
                ),
                tooltip: context.l10n!.back,
              ),
            ),
            actions: _buildAppBarActions(context, playlist),
          ),
          body: playlist != null
              ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeaderSection(context, playlist),
                    ),
                    if (((playlist['list'] as List?) ?? const [])
                        .isNotEmpty) ...[
                      ValueListenableBuilder<String>(
                        valueListenable: controller.searchQueryNotifier,
                        builder: (context, searchQuery, _) {
                          final sourceList = controller.getSourceList();
                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            sliver: SliverList.builder(
                              itemCount: _adSlot.count(sourceList.length),
                              itemBuilder: (context, row) {
                                if (_adSlot.isAd(row, sourceList.length)) {
                                  return const NativeAdTile(
                                    placement: AdNativePlacement.playlist,
                                  );
                                }
                                final index = _adSlot.item(
                                  row,
                                  sourceList.length,
                                );
                                final isRemovable =
                                    playlist['source'] == 'user-created';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _buildSongListItem(
                                    context,
                                    playlist,
                                    sourceList[index],
                                    index,
                                    isRemovable,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ] else
                      ValueListenableBuilder<bool>(
                        valueListenable: controller.loadFailed,
                        builder: (context, failed, _) => failed
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: LoadErrorView(
                                  onRetry: controller.retryLoad,
                                ),
                              )
                            : EmptyPlaylistState(
                                message: context.l10n!.noSongsInPlaylist,
                              ),
                      ),
                  ],
                )
              : ValueListenableBuilder<bool>(
                  valueListenable: controller.loadFailed,
                  builder: (context, failed, _) => failed
                      ? LoadErrorView(onRetry: controller.retryLoad)
                      : SizedBox(
                          height: MediaQuery.sizeOf(context).height - 100,
                          child: const Spinner(),
                        ),
                ),
        );
      },
    );
  }

  Widget _buildPlaylistImage(BuildContext context, dynamic playlist) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth > MediaQuery.sizeOf(context).height;
    return PlaylistCube(
      playlist,
      size: isLandscape ? 250 : screenWidth * 0.8,
      cubeIcon: controller.cubeIcon,
      showTypeLabel: false,
    );
  }

  /// Who the playlist is from, under its title.
  String _ownerLabel(BuildContext context, Map playlist) {
    final l10n = context.l10n!;
    if (playlist['source'] == 'user-created') return l10n.yourPlaylist;
    if (playlist['isAlbum'] == true) {
      final artist = playlist['artist']?.toString() ?? '';
      return artist.isNotEmpty ? artist : l10n.album;
    }
    // The app's own curated lists vs. any playlist from YouTube.
    final curated = playlists.any((p) => p['ytid'] == playlist['ytid']);
    return curated ? l10n.createdByApp : l10n.youTube;
  }

  Widget _buildHeaderSection(BuildContext context, dynamic playlist) {
    final songsLength = (playlist['list'] as List?)?.length ?? 0;

    return Column(
      children: [
        PlaylistHeader(
          _buildPlaylistImage(context, playlist),
          playlist['title'],
          songsLength,
          isAlbum: playlist['isAlbum'] == true,
          owner: _ownerLabel(context, playlist),
        ),
        if (songsLength > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: PlayShuffleButtons(
              onPlay: () => controller.playSong(0),
              onShuffle: controller.shufflePlay,
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Save to library and Sync, in the app bar: both only make sense for a
  /// playlist that comes from YouTube (not one the user made).
  List<Widget> _buildAppBarActions(BuildContext context, dynamic playlist) {
    if (playlist == null) return const [];
    final l10n = context.l10n!;
    final isUserCreated = playlist['source'] == 'user-created';
    final canSave = controller.playlistId != null && !isUserCreated;
    final canSync =
        !isUserCreated &&
        playlist['isAlbum'] != true &&
        (playlist['ytid']?.toString().isNotEmpty ?? false);

    return [
      if (canSave)
        ValueListenableBuilder<bool>(
          valueListenable: controller.playlistLikeStatus,
          builder: (context, saved, _) => IconButton(
            tooltip: saved ? l10n.removeFromLibrary : l10n.saveToLibrary,
            isSelected: saved,
            icon: const Icon(FluentIcons.add_circle_24_regular),
            selectedIcon: Icon(
              FluentIcons.checkmark_circle_24_filled,
              color: context.neo.onSurface,
            ),
            onPressed: () {
              controller.toggleLikeStatus();
              showToast(
                context,
                controller.playlistLikeStatus.value
                    ? l10n.savedToLibrary
                    : l10n.removedFromLibrary,
              );
            },
          ),
        ),
      if (canSync)
        IconButton(
          tooltip: l10n.sync,
          icon: const Icon(FluentIcons.arrow_sync_24_regular),
          onPressed: controller.syncPlaylist,
        ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildSongListItem(
    BuildContext context,
    dynamic playlist,
    dynamic song,
    int index,
    bool isRemovable,
  ) {
    final sourceList = controller.getSourceList();
    final totalItems = sourceList.length;
    final borderRadius = getItemBorderRadius(index, totalItems);
    final isUserCreatedPlaylist = playlist['source'] == 'user-created';
    final playlistId = isUserCreatedPlaylist ? playlist['ytid'] : null;
    final isSearching = controller.searchQueryNotifier.value.isNotEmpty;
    final fullIndex = isSearching
        ? PlaylistUtils.findSongIndexByYtid(playlist, song['ytid'])
        : index;

    if (isSearching && fullIndex == -1) {
      logger.log('Warning: Song ${song['ytid']} not found in full playlist');
    }

    return SongBar(
      song,
      true,
      key: listItemKey('playlist_song', index, song),
      onRemove: (isRemovable && !isSearching)
          ? () => controller.removeSong(index, song)
          : null,
      onPlay: () {
        controller.playSong(fullIndex != -1 ? fullIndex : index);
      },
      borderRadius: borderRadius,
      playlistId: playlistId,
      onRenamed: controller.onSongRenamed,
    );
  }
}

/// One native ad after the first five songs.
const _adSlot = InlineAdSlot(5);
