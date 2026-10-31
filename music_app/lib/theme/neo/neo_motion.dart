/*
 * Neon Tube — motion tokens and effects (glow, elevation shadows).
 */

import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';

/// Returns [full], or [Duration.zero] when the OS asks to reduce motion.
/// Reduced motion means stop, never "a bit shorter".
Duration resolveMotion(BuildContext context, Duration full) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;

@immutable
class NeoMotion extends ThemeExtension<NeoMotion> {
  const NeoMotion({
    required this.quick,
    required this.standard,
    required this.emphasized,
    required this.ambient,
    required this.enter,
    required this.exit,
    required this.move,
  });

  /// Press feedback, toggles. Invariant: quick < standard < emphasized.
  final Duration quick;

  /// Cross-fades, expanding rows.
  final Duration standard;

  /// Sheets, the now-playing transition.
  final Duration emphasized;

  /// One loop of an idle animation (now-playing bars).
  final Duration ambient;

  final Curve enter;
  final Curve exit;
  final Curve move;

  static NeoMotion of(BuildContext context) {
    final ext = Theme.of(context).extension<NeoMotion>();
    assert(
      ext != null,
      'NeoMotion missing. Build ThemeData via buildNeoTheme().',
    );
    return ext!;
  }

  static const standardSet = NeoMotion(
    quick: Duration(milliseconds: 120),
    standard: Duration(milliseconds: 220),
    emphasized: Duration(milliseconds: 360),
    ambient: Duration(milliseconds: 900),
    enter: Curves.easeOutCubic,
    exit: Curves.easeInCubic,
    move: Curves.easeInOutCubic,
  );

  @override
  NeoMotion copyWith({
    Duration? quick,
    Duration? standard,
    Duration? emphasized,
    Duration? ambient,
    Curve? enter,
    Curve? exit,
    Curve? move,
  }) {
    return NeoMotion(
      quick: quick ?? this.quick,
      standard: standard ?? this.standard,
      emphasized: emphasized ?? this.emphasized,
      ambient: ambient ?? this.ambient,
      enter: enter ?? this.enter,
      exit: exit ?? this.exit,
      move: move ?? this.move,
    );
  }

  /// Deliberate step: durations and curves are not interpolable in a way that
  /// means anything, and there is only one motion set. Snap at the midpoint.
  @override
  NeoMotion lerp(covariant NeoMotion? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}

@immutable
class NeoEffects extends ThemeExtension<NeoEffects> {
  const NeoEffects({required this.accentGlow, required this.floating});

  factory NeoEffects.from(NeoColors colors) {
    return NeoEffects(
      accentGlow: [
        BoxShadow(color: colors.accentGlow, blurRadius: 24, spreadRadius: -6),
      ],
      floating: [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// The neon glow behind primary play controls and the primary button.
  final List<BoxShadow> accentGlow;

  /// Shadow for floating chrome (mini player).
  final List<BoxShadow> floating;

  static NeoEffects of(BuildContext context) {
    final ext = Theme.of(context).extension<NeoEffects>();
    assert(
      ext != null,
      'NeoEffects missing. Build ThemeData via buildNeoTheme().',
    );
    return ext!;
  }

  @override
  NeoEffects copyWith({
    List<BoxShadow>? accentGlow,
    List<BoxShadow>? floating,
  }) {
    return NeoEffects(
      accentGlow: accentGlow ?? this.accentGlow,
      floating: floating ?? this.floating,
    );
  }

  @override
  NeoEffects lerp(covariant NeoEffects? other, double t) {
    if (other == null) return this;
    return NeoEffects(
      accentGlow: BoxShadow.lerpList(accentGlow, other.accentGlow, t)!,
      floating: BoxShadow.lerpList(floating, other.floating, t)!,
    );
  }
}
