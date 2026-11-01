// Where and when ads may show: nothing before consent and the SDK, nothing
// for Premium or during earned ad-free time, no App Open ad on the first
// launch or over music, interstitials spaced out and capped per day, and one
// native ad per list once it is long enough.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:muzee/services/monetization/ad_free_wallet_service.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ads_runtime.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/monetization/monetization_remote_config.dart';
import 'package:muzee/services/monetization/ui_route_flags.dart';
import 'package:muzee/widgets/monetization/native_ad_tile.dart';

import '../helpers/audio_test_harness.dart';

void main() {
  late Directory storage;
  var playing = false;

  setUpAll(() async {
    storage = await setUpTestStorage();
    AdPlacementGate.playbackPlayingResolver = () => playing;
  });
  tearDownAll(() => tearDownTestStorage(storage));

  setUp(() async {
    await Hive.box('monetization').clear();
    await MonetizationRemoteConfig.ensureDefaults();
    AdsRuntime.ready.value = true;
    AdsRuntime.launchCount = 5;
    EntitlementService.isPremium.value = false;
    UiRouteFlags.nowPlayingVisible.value = false;
    UiRouteFlags.videoFullscreenVisible.value = false;
    playing = false;
  });

  /// Well past the session's grace period.
  DateTime later([Duration extra = Duration.zero]) =>
      AdsRuntime.sessionStart.add(const Duration(hours: 1) + extra);

  group('every format', () {
    test('waits for consent and the SDK', () async {
      AdsRuntime.ready.value = false;
      expect(
        await AdPlacementGate.canShowBanner(AdBannerPlacement.home),
        isFalse,
      );
      expect(
        await AdPlacementGate.canShowNative(AdNativePlacement.playlist),
        isFalse,
      );
      expect(await AdPlacementGate.canShowRewarded(), isFalse);
    });

    test('stays away from Premium', () async {
      EntitlementService.isPremium.value = true;
      expect(
        await AdPlacementGate.canShowBanner(AdBannerPlacement.home),
        isFalse,
      );
      expect(
        await AdPlacementGate.canShowInterstitial(
          AdInterstitialTrigger.startList,
          now: later(),
        ),
        isFalse,
      );
    });

    test('earned ad-free time stops ads but not a new reward', () async {
      await AdFreeWalletService.grant(const Duration(minutes: 30));
      expect(
        await AdPlacementGate.canShowBanner(AdBannerPlacement.home),
        isFalse,
      );
      expect(await AdPlacementGate.canShowRewarded(), isTrue);
    });

    test('never over full-screen video', () async {
      UiRouteFlags.videoFullscreenVisible.value = true;
      expect(
        await AdPlacementGate.canShowBanner(AdBannerPlacement.search),
        isFalse,
      );
      expect(await AdPlacementGate.canShowRewarded(), isFalse);
    });
  });

  group('App Open', () {
    test('not on the first launch after install', () async {
      AdsRuntime.launchCount = 1;
      expect(
        await AdPlacementGate.canShowAppOpen(matchedLocation: '/home'),
        isFalse,
      );
    });

    test('not while music plays or on the player', () async {
      expect(
        await AdPlacementGate.canShowAppOpen(matchedLocation: '/home'),
        isTrue,
      );
      playing = true;
      expect(
        await AdPlacementGate.canShowAppOpen(matchedLocation: '/home'),
        isFalse,
      );
      playing = false;
      UiRouteFlags.nowPlayingVisible.value = true;
      expect(
        await AdPlacementGate.canShowAppOpen(matchedLocation: '/home'),
        isFalse,
      );
    });
  });

  group('interstitial', () {
    Future<bool> allowed(DateTime at) => AdPlacementGate.canShowInterstitial(
      AdInterstitialTrigger.startList,
      now: at,
    );

    test('the session starts at launch, not at the first ad check', () async {
      AdsRuntime.sessionStart = DateTime(2000);
      final before = DateTime.now();
      await AdsRuntime.recordLaunch();
      expect(AdsRuntime.sessionStart.isBefore(before), isFalse);
      AdsRuntime.launchCount = 5;
    });

    test('waits out the start of the session', () async {
      expect(
        await allowed(AdsRuntime.sessionStart.add(const Duration(minutes: 1))),
        isFalse,
      );
      expect(await allowed(later()), isTrue);
    });

    test('is spaced out', () async {
      await AdPlacementGate.recordInterstitialShown(now: later());
      expect(await allowed(later(const Duration(minutes: 2))), isFalse);
      expect(await allowed(later(const Duration(minutes: 6))), isTrue);
    });

    test('is capped per day', () async {
      final day = DateTime(2030, 1, 1, 9);
      for (var i = 0; i < MonetizationRemoteConfig.interstitialDailyCap; i++) {
        await AdPlacementGate.recordInterstitialShown(
          now: day.add(Duration(minutes: 10 * i)),
        );
      }
      expect(await allowed(day.add(const Duration(hours: 5))), isFalse);
      // A new day starts the count again.
      expect(await allowed(day.add(const Duration(days: 1))), isTrue);
    });

    test('never on the player', () async {
      UiRouteFlags.nowPlayingVisible.value = true;
      expect(await allowed(later()), isFalse);
    });
  });

  group('inline ad slot', () {
    const slot = InlineAdSlot(5);

    test('a short list gets no ad', () {
      expect(slot.count(5), 5);
      expect(List.generate(5, (i) => slot.isAd(i, 5)), everyElement(isFalse));
    });

    test('a long list gets one, after the first items', () {
      expect(slot.count(12), 13);
      expect(slot.isAd(5, 12), isTrue);
      expect([
        for (var row = 0; row < 13; row++)
          if (!slot.isAd(row, 12)) slot.item(row, 12),
      ], List.generate(12, (i) => i));
    });
  });
}
