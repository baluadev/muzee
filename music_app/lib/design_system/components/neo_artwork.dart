import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';
import 'package:muzee/theme/neo/neo_motion.dart';

/// Cover art with a themed placeholder. Radius follows size (tight for row
/// thumbnails, round for cards); [circular] is for artists.
///
/// Decorative: excluded from semantics. The owning tile names the item.
class NeoArtwork extends StatelessWidget {
  const NeoArtwork({
    required this.size,
    this.image,
    this.placeholderIcon = NeoIcons.song,
    this.circular = false,
    this.overlay,
    super.key,
  });

  final double size;
  final ImageProvider? image;
  final IconData placeholderIcon;
  final bool circular;

  /// Drawn centered on a scrim over the image (now-playing state).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final shapes = NeoShapes.of(context);

    // Under an overlay the placeholder glyph would fight the overlay glyph.
    final placeholder = ColoredBox(
      color: c.surfaceRaised,
      child: overlay != null
          ? null
          : Center(
              child: Icon(
                placeholderIcon,
                color: c.onSurfaceSubtle,
                size: size <= layout.artworkTile
                    ? layout.iconMedium
                    : layout.iconLarge,
              ),
            ),
    );

    final picture = image == null
        ? placeholder
        : Image(
            image: image!,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, _, _) => placeholder,
            frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
                wasSynchronouslyLoaded || frame != null ? child : placeholder,
          );

    final stacked = Stack(
      fit: StackFit.expand,
      children: [
        picture,
        if (overlay != null)
          ColoredBox(
            color: c.artworkScrim,
            child: Center(child: overlay),
          ),
      ],
    );

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: circular
            ? ClipOval(child: stacked)
            : ClipRRect(borderRadius: shapes.artwork(size), child: stacked),
      ),
    );
  }
}

/// Three equalizer bars: animated while [isActive], frozen when paused or
/// when the OS asks to reduce motion.
class NeoNowPlayingBars extends StatefulWidget {
  const NeoNowPlayingBars({
    required this.isActive,
    this.height,
    this.color,
    super.key,
  });

  final bool isActive;

  /// Defaults to the accent; pass `onArtworkScrim` when drawn over art.
  final Color? color;

  /// Defaults to the medium icon size.
  final double? height;

  @override
  State<NeoNowPlayingBars> createState() => _NeoNowPlayingBarsState();
}

class _NeoNowPlayingBarsState extends State<NeoNowPlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  // Phase offsets so the bars never move in lockstep.
  static const _phases = [0.0, 0.66, 0.33];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = NeoMotion.of(context).ambient;
    _sync();
  }

  @override
  void didUpdateWidget(NeoNowPlayingBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.isActive && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);
    final height = widget.height ?? layout.iconMedium;

    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, phase) in _phases.indexed) ...[
                if (i > 0) SizedBox(width: layout.space2),
                Container(
                  width: layout.space4,
                  height: height * _level(phase),
                  decoration: BoxDecoration(
                    color: widget.color ?? c.accent,
                    borderRadius: BorderRadius.all(
                      Radius.circular(layout.space2),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Bar height as a fraction of the full height, never below a third so a
  /// frozen bar still reads as a bar.
  double _level(double phase) {
    final t = _controller.value + phase;
    return 1 / 3 + (2 / 3) * math.sin(t * math.pi).abs();
  }
}
