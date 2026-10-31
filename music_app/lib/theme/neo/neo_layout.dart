/*
 * Neon Tube — spacing scale, component sizes and corner shapes.
 *
 * Components ask for a role (`gutter`, `artworkTile`, `cardShape()`), never a
 * number, so resizing the system is one edit in this file.
 */

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// 4pt-based spacing scale plus component sizes.
@immutable
class NeoLayout extends ThemeExtension<NeoLayout> {
  const NeoLayout({
    required this.space2,
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space24,
    required this.space32,
    required this.space48,
    required this.gutter,
    required this.sectionGap,
    required this.minTouchTarget,
    required this.iconSmall,
    required this.iconMedium,
    required this.iconLarge,
    required this.controlHeight,
    required this.controlHeightLarge,
    required this.chipHeight,
    required this.listRowMinHeight,
    required this.artworkTile,
    required this.artworkCard,
    required this.playButtonSmall,
    required this.playButtonMedium,
    required this.playButtonLarge,
    required this.miniPlayerHeight,
    required this.progressTrack,
    required this.hairlineWidth,
    required this.focusWidth,
  });

  final double space2;
  final double space4;
  final double space8;
  final double space12;
  final double space16;
  final double space24;
  final double space32;
  final double space48;

  /// Horizontal page padding.
  final double gutter;

  /// Vertical gap between home/explore sections.
  final double sectionGap;

  /// Minimum hit area for any tappable element.
  final double minTouchTarget;

  final double iconSmall;
  final double iconMedium;
  final double iconLarge;

  final double controlHeight;
  final double controlHeightLarge;
  final double chipHeight;
  final double listRowMinHeight;

  /// Artwork in song rows.
  final double artworkTile;

  /// Artwork in playlist/album cards.
  final double artworkCard;

  final double playButtonSmall;
  final double playButtonMedium;
  final double playButtonLarge;

  final double miniPlayerHeight;

  /// Thickness of progress tracks.
  final double progressTrack;

  final double hairlineWidth;

  /// Border width of a focused control.
  final double focusWidth;

  static NeoLayout of(BuildContext context) {
    final ext = Theme.of(context).extension<NeoLayout>();
    assert(
      ext != null,
      'NeoLayout missing. Build ThemeData via buildNeoTheme().',
    );
    return ext!;
  }

  static const standard = NeoLayout(
    space2: 2,
    space4: 4,
    space8: 8,
    space12: 12,
    space16: 16,
    space24: 24,
    space32: 32,
    space48: 48,
    gutter: 16,
    sectionGap: 28,
    minTouchTarget: 48,
    iconSmall: 16,
    iconMedium: 20,
    iconLarge: 24,
    controlHeight: 44,
    controlHeightLarge: 56,
    chipHeight: 36,
    listRowMinHeight: 56,
    artworkTile: 48,
    artworkCard: 148,
    playButtonSmall: 40,
    playButtonMedium: 56,
    playButtonLarge: 72,
    miniPlayerHeight: 64,
    progressTrack: 3,
    hairlineWidth: 1,
    focusWidth: 2,
  );

  @override
  NeoLayout copyWith({
    double? space2,
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space24,
    double? space32,
    double? space48,
    double? gutter,
    double? sectionGap,
    double? minTouchTarget,
    double? iconSmall,
    double? iconMedium,
    double? iconLarge,
    double? controlHeight,
    double? controlHeightLarge,
    double? chipHeight,
    double? listRowMinHeight,
    double? artworkTile,
    double? artworkCard,
    double? playButtonSmall,
    double? playButtonMedium,
    double? playButtonLarge,
    double? miniPlayerHeight,
    double? progressTrack,
    double? hairlineWidth,
    double? focusWidth,
  }) {
    return NeoLayout(
      space2: space2 ?? this.space2,
      space4: space4 ?? this.space4,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space24: space24 ?? this.space24,
      space32: space32 ?? this.space32,
      space48: space48 ?? this.space48,
      gutter: gutter ?? this.gutter,
      sectionGap: sectionGap ?? this.sectionGap,
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
      iconSmall: iconSmall ?? this.iconSmall,
      iconMedium: iconMedium ?? this.iconMedium,
      iconLarge: iconLarge ?? this.iconLarge,
      controlHeight: controlHeight ?? this.controlHeight,
      controlHeightLarge: controlHeightLarge ?? this.controlHeightLarge,
      chipHeight: chipHeight ?? this.chipHeight,
      listRowMinHeight: listRowMinHeight ?? this.listRowMinHeight,
      artworkTile: artworkTile ?? this.artworkTile,
      artworkCard: artworkCard ?? this.artworkCard,
      playButtonSmall: playButtonSmall ?? this.playButtonSmall,
      playButtonMedium: playButtonMedium ?? this.playButtonMedium,
      playButtonLarge: playButtonLarge ?? this.playButtonLarge,
      miniPlayerHeight: miniPlayerHeight ?? this.miniPlayerHeight,
      progressTrack: progressTrack ?? this.progressTrack,
      hairlineWidth: hairlineWidth ?? this.hairlineWidth,
      focusWidth: focusWidth ?? this.focusWidth,
    );
  }

