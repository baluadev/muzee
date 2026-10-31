import 'package:muzee/services/monetization/ad_free_wallet_service.dart';
import 'package:muzee/services/monetization/ad_unit_ids.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/monetization/monetization_remote_config.dart';
import 'package:muzee/services/monetization/ui_route_flags.dart';
import 'package:muzee/services/pip_service.dart';

enum AdBannerPlacement { home, settings, library, search }

enum AdNativePlacement { home, library }

enum AdInterstitialTrigger { explicitNavigationBackFromNowPlaying }

/// Single policy surface for all ad formats.
class AdPlacementGate {
  AdPlacementGate._();

  /// Set from app bootstrap after the audio handler exists (avoids importing `main.dart`).
  static bool Function()? playbackPlayingResolver;

  static Future<bool> _playbackBlockedForInterruptAds() async {
    if (UiRouteFlags.videoFullscreenVisible.value) return true;
    if (await PipService.isInPip()) return true;

    final playing = playbackPlayingResolver?.call() ?? false;
    if (UiRouteFlags.nowPlayingVisible.value && playing) return true;

    return false;
  }

  static Future<bool> canShowRewarded() async {
    if (!AdUnitIds.hasRewarded) return false;
    if (EntitlementService.isPremium.value) return false;
    if (UiRouteFlags.videoFullscreenVisible.value) return false;
    if (await PipService.isInPip()) return false;
    return true;
  }

  static Future<bool> canShowAppOpen({required String matchedLocation}) async {
    if (EntitlementService.isPremium.value) return false;
    if (AdFreeWalletService.isAdFreeActive) return false;
    if (await _playbackBlockedForInterruptAds()) return false;

    if (matchedLocation.contains('fullscreen')) return false;

    return true;
  }

  static Future<bool> canShowBanner(AdBannerPlacement placement) async {
    if (!MonetizationRemoteConfig.enableBanner) return false;

    if (EntitlementService.isPremium.value) return false;
    if (AdFreeWalletService.isAdFreeActive) return false;
    if (await PipService.isInPip()) return false;
    if (UiRouteFlags.videoFullscreenVisible.value) return false;
    return true;
  }

  static Future<bool> canShowNative(AdNativePlacement placement) async {
    if (!MonetizationRemoteConfig.enableNative) return false;

    if (EntitlementService.isPremium.value) return false;
    if (AdFreeWalletService.isAdFreeActive) return false;
    if (await PipService.isInPip()) return false;
    if (UiRouteFlags.videoFullscreenVisible.value) return false;
    return true;
  }

  static Future<bool> canShowInterstitial(AdInterstitialTrigger trigger) async {
    if (!MonetizationRemoteConfig.enableInterstitial) return false;

    if (EntitlementService.isPremium.value) return false;
    if (AdFreeWalletService.isAdFreeActive) return false;
    if (await _playbackBlockedForInterruptAds()) return false;
    return true;
  }
}
