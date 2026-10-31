import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/monetization/ads_facade.dart';
import 'package:muzee/services/monetization/monetization_remote_config.dart';
import 'package:muzee/services/monetization/monetization_telemetry.dart';
import 'package:muzee/services/router_service.dart';

/// Cold start + resume App Open scheduling with timing guards from [MonetizationRemoteConfig].
class MonetizationLifecycleObserver extends WidgetsBindingObserver {
  DateTime? _pausedAt;
  DateTime? _lastAppOpenShownAt;
  bool _coldStartConsumed = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      unawaited(AdsFacade.instance.preloadAppOpenIfNeeded());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
  }

  Future<void> _onResumed() async {
    final now = DateTime.now();
    final minBg = MonetizationRemoteConfig.appOpenMinBackground;
    final minInterval = MonetizationRemoteConfig.appOpenMinInterval;

    final path =
        NavigationManager.router.routeInformationProvider.value.uri.path;

    final eligibleColdStart = !_coldStartConsumed;
    final eligibleBg = _pausedAt != null && now.difference(_pausedAt!) >= minBg;

    if (!eligibleColdStart && !eligibleBg) {
      MonetizationTelemetry.appOpenSkipped('timing');
      _pausedAt = null;
      return;
    }

    if (_lastAppOpenShownAt != null &&
        now.difference(_lastAppOpenShownAt!) < minInterval) {
      MonetizationTelemetry.appOpenSkipped('interval');
      _pausedAt = null;
      return;
    }

    if (!await AdPlacementGate.canShowAppOpen(matchedLocation: path)) {
      MonetizationTelemetry.appOpenSkipped('gate');
      _pausedAt = null;
      return;
    }

    await AdsFacade.instance.preloadAppOpenIfNeeded();
    final shown = await AdsFacade.instance.showAppOpenIfReady();
    if (shown) {
      _lastAppOpenShownAt = now;
      MonetizationTelemetry.appOpenShown();
      if (eligibleColdStart) _coldStartConsumed = true;
    } else {
      MonetizationTelemetry.appOpenSkipped('not_loaded');
    }

    _pausedAt = null;
  }
}
