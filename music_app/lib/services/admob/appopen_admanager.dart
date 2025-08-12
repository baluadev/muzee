import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/configs/const.dart';

class AppOpenAdManager {
  static final AppOpenAdManager inst = AppOpenAdManager._internal();
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  DateTime? _loadTime;
  DateTime? _lastPausedAt;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  bool _hasShownInitial = false; // ✅ mới thêm: để biết đã show lần đầu hay chưa

  final Duration maxCacheDuration = const Duration(hours: 4);
  final Duration minBackgroundDuration = const Duration(minutes: 30); // ✅ 30 phút

  void onAppPaused() {
    _lastPausedAt = DateTime.now();
  }

  void onAppResumed() {
    final now = DateTime.now();

    final shouldShow = _hasShownInitial && // ✅ chỉ kiểm tra thời gian sau lần đầu đã show
        _lastPausedAt != null &&
        now.difference(_lastPausedAt!) >= minBackgroundDuration;

    debugPrint(
      '[AppOpenAd] Resumed after ${_lastPausedAt != null ? now.difference(_lastPausedAt!).inMinutes : 0} minutes. Should show = $shouldShow',
    );

    if (shouldShow) {
      showAdIfAvailable();
    }
  }

  void showAdIfAvailable() {
    if (!_isAdAvailable) {
      loadAd();
      debugPrint('[AppOpenAd] No ad available to show.');
      return;
    }

    if (_isShowingAd) {
      debugPrint('[AppOpenAd] Ad already showing.');
      return;
    }

    if (_isAdExpired) {
      debugPrint('[AppOpenAd] Ad expired. Reloading...');
      _disposeAd();
      loadAd();
      return;
    }

    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('[AppOpenAd] Ad shown.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AppOpenAd] Failed to show: $error');
        _isShowingAd = false;
        _disposeAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AppOpenAd] Ad dismissed.');
        _isShowingAd = false;
        _disposeAd();
        loadAd();
      },
    );

    _appOpenAd?.show();
    _hasShownInitial = true; // ✅ Đánh dấu đã show lần đầu
  }

  bool get _isAdAvailable => _appOpenAd != null;
  bool get _isAdExpired {
    if (_loadTime == null) return true;
    return DateTime.now().difference(_loadTime!) > maxCacheDuration;
  }

  void loadAd() {
    if (_isLoadingAd || _isAdAvailable) {
      return;
    }

    String openAppId = Const.adUnitIdOpenApp;

    if (kDebugMode) {
      openAppId = Const.testAdUnitIdOpenApp;
    }

    _isLoadingAd = true;

    AppOpenAd.load(
      adUnitId: openAppId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AppOpenAd] Ad loaded.');
          _appOpenAd = ad;
          _loadTime = DateTime.now();
          _isLoadingAd = false;

          // ✅ Show luôn nếu chưa từng show
          if (!_hasShownInitial) {
            showAdIfAvailable();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AppOpenAd] Failed to load: $error');
          _isLoadingAd = false;
        },
      ),
    );
  }

  void _disposeAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _loadTime = null;
  }

  void reset() {
    _isShowingAd = false;
    _isLoadingAd = false;
    _hasShownInitial = false;
    _disposeAd();
    _lastPausedAt = null;
  }
}
