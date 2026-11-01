import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzee/services/monetization/ad_free_wallet_service.dart';
import 'package:muzee/services/monetization/ad_unit_ids.dart';
import 'package:muzee/services/monetization/ads_runtime.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/monetization/monetization_remote_config.dart';
import 'package:muzee/services/monetization/ui_route_flags.dart';
import 'package:muzee/services/pip_service.dart';

/// Where banners sit: inline in the browsing screens, at the foot of the
/// queue sheet, and at the top of the player (above the artwork, away from
/// its controls, only when the screen has room to spare).
enum AdBannerPlacement { home, library, search, queue, player }

/// Where native ads sit: inside long lists.
enum AdNativePlacement { playlist, searchResults, allPlaylists }

/// The natural breaks an interstitial may fill.
enum AdInterstitialTrigger {
  /// The listener starts a new list (Play on a playlist, a search result):
  /// shown before the music starts, so it never talks over it.
  startList,
}

/// Single policy surface for all ad formats.
///
/// Rules every format shares: nothing before [AdsRuntime.ready] (consent and
/// SDK), nothing for Premium or during earned ad-free time, nothing over
/// full-screen video or picture-in-picture.
class AdPlacementGate {
  AdPlacementGate._();

  /// Set from app bootstrap after the audio handler exists (avoids importing `main.dart`).
  static bool Function()? playbackPlayingResolver;

  static bool get _playing => playbackPlayingResolver?.call() ?? false;

  static Box<dynamic> get _box => Hive.box('monetization');
  static const _lastInterstitialKey = 'ads_last_interstitial_ms';
  static const _interstitialDayKey = 'ads_interstitial_day';
  static const _interstitialCountKey = 'ads_interstitial_count';

  static Future<bool> _common({bool allowAdFree = false}) async {
    if (!AdsRuntime.ready.value) return false;
    if (EntitlementService.isPremium.value) return false;
    if (!allowAdFree && AdFreeWalletService.isAdFreeActive) return false;
    if (UiRouteFlags.videoFullscreenVisible.value) return false;
    if (await PipService.isInPip()) return false;
    return true;
  }

  /// The listener asks for it, so earned ad-free time doesn't stop it.
  static Future<bool> canShowRewarded() async {
    if (!AdUnitIds.hasRewarded) return false;
    return _common(allowAdFree: true);
  }

  /// App Open: never on the first launch after install, never while music
  /// plays (coming back to the app mid-song shouldn't cost a full-screen
  /// ad), never on the player.
  static Future<bool> canShowAppOpen({required String matchedLocation}) async {
    if (AdsRuntime.isFirstLaunch) return false;
    if (!await _common()) return false;
    if (_playing) return false;
    if (UiRouteFlags.nowPlayingVisible.value) return false;
    if (matchedLocation.contains('fullscreen')) return false;
    return true;
  }

  static Future<bool> canShowBanner(AdBannerPlacement placement) async {
    if (!MonetizationRemoteConfig.enableBanner) return false;
    return _common();
  }

  static Future<bool> canShowNative(AdNativePlacement placement) async {
    if (!MonetizationRemoteConfig.enableNative) return false;
    return _common();
  }

  /// Interstitials: not in the first minutes of a session, spaced out and
  /// capped per day (see [MonetizationRemoteConfig]), never on the player.
  static Future<bool> canShowInterstitial(
    AdInterstitialTrigger trigger, {
    DateTime? now,
  }) async {
    if (!MonetizationRemoteConfig.enableInterstitial) return false;
    if (!await _common()) return false;
    if (UiRouteFlags.nowPlayingVisible.value) return false;

    final at = now ?? DateTime.now();
    if (at.difference(AdsRuntime.sessionStart) <
        MonetizationRemoteConfig.interstitialGrace) {
      return false;
    }
    final lastMs = _box.get(_lastInterstitialKey) as int?;
    if (lastMs != null &&
        at.difference(DateTime.fromMillisecondsSinceEpoch(lastMs)) <
            MonetizationRemoteConfig.interstitialMinInterval) {
      return false;
    }
    final todayCount = _box.get(_interstitialDayKey) == _dayKey(at)
        ? _box.get(_interstitialCountKey, defaultValue: 0) as int
        : 0;
    return todayCount < MonetizationRemoteConfig.interstitialDailyCap;
  }

  /// Counts an interstitial that was shown, for the spacing and daily cap.
  static Future<void> recordInterstitialShown({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final day = _dayKey(at);
    final count = _box.get(_interstitialDayKey) == day
        ? _box.get(_interstitialCountKey, defaultValue: 0) as int
        : 0;
    await _box.putAll({
      _lastInterstitialKey: at.millisecondsSinceEpoch,
      _interstitialDayKey: day,
      _interstitialCountKey: count + 1,
    });
  }

  static String _dayKey(DateTime at) => '${at.year}-${at.month}-${at.day}';
}
