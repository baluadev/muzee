import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/constants/app_constants.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/flutter_toast.dart';
import 'package:muzee/utilities/formatter.dart';
import 'package:muzee/utilities/playlist_dialogs.dart';
import 'package:muzee/widgets/no_artwork_cube.dart';
import 'package:muzee/widgets/playing_indicator.dart';
import 'package:muzee/widgets/rename_song_dialog.dart';

class SongBar extends StatefulWidget {
  const SongBar(
    this.song,
    this.clearPlaylist, {
    this.backgroundColor,
    this.showMusicDuration = false,
    this.onPlay,
    this.isRecentSong,
    this.onRemove,
    this.borderRadius = BorderRadius.zero,
    this.isFromLikedSongs = false,
    this.showQueueActions = true,
    this.showPlayTime = false,
    this.playlistId,
    this.onRenamed,
    super.key,
  });

  final dynamic song;
  final bool clearPlaylist;
  final Color? backgroundColor;
  final VoidCallback? onRemove;
  final VoidCallback? onPlay;
  final bool? isRecentSong;
  final bool showMusicDuration;
  final bool showPlayTime;
  final BorderRadius borderRadius;
  final bool isFromLikedSongs;
  final bool showQueueActions;
  final String? playlistId;
  final VoidCallback? onRenamed;

  @override
  State<SongBar> createState() => _SongBarState();
}

class _SongBarState extends State<SongBar> {
  static const likeStatusToIconMapper = {
    true: FluentIcons.heart_off_24_regular,
    false: FluentIcons.heart_24_regular,
  };

  late final ValueNotifier<bool> _songLikeStatus;
  late String _songTitle;
  late String _songArtist;
  late final String _lowResImageUrl;
  late final String _ytid;

  @override
  void initState() {
    super.initState();

    // Cache frequently accessed values
    _songTitle = widget.song['title'] ?? '';
    _songArtist = widget.song['artist']?.toString() ?? '';
    _lowResImageUrl = widget.song['lowResImage']?.toString() ?? '';
    _ytid = widget.song['ytid'] ?? '';

    // Initialize ValueNotifiers only once
    _songLikeStatus = ValueNotifier(isSongAlreadyLiked(_ytid));
  }

  @override
  void didUpdateWidget(SongBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update cached title and artist if they changed
    final newTitle = widget.song['title'] ?? '';
    final newArtist = widget.song['artist']?.toString() ?? '';

    if (_songTitle != newTitle || _songArtist != newArtist) {
      setState(() {
        _songTitle = newTitle;
        _songArtist = newArtist;
      });
    }
  }

