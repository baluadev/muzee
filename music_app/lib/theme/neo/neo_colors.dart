/*
 * Muzee Mono — Tier 2 semantic color slots.
 *
 * Widgets read these slots through [NeoColors.of]; they never reach a
 * [NeoPrimitives] value. Every foreground/background pair declared here is
 * verified for WCAG AA in test/design_system/neo_contrast_test.dart.
 */

import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_primitives.dart';

@immutable
class NeoColors extends ThemeExtension<NeoColors> {
  const NeoColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.outline,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceSubtle,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.accentGlow,
    required this.secondary,
    required this.onSecondary,
    required this.secondarySoft,
    required this.onSecondarySoft,
    required this.danger,
    required this.onDanger,
    required this.dangerSoft,
    required this.onDangerSoft,
    required this.success,
    required this.scrim,
    required this.artworkScrim,
    required this.onArtworkScrim,
    required this.shadow,
    required this.pressedOverlay,
  });

  /// Scaffold and app chrome.
  final Color background;

  /// Cards, sheets, grouped lists, mini player.
  final Color surface;

  /// Inputs, chips, artwork placeholders, anything sitting on [surface].
  final Color surfaceRaised;

  /// Decorative dividers only. Not contrast-checked; never carries meaning.
  final Color hairline;

  /// Meaningful borders (focused input, outlined control). >= 3:1.
  final Color outline;

  /// Primary text and icons. >= 4.5:1 on every surface.
  final Color onSurface;

  /// Secondary text (artist, subtitle, metadata). >= 4.5:1 on every surface.
  final Color onSurfaceMuted;

  /// Tertiary: disabled labels, large text and decorative icons only. >= 3:1.
  final Color onSurfaceSubtle;

  /// The foreground of the icon (white in dark, near-black in light): active
  /// state, progress, primary action fill. Also safe as text/icon color on
  /// every surface (>= 4.5:1). State never relies on it alone: selected items
  /// also change fill, weight or shape.
  final Color accent;
  final Color onAccent;

  /// Tinted container for accent content (badges, highlighted rows).
  final Color accentSoft;
  final Color onAccentSoft;

  /// Translucent accent: text selection, slider overlay. Decorative.
  final Color accentGlow;

  /// Secondary emphasis (light grey in dark). >= 3:1 on surfaces.
  final Color secondary;
  final Color onSecondary;
  final Color secondarySoft;
  final Color onSecondarySoft;

  /// Destructive actions. >= 4.5:1 on surfaces.
  final Color danger;
  final Color onDanger;
  final Color dangerSoft;
  final Color onDangerSoft;

  /// Success check ("added", "backed up"). Always shown next to an icon, never
  /// as the only signal. >= 4.5:1 on surfaces.
  final Color success;

  /// Modal barrier.
  final Color scrim;

  /// Darkening layer over cover art (now-playing overlay). Same strength in
  /// every theme because the art underneath can be any color.
  final Color artworkScrim;

  /// Glyphs drawn on [artworkScrim]. >= 3:1 even over white art.
  final Color onArtworkScrim;

  /// Drop shadow of floating chrome.
  final Color shadow;

  /// Pressed/hovered ink highlight over any surface.
  final Color pressedOverlay;

  /// Asserts instead of falling back: a fallback would ship a palette no test
  /// verified.
  static NeoColors of(BuildContext context) {
    final ext = Theme.of(context).extension<NeoColors>();
    assert(
      ext != null,
      'NeoColors missing. Build ThemeData via buildNeoTheme().',
    );
    return ext!;
  }

  static const dark = NeoColors(
    background: NeoPrimitives.mono5,
    surface: NeoPrimitives.mono10,
    surfaceRaised: NeoPrimitives.mono14,
    hairline: NeoPrimitives.mono16,
    outline: NeoPrimitives.mono46,
    onSurface: NeoPrimitives.mono96,
    onSurfaceMuted: NeoPrimitives.mono66,
    onSurfaceSubtle: NeoPrimitives.mono46,
    accent: NeoPrimitives.mono100,
    onAccent: NeoPrimitives.mono5,
    accentSoft: NeoPrimitives.mono20,
    onAccentSoft: NeoPrimitives.mono100,
    accentGlow: NeoPrimitives.mono100a24,
    secondary: NeoPrimitives.mono83,
    onSecondary: NeoPrimitives.mono5,
    secondarySoft: NeoPrimitives.mono15,
    onSecondarySoft: NeoPrimitives.mono96,
    danger: NeoPrimitives.red70,
    onDanger: NeoPrimitives.mono5,
    dangerSoft: NeoPrimitives.red25,
    onDangerSoft: NeoPrimitives.red80,
    success: NeoPrimitives.green70,
    scrim: NeoPrimitives.mono0a60,
    artworkScrim: NeoPrimitives.mono0a60,
    onArtworkScrim: NeoPrimitives.mono100,
    shadow: NeoPrimitives.mono0a40,
    pressedOverlay: NeoPrimitives.mono100a10,
  );

  /// OLED variant: true-black chrome, same accents as [dark].
  static final darkPureBlack = dark.copyWith(
    background: NeoPrimitives.mono0,
    surface: NeoPrimitives.mono7,
    surfaceRaised: NeoPrimitives.mono11,
    hairline: NeoPrimitives.mono15,
  );

  /// Hand-tuned light variant (not an auto-flip): the icon inverted, black
  /// on white, so the white accent becomes near-black.
  static const light = NeoColors(
    background: NeoPrimitives.mono97,
    surface: NeoPrimitives.mono100,
    surfaceRaised: NeoPrimitives.mono93,
    hairline: NeoPrimitives.mono88,
    outline: NeoPrimitives.mono46,
    onSurface: NeoPrimitives.mono7,
    onSurfaceMuted: NeoPrimitives.mono33,
    onSurfaceSubtle: NeoPrimitives.mono46,
    accent: NeoPrimitives.mono7,
    onAccent: NeoPrimitives.mono100,
    accentSoft: NeoPrimitives.mono89,
    onAccentSoft: NeoPrimitives.mono7,
    accentGlow: NeoPrimitives.mono0a20,
    secondary: NeoPrimitives.mono24,
    onSecondary: NeoPrimitives.mono100,
    secondarySoft: NeoPrimitives.mono91,
    onSecondarySoft: NeoPrimitives.mono10,
    danger: NeoPrimitives.red45,
    onDanger: NeoPrimitives.mono100,
    dangerSoft: NeoPrimitives.red95,
    onDangerSoft: NeoPrimitives.red30,
    success: NeoPrimitives.green45,
    scrim: NeoPrimitives.mono0a40,
    artworkScrim: NeoPrimitives.mono0a60,
    onArtworkScrim: NeoPrimitives.mono100,
    shadow: NeoPrimitives.mono0a12,
    pressedOverlay: NeoPrimitives.mono0a8,
  );

  @override
  NeoColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? hairline,
    Color? outline,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? onSurfaceSubtle,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? onAccentSoft,
    Color? accentGlow,
    Color? secondary,
    Color? onSecondary,
    Color? secondarySoft,
    Color? onSecondarySoft,
    Color? danger,
    Color? onDanger,
    Color? dangerSoft,
    Color? onDangerSoft,
    Color? success,
    Color? scrim,
    Color? artworkScrim,
    Color? onArtworkScrim,
    Color? shadow,
    Color? pressedOverlay,
  }) {
    return NeoColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      hairline: hairline ?? this.hairline,
      outline: outline ?? this.outline,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      onSurfaceSubtle: onSurfaceSubtle ?? this.onSurfaceSubtle,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccentSoft: onAccentSoft ?? this.onAccentSoft,
      accentGlow: accentGlow ?? this.accentGlow,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      onSecondarySoft: onSecondarySoft ?? this.onSecondarySoft,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      onDangerSoft: onDangerSoft ?? this.onDangerSoft,
      success: success ?? this.success,
      scrim: scrim ?? this.scrim,
      artworkScrim: artworkScrim ?? this.artworkScrim,
      onArtworkScrim: onArtworkScrim ?? this.onArtworkScrim,
      shadow: shadow ?? this.shadow,
      pressedOverlay: pressedOverlay ?? this.pressedOverlay,
    );
  }

  /// Every field is interpolated; a field missing here never animates.
  @override
  NeoColors lerp(covariant NeoColors? other, double t) {
    if (other == null) return this;
    return NeoColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      onSurfaceSubtle: Color.lerp(onSurfaceSubtle, other.onSurfaceSubtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccentSoft: Color.lerp(onAccentSoft, other.onAccentSoft, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t)!,
      onSecondarySoft: Color.lerp(onSecondarySoft, other.onSecondarySoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      onDangerSoft: Color.lerp(onDangerSoft, other.onDangerSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      artworkScrim: Color.lerp(artworkScrim, other.artworkScrim, t)!,
      onArtworkScrim: Color.lerp(onArtworkScrim, other.onArtworkScrim, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      pressedOverlay: Color.lerp(pressedOverlay, other.pressedOverlay, t)!,
    );
  }
}

/// `context.neo.accent` instead of `NeoColors.of(context).accent`.
extension NeoColorsContext on BuildContext {
  NeoColors get neo => NeoColors.of(this);
}
