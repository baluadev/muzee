import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ads_facade.dart';
import 'package:muzee/services/monetization/ads_runtime.dart';
import 'package:muzee/services/monetization/monetization_remote_config.dart';
import 'package:muzee/services/monetization/monetization_telemetry.dart';
import 'package:muzee/services/router_service.dart';

/// When the App Open ad may show:
///
/// - Cold start ([onColdStart]): not on the first launch after install, and
///   only if the ad is ready within a few seconds of the first frame; past
///   that the app goes on without it rather than interrupting later.
/// - Coming back from the background after at least
///   [MonetizationRemoteConfig.appOpenMinBackground], spaced by
///   [MonetizationRemoteConfig.appOpenMinInterval]. A trip out of the app
///   for another ad (or a short one for a dialog, a picker…) doesn't count.
class MonetizationLifecycleObserver extends WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _pausedForAd = false;
  DateTime? _lastShownAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _pausedForAd = AdsFacade.instance.isShowingFullScreen;
      unawaited(AdsFacade.instance.preloadAppOpenIfNeeded());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
  }

  /// Call once the first frame is up.
  Future<void> onColdStart() async {
    if (AdsRuntime.isFirstLaunch) {
      MonetizationTelemetry.appOpenSkipped('first_launch');
      return;
    }
    final deadline = DateTime.now().add(
      MonetizationRemoteConfig.appOpenColdStartWait,
    );
    await AdsRuntime.start();
    unawaited(AdsFacade.instance.preloadAppOpenIfNeeded());
    while (!AdsFacade.instance.hasAppOpenLoaded &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (!AdsFacade.instance.hasAppOpenLoaded) {
      MonetizationTelemetry.appOpenSkipped('cold_start_late');
      return;
    }
    await _tryShow();
  }

  Future<void> _onResumed() async {
    final pausedAt = _pausedAt;
    final forAd = _pausedForAd;
    _pausedAt = null;
    _pausedForAd = false;
    if (pausedAt == null || forAd) return;

    final now = DateTime.now();
    if (now.difference(pausedAt) <
        MonetizationRemoteConfig.appOpenMinBackground) {
      MonetizationTelemetry.appOpenSkipped('timing');
      return;
    }
    await _tryShow();
  }

  Future<void> _tryShow() async {
    final now = DateTime.now();
    final last = _lastShownAt;
    if (last != null &&
        now.difference(last) < MonetizationRemoteConfig.appOpenMinInterval) {
      MonetizationTelemetry.appOpenSkipped('interval');
      return;
    }
    final path =
        NavigationManager.router.routeInformationProvider.value.uri.path;
    if (!await AdPlacementGate.canShowAppOpen(matchedLocation: path)) {
      MonetizationTelemetry.appOpenSkipped('gate');
      return;
    }
    if (await AdsFacade.instance.showAppOpenIfReady()) {
      _lastShownAt = now;
      MonetizationTelemetry.appOpenShown();
    } else {
      MonetizationTelemetry.appOpenSkipped('not_loaded');
    }
  }
}
