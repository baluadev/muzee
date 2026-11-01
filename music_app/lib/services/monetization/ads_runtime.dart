import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Brings ads up without holding the app back: asks for consent where the
/// law requires it (EEA/UK, through Google's UMP form), then starts the
/// Mobile Ads SDK. Nothing may load an ad before [ready] turns true.
class AdsRuntime {
  AdsRuntime._();

  /// Consent gathered (or not needed) and the SDK started.
  static final ValueNotifier<bool> ready = ValueNotifier(false);

  /// When this run of the app started ([recordLaunch]); interstitials wait
  /// a while after it.
  static DateTime sessionStart = DateTime.now();

  static const _launchCountKey = 'ads_launch_count';

  /// How many times the app has been started, this run included.
  static int launchCount = 0;

  /// The first run after install: no App Open ad on it.
  static bool get isFirstLaunch => launchCount <= 1;

  static Completer<void>? _starting;

  /// Counts this launch. Call once at startup, before [start].
  static Future<void> recordLaunch() async {
    sessionStart = DateTime.now();
    final box = Hive.box('monetization');
    launchCount = (box.get(_launchCountKey, defaultValue: 0) as int) + 1;
    await box.put(_launchCountKey, launchCount);
  }

  /// Gathers consent, then starts the SDK. Safe to call more than once;
  /// later calls wait for the first.
  static Future<void> start() {
    final running = _starting;
    if (running != null) return running.future;
    final completer = _starting = Completer<void>();
    unawaited(_start().whenComplete(completer.complete));
    return completer.future;
  }

  static Future<void> _start() async {
    try {
      await _gatherConsent().timeout(const Duration(seconds: 15));
    } catch (e) {
      developer.log('Consent step failed: $e', name: 'AdsRuntime');
    }
    try {
      if (!await ConsentInformation.instance.canRequestAds()) {
        developer.log('No consent to request ads', name: 'AdsRuntime');
        return;
      }
      await MobileAds.instance.initialize();
      ready.value = true;
    } catch (e) {
      developer.log('Mobile Ads start failed: $e', name: 'AdsRuntime');
    }
  }

  static Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            developer.log('Consent form: ${error.message}', name: 'AdsRuntime');
          }
          if (!done.isCompleted) done.complete();
        });
      },
      (error) {
        developer.log('Consent update: ${error.message}', name: 'AdsRuntime');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }
}
