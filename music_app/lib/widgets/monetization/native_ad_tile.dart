import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/services/monetization/ad_free_wallet_service.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ad_unit_ids.dart';
import 'package:muzee/services/monetization/ads_runtime.dart';
import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/widgets/monetization/banner_ad_widget.dart';

/// Where one ad sits in a list: after the first [after] items, and only in
/// lists longer than that (a short list gets no ad).
class InlineAdSlot {
  const InlineAdSlot(this.after);

  final int after;

  bool _has(int items) => items > after;

  /// Rows to build for [items] items.
  int count(int items) => _has(items) ? items + 1 : items;

  /// Whether row [index] is the ad.
  bool isAd(int index, int items) => _has(items) && index == after;

  /// The item that row [index] shows (not the ad row).
  int item(int index, int items) =>
      _has(items) && index > after ? index - 1 : index;
}

/// A native ad in Google's small template, coloured like the app's list
/// rows. Takes no room until an ad has loaded; gone for Premium or earned
/// ad-free time.
class NativeAdTile extends StatelessWidget {
  const NativeAdTile({
    super.key,
    required this.placement,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final AdNativePlacement placement;
  final EdgeInsets padding;

  /// The small template needs about this much height.
  static const height = 92.0;

  @override
  Widget build(BuildContext context) => AdEligibilityBuilder(
    builder: (context) => _GatedNative(
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

class _GatedNative extends StatefulWidget {
  const _GatedNative({
    super.key,
    required this.placement,
    required this.padding,
  });

  final AdNativePlacement placement;
  final EdgeInsets padding;

  @override
  State<_GatedNative> createState() => _GatedNativeState();
}

class _GatedNativeState extends State<_GatedNative> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _load(NeoColors neo) async {
    _requested = true;
    if (!await AdPlacementGate.canShowNative(widget.placement) || !mounted) {
      return;
    }
    NativeTemplateTextStyle text(Color color, {Color? background}) =>
        NativeTemplateTextStyle(
          textColor: color,
          backgroundColor: background,
          style: NativeTemplateFontStyle.normal,
        );
    final ad = NativeAd(
      adUnitId: AdUnitIds.nativeAd,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: neo.surface,
        cornerRadius: 12,
        primaryTextStyle: text(neo.onSurface),
        secondaryTextStyle: text(neo.onSurfaceMuted),
        tertiaryTextStyle: text(neo.onSurfaceMuted),
        callToActionTextStyle: text(neo.onAccent, background: neo.accent),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          developer.log(
            'Native (${widget.placement.name}) failed: $error',
            name: 'NativeAdTile',
          );
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    setState(() => _ad = ad);
    unawaited(ad.load());
  }

  @override
  Widget build(BuildContext context) {
    if (!_requested) unawaited(_load(context.neo));
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: NativeAdTile.height,
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
