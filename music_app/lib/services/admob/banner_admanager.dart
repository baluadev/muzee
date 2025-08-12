import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/configs/const.dart';

class BannerAdmanager extends StatefulWidget {
  final AdSize size;
  final bool isPadding;
  final String? collapsiblePos;
  final Duration reloadInterval; // 👈 Thêm reloadInterval

  const BannerAdmanager({
    super.key,
    this.size = AdSize.mediumRectangle,
    this.isPadding = true,
    this.collapsiblePos,
    this.reloadInterval = const Duration(minutes: 2),
  });

  @override
  State<BannerAdmanager> createState() => _BannerAdmanagerState();
}

class _BannerAdmanagerState extends State<BannerAdmanager>
    with AutomaticKeepAliveClientMixin {
  AdManagerBannerAd? _bannerAd;
  bool _isLoaded = false;
  int _retryCount = 0;
  final int _maxRetries = 3;
  String? collapsiblePos;

  @override
  void initState() {
    collapsiblePos = widget.collapsiblePos;
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    String bannerId = Const.adUnitIdBanner;

    if (kDebugMode) {
      bannerId = Const.testAdUnitIdBanner;
    }

    Map<String, String>? extras;
    if (collapsiblePos != null) {
      extras = {'collapsible': collapsiblePos!};
    }

    _bannerAd?.dispose();
    _bannerAd = AdManagerBannerAd(
      adUnitId: bannerId,
      request: AdManagerAdRequest(
        extras: extras,
      ),
      sizes: <AdSize>[widget.size],
      listener: AdManagerBannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('[BannerAd] Loaded successfully.');
          setState(() {
            _isLoaded = true;
            _retryCount = 0;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('[BannerAd] Failed to load: $error');
          ad.dispose();
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });

          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(const Duration(seconds: 5), _loadBannerAd);
          } else {
            debugPrint('Banner failed after $_retryCount retries.');
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_bannerAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.isPadding
          ? const EdgeInsets.symmetric(vertical: Const.padding)
          : EdgeInsets.zero,
      child: Center(
        child: SizedBox(
          width: _bannerAd!.sizes.first.width.toDouble(),
          height: _bannerAd!.sizes.first.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
