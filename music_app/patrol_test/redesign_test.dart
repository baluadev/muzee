import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/screens/now_playing_page.dart';
import 'package:muzee/widgets/mini_player.dart';
import 'package:muzee/widgets/song_bar.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app.dart';

// The redesigned screens, in whatever language the device uses (strings come
// from the running app). They need the network (YouTube charts and streams)
// but change no device settings, so they can run on a real phone.
void main() {
  const long = Duration(seconds: 60);

  AppLocalizations strings(PatrolIntegrationTester $) =>
      AppLocalizations.of($.tester.element(find.byType(NavigationBar)))!;

  patrolTest('UX-001: Home greets, and its Settings button opens Settings', (
    $,
  ) async {
    await launchApp($);
    final en = strings($);

    final greetings = [en.goodMorning, en.goodAfternoon, en.goodEvening];
    expect(
      greetings.where((g) => $(g).exists),
      hasLength(1),
      reason: 'one greeting for the time of day',
    );

    await $(find.byTooltip(en.settings)).tap();
    await $(en.playbackSection).waitUntilVisible(timeout: long);
    await $(en.dataSection).scrollTo();
    expect($(en.dataSection).exists, isTrue);
    await $(en.others).scrollTo();
    expect($(en.version).exists, isTrue);

    // The app bar's back arrow (the system Back key, checked by hand on a
    // Galaxy Z Flip4, isn't delivered to the app under Patrol there).
    final back = MaterialLocalizations.of(
      $.tester.element(find.byType(AppBar)),
    ).backButtonTooltip;
    await $(find.byTooltip(back)).tap();
    await $(NavigationBar).waitUntilVisible(timeout: long);
  });

  patrolTest(
    'UX-002: Search tab plays a top song; mini player and Now Playing work',
    ($) async {
      await launchApp($);
      final en = strings($);

      await $(find.byType(NavigationDestination)).at(1).tap();
      await $(en.searchHint).waitUntilVisible(timeout: long);
      await $(SongBar).first.waitUntilVisible(timeout: long);
      await $(SongBar).first.tap();

      // The mini player shows the song, then its play/pause button once it
      // has loaded.
      await $(MiniPlayer).waitUntilVisible(timeout: long);
      await $(find.byTooltip(en.pause)).waitUntilVisible(timeout: long);
      expect($(find.byTooltip(en.next)).exists, isTrue);

      // Now Playing.
      await $(MiniPlayer).tap();
      await $(NowPlayingPage).waitUntilVisible(timeout: long);
      expect($(en.nowPlaying).exists, isTrue);

      await $(find.byTooltip(en.shuffleOff)).tap();
      await $(find.byTooltip(en.shuffleOn)).waitUntilVisible();
      await $(find.byTooltip(en.shuffleOn)).tap();
      await $(find.byTooltip(en.shuffleOff)).waitUntilVisible();

      await $(find.byTooltip(en.repeatOff)).tap();
      await $(find.byTooltip(en.repeatAll)).waitUntilVisible();
      await $(find.byTooltip(en.repeatAll)).tap();
      await $(find.byTooltip(en.repeatOne)).waitUntilVisible();
      await $(find.byTooltip(en.repeatOne)).tap();
      await $(find.byTooltip(en.repeatOff)).waitUntilVisible();

      // The queue sheet.
      await $(find.byTooltip(en.queue)).tap();
      await $(en.upNext).waitUntilVisible(timeout: long);
      expect($(en.clearAll).exists, isTrue);
      // Close it by tapping above it.
      await $.tester.tapAt(const Offset(200, 60));
      await $.pumpAndSettle();
      expect($(en.upNext).exists, isFalse);

      // Swipe down closes Now Playing.
      await $.tester.flingFrom(
        const Offset(200, 260),
        const Offset(0, 500),
        2500,
      );
      // Not pumpAndSettle: the mini player's playing indicator never stops.
      await $.pump(const Duration(seconds: 2));
      expect($(NowPlayingPage).exists, isFalse);
      expect($(NavigationBar).exists, isTrue);

      await $(find.byTooltip(en.pause)).tap();
      await $(find.byTooltip(en.play)).waitUntilVisible(timeout: long);
    },
  );

  patrolTest('UX-003: Library "+" offers a playlist or a folder', ($) async {
    await launchApp($);
    final en = strings($);

    await $(find.byType(NavigationDestination)).at(2).tap();
    await $(find.byTooltip(en.createNew)).waitUntilVisible(timeout: long);
    await $(find.byTooltip(en.createNew)).tap();

    await $(en.createPlaylist).waitUntilVisible();
    expect($(en.createFolder).exists, isTrue);
    await $.tester.tapAt(const Offset(200, 60));
  });
}
