// The sleep timer sheet: one tap on a length starts it, the running timer
// counts down with a way to turn it off, and "end of this song" works.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/main.dart' show audioHandler;
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/services/sleep_timer.dart';
import 'package:muzee/theme/neo/neo_theme.dart';
import 'package:muzee/widgets/now_playing/sleep_timer_sheet.dart';

import '../helpers/audio_test_harness.dart';
import '../helpers/fake_youtube_http.dart';

void main() {
  late Directory storage;
  late TestAudioHandler handler;
  final en = lookupAppLocalizations(const Locale('en'));

  setUpAll(() async {
    storage = await setUpTestStorage();
    HttpOverrides.global = FakeYouTubeHttp();
    offlineMode.value = true;
    handler = TestAudioHandler.create();
    audioHandler = handler;
  });

  tearDownAll(() async {
    handler.retire();
    await tearDownTestStorage(storage);
  });

  tearDown(() => SleepTimer.instance.turnOff());

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNeoTheme(NeoThemeVariant.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSleepTimerSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  test('countdowns read like a clock', () {
    expect(formatCountdown(const Duration(minutes: 4, seconds: 5)), '04:05');
    expect(
      formatCountdown(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });

  testWidgets('one tap on a length starts it and closes the sheet', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text(en.sleepTimerMinutes(30)));
    await tester.pumpAndSettle();

    expect(find.byType(SleepTimerSheet), findsNothing);
    final left = SleepTimer.instance.remaining()!;
    expect(left.inMinutes, inInclusiveRange(29, 30));
    expect(sleepTimerNotifier.value, const Duration(minutes: 30));
    // The player's timer runs on the test clock: stop it before the end.
    SleepTimer.instance.turnOff();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a running timer counts down and can be turned off', (
    tester,
  ) async {
    SleepTimer.instance.start(const Duration(minutes: 10));
    await openSheet(tester);

    expect(find.textContaining('left'), findsOneWidget);
    await tester.tap(find.text(en.sleepTimerTurnOff));
    await tester.pumpAndSettle();

    expect(SleepTimer.instance.isActive, isFalse);
    expect(find.byType(SleepTimerSheet), findsNothing);
  });

  testWidgets('"End of this song" asks the player to stop after it', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text(en.sleepTimerEndOfSong));
    await tester.pumpAndSettle();

    expect(handler.sleepAtEndOfTrack.value, isTrue);
    expect(SleepTimer.instance.remaining(), isNull);
  });

  testWidgets('the timer firing clears the countdown', (tester) async {
    SleepTimer.instance.start(const Duration(minutes: 5));
    // What the player does when it fires.
    sleepTimerNotifier.value = Duration.zero;
    expect(SleepTimer.instance.isActive, isFalse);
    handler.cancelSleepTimer();
  });
}
