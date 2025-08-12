import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/configs/const.dart';

class NativeAdManager extends StatefulWidget {
  final TemplateType templateType;

  const NativeAdManager({
    super.key,
    this.templateType = TemplateType.medium,
  });

  @override
  State<NativeAdManager> createState() => _NativeAdManagerState();
}

class _NativeAdManagerState extends State<NativeAdManager> {
  NativeAd? _nativeAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    String adUnitId =
        kDebugMode ? Const.testAdUnitIdNative : Const.adUnitIdNative;

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdManagerAdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[NativeAd] Loaded.');
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[NativeAd] Failed to load: $error');
          ad.dispose();
          _reloadAd();
          setState(() => _loaded = false);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: widget.templateType == TemplateType.small
            ? Colors.white
            : Colors.blue.shade50,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          size: 12.0,
        ),
      ),
    )..load();
  }

  void _reloadAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    if (!mounted) return;
    _loaded = false;
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _nativeAd == null) return const SizedBox.shrink();
    final height = widget.templateType == TemplateType.small ? 100.0 : 200.0;
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

class SongNativeAdManager extends StatefulWidget {
  const SongNativeAdManager({super.key});

  @override
  State<SongNativeAdManager> createState() => _SongNativeAdManagerState();
}

class _SongNativeAdManagerState extends State<SongNativeAdManager> {
  NativeAd? _nativeAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    String adUnitId =
        kDebugMode ? Const.testAdUnitIdNative : Const.adUnitIdNative;
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'songNativeAds',
      request: const AdManagerAdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[NativeAd] Loaded.');
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[NativeAd] Failed to load: $error');
          ad.dispose();
          _reloadAd();
          setState(() => _loaded = false);
        },
      ),
    )..load();
  }

  void _reloadAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    if (!mounted) return;
    _loaded = false;
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      height: 38,
      margin: EdgeInsets.only(bottom: 16.h),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

class PlaylistNativeAdManager extends StatefulWidget {
  const PlaylistNativeAdManager({super.key});

  @override
  State<PlaylistNativeAdManager> createState() =>
      _PlaylistNativeAdManagerState();
}

class _PlaylistNativeAdManagerState extends State<PlaylistNativeAdManager> {
  NativeAd? _nativeAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    String adUnitId =
        kDebugMode ? Const.testAdUnitIdNative : Const.adUnitIdNative;
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'playlistNativeAds',
      request: const AdManagerAdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[NativeAd] Loaded.');
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[NativeAd] Failed to load: $error');
          ad.dispose();
          _reloadAd();
          setState(() => _loaded = false);
        },
      ),
    )..load();
  }

  void _reloadAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    if (!mounted) return;
    _loaded = false;
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      // height: 50,
      // width: 50,
      // color: Colors.red,
      margin: EdgeInsets.only(bottom: 16.h),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

class NativedDefault extends StatefulWidget {
  const NativedDefault({super.key});

  @override
  State<NativedDefault> createState() => _NativedDefaultState();
}

class _NativedDefaultState extends State<NativedDefault> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  String adUnitId =
      kDebugMode ? Const.testAdUnitIdNative : Const.adUnitIdNative;

  /// Loads a native ad.
  void loadAd() {
    _nativeAd = NativeAd(
        adUnitId: adUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            print('$NativeAd loaded.');
            setState(() {
              _nativeAdIsLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Dispose the ad here to free resources.
            print('$NativeAd failedToLoad: $error');
            ad.dispose();
          },
          // Called when a click is recorded for a NativeAd.
          onAdClicked: (ad) {},
          // Called when an impression occurs on the ad.
          onAdImpression: (ad) {},
          // Called when an ad removes an overlay that covers the screen.
          onAdClosed: (ad) {},
          // Called when an ad opens an overlay that covers the screen.
          onAdOpened: (ad) {},
          // For iOS only. Called before dismissing a full screen view
          onAdWillDismissScreen: (ad) {},
          // Called when an ad receives revenue value.
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
        ),
        request: const AdRequest(),
        // Styling
        nativeTemplateStyle: NativeTemplateStyle(
            // Required: Choose a template.
            templateType: TemplateType.medium,
            // Optional: Customize the ad's style.
            mainBackgroundColor: Colors.purple,
            cornerRadius: 10.0,
            callToActionTextStyle: NativeTemplateTextStyle(
                textColor: Colors.cyan,
                backgroundColor: Colors.red,
                style: NativeTemplateFontStyle.monospace,
                size: 16.0),
            primaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.red,
                backgroundColor: Colors.cyan,
                style: NativeTemplateFontStyle.italic,
                size: 16.0),
            secondaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.green,
                backgroundColor: Colors.black,
                style: NativeTemplateFontStyle.bold,
                size: 16.0),
            tertiaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.brown,
                backgroundColor: Colors.amber,
                style: NativeTemplateFontStyle.normal,
                size: 16.0)))
      ..load();
  }

  @override
  Widget build(BuildContext context) {
    if (_nativeAdIsLoaded == false || _nativeAd == null) {
      loadAd();
      return const SizedBox.shrink();
    }

    final adContainer = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 320, // minimum recommended width
        minHeight: 90, // minimum recommended height
        maxWidth: 400,
        maxHeight: 200,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
    return adContainer;
  }
}
