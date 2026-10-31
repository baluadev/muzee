// Proves font coverage from the bundled files themselves (their cmap and fvar
// tables), not from a foundry page: a missing glyph shows up as tofu only on
// the device of someone who reads that language.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/design_system/neo_design_system.dart';

const _inter = 'assets/fonts/inter/Inter-Variable.ttf';
const _spaceGrotesk = 'assets/fonts/space_grotesk/SpaceGrotesk-Variable.ttf';

class _Font {
  _Font(String path) : _d = ByteData.sublistView(File(path).readAsBytesSync()) {
    final count = _d.getUint16(4);
    for (var i = 0; i < count; i++) {
      final r = 12 + 16 * i;
      final tag = String.fromCharCodes(
        List.generate(4, (k) => _d.getUint8(r + k)),
      );
      _tables[tag] = _d.getUint32(r + 8);
    }
  }

  final ByteData _d;
  final _tables = <String, int>{};

  /// Variation axes: tag -> (min, max).
  Map<String, (double, double)> get axes {
    final o = _tables['fvar'];
    if (o == null) return {};
    final axesOffset = _d.getUint16(o + 4);
    final count = _d.getUint16(o + 8);
    final size = _d.getUint16(o + 10);
    return {
      for (var i = 0; i < count; i++)
        String.fromCharCodes(
          List.generate(4, (k) => _d.getUint8(o + axesOffset + i * size + k)),
        ): (
          _d.getInt32(o + axesOffset + i * size + 4) / 65536,
          _d.getInt32(o + axesOffset + i * size + 12) / 65536,
        ),
    };
  }

  /// Code points mapped to a real glyph (format 12 or 4 Unicode subtable).
  late final Set<int> codePoints = _readCmap();

  Set<int> _readCmap() {
    final o = _tables['cmap']!;
    final subtables = <(int, int), int>{};
    for (var i = 0; i < _d.getUint16(o + 2); i++) {
      final r = o + 4 + 8 * i;
      subtables[(_d.getUint16(r), _d.getUint16(r + 2))] =
          o + _d.getUint32(r + 4);
    }
    for (final key in [(3, 10), (0, 4), (3, 1), (0, 3)]) {
      final p = subtables[key];
      if (p == null) continue;
      final format = _d.getUint16(p);
      if (format == 12) return _format12(p);
      if (format == 4) return _format4(p);
    }
    throw StateError('No Unicode cmap subtable');
  }

  Set<int> _format12(int p) {
    final out = <int>{};
    for (var g = 0; g < _d.getUint32(p + 12); g++) {
      final r = p + 16 + 12 * g;
      final start = _d.getUint32(r);
      final end = _d.getUint32(r + 4);
      final glyph = _d.getUint32(r + 8);
      for (var c = start; c <= end; c++) {
        if (glyph + (c - start) != 0) out.add(c);
      }
    }
    return out;
  }

  Set<int> _format4(int p) {
    final out = <int>{};
    final seg = _d.getUint16(p + 6) ~/ 2;
    final ends = p + 14;
    final starts = ends + 2 * seg + 2;
    final deltas = starts + 2 * seg;
    final rangeOffsets = deltas + 2 * seg;
    for (var i = 0; i < seg; i++) {
      final start = _d.getUint16(starts + 2 * i);
      final end = _d.getUint16(ends + 2 * i);
      final delta = _d.getInt16(deltas + 2 * i);
      final ro = _d.getUint16(rangeOffsets + 2 * i);
      for (var c = start; c <= end && c != 0xFFFF; c++) {
        int glyph;
        if (ro == 0) {
          glyph = (c + delta) & 0xFFFF;
        } else {
          glyph = _d.getUint16(rangeOffsets + 2 * i + ro + 2 * (c - start));
          if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
        }
        if (glyph != 0) out.add(c);
      }
    }
    return out;
  }

  List<String> missing(String chars) => chars.runes
      .where((r) => !codePoints.contains(r))
      .map(String.fromCharCode)
      .toList();
}

