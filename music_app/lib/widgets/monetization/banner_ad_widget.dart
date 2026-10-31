import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/services/monetization/ad_free_wallet_service.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ad_unit_ids.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, required this.placement});
  final AdBannerPlacement placement;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _canShow = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoadAd();
    AdFreeWalletService.revision.addListener(_onRevisionChanged);
  }

  @override
  void dispose() {
    AdFreeWalletService.revision.removeListener(_onRevisionChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  void _onRevisionChanged() {
    _checkAndLoadAd();
  }

  Future<void> _checkAndLoadAd() async {
    final canShow = await AdPlacementGate.canShowBanner(widget.placement);
    if (!mounted) return;

    if (canShow && !_isLoaded && _bannerAd == null) {
      setState(() {
        _canShow = true;
      });
      _loadAd();
    } else if (!canShow && _isLoaded) {
      setState(() {
        _canShow = false;
        _isLoaded = false;
      });
      unawaited(_bannerAd?.dispose());
      _bannerAd = null;
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          developer.log(
            'BannerAd loaded for ${widget.placement}',
            name: 'BannerAdWidget',
          );
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          developer.log(
            'BannerAd failed to load: $error',
            name: 'BannerAdWidget',
          );
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _isLoaded = false;
            _bannerAd = null;
          });
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canShow || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
