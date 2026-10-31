import 'package:flutter/material.dart';
import 'package:muzee/design_system/components/neo_artwork.dart';
import 'package:muzee/design_system/components/neo_icon_button.dart';
import 'package:muzee/design_system/components/neo_play_button.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';
import 'package:muzee/theme/neo/neo_motion.dart';

/// Floating player bar above the navigation. Presentational only: the app
/// wires it to the audio handler.
class NeoMiniPlayer extends StatelessWidget {
  const NeoMiniPlayer({
    required this.title,
    required this.subtitle,
    required this.isPlaying,
    required this.onPlayPause,
    required this.playLabel,
    required this.pauseLabel,
    this.image,
    this.isBuffering = false,
    this.progress,
    this.onTap,
    this.onNext,
    this.nextLabel,
    super.key,
  }) : assert(
         onNext == null || nextLabel != null,
         'nextLabel is required when onNext is set.',
       );

  final String title;
  final String subtitle;
  final ImageProvider? image;
  final bool isPlaying;
  final bool isBuffering;

  /// 0..1, or null to hide the progress line.
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final String playLabel;
  final String pauseLabel;
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final shapes = NeoShapes.of(context);
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: c.surface,
        shape: shapes.cardShape(),
        shadows: NeoEffects.of(context).floating,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: shapes.cardShape(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: layout.miniPlayerHeight,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: layout.space8,
                    end: layout.space4,
                  ),
                  child: Row(
                    children: [
                      NeoArtwork(size: layout.artworkTile, image: image),
                      SizedBox(width: layout.space12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall,
                            ),
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
                      NeoPlayButton(
                        isPlaying: isPlaying,
                        isBuffering: isBuffering,
                        onPressed: onPlayPause,
                        playLabel: playLabel,
                        pauseLabel: pauseLabel,
                        size: NeoPlayButtonSize.small,
                      ),
                      if (onNext != null)
                        NeoIconButton(
                          icon: NeoIcons.next,
                          tooltip: nextLabel!,
                          onPressed: onNext,
                        ),
                    ],
                  ),
                ),
              ),
              if (progress != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(end: progress!.clamp(0, 1)),
                  duration: resolveMotion(
                    context,
                    NeoMotion.of(context).standard,
                  ),
                  builder: (context, value, _) =>
                      LinearProgressIndicator(value: value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
