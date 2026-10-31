/*
 * Fixed Tubify ColorScheme when dynamic color (Material You) is off.
 * Values derive from [TubifyTokens]; harmonized for subtle Material tuning.
 */

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:muzee/theme/tubify_tokens.dart';

abstract final class TubifyColorSchemes {
  static ColorScheme get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: TubifyTokens.darkSeed,
          brightness: Brightness.dark,
        ).copyWith(
          primary: TubifyTokens.darkPrimary,
          onPrimary: TubifyTokens.darkOnPrimary,
          primaryContainer: TubifyTokens.darkPrimaryContainer,
          onPrimaryContainer: TubifyTokens.darkOnPrimaryContainer,
          secondary: TubifyTokens.darkSecondary,
          onSecondary: TubifyTokens.darkOnSecondary,
          secondaryContainer: TubifyTokens.darkSecondaryContainer,
          onSecondaryContainer: TubifyTokens.darkOnSecondaryContainer,
          tertiary: TubifyTokens.darkTertiary,
          onTertiary: TubifyTokens.darkOnSecondary,
          tertiaryContainer: TubifyTokens.darkSurfaceContainerHigh,
          onTertiaryContainer: TubifyTokens.darkOnSurface,
          surface: TubifyTokens.darkSurface,
          surfaceContainerLowest: TubifyTokens.darkSurface,
          surfaceContainerLow: TubifyTokens.darkSurfaceContainerLow,
          surfaceContainer: TubifyTokens.darkSurfaceContainer,
          surfaceContainerHigh: TubifyTokens.darkSurfaceContainerHigh,
          surfaceContainerHighest: TubifyTokens.darkSurfaceContainerHighest,
          onSurface: TubifyTokens.darkOnSurface,
          onSurfaceVariant: TubifyTokens.darkOnSurfaceVariant,
          surfaceTint: TubifyTokens.darkPrimary,
          outline: TubifyTokens.darkOutline,
          outlineVariant: TubifyTokens.darkOutlineVariant,
          error: TubifyTokens.darkError,
          onError: TubifyTokens.darkOnError,
        );
    // Keep exact brand primaries; harmonized() can nudge hue/chroma away from Figma.
    return scheme.harmonized().copyWith(
      primary: TubifyTokens.darkPrimary,
      onPrimary: TubifyTokens.darkOnPrimary,
      primaryContainer: TubifyTokens.darkPrimaryContainer,
      onPrimaryContainer: TubifyTokens.darkOnPrimaryContainer,
      surface: TubifyTokens.darkSurface,
      surfaceContainerLowest: TubifyTokens.darkSurface,
      surfaceTint: TubifyTokens.darkPrimary,
    );
  }

  static ColorScheme get light {
    final scheme = ColorScheme.fromSeed(seedColor: TubifyTokens.lightSeed)
        .copyWith(
          primary: TubifyTokens.lightPrimary,
          onPrimary: TubifyTokens.lightOnPrimary,
          primaryContainer: TubifyTokens.lightPrimaryContainer,
          onPrimaryContainer: TubifyTokens.lightOnPrimaryContainer,
          secondary: TubifyTokens.lightSecondary,
          onSecondary: TubifyTokens.lightOnSecondary,
          secondaryContainer: TubifyTokens.lightSecondaryContainer,
          onSecondaryContainer: TubifyTokens.lightOnSecondaryContainer,
          tertiary: TubifyTokens.lightTertiary,
          onTertiary: TubifyTokens.lightOnPrimary,
          tertiaryContainer: TubifyTokens.lightSurfaceContainerHigh,
          onTertiaryContainer: TubifyTokens.lightOnSurface,
          surface: TubifyTokens.lightSurface,
          surfaceContainerLowest: TubifyTokens.lightSurface,
          surfaceContainerLow: TubifyTokens.lightSurfaceContainerLow,
          surfaceContainer: TubifyTokens.lightSurfaceContainer,
          surfaceContainerHigh: TubifyTokens.lightSurfaceContainerHigh,
          surfaceContainerHighest: TubifyTokens.lightSurfaceContainerHighest,
          onSurface: TubifyTokens.lightOnSurface,
          onSurfaceVariant: TubifyTokens.lightOnSurfaceVariant,
          surfaceTint: TubifyTokens.lightPrimary,
          outline: TubifyTokens.lightOutline,
          outlineVariant: TubifyTokens.lightOutlineVariant,
          error: TubifyTokens.lightError,
          onError: TubifyTokens.lightOnError,
        );
    return scheme.harmonized().copyWith(
      primary: TubifyTokens.lightPrimary,
      onPrimary: TubifyTokens.lightOnPrimary,
      primaryContainer: TubifyTokens.lightPrimaryContainer,
      onPrimaryContainer: TubifyTokens.lightOnPrimaryContainer,
      surfaceTint: TubifyTokens.lightPrimary,
    );
  }
}
