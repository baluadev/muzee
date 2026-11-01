import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/services/monetization/ad_free_wallet_service.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ad_unit_ids.dart';
import 'package:muzee/services/monetization/ads_runtime.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';

/// Rebuilds [builder] whenever an ad could start or stop being allowed:
/// ads becoming ready, Premium, earned ad-free time.
class AdEligibilityBuilder extends StatelessWidget {
  const AdEligibilityBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      AdsRuntime.ready,
      EntitlementService.isPremium,
      AdFreeWalletService.revision,
    ]),
    builder: (context, _) => builder(context),
  );
}

/// A banner as wide as its slot (Google's adaptive size for that width),
/// centred, that takes no room until an ad has loaded and goes away for
/// Premium or earned ad-free time.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({
    super.key,
    required this.placement,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final AdBannerPlacement placement;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => AdEligibilityBuilder(
    builder: (context) => _GatedBanner(
      // A new key when eligibility may have changed, so the gate is asked
      // again.
      key: ValueKey(
        '${AdsRuntime.ready.value}'
        '${EntitlementService.isPremium.value}'
        '${AdFreeWalletService.isAdFreeActive}',
      ),
      placement: placement,
      padding: padding,
    ),
  );
}

class _GatedBanner extends StatefulWidget {
  const _GatedBanner({
    super.key,
    required this.placement,
    required this.padding,
  });

  final AdBannerPlacement placement;
  final EdgeInsets padding;

  @override
  State<_GatedBanner> createState() => _GatedBannerState();
}

class _GatedBannerState extends State<_GatedBanner> {
  BannerAd? _ad;
  AdSize? _size;
  int? _requestedWidth;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _load(int width) async {
    _requestedWidth = width;
    if (!await AdPlacementGate.canShowBanner(widget.placement) || !mounted) {
      return;
    }
    // A steady height (Google's adaptive banner for this width, never below
    // 50): inline adaptive banners can come back as thin as 32 dp, too
    // small to read or to tap on purpose.
    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ??
        AdSize.banner;
    if (!mounted) return;
    final ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          final banner = ad as BannerAd;
          final actual = await banner.getPlatformAdSize();
          // Gone, or loaded for a width the slot no longer has.
          if (!mounted || _requestedWidth != width) {
            await banner.dispose();
            return;
          }
          final previous = _ad;
          if (previous != null && previous != banner) {
            unawaited(previous.dispose());
          }
          setState(() {
            _ad = banner;
            _size = actual ?? size;
          });
        },
        onAdFailedToLoad: (ad, error) {
          developer.log(
            'Banner (${widget.placement.name}) failed: $error',
            name: 'BannerAdWidget',
          );
          ad.dispose();
        },
      ),
    );
    unawaited(ad.load());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - widget.padding.horizontal)
            .floor();
        if (width > 0 && _requestedWidth != width) {
          // First layout, or the slot changed width (the phone turned):
          // load a banner sized for it, after this frame.
          final old = _ad;
          _requestedWidth = width;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (old != null) {
              setState(() {
                _ad = null;
                _size = null;
              });
              unawaited(old.dispose());
            }
            unawaited(_load(width));
          });
        }
        final ad = _ad;
        final size = _size;
        if (ad == null || size == null) return const SizedBox.shrink();
        return Padding(
          padding: widget.padding,
          child: Center(
            child: SizedBox(
              width: size.width.toDouble(),
              height: size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
        );
      },
    );
  }
}