  @override
  void dispose() {
    _songLikeStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final _plays = widget.showPlayTime
        ? (widget.song['listeningCount'] is int)
              ? widget.song['listeningCount'] as int
              : int.tryParse(widget.song['listeningCount']?.toString() ?? '') ??
                    0
        : null;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final isActive =
            mediaSnapshot.data?.extras?['ytid'] == _ytid && _ytid.isNotEmpty;

        return Padding(
          padding: commonBarPadding,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isActive ? context.neo.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _handleSongTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, stateSnapshot) {
                    final playbackState = stateSnapshot.data;
                    final isPlaying = playbackState?.playing ?? false;
                    final isBuffering =
                        playbackState?.processingState ==
                            AudioProcessingState.buffering ||
                        playbackState?.processingState ==
                            AudioProcessingState.loading;

                    return Row(
                      children: [
                        _buildAlbumArt(
                          colorScheme,
                          isActive,
                          isPlaying,
                          isBuffering,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SongInfo(
                            title: _songTitle,
                            artist: _songArtist,
                            plays: _plays,
                            colorScheme: colorScheme,
                            isActive: isActive,
                          ),
                        ),
                        if (isActive && isPlaying)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: PlayingIndicator(),
                          ),
                        _buildActionButtons(context, colorScheme),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSongTap() {
    if (widget.onPlay != null) {
      widget.onPlay!();
      return;
    }

    if (widget.clearPlaylist) {
      audioHandler.addPlaylistToQueue([widget.song], replace: true);
    } else {
      audioHandler.playSong(widget.song);
    }
  }

  Widget _buildAlbumArt(
    ColorScheme colorScheme,
    bool isActive,
    bool isPlaying,
    bool isBuffering,
  ) {
    const size = 52.0;
    final isDurationAvailable =
        widget.showMusicDuration && widget.song['duration'] != null;

    return ValueListenableBuilder<bool>(
      valueListenable: _songLikeStatus,
      builder: (_, isLiked, __) {
        return _OnlineArtwork(
          lowResImageUrl: _lowResImageUrl,
          size: size,
          isDurationAvailable: isDurationAvailable,
          colorScheme: colorScheme,
          duration: widget.song['duration'],
          isLiked: isLiked,
          isActive: isActive,
          isPlaying: isPlaying,
          isBuffering: isBuffering,
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: PopupMenuButton<String>(
          icon: Icon(
            FluentIcons.more_vertical_24_regular,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => _buildMenuItems(context, colorScheme),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'play_next':
        audioHandler.playNext(widget.song);
        showToast(
          context,
          context.l10n!.songAdded,
          duration: const Duration(seconds: 1),
        );
        break;
      case 'add_to_queue':
        audioHandler.addToQueue(widget.song);
        showToast(
          context,
          context.l10n!.songAdded,
          duration: const Duration(seconds: 1),
        );
        break;
      case 'like':
        final newValue = !_songLikeStatus.value;
        _songLikeStatus.value = newValue;
        final likedSongsLength = currentLikedSongsLength.value;
        currentLikedSongsLength.value = newValue
            ? likedSongsLength + 1
            : likedSongsLength - 1;
        updateSongLikeStatus(_ytid, newValue).catchError((e) {
          logger.log('Error updating song like status', error: e);
          // Revert on error
          _songLikeStatus.value = !newValue;
          currentLikedSongsLength.value = likedSongsLength;
        });
        showToast(
          context,
          newValue
              ? context.l10n!.addedToLikedSongs
              : context.l10n!.removedFromLikedSongs,
          duration: const Duration(seconds: 1),
        );
        break;
      case 'remove':
        widget.onRemove?.call();
        break;
      case 'rename':
        _handleRenameSong(context);
        break;
      case 'add_to_playlist':
        showAddToPlaylistDialog(context, song: widget.song);
        break;
      case 'remove_from_recents':
        removeFromRecentlyPlayed(_ytid).catchError((e) {
          logger.log('Error removing from recently played', error: e);
        });
        break;
    }
  }

  void _handleRenameSong(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RenameSongDialog(
        currentTitle: _songTitle,
        currentArtist: _songArtist,
        onRename: (newTitle, newArtist) {
          _renameSong(newTitle, newArtist, context);
        },
      ),
    );
  }

  Future<void> _renameSong(
    String newTitle,
    String newArtist,
    BuildContext context,
  ) async {
    try {
      if (widget.isFromLikedSongs) {
        await renameSongInLikedSongs(_ytid, newTitle, newArtist);
        widget.song['title'] = newTitle;
        widget.song['artist'] = newArtist;
        if (context.mounted) {
          setState(() {
            _songTitle = newTitle;
            _songArtist = newArtist;
          });
          showToast(context, context.l10n!.settingChangedMsg);
        }
      } else if (widget.playlistId != null) {
        await renameSongInPlaylist(
          widget.playlistId,
          _ytid,
          newTitle,
          newArtist,
        );
        widget.song['title'] = newTitle;
        widget.song['artist'] = newArtist;
        if (context.mounted) {
          setState(() {
            _songTitle = newTitle;
            _songArtist = newArtist;
          });
          showToast(context, context.l10n!.settingChangedMsg);
          widget.onRenamed?.call();
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error renaming song', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showToast(context, context.l10n!.error);
      }
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    // Capture localization strings before building menu items to avoid
    // accessing context.l10n inside ValueListenableBuilder which can fail
    // when the widget is being disposed
    final l10n = context.l10n!;
    final playNextText = l10n.playNext;
    final addToQueueText = l10n.addToQueue;
    final removeFromLikedSongsText = l10n.removeFromLikedSongs;
    final addToLikedSongsText = l10n.addToLikedSongs;
    final removeFromPlaylistText = l10n.removeFromPlaylist;
    final addToPlaylistText = l10n.addToPlaylist;
    final removeFromRecentlyPlayedText = l10n.removeFromRecentlyPlayed;
    final renameSongText = l10n.renameSong;
    final canRename = widget.isFromLikedSongs || widget.playlistId != null;

    return [
      if (widget.showQueueActions)
        PopupMenuItem<String>(
          value: 'play_next',
          child: Row(
            children: [
              Icon(
                FluentIcons.receipt_play_24_regular,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                playNextText,
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
        ),
      if (widget.showQueueActions)
        PopupMenuItem<String>(
          value: 'add_to_queue',
          child: Row(
            children: [
              Icon(
                FluentIcons.text_bullet_list_add_24_regular,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                addToQueueText,
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
        ),
      if (!offlineMode.value)
        PopupMenuItem<String>(
          value: 'like',
          child: ValueListenableBuilder<bool>(
            valueListenable: _songLikeStatus,
            builder: (_, value, __) {
              return Row(
                children: [
                  Icon(
                    likeStatusToIconMapper[value],
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value ? removeFromLikedSongsText : addToLikedSongsText,
                    style: TextStyle(color: colorScheme.secondary),
                  ),
                ],
              );
            },
          ),
        ),
      if (canRename)
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(FluentIcons.edit_24_regular, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                renameSongText,
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
        ),
      if (widget.onRemove != null)
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(FluentIcons.delete_24_regular, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                removeFromPlaylistText,
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
        ),
      if (!offlineMode.value)
        PopupMenuItem<String>(
          value: 'add_to_playlist',
          child: Row(
            children: [
              Icon(
                FluentIcons.album_add_24_regular,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                addToPlaylistText,
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
        ),
      if (widget.isRecentSong == true)
        PopupMenuItem<String>(
          value: 'remove_from_recents',
          child: Row(
            children: [
              Icon(FluentIcons.delete_24_regular, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                removeFromRecentlyPlayedText,
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
        ),
    ];
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({
    required this.title,
    required this.artist,
    this.plays,
    required this.colorScheme,
    required this.isActive,
  });

  final String title;
  final String artist;
  final int? plays;
  final ColorScheme colorScheme;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isActive ? context.neo.accent : context.neo.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                artist,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: context.neo.onSurfaceMuted,
                ),
              ),
            ),
            if (plays != null && plays! > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '•',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: context.neo.onSurfaceMuted,
                  ),
                ),
              ),
              Icon(
                FluentIcons.headphones_20_filled,
                size: 12,
                color: context.neo.onSurfaceMuted,
              ),
              const SizedBox(width: 3),
              Text(
                '$plays',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.neo.onSurfaceMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _OnlineArtwork extends StatelessWidget {
  const _OnlineArtwork({
    required this.lowResImageUrl,
    required this.size,
    required this.isDurationAvailable,
    required this.colorScheme,
    required this.duration,
    required this.isLiked,
    required this.isActive,
    required this.isPlaying,
    required this.isBuffering,
  });

  final String lowResImageUrl;
  final double size;
  final bool isDurationAvailable;
  final ColorScheme colorScheme;
  final dynamic duration;
  final bool isLiked;
  final bool isActive;
  final bool isPlaying;
  final bool isBuffering;

  @override
  Widget build(BuildContext context) {
    final isImageSmall = lowResImageUrl.contains('default.jpg');

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: lowResImageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth: 256,
            memCacheHeight: 256,
            imageBuilder: (context, imageProvider) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Image(
                    image: imageProvider,
                    fit: isImageSmall ? BoxFit.fill : BoxFit.cover,
                    width: size,
                    height: size,
                    centerSlice: isImageSmall
                        ? const Rect.fromLTRB(1, 1, 1, 1)
                        : null,
                  ),
                  if (isActive)
                    ColoredBox(
                      color: context.neo.artworkScrim,
                      child: Center(
                        child: isBuffering
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? FluentIcons.pause_24_filled
                                    : FluentIcons.play_24_filled,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                      ),
                    ),
                  if (isLiked)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FluentIcons.heart_24_filled,
                          size: 11,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            errorWidget: (context, url, error) =>
                const NullArtworkWidget(iconSize: 30),
          ),
          if (isDurationAvailable)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.85,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formatDuration(duration),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
