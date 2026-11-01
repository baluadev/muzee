// "Come back" reminders: 2 and 4 days after the app was last used, never
// in the quiet hours, naming the last song when there is one.

import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/services/reminder_service.dart';

import '../helpers/audio_test_harness.dart';

void main() {
  late Directory storage;
  setUpAll(() async => storage = await setUpTestStorage());
  tearDownAll(() => tearDownTestStorage(storage));

  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  group('when', () {
    test('2 and 4 days later, at the same time of day', () {
      final open = DateTime(2026, 11, 1, 15, 30);
      expect(reminderTimes(open), [
        DateTime(2026, 11, 3, 15, 30),
        DateTime(2026, 11, 5, 15, 30),
      ]);
    });

    test('late at night moves to 20:00 that day', () {
      expect(
        reminderTimes(DateTime(2026, 11, 1, 23, 10)).first,
        DateTime(2026, 11, 3, 20),
      );
    });

    test('early morning moves to 9:00', () {
      expect(
        reminderTimes(DateTime(2026, 11, 1, 6, 45)).first,
        DateTime(2026, 11, 3, 9),
      );
    });
  });

  group('what', () {
    final song = {'ytid': 'abc', 'title': 'Nàng Thơ', 'artist': 'Hoàng Dũng'};

    test('the first names the last song and plays it on tap', () {
      final first = reminderContent(vi, 0, lastSong: song);
      expect(first.title, 'Nhớ Hoàng Dũng không?');
      expect(first.body, contains('Nàng Thơ'));
      expect(first.songId, 'abc');
    });

    test('without a last song it stays general', () {
      final first = reminderContent(en, 0);
      expect(first.title, en.reminderTitle);
      expect(first.songId, isNull);
    });

    test('the second is a lighter nudge that just opens the app', () {
      final second = reminderContent(en, 1, lastSong: song);
      expect(second.title, en.reminderTitleLater);
      expect(second.songId, isNull);
    });
  });
}