// Letters each shipped locale needs beyond basic ASCII.
const _ascii =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    '.,:;!?()[]/-_\'"&%@#';
const _punctuation = '“”‘’…–—·•©®™€';
const _vietnamese =
    'ăâđêôơưĂÂĐÊÔƠƯ₫'
    'àáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ'
    'ÀÁẢÃẠẰẮẲẴẶẦẤẨẪẬÈÉẺẼẸỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌỒỐỔỖỘỜỚỞỠỢÙÚỦŨỤỪỨỬỮỰỲÝỶỸỴ';
const _latinEurope =
    'äöüßÄÖÜ' // de
    'ąćęłńóśźżĄĆĘŁŃÓŚŹŻ' // pl
    'őűŐŰ' // hu
    'çğıİşÇĞŞ' // tr
    'õšžÕŠŽ' // et
    'åÅ' // sv
    'ñÑáéíóúãâêôàèìòùœæëïÿŒÆ«»¿¡'; // es, pt, fr, it
const _cyrillic =
    'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя'
    'ЄєІіЇїҐґ'; // uk
const _greek =
    'ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρσςτυφχψω'
    'άέήίόύώΐΰΆΈΉΊΌΎΏ';

void main() {
  final inter = _Font(_inter);
  final spaceGrotesk = _Font(_spaceGrotesk);

  group('Inter (UI text) covers every Latin, Cyrillic and Greek locale', () {
    for (final (name, chars) in [
      ('ascii', _ascii),
      ('punctuation', _punctuation),
      ('vi', _vietnamese),
      ('latin europe', _latinEurope),
      ('ru, uk', _cyrillic),
      ('el', _greek),
    ]) {
      test(name, () => expect(inter.missing(chars), isEmpty));
    }
  });

  group('Space Grotesk (headings) covers its locales', () {
    for (final (name, chars) in [
      ('ascii', _ascii),
      ('punctuation', _punctuation),
      ('vi', _vietnamese),
      ('latin europe', _latinEurope),
    ]) {
      test(name, () => expect(spaceGrotesk.missing(chars), isEmpty));
    }

    test('lacks Cyrillic and Greek, so those locales use Inter', () {
      expect(spaceGrotesk.missing(_cyrillic), isNotEmpty);
      expect(spaceGrotesk.missing(_greek), isNotEmpty);
      for (final code in ['ru', 'uk', 'el', 'zh', 'ja', 'ko', 'he', 'hi']) {
        expect(
          NeoFontFamilies.displayFor(code),
          NeoFontFamilies.text,
          reason: code,
        );
      }
      // Muzee sets every heading in Inter, Latin locales included.
      expect(NeoFontFamilies.displayFor('vi'), NeoFontFamilies.text);
    });
  });

  test('every weight the type scale uses is inside the wght axis', () {
    final theme = buildNeoTheme(NeoThemeVariant.dark).textTheme;
    final styles = [
      theme.displayLarge,
      theme.displayMedium,
      theme.displaySmall,
      theme.headlineLarge,
      theme.headlineMedium,
      theme.headlineSmall,
      theme.titleLarge,
      theme.titleMedium,
      theme.titleSmall,
      theme.bodyLarge,
      theme.bodyMedium,
      theme.bodySmall,
      theme.labelLarge,
      theme.labelMedium,
      theme.labelSmall,
    ].nonNulls;
    final fonts = {
      NeoFontFamilies.text: inter,
      NeoFontFamilies.display: spaceGrotesk,
    };
    for (final style in styles) {
      final (min, max) = fonts[style.fontFamily]!.axes['wght']!;
      // Components also bump weights to w700 for emphasis.
      for (final weight in [style.fontWeight!, FontWeight.w700]) {
        expect(
          weight.value,
          inInclusiveRange(min, max),
          reason: '${style.fontFamily} ${weight.value}',
        );
      }
    }
  });

  test('Inter ships tabular figures for timecodes', () {
    // The tnum feature tag must exist in GSUB for FontFeature.tabularFigures.
    final bytes = File(_inter).readAsBytesSync();
    expect(String.fromCharCodes(bytes).contains('tnum'), isTrue);
  });
}
