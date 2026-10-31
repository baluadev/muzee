import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/formatter.dart';
import 'package:muzee/utilities/language_utils.dart';

import '../helpers/audio_test_harness.dart';

void main() {
  late Directory storage;
  setUpAll(() async => storage = await setUpTestStorage());
  tearDownAll(() => tearDownTestStorage(storage));

  group('chart titles read as song titles', () {
    test('"(Official Video)" goes', () {
      expect(
        formatChartTitle('Coming Up Roses (Official Video)', 'Harry Styles'),
        'Coming Up Roses',
      );
    });

    test('a leading "Artist - " goes when that artist is shown anyway', () {
      expect(
        formatChartTitle(
          'Megan Thee Stallion - Thin Ice',
          'Megan Thee Stallion',
        ),
        'Thin Ice',
      );
      expect(
        formatChartTitle('KAROL G - BbY WOW', 'KAROL G, Judeline, rusowsky'),
        'BbY WOW',
      );
    });

    test('a dash that is part of the title stays', () {
      expect(
        formatChartTitle('K/DA - FIRESTARTER', 'League of Legends'),
        'K/DA - FIRESTARTER',
      );
      expect(formatChartTitle('Dai Dai', 'Shakira, Burna Boy'), 'Dai Dai');
    });
  });

  group('first launch follows the phone', () {
    test('a Vietnamese phone gets Vietnamese and the Vietnam charts', () {
      const vi = Locale('vi', 'VN');
      expect(defaultLanguageCode(vi), 'vi');
      expect(defaultChartsCountryCode(vi), 'vn');
    });

    test('an unsupported language or region falls back to English / US', () {
      const xx = Locale('xx', 'ZZ');
      expect(defaultLanguageCode(xx), 'en');
      expect(defaultChartsCountryCode(xx), 'us');
      expect(defaultChartsCountryCode(const Locale('fr')), 'us');
    });
  });
}
