// The full-screen video: taps on the sides seek 5 s, adding up when they come
// in a row; the middle shows and hides the controls.

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/main.dart' show audioHandler;
import 'package:muzee/screens/video_fullscreen_page.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_theme.dart';

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

  setUp(() async {
    handler
      ..seeks.clear()
      ..mediaItem.add(
        const MediaItem(id: 'song_000000', title: 'Song 0', artist: 'Artist 0'),
      )
      ..reportTrack(
        const Duration(minutes: 3),
        position: const Duration(seconds: 60),
      );
    await settle();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNeoTheme(NeoThemeVariant.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VideoFullscreenPage.withVideo(video: SizedBox.expand()),
      ),
    );
    await tester.pump();
  }

  // 800 × 360 logical: the side zones are the outer 30 %.
  const left = Offset(60, 180);
  const right = Offset(740, 180);
  const middle = Offset(400, 300);

  Future<void> endStreak(WidgetTester tester) =>
      tester.pump(VideoFullscreenPage.seekStreakWindow * 2);

  testWidgets('one tap on the right goes forward 5 s', (tester) async {
    await pumpPage(tester);
    await tester.tapAt(right);
    await tester.pump();
    expect(handler.seeks, [const Duration(seconds: 65)]);
    expect(find.text('+5s'), findsOneWidget);
    await endStreak(tester);
  });

  testWidgets('taps in a row add up: 10 s, then 15 s', (tester) async {
    await pumpPage(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(right);
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(handler.seeks, const [
      Duration(seconds: 65),
      Duration(seconds: 70),
      Duration(seconds: 75),
    ]);
    expect(find.text('+15s'), findsOneWidget);
    await endStreak(tester);
  });

  testWidgets('the left side goes back, twice = 10 s', (tester) async {
    await pumpPage(tester);
    await tester.tapAt(left);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(left);
    await tester.pump();
    expect(handler.seeks.last, const Duration(seconds: 50));
    expect(find.text('−10s'), findsOneWidget);
    await endStreak(tester);
  });

  testWidgets('a pause between taps starts a new count', (tester) async {
    await pumpPage(tester);
    await tester.tapAt(right);
    await endStreak(tester);
    await tester.tapAt(right);
    await tester.pump();
    expect(find.text('+5s'), findsOneWidget);
    await endStreak(tester);
  });

  testWidgets('seeking back stops at the start', (tester) async {
    handler.reportTrack(
      const Duration(minutes: 3),
      position: const Duration(seconds: 3),
    );
    await pumpPage(tester);
    await tester.tapAt(left);
    await tester.pump();
    expect(handler.seeks.last, Duration.zero);
    await endStreak(tester);
  });

  testWidgets('live streams do not seek', (tester) async {
    handler.mediaItem.add(
      const MediaItem(id: 'live', title: 'Live', extras: {'isLive': true}),
    );
    await pumpPage(tester);
    await tester.tapAt(right);
    await tester.pump();
    expect(handler.seeks, isEmpty);
    await endStreak(tester);
  });

  testWidgets('the middle shows and hides the controls', (tester) async {
    await pumpPage(tester);
    expect(find.byTooltip(en.exitFullscreen), findsOneWidget);
    expect(find.text('Song 0'), findsOneWidget);

    IgnorePointer controlsGate() => tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.byTooltip(en.exitFullscreen),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(controlsGate().ignoring, isFalse);

    await tester.tapAt(middle);
    await tester.pump(const Duration(milliseconds: 400));
    expect(controlsGate().ignoring, isTrue);

    await tester.tapAt(middle);
    await tester.pump(const Duration(milliseconds: 400));
    expect(controlsGate().ignoring, isFalse);
  });

  testWidgets('the side zones are labelled for screen readers', (tester) async {
    await pumpPage(tester);
    expect(find.bySemanticsLabel(en.seekBackSeconds(5)), findsOneWidget);
    expect(find.bySemanticsLabel(en.seekForwardSeconds(5)), findsOneWidget);
  });
}
