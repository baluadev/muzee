// The redesigned player pieces, queue sheet and Premium screen: labels come
// from the app's strings, states are shown without relying on color, and
// they work in the light theme too.

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzee/localization/app_localizations.dart';
import 'package:muzee/main.dart' show audioHandler;
import 'package:muzee/screens/premium_paywall_page.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_theme.dart';
import 'package:muzee/widgets/mini_player.dart';
import 'package:muzee/widgets/now_playing/now_playing_controls.dart';
import 'package:muzee/widgets/queue_list_view.dart';

import '../helpers/audio_test_harness.dart';
import '../helpers/fake_youtube_http.dart';

void main() {
  late Directory storage;
  late TestAudioHandler handler;
  final en = lookupAppLocalizations(const Locale('en'));

  Widget app(Widget child, {NeoThemeVariant variant = NeoThemeVariant.dark}) =>
      MaterialApp(
        theme: buildNeoTheme(variant),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  setUpAll(() async {
    storage = await setUpTestStorage();
    HttpOverrides.global = FakeYouTubeHttp();
    offlineMode.value = true; // no background preloading
    handler = TestAudioHandler.create();
    audioHandler = handler;
  });

  tearDownAll(() async {
    handler.retire();
    await tearDownTestStorage(storage);
  });

  tearDown(() {
    shuffleNotifier.value = false;
    repeatNotifier.value = AudioServiceRepeatMode.none;
    EntitlementService.isPremium.value = false;
  });

  group('player controls', () {
    const metadata = MediaItem(id: 'song_000000', title: 'Song 0');

    Future<void> pumpControls(WidgetTester tester) => tester.pumpWidget(
      app(
        const PlayerControlButtons(
          metadata: metadata,
          iconSize: 40,
          miniIconSize: 24,
        ),
      ),
    );

    testWidgets('shuffle says whether it is on, with a filled icon', (
      tester,
    ) async {
      await pumpControls(tester);
      expect(find.byTooltip(en.shuffleOff), findsOneWidget);
      expect(find.byIcon(FluentIcons.arrow_shuffle_24_regular), findsOneWidget);
      // No "slashed" icons for the off state.
      expect(
        find.byIcon(FluentIcons.arrow_shuffle_off_24_regular),
        findsNothing,
      );

      shuffleNotifier.value = true;
      await tester.pump();

      expect(find.byTooltip(en.shuffleOn), findsOneWidget);
      expect(find.byIcon(FluentIcons.arrow_shuffle_24_filled), findsOneWidget);
    });

    testWidgets('repeat cycles off → one → off for a single song', (
      tester,
    ) async {
      await pumpControls(tester);
      expect(find.byTooltip(en.repeatOff), findsOneWidget);
      expect(
        find.byIcon(FluentIcons.arrow_repeat_all_off_24_regular),
        findsNothing,
      );

      await tester.tap(find.byTooltip(en.repeatOff));
      await tester.pump();
      expect(repeatNotifier.value, AudioServiceRepeatMode.one);
      expect(find.byTooltip(en.repeatOne), findsOneWidget);
      expect(find.byIcon(FluentIcons.arrow_repeat_1_24_filled), findsOneWidget);

      await tester.tap(find.byTooltip(en.repeatOne));
      await tester.pump();
      expect(repeatNotifier.value, AudioServiceRepeatMode.none);
    });

    testWidgets('repeat all has its own label', (tester) async {
      repeatNotifier.value = AudioServiceRepeatMode.all;
      await pumpControls(tester);
      expect(find.byTooltip(en.repeatAll), findsOneWidget);
    });

    testWidgets('previous and next have labels', (tester) async {
      await pumpControls(tester);
      expect(find.byTooltip(en.skipToPrevious), findsOneWidget);
      expect(find.byTooltip(en.skipToNext), findsOneWidget);
    });
  });

  group('queue sheet and mini player', () {
    testWidgets('an empty queue says so and offers nothing to clear', (
      tester,
    ) async {
      await tester.pumpWidget(app(const QueueWidget(isBottomSheet: true)));
      await tester.pump();

      expect(find.text(en.noSongsInQueue), findsOneWidget);
      expect(find.text(en.clearAll), findsNothing);
    });

    testWidgets('a queue shows Now playing, Up next and Clear all', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await handler.addPlaylistToQueue(buildSongs(3), replace: true);
        await settle();
      });

      await tester.pumpWidget(app(const QueueWidget(isBottomSheet: true)));
      await tester.pump();

      expect(find.text(en.nowPlaying), findsOneWidget);
      expect(find.text(en.upNext), findsOneWidget);
      expect(find.text(en.clearAll), findsOneWidget);
      expect(find.text(en.songCount(3)), findsOneWidget);
      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('NOW PLAYING'), findsNothing);
      expect(find.text('UP NEXT'), findsNothing);
    });

    testWidgets(
      'the mini player has labelled 48 dp controls and a progress line',
      (tester) async {
        await tester.runAsync(() async {
          await handler.addPlaylistToQueue(buildSongs(3), replace: true);
          await settle();
        });
        // The harness skips the real stream lookup, which is what publishes
        // the media item.
        handler.mediaItem.add(
          const MediaItem(
            id: 'song_000000',
            title: 'Song 0',
            artist: 'Artist 0',
          ),
        );
        // Paused and ready: the case where no position update ever arrives.
        handler.playbackState.add(
          handler.playbackState.value.copyWith(
            processingState: AudioProcessingState.ready,
            playing: false,
          ),
        );

        await tester.pumpWidget(
          app(
            const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
          ),
        );
        // The player state is debounced by 100 ms. Nothing is playing, so no
        // position update arrives: it must show anyway.
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.text('Song 0'), findsOneWidget);
        final artist = tester.widget<Text>(find.text('Artist 0'));
        expect(artist.style?.fontSize, 13);

        final play = find.byWidgetPredicate(
          (w) =>
              w is IconButton &&
              (w.tooltip == en.play ||
                  w.tooltip == en.pause ||
                  w.tooltip == en.replay),
        );
        final next = find.byTooltip(en.next);
        expect(play, findsOneWidget);
        expect(next, findsOneWidget);
        expect(tester.getSize(play).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(next).height, greaterThanOrEqualTo(48));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Let the title marquee's timers finish.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 15));
      },
    );
  });

  group('Muzee Premium', () {
    testWidgets('promises only what the one-time purchase gives', (
      tester,
    ) async {
      await tester.pumpWidget(app(const PremiumPaywallPage()));
      await tester.pump();

      expect(find.text(en.musifyPremium), findsOneWidget);
      expect(find.text(en.adFreeListening), findsOneWidget);
      expect(find.text(en.dataBackupRestore), findsOneWidget);
      expect(find.text(en.premiumTerms), findsOneWidget);
      expect(en.premiumTerms, contains('Not a subscription'));
      expect(find.textContaining(RegExp('month|/mo|trial')), findsNothing);
      // No store in tests: says so instead of a dead Buy button.
      expect(find.text(en.premiumProductsUnavailable), findsOneWidget);
      expect(find.text(en.restorePurchases), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('a Premium user sees it is active, with no purchase button', (
      tester,
    ) async {
      EntitlementService.isPremium.value = true;
      await tester.pumpWidget(app(const PremiumPaywallPage()));
      await tester.pump();

      expect(find.text(en.premiumActive), findsOneWidget);
      expect(find.text(en.premiumProductsUnavailable), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('reads in the light theme', (tester) async {
      await tester.pumpWidget(
        app(const PremiumPaywallPage(), variant: NeoThemeVariant.light),
      );
      await tester.pump();

      final title = tester.widget<Text>(find.text(en.musifyPremium));
      final style = DefaultTextStyle.of(
        tester.element(find.text(en.musifyPremium)),
      ).style.merge(title.style);
      expect(style.color, NeoColors.light.onSurface);
    });
  });
}
