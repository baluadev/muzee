import 'dart:async';
import 'dart:developer' as developer;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ad_unit_ids.dart';
import 'package:muzee/services/monetization/ads_runtime.dart';

/// What full-screen ads need from the player: they pause the music while
/// they are up (an ad never talks over a song).
class AdPlaybackControl {
  const AdPlaybackControl({
    required this.isPlaying,
    required this.pause,
    required this.play,
  });

  final bool Function() isPlaying;
  final Future<void> Function() pause;
  final Future<void> Function() play;
}

/// Loads and shows the full-screen formats (rewarded, App Open,
/// interstitial) behind [AdPlacementGate]. Banners and native ads load in
/// their own widgets.
class AdsFacade {
  AdsFacade._();
  static final AdsFacade instance = AdsFacade._();

  /// Set at startup once the audio handler exists.
  static AdPlaybackControl? playback;

  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  bool _rewardLoadInFlight = false;
  bool _appOpenLoadInFlight = false;
  bool _interstitialLoadInFlight = false;

  /// A full-screen ad is on screen.
  bool get isShowingFullScreen => _showing;
  bool _showing = false;

  Future<void> disposeLoadedAds() async {
    final loaded = <Ad?>[_rewardedAd, _appOpenAd, _interstitialAd];
    _rewardedAd = null;
    _appOpenAd = null;
    _interstitialAd = null;
    for (final ad in loaded) {
      await ad?.dispose();
    }
  }

  /// Loads the full-screen formats in the background once ads can run.
  void preloadAll() {
    unawaited(preloadRewarded());
    unawaited(preloadAppOpenIfNeeded());
    unawaited(preloadInterstitialIfNeeded());
  }

  // --- Rewarded ---------------------------------------------------------------

  Future<void> preloadRewarded() async {
    if (!AdsRuntime.ready.value || !AdUnitIds.hasRewarded) return;
    if (_rewardedAd != null || _rewardLoadInFlight) return;
    _rewardLoadInFlight = true;
    await RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardLoadInFlight = false;
          _rewardedAd = ad;
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
    _rewardedAd = null;

    final rewarded = ad;
    await _showFullScreen(
      resumeMusic: true,
      show: (closed) {
        rewarded.fullScreenContentCallback = _closing(closed);
        return rewarded.show(
          onUserEarnedReward: (AdWithoutView _, RewardItem reward) {
            onUserEarned(reward.amount.round(), reward.type);
          },
        );
      },
    );
    unawaited(preloadRewarded());
    return RewardedShowResult.shown;
  }

  // --- App Open ---------------------------------------------------------------

  bool get hasAppOpenLoaded => _appOpenAd != null;

  Future<void> preloadAppOpenIfNeeded() async {
    if (!AdsRuntime.ready.value) return;
    if (_appOpenAd != null || _appOpenLoadInFlight) return;
    _appOpenLoadInFlight = true;
    await AppOpenAd.load(
      adUnitId: AdUnitIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoadInFlight = false;
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          _appOpenLoadInFlight = false;
          developer.log('AppOpen load failed: $error', name: 'AdsFacade');
        },
      ),
    );
  }

  /// Shows the loaded App Open ad, if any. Returns once it is closed.
  Future<bool> showAppOpenIfReady() async {
    final ad = _appOpenAd;
    if (ad == null || _showing) return false;
    _appOpenAd = null;
    await _showFullScreen(
      resumeMusic: true,
      show: (closed) {
        ad.fullScreenContentCallback = _closing(closed);
        return ad.show();
      },
    );
    unawaited(preloadAppOpenIfNeeded());
    return true;
  }

  // --- Interstitial -----------------------------------------------------------

  Future<void> preloadInterstitialIfNeeded() async {
    if (!AdsRuntime.ready.value) return;
    if (_interstitialAd != null || _interstitialLoadInFlight) return;
    _interstitialLoadInFlight = true;
    await InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoadInFlight = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadInFlight = false;
          developer.log('Interstitial load failed: $error', name: 'AdsFacade');
        },
      ),
    );
  }

  /// Shows an interstitial at [trigger] when the gate allows it and one is
  /// already loaded (it never makes the listener wait for a load). Returns
  /// once it is closed. The music stays paused afterwards: the caller is
  /// about to start something new.
  Future<bool> showInterstitialIfAllowed(AdInterstitialTrigger trigger) async {
    final ad = _interstitialAd;
    if (ad == null) {
      unawaited(preloadInterstitialIfNeeded());
      return false;
    }
    if (_showing || !await AdPlacementGate.canShowInterstitial(trigger)) {
      return false;
    }
    _interstitialAd = null;
    await _showFullScreen(
      resumeMusic: false,
      show: (closed) {
        ad.fullScreenContentCallback = _closing(closed);
        return ad.show();
      },
    );
    await AdPlacementGate.recordInterstitialShown();
    unawaited(preloadInterstitialIfNeeded());
    return true;
  }

  // --- Shared -----------------------------------------------------------------

  /// Closes [closed] (and frees the ad) once the ad is dismissed or fails
  /// to show.
  static FullScreenContentCallback<T> _closing<T extends Ad>(
    Completer<void> closed,
  ) {
    void finish(T ad) {
      ad.dispose();
      if (!closed.isCompleted) closed.complete();
    }

    return FullScreenContentCallback<T>(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, _) => finish(ad),
    );
  }

  /// Runs [show] with the music paused and completes when the ad is closed.
  /// With [resumeMusic], music that was playing goes on afterwards.
  Future<void> _showFullScreen({
    required bool resumeMusic,
    required Future<void> Function(Completer<void> closed) show,
  }) async {
    final closed = Completer<void>();
    final control = playback;
    final wasPlaying = control?.isPlaying() ?? false;
    if (wasPlaying) await control!.pause();
    _showing = true;
    try {
      await show(closed);
      await closed.future;
    } catch (e) {
      developer.log('Showing an ad failed: $e', name: 'AdsFacade');
    } finally {
      _showing = false;
      if (wasPlaying && resumeMusic) await control!.play();
    }
  }
}

enum RewardedShowResult { shown, skipped, loadFailed }
