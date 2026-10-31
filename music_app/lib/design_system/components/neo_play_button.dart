import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';
import 'package:muzee/theme/neo/neo_motion.dart';

enum NeoPlayButtonSize { small, medium, large }

/// The lime play/pause disc. Medium and large sizes carry the neon glow.
///
/// Labels are required because this layer has no localizations: pass the
/// app's translated "Play" / "Pause".
class NeoPlayButton extends StatelessWidget {
  const NeoPlayButton({
    required this.isPlaying,
    required this.onPressed,
    required this.playLabel,
    required this.pauseLabel,
    this.isBuffering = false,
    this.size = NeoPlayButtonSize.medium,
    super.key,
  });

  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback? onPressed;
  final String playLabel;
  final String pauseLabel;
  final NeoPlayButtonSize size;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final motion = NeoMotion.of(context);

    final (dimension, iconSize) = switch (size) {
      NeoPlayButtonSize.small => (layout.playButtonSmall, layout.iconMedium),
      NeoPlayButtonSize.medium => (layout.playButtonMedium, layout.iconLarge),
      NeoPlayButtonSize.large => (
        layout.playButtonLarge,
        layout.iconLarge + layout.space8,
      ),
    };
    final glows = size != NeoPlayButtonSize.small && onPressed != null;

    final glyph = isBuffering
        ? SizedBox.square(
            key: const ValueKey('buffering'),
            dimension: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: layout.focusWidth,
              color: c.onAccent,
            ),
          )
        : Icon(
            isPlaying ? NeoIcons.pause : NeoIcons.play,
            key: ValueKey(isPlaying),
            size: iconSize,
            color: c.onAccent,
          );

    // Keep the hit area at least minTouchTarget even for the small disc.
    final hitSize = dimension < layout.minTouchTarget
        ? layout.minTouchTarget
        : dimension;

    return Tooltip(
      message: isPlaying ? pauseLabel : playLabel,
      child: SizedBox.square(
        dimension: hitSize,
        child: Center(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: onPressed == null ? c.surfaceRaised : c.accent,
              shape: const CircleBorder(),
              shadows: glows ? NeoEffects.of(context).accentGlow : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: SizedBox.square(
                  dimension: dimension,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: resolveMotion(context, motion.quick),
                      switchInCurve: motion.enter,
                      switchOutCurve: motion.exit,
                      child: glyph,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
