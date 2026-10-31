import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_theme.dart';

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final variant in NeoThemeVariant.values) {
    group('${variant.name} meets WCAG AA', () {
      final c = variant.colors;
      final surfaces = <String, Color>{
        'background': c.background,
        'surface': c.surface,
        'surfaceRaised': c.surfaceRaised,
      };

      void expectRatio(String fg, Color f, String bg, Color b, double min) {
        test('$fg on $bg >= $min', () {
          expect(contrastRatio(f, b), greaterThanOrEqualTo(min));
        });
      }

      // Text: 4.5:1 on every surface.
      for (final MapEntry(key: name, value: bg) in surfaces.entries) {
        expectRatio('onSurface', c.onSurface, name, bg, 4.5);
        expectRatio('onSurfaceMuted', c.onSurfaceMuted, name, bg, 4.5);
        expectRatio('accent', c.accent, name, bg, 4.5);
        expectRatio('danger', c.danger, name, bg, 4.5);
        // Large text / meaningful non-text: 3:1.
        expectRatio('onSurfaceSubtle', c.onSurfaceSubtle, name, bg, 3);
        expectRatio('outline', c.outline, name, bg, 3);
        expectRatio('secondary', c.secondary, name, bg, 3);
      }

      // On-fill pairs.
      expectRatio('onAccent', c.onAccent, 'accent', c.accent, 4.5);
      expectRatio(
        'onAccentSoft',
        c.onAccentSoft,
        'accentSoft',
        c.accentSoft,
        4.5,
      );
      expectRatio('accent', c.accent, 'accentSoft', c.accentSoft, 3);
      expectRatio('onSecondary', c.onSecondary, 'secondary', c.secondary, 4.5);
      expectRatio(
        'onSecondarySoft',
        c.onSecondarySoft,
        'secondarySoft',
        c.secondarySoft,
        4.5,
      );
      expectRatio('onDanger', c.onDanger, 'danger', c.danger, 4.5);
      expectRatio(
        'onDangerSoft',
        c.onDangerSoft,
        'dangerSoft',
        c.dangerSoft,
        4.5,
      );

      // The Premium "active" check and other success marks (non-text).
      expectRatio('success', c.success, 'accentSoft', c.accentSoft, 3);
      expectRatio('success', c.success, 'surface', c.surface, 3);

      // Overlay glyphs sit on a translucent scrim over arbitrary cover art:
      // measure the worst cases, the scrim composited over white and black.
      for (final art in [const Color(0xFFFFFFFF), const Color(0xFF000000)]) {
        final composite = Color.alphaBlend(c.artworkScrim, art);
        expectRatio(
          'onArtworkScrim',
          c.onArtworkScrim,
          'artworkScrim over ${art == const Color(0xFFFFFFFF) ? 'white' : 'black'} art',
          composite,
          3,
        );
      }
    });
  }

  test(
    'Muzee Mono: the accent is white in dark themes, near-black in light',
    () {
      expect(NeoColors.dark.accent.computeLuminance(), greaterThan(0.9));
      expect(
        NeoColors.darkPureBlack.accent.computeLuminance(),
        greaterThan(0.9),
      );
      expect(NeoColors.light.accent.computeLuminance(), lessThan(0.05));
    },
  );

  test('pure black keeps the dark accents', () {
    expect(NeoColors.darkPureBlack.accent, NeoColors.dark.accent);
    expect(
      NeoColors.darkPureBlack.background,
      isNot(NeoColors.dark.background),
    );
  });
}
