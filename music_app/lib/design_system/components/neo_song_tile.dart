import 'package:flutter/material.dart';
import 'package:muzee/design_system/components/neo_artwork.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_layout.dart';
import 'package:muzee/theme/neo/neo_typography.dart';

/// Where a song stands relative to the player.
enum NeoPlaybackState {
  /// Not the current song.
  none,
  buffering,
  playing,
  paused;

  bool get isCurrent => this != NeoPlaybackState.none;
}

/// A song row: artwork, title, artist, optional trailing action.
///
/// The current song is carried by four signals: the artwork overlay (bars or
/// spinner), the accent title color, a heavier title weight, and the selected
/// semantics with [currentLabel] as its value. Color is derived last from
/// [playbackState].
class NeoSongTile extends StatelessWidget {
  const NeoSongTile({
    required this.title,
    required this.subtitle,
    this.image,
    this.playbackState = NeoPlaybackState.none,
    this.currentLabel,
    this.leadingIndex,
    this.trailing,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final String title;
  final String subtitle;
  final ImageProvider? image;
  final NeoPlaybackState playbackState;

  /// Announced for the current song, e.g. the app's "Now playing".
  final String? currentLabel;

  /// Track number for album/chart lists.
  final int? leadingIndex;

  /// Usually a `NeoIconButton` with the "more" menu.
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final text = Theme.of(context).textTheme;
    final isCurrent = playbackState.isCurrent;

    final overlay = switch (playbackState) {
      NeoPlaybackState.none => null,
      NeoPlaybackState.buffering => SizedBox.square(
        dimension: layout.iconMedium,
        child: CircularProgressIndicator(
          strokeWidth: layout.focusWidth,
          color: c.onArtworkScrim,
        ),
      ),
      NeoPlaybackState.playing => NeoNowPlayingBars(
        isActive: true,
        color: c.onArtworkScrim,
      ),
      NeoPlaybackState.paused => NeoNowPlayingBars(
        isActive: false,
        color: c.onArtworkScrim,
      ),
    };

    return Semantics(
      selected: isCurrent,
      value: isCurrent ? currentLabel : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: layout.listRowMinHeight),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: layout.gutter,
              end: trailing == null ? layout.gutter : layout.space4,
              top: layout.space8,
              bottom: layout.space8,
            ),
            child: Row(
              children: [
                if (leadingIndex != null)
                  SizedBox(
                    width: layout.space32,
                    child: Text(
                      '$leadingIndex',
                      style: NeoTypeExtras.of(context).timecode,
                    ),
                  ),
                NeoArtwork(
                  size: layout.artworkTile,
                  image: image,
                  overlay: overlay,
                ),
                SizedBox(width: layout.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium!.copyWith(
                          color: isCurrent ? c.accent : c.onSurface,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: layout.space2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall!.copyWith(
                          color: c.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