  @override
  NeoLayout lerp(covariant NeoLayout? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => lerpDouble(a, b, t)!;
    return NeoLayout(
      space2: l(space2, other.space2),
      space4: l(space4, other.space4),
      space8: l(space8, other.space8),
      space12: l(space12, other.space12),
      space16: l(space16, other.space16),
      space24: l(space24, other.space24),
      space32: l(space32, other.space32),
      space48: l(space48, other.space48),
      gutter: l(gutter, other.gutter),
      sectionGap: l(sectionGap, other.sectionGap),
      minTouchTarget: l(minTouchTarget, other.minTouchTarget),
      iconSmall: l(iconSmall, other.iconSmall),
      iconMedium: l(iconMedium, other.iconMedium),
      iconLarge: l(iconLarge, other.iconLarge),
      controlHeight: l(controlHeight, other.controlHeight),
      controlHeightLarge: l(controlHeightLarge, other.controlHeightLarge),
      chipHeight: l(chipHeight, other.chipHeight),
      listRowMinHeight: l(listRowMinHeight, other.listRowMinHeight),
      artworkTile: l(artworkTile, other.artworkTile),
      artworkCard: l(artworkCard, other.artworkCard),
      playButtonSmall: l(playButtonSmall, other.playButtonSmall),
      playButtonMedium: l(playButtonMedium, other.playButtonMedium),
      playButtonLarge: l(playButtonLarge, other.playButtonLarge),
      miniPlayerHeight: l(miniPlayerHeight, other.miniPlayerHeight),
      progressTrack: l(progressTrack, other.progressTrack),
      hairlineWidth: l(hairlineWidth, other.hairlineWidth),
      focusWidth: l(focusWidth, other.focusWidth),
    );
  }
}

/// Corner radii and the shape factories components ask for.
@immutable
class NeoShapes extends ThemeExtension<NeoShapes> {
  const NeoShapes({
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusSheet,
  });

  /// Small artwork in song rows.
  final double radiusSmall;

  /// Inputs, chips, menus.
  final double radiusMedium;

  /// Cards, grouped lists, card artwork, dialogs, mini player.
  final double radiusLarge;

  /// Top corners of bottom sheets.
  final double radiusSheet;

  static NeoShapes of(BuildContext context) {
    final ext = Theme.of(context).extension<NeoShapes>();
    assert(
      ext != null,
      'NeoShapes missing. Build ThemeData via buildNeoTheme().',
    );
    return ext!;
  }

  static const standard = NeoShapes(
    radiusSmall: 8,
    radiusMedium: 12,
    radiusLarge: 16,
    radiusSheet: 24,
  );

  BorderRadius get small => BorderRadius.circular(radiusSmall);
  BorderRadius get medium => BorderRadius.circular(radiusMedium);
  BorderRadius get large => BorderRadius.circular(radiusLarge);
  BorderRadius get sheetTop =>
      BorderRadius.vertical(top: Radius.circular(radiusSheet));

  RoundedRectangleBorder cardShape({BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(borderRadius: large, side: side);

  RoundedRectangleBorder controlShape({BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(borderRadius: medium, side: side);

  RoundedRectangleBorder sheetShape() =>
      RoundedRectangleBorder(borderRadius: sheetTop);

  StadiumBorder pillShape({BorderSide side = BorderSide.none}) =>
      StadiumBorder(side: side);

  /// Artwork radius scales with size: row thumbnails stay tight, cards round.
  BorderRadius artwork(double size) => size <= 64 ? small : large;

  @override
  NeoShapes copyWith({
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusSheet,
  }) {
    return NeoShapes(
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      radiusSheet: radiusSheet ?? this.radiusSheet,
    );
  }

  @override
  NeoShapes lerp(covariant NeoShapes? other, double t) {
    if (other == null) return this;
    return NeoShapes(
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
      radiusSheet: lerpDouble(radiusSheet, other.radiusSheet, t)!,
    );
  }
}
