import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/design_system/neo_design_system.dart';

void main() {
  for (final variant in NeoThemeVariant.values) {
    group('buildNeoTheme(${variant.name})', () {
      final theme = buildNeoTheme(variant);
      final c = variant.colors;

      test('attaches every extension', () {
        expect(theme.extension<NeoColors>(), isNotNull);
        expect(theme.extension<NeoLayout>(), isNotNull);
        expect(theme.extension<NeoShapes>(), isNotNull);
        expect(theme.extension<NeoMotion>(), isNotNull);
        expect(theme.extension<NeoEffects>(), isNotNull);
        expect(theme.extension<NeoTypeExtras>(), isNotNull);
      });

      test('ColorScheme is folded from the slots', () {
        final s = theme.colorScheme;
        expect(s.brightness, variant.brightness);
        expect(s.primary, c.accent);
        expect(s.onPrimary, c.onAccent);
        expect(s.secondary, c.secondary);
        expect(s.surface, c.background);
        expect(s.surfaceContainerHigh, c.surfaceRaised);
        expect(s.surfaceContainerHighest, c.surfaceRaised);
        expect(s.onSurfaceVariant, c.onSurfaceMuted);
        expect(s.outline, c.outline);
        expect(s.error, c.danger);
        expect(theme.scaffoldBackgroundColor, c.background);
      });

      test('text roles use the bundled families', () {
        expect(theme.textTheme.titleLarge!.fontFamily, NeoFontFamilies.text);
        expect(theme.textTheme.bodyMedium!.fontFamily, NeoFontFamilies.text);
      });
    });
  }

  test('headings use Inter in every locale (Muzee wordmark face)', () {
    TextStyle heading(String code) => buildNeoTheme(
      NeoThemeVariant.dark,
      locale: Locale(code),
    ).textTheme.titleLarge!;
    for (final code in ['vi', 'en', 'el', 'ru']) {
      expect(heading(code).fontFamily, NeoFontFamilies.text, reason: code);
    }
  });

  test('NeoColors.lerp hits both endpoints', () {
    const a = NeoColors.dark;
    const b = NeoColors.light;
    expect(a.lerp(b, 0).accent, a.accent);
    expect(a.lerp(b, 1).accent, b.accent);
    expect(a.lerp(b, 1).pressedOverlay, b.pressedOverlay);
  });

  test('copyWith changes only the named slot', () {
    final changed = NeoColors.dark.copyWith(accent: NeoColors.light.accent);
    expect(changed.accent, NeoColors.light.accent);
    expect(changed.background, NeoColors.dark.background);
  });

  test('motion invariant: quick < standard < emphasized', () {
    const m = NeoMotion.standardSet;
    expect(m.quick < m.standard, isTrue);
    expect(m.standard < m.emphasized, isTrue);
  });

  test('settings map onto variants', () {
    expect(
      NeoThemeVariant.resolve(brightness: Brightness.dark, pureBlack: true),
      NeoThemeVariant.darkPureBlack,
    );
    expect(
      NeoThemeVariant.resolve(brightness: Brightness.light, pureBlack: true),
      NeoThemeVariant.light,
    );
  });
}
