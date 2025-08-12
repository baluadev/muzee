import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/configs/const.dart';
import 'package:muzee/main.dart';

class InterstitialAdManager {
  static final InterstitialAdManager inst = InterstitialAdManager._internal();
  InterstitialAdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdShowing = false;
  bool _isAdLoading = false;

  int _actionCount = 0; // ✅ số lần hành động đã ghi nhận
  final int actionThreshold = 5; // ✅ show sau mỗi 5 hành động

  void registerAction({
    VoidCallback? onAdShown,
    VoidCallback? onAdDismissed,
    Function(LoadAdError)? onAdFailedToShow,
  }) {
    _actionCount++;
    debugPrint('[InterstitialAd] Action count = $_actionCount');
    if (_actionCount >= actionThreshold) {
      _actionCount = 0;
      showAd(
        onAdShown: onAdShown,
        onAdDismissed: onAdDismissed,
        onAdFailedToShow: onAdFailedToShow,
      );
    }
  }

  void loadAd() {
    if (_isAdLoading || _interstitialAd != null) return;

    String adUnitId = Const.adUnitInter;
    if (kDebugMode) {
      adUnitId = Const.testAdUnitInter;
    }

    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[InterstitialAd] Loaded.');
          _interstitialAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[InterstitialAd] Failed to load: $error');
          _interstitialAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  void showAd({
    VoidCallback? onAdShown,
    VoidCallback? onAdDismissed,
    Function(LoadAdError)? onAdFailedToShow,
  }) {
    if (_interstitialAd == null) {
      debugPrint('[InterstitialAd] Not available.');
      loadAd();
      return;
    }

    if (_isAdShowing) {
      debugPrint('[InterstitialAd] Already showing.');
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAdShowing = true;
        debugPrint('[InterstitialAd] Showing.');
        // ✅ Pause nhạc khi quảng cáo bắt đầu
        myPlayerService.pause();
        onAdShown?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isAdShowing = false;
        debugPrint('[InterstitialAd] Dismissed.');
        // ✅ Resume nhạc khi quảng cáo bị tắt
        myPlayerService.play();
        ad.dispose();
        _interstitialAd = null;
        loadAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        _isAdShowing = false;
        debugPrint('[InterstitialAd] Failed to show: $error');
        // ✅ Resume nhạc nếu quảng cáo không hiển thị được
        myPlayerService.play();
        ad.dispose();
        _interstitialAd = null;
        loadAd();
        // onAdFailedToShow
        //     ?.call(LoadAdError(0, error.code, error.message, error.domain));
      },
    );

    _interstitialAd?.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  void reset() {
    _isAdShowing = false;
    _isAdLoading = false;
    _actionCount = 0;
    dispose();
  }
}
