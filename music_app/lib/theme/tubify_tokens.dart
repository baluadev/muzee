/*
 * Tubify brand tokens (mobile-first).
 *
 * Figma: https://www.figma.com/design/vt7bZbgVdwrHJ4QrnXZzyn/tubify
 * Reference nodes: 1:5209, 1:802, 1:834
 */

import 'package:flutter/material.dart';

/// Raw palette aligned with Tubify dark/light.
abstract final class TubifyTokens {
  // --- Dark ---
  static const Color darkSeed = Color(0xFF00FFA3);
  static const Color darkPrimary = Color(0xFF00FFA3);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkPrimaryContainer = Color(0xFF262626);
  static const Color darkOnPrimaryContainer = Color(0xFFE5E2E1);

  static const Color darkSecondary = Color(0xFFE5E2E1);
  static const Color darkOnSecondary = Color(0xFF131313);
  static const Color darkSecondaryContainer = Color(0xFF2A2A2A);
  static const Color darkOnSecondaryContainer = Color(0xFFC8C6C5);

  static const Color darkTertiary = Color(0xFF1DB954);

  /// App shell / scaffold background (Home, tabs, standard pages).
  static const Color darkSurface = Color(0xFF0C150F);
  static const Color darkSurfaceContainerLow = Color(0xFF171717);
  static const Color darkSurfaceContainer = Color(0xFF171717);
  static const Color darkSurfaceContainerHigh = Color(0xFF262626);
  static const Color darkSurfaceContainerHighest = Color(0xFF262626);

  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFFA3A3A3);

  static const Color darkOutline = Color(0xFF262626);
  static const Color darkOutlineVariant = Color(0xFF171717);

  static const Color darkError = Color(0xFFFF4B4B);
  static const Color darkOnError = Color(0xFFFFFFFF);

  // --- Light ---
  static const Color lightSeed = Color(0xFFABD600);
  static const Color lightPrimary = Color(0xFFABD600);
  static const Color lightOnPrimary = Color(0xFF161E00);
  static const Color lightPrimaryContainer = Color(0xFFD9EC9B);
  static const Color lightOnPrimaryContainer = Color(0xFF161E00);

  static const Color lightSecondary = Color(0xFF4D4A49);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFE8E3D9);
  static const Color lightOnSecondaryContainer = Color(0xFF1C1B1B);

  static const Color lightTertiary = Color(0xFF008B3A);

  static const Color lightSurface = Color(0xFFF7F5EF);
  static const Color lightSurfaceContainerLow = Color(0xFFEFEBE1);
  static const Color lightSurfaceContainer = Color(0xFFE8E3D9);
  static const Color lightSurfaceContainerHigh = Color(0xFFDAD5CC);
  static const Color lightSurfaceContainerHighest = Color(0xFFCCC7BF);

  static const Color lightOnSurface = Color(0xFF1C1B1B);
  static const Color lightOnSurfaceVariant = Color(0xFF4D4A49);

  static const Color lightOutline = Color(0x33444933);
  static const Color lightOutlineVariant = Color(0x1A444933);

  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
}
