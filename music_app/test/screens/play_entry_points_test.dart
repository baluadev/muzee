// Entry points that start playback: trending songs on Home/Explore go
// through the queue (like search), and the search page focuses its field.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/main.dart' show audioHandler;
import 'package:muzee/screens/explore/explore_controller.dart';
import 'package:muzee/screens/home/home_controller.dart';
import 'package:muzee/screens/search_page.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_theme.dart';

import '../helpers/audio_test_harness.dart';
import '../helpers/fake_youtube_http.dart';

void main() {
  late Directory storage;
  late TestAudioHandler handler;

  setUpAll(() async {
    storage = await setUpTestStorage();
    HttpOverrides.global = FakeYouTubeHttp();
  });

  tearDownAll(() => tearDownTestStorage(storage));

  setUp(() {
    offlineMode.value = true; // no background preloading
    handler = TestAudioHandler.create();
    audioHandler = handler;
  });

  tearDown(() {
    handler.retire();
    expect(handler.unexpectedErrors, isEmpty);
  });

  test('a Home trending song plays through the queue', () async {
    final song = buildSongs(1).single;

    HomeController().playTrendingSong(song);
    await settle();

    expect(handler.currentQueue.map((s) => s['ytid']), [songId(0)]);
    expect(handler.currentSong?['ytid'], songId(0));
    expect(handler.played, [songId(0)]);
  });

  test('an Explore song plays through the queue', () async {
    final song = buildSongs(2).last;

    ExploreController().playSong(song);
    await settle();

    expect(handler.currentQueue.map((s) => s['ytid']), [songId(1)]);
    expect(handler.played, [songId(1)]);
  });

  testWidgets('the search page focuses its field when opened', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNeoTheme(NeoThemeVariant.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchPage(),
      ),
    );
    await tester.pump();

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('when pushed, it focuses after the page transition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNeoTheme(NeoThemeVariant.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const SearchPage())),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    FocusNode node() =>
        tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    expect(node().hasFocus, isFalse, reason: 'still animating in');

    await tester.pumpAndSettle();
    expect(node().hasFocus, isTrue);
  });
}
