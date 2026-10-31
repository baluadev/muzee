/*
 * Neon Tube — typography.
 *
 * Two bundled variable fonts (assets/fonts, SIL OFL 1.1): Space Grotesk for
 * headings and Inter for UI text. FontWeight drives their wght axis.
 * The family strings below are the only place a font name may appear.
 *
 * Coverage, verified from each file's cmap (test/design_system/
 * neo_font_coverage_test.dart):
 *  - Inter: Latin incl. Vietnamese, Cyrillic, Greek.
 *  - Space Grotesk: Latin incl. Vietnamese only.
 *  - Neither: CJK, Hebrew, Devanagari, Tamil -> platform font.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class NeoFontFamilies {
  static const display = 'SpaceGrotesk';
  static const text = 'Inter';

  /// Glyphs missing from the display face fall back to Inter, then to the
  /// platform font.
  static const displayFallback = <String>[text];

  /// Locales whose script Space Grotesk fully covers.
  static const _displayLocales = {
    'de',
    'en',
    'es',
    'et',
    'fr',
    'hu',
    'id',
    'it',
    'pl',
    'pt',
    'sv',
    'tr',
    'vi',
  };

  /// Heading family for a locale. Muzee uses Inter for headings everywhere:
  /// its bold weight matches the icon's wordmark, and it covers Vietnamese
  /// diacritics. [display] stays bundled for the design-system gallery.
  static String displayFor(String? languageCode) => text;

  /// Locales Space Grotesk would cover, kept for the gallery's comparison.
  static Set<String> get displayLocales => _displayLocales;
}

/// Shows the bundled fonts' licenses on the app's licenses page. Call once in
/// `main()` before `runApp`.
void registerNeoFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      NeoFontFamilies.text,
    ], await rootBundle.loadString('assets/fonts/inter/OFL.txt'));
    yield LicenseEntryWithLineBreaks(const [
      NeoFontFamilies.display,
    ], await rootBundle.loadString('assets/fonts/space_grotesk/OFL.txt'));
  });
}

/// Builds the M3 text theme. Material widgets read these roles directly;
/// components pick a role by name and never set a `fontSize`.
TextTheme buildNeoTextTheme(
  Color onSurface, {
  String displayFamily = NeoFontFamilies.display,
}) {
  TextStyle display(
    double size,
    double lineHeight,
    FontWeight weight, [
    double tracking = 0,
  ]) {
    return TextStyle(
      fontFamily: displayFamily,
      fontFamilyFallback: NeoFontFamilies.displayFallback,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: tracking,
      color: onSurface,
    );
  }

  TextStyle text(
    double size,
    double lineHeight,
    FontWeight weight, [
    double tracking = 0,
  ]) {
    return TextStyle(
      fontFamily: NeoFontFamilies.text,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: tracking,
      color: onSurface,
    );
  }

  return TextTheme(
    // Line height >= 1.2 so Vietnamese stacked diacritics don't collide.
    displayLarge: display(44, 54, FontWeight.w700, -1),
    displayMedium: display(36, 44, FontWeight.w700, -0.8),
    displaySmall: display(30, 38, FontWeight.w700, -0.6),
    headlineLarge: display(28, 34, FontWeight.w700, -0.5),
    headlineMedium: display(24, 30, FontWeight.w700, -0.3),
    headlineSmall: display(20, 26, FontWeight.w600, -0.2),
    titleLarge: display(18, 24, FontWeight.w600, -0.1),
    titleMedium: text(16, 22, FontWeight.w600),
    titleSmall: text(14, 20, FontWeight.w600),
    bodyLarge: text(16, 24, FontWeight.w400),
    bodyMedium: text(14, 20, FontWeight.w400),
    bodySmall: text(12, 16, FontWeight.w400),
    labelLarge: text(14, 20, FontWeight.w600, 0.1),
    labelMedium: text(12, 16, FontWeight.w600, 0.2),
    // 12 sp is the smallest text in the app.
    labelSmall: text(12, 16, FontWeight.w500, 0.2),
  );
}

/// Roles the M3 text theme has no slot for.
@immutable
class NeoTypeExtras extends ThemeExtension<NeoTypeExtras> {
  const NeoTypeExtras({required this.timecode, required this.eyebrow});

  factory NeoTypeExtras.from(Color muted, Color accent) {
    return NeoTypeExtras(
      timecode: TextStyle(
        fontFamily: NeoFontFamilies.text,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: muted,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      eyebrow: TextStyle(
        fontFamily: NeoFontFamilies.text,
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: accent,
      ),
    );
  }

  /// Elapsed / total time. Tabular figures so digits do not jitter.
  final TextStyle timecode;

  /// Small kicker above a hero title. Casing comes from the localized string,
  /// never from `toUpperCase()`.
  final TextStyle eyebrow;

  static NeoTypeExtras of(BuildContext context) {
    final ext = Theme.of(context).extension<NeoTypeExtras>();
    assert(
      ext != null,
      'NeoTypeExtras missing. Build ThemeData via buildNeoTheme().',
    );
    return ext!;
  }

  @override
  NeoTypeExtras copyWith({TextStyle? timecode, TextStyle? eyebrow}) {
    return NeoTypeExtras(
      timecode: timecode ?? this.timecode,
      eyebrow: eyebrow ?? this.eyebrow,
    );
  }

  /// TextStyle.lerp interpolates sizes/colors and snaps the family itself.
  @override
  NeoTypeExtras lerp(covariant NeoTypeExtras? other, double t) {
    if (other == null) return this;
    return NeoTypeExtras(
      timecode: TextStyle.lerp(timecode, other.timecode, t)!,
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
    );
  }
}
