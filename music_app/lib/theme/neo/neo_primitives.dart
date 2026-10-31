/*
 * Muzee Mono — Tier 1 primitives.
 *
 * The palette of the app icon: white on near-black, no hue. Color comes from
 * album art; the only hue in the chrome is red for errors (and green for a
 * success check).
 *
 * Named by family + lightness in percent of white (`mono10` = #1A1A1A), never
 * by role. This is the ONLY file in the app allowed a raw color literal.
 * Widgets never read these: they read [NeoColors] slots.
 *
 * Alpha variants carry the alpha percentage as a suffix (`a40` = 40% opacity).
 */

import 'package:flutter/painting.dart';

abstract final class NeoPrimitives {
  // --- Mono: pure greys ---
  static const mono0 = Color(0xFF000000);
  static const mono5 = Color(0xFF0D0D0D); // icon background, splash
  static const mono7 = Color(0xFF111111);
  static const mono10 = Color(0xFF1A1A1A); // icon tile
  static const mono11 = Color(0xFF1C1C1C);
  static const mono14 = Color(0xFF242424);
  static const mono15 = Color(0xFF262626);
  static const mono16 = Color(0xFF2A2A2A);
  static const mono20 = Color(0xFF333333);
  static const mono24 = Color(0xFF3D3D3D);
  static const mono33 = Color(0xFF555555);
  static const mono46 = Color(0xFF767676);
  static const mono66 = Color(0xFFA8A8A8);
  static const mono83 = Color(0xFFD4D4D4);
  static const mono88 = Color(0xFFE0E0E0);
  static const mono89 = Color(0xFFE3E3E3);
  static const mono91 = Color(0xFFE8E8E8);
  static const mono93 = Color(0xFFEEEEEE);
  static const mono96 = Color(0xFFF5F5F5);
  static const mono97 = Color(0xFFF7F7F7);
  static const mono100 = Color(0xFFFFFFFF);

  static const mono0a12 = Color(0x1F000000);
  static const mono0a40 = Color(0x66000000);
  static const mono0a60 = Color(0x99000000);
  static const mono0a8 = Color(0x14000000);
  static const mono100a0 = Color(0x00FFFFFF);
  static const mono100a10 = Color(0x1AFFFFFF);
  static const mono100a24 = Color(0x3DFFFFFF);
  static const mono0a20 = Color(0x33000000);

  // --- Red: destructive and error ---
  static const red25 = Color(0xFF3A1A1A);
  static const red30 = Color(0xFF7F1515);
  static const red45 = Color(0xFFC62828);
  static const red70 = Color(0xFFFF6B6B);
  static const red80 = Color(0xFFFFB3B3);
  static const red95 = Color(0xFFFDE7E7);

  // --- Green: success check only, always next to an icon ---
  static const green45 = Color(0xFF1E7D45);
  static const green70 = Color(0xFF5BD68A);
}
