import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/widgets/muzee_artwork.dart';
import 'package:muzee/widgets/playlist_artwork.dart';

class PlaylistCube extends StatelessWidget {
  const PlaylistCube(
    this.playlist, {
    super.key,
    this.playlistData,
    this.cubeIcon = FluentIcons.text_bullet_list_24_filled,
    this.size = 220,
    this.borderRadius = 16,
    this.showTypeLabel = true,
  });

  final Map? playlistData;
  final Map playlist;
  final IconData cubeIcon;
  final double size;
  final double borderRadius;
  final bool showTypeLabel;

  static const double typeLabelOffset = 10;

  /// The first song of [playlist], when it has songs: its artwork stands in
  /// for a playlist or album that has no cover of its own.
  Map? get _firstSong {
    final songs = playlist['list'];
    if (songs is! List) return null;
    for (final song in songs) {
      if (song is Map) return song;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cover = playlist['image']?.toString();
    final firstSong = cover == null ? _firstSong : null;
    final firstSongArt = (firstSong?['highResImage'] ?? firstSong?['image'])
        ?.toString();
    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (cover == null && firstSongArt != null)
            // MuzeeArtwork steps down to smaller thumbnails for old videos.
            MuzeeArtwork(
              url: firstSongArt,
              width: size,
              height: size,
              borderRadius: 0,
              iconSize: size * 0.3,
              fallbackIcon: cubeIcon,
            )
          else
            PlaylistArtwork(
              playlistArtwork: cover,
              size: size,
              cubeIcon: cubeIcon,
            ),
          if (showTypeLabel && playlist['image'] != null)
            Positioned(
              top: typeLabelOffset,
              right: typeLabelOffset,
              child: _buildLabel(context),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAlbum = playlist['isAlbum'] == true;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        isAlbum ? context.l10n!.album : context.l10n!.playlist,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
