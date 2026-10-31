import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ad_unit_ids.dart';

/// Loads/shows ads behind [AdPlacementGate]. Banner/native/interstitial are stubs until enabled.
class AdsFacade {
  AdsFacade._();
  static final AdsFacade instance = AdsFacade._();

  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  bool _rewardLoadInFlight = false;
  bool _interstitialLoadInFlight = false;

  Future<void> disposeLoadedAds() async {
    final rewarded = _rewardedAd;
    final open = _appOpenAd;
    final interstitial = _interstitialAd;
    _rewardedAd = null;
    _appOpenAd = null;
    _interstitialAd = null;
    if (rewarded != null) await rewarded.dispose();
    if (open != null) await open.dispose();
    if (interstitial != null) await interstitial.dispose();
  }

  Future<void> preloadRewarded() async {
    if (!AdUnitIds.hasRewarded) return;
    if (_rewardedAd != null || _rewardLoadInFlight) return;
    _rewardLoadInFlight = true;
    await RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardLoadInFlight = false;
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (identical(_rewardedAd, ad)) _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (identical(_rewardedAd, ad)) _rewardedAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardLoadInFlight = false;
          developer.log('Rewarded load failed: $error', name: 'AdsFacade');
        },
      ),
    );
  }

  Future<RewardedShowResult> showRewardedIfAllowed({
    required Future<bool> Function() gate,
    required void Function(int rewardAmount, String rewardType) onUserEarned,
  }) async {
    if (!await gate()) return RewardedShowResult.skipped;

    var ad = _rewardedAd;
    if (ad == null) {
      await preloadRewarded();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      ad = _rewardedAd;
    }
    if (ad == null) return RewardedShowResult.loadFailed;

    await ad.show(
      onUserEarnedReward: (AdWithoutView _, RewardItem reward) {
        onUserEarned(reward.amount.round(), reward.type);
      },
    );

    _rewardedAd = null;
    unawaited(preloadRewarded());
    return RewardedShowResult.shown;
  }

  Future<void> preloadAppOpenIfNeeded() async {
    if (_appOpenAd != null) return;

    await AppOpenAd.load(
      adUnitId: AdUnitIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (AppOpenAd a) {
              a.dispose();
              if (identical(_appOpenAd, a)) _appOpenAd = null;
            },
            onAdFailedToShowFullScreenContent: (AppOpenAd a, _) {
              a.dispose();
              if (identical(_appOpenAd, a)) _appOpenAd = null;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          developer.log('AppOpen load failed: $error', name: 'AdsFacade');
        },
      ),
    );
  }

  Future<bool> showAppOpenIfReady() async {
    final ad = _appOpenAd;
    if (ad == null) return false;
    _appOpenAd = null;
    await ad.show();
    unawaited(preloadAppOpenIfNeeded());
    return true;
  }

  // --- Formats wired later (Gate-ready API surface) ---

  Future<void> preloadBanner(AdBannerPlacement placement) async {
    if (!await AdPlacementGate.canShowBanner(placement)) return;
    if (kDebugMode) {
      developer.log('preloadBanner($placement) no-op', name: 'AdsFacade');
    }
  }

  Future<void> preloadInterstitialIfNeeded() async {
    if (_interstitialAd != null || _interstitialLoadInFlight) return;

    _interstitialLoadInFlight = true;
    await InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoadInFlight = false;
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (identical(_interstitialAd, ad)) _interstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (identical(_interstitialAd, ad)) _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadInFlight = false;
          developer.log('Interstitial load failed: $error', name: 'AdsFacade');
        },
      ),
    );
  }

  Future<void> preloadNative(AdNativePlacement placement) async {
    if (!await AdPlacementGate.canShowNative(placement)) return;
    if (kDebugMode) {
      developer.log('preloadNative($placement) no-op', name: 'AdsFacade');
    }
  }

  Future<bool> showInterstitialIfAllowed(AdInterstitialTrigger trigger) async {
    if (!await AdPlacementGate.canShowInterstitial(trigger)) return false;

    var ad = _interstitialAd;
    if (ad == null) {
      await preloadInterstitialIfNeeded();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      ad = _interstitialAd;
    }

    if (ad == null) return false;

    await ad.show();
    _interstitialAd = null;
    unawaited(preloadInterstitialIfNeeded());
    return true;
  }
}

enum RewardedShowResult { shown, skipped, loadFailed }
