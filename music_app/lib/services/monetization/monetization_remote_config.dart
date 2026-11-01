import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

/// Local tuning persisted in Hive. Replace with true remote config when needed.
class MonetizationRemoteConfig {
  MonetizationRemoteConfig._();

  static const String _rewardMinutes = 'remote_reward_minutes';
  static const String _walletCapHours = 'remote_wallet_cap_hours';
  static const String _rewardCooldownSec = 'remote_reward_cooldown_sec';
  static const String _appOpenMinBackgroundMinutes =
      'remote_app_open_min_background_minutes';
  static const String _appOpenMinIntervalMinutes =
      'remote_app_open_min_interval_minutes';
  static const String _enableBanner = 'remote_enable_banner';
  static const String _enableNative = 'remote_enable_native';
  static const String _enableInterstitial = 'remote_enable_interstitial';
  static const String _interstitialGraceMinutes =
      'remote_interstitial_grace_minutes';
  static const String _interstitialMinIntervalMinutes =
      'remote_interstitial_min_interval_minutes';
  static const String _interstitialDailyCap = 'remote_interstitial_daily_cap';
  static const String _appOpenColdStartWaitSec =
      'remote_app_open_cold_start_wait_sec';

  static Box<dynamic> get _box => Hive.box('monetization');

  static int get rewardGrantMinutes =>
      _box.get(_rewardMinutes, defaultValue: 30) as int;

  static Duration get walletCap =>
      Duration(hours: _box.get(_walletCapHours, defaultValue: 6) as int);

  static Duration get rewardCooldown =>
      Duration(seconds: _box.get(_rewardCooldownSec, defaultValue: 60) as int);

  static Duration get appOpenMinBackground => Duration(
    minutes: _box.get(_appOpenMinBackgroundMinutes, defaultValue: 4) as int,
  );

  static Duration get appOpenMinInterval => Duration(
    minutes: _box.get(_appOpenMinIntervalMinutes, defaultValue: 10) as int,
  );

  static bool get enableBanner =>
      _box.get(_enableBanner, defaultValue: true) as bool;

  static bool get enableNative =>
      _box.get(_enableNative, defaultValue: true) as bool;

  static bool get enableInterstitial =>
      _box.get(_enableInterstitial, defaultValue: true) as bool;

  /// No interstitial this soon after the app starts.
  static Duration get interstitialGrace => Duration(
    minutes: _box.get(_interstitialGraceMinutes, defaultValue: 3) as int,
  );

  /// Least time between two interstitials.
  static Duration get interstitialMinInterval => Duration(
    minutes: _box.get(_interstitialMinIntervalMinutes, defaultValue: 5) as int,
  );

  /// Most interstitials a day.
  static int get interstitialDailyCap =>
      _box.get(_interstitialDailyCap, defaultValue: 6) as int;

  /// How long a cold start waits for the App Open ad before going on
  /// without it.
  static Duration get appOpenColdStartWait => Duration(
    seconds: _box.get(_appOpenColdStartWaitSec, defaultValue: 3) as int,
  );

  static Future<void> ensureDefaults() async {
    final b = Hive.box('monetization');
    void putDefault(String key, Object value) {
      if (!b.containsKey(key)) b.put(key, value);
    }

    putDefault(_rewardMinutes, 30);
    putDefault(_walletCapHours, 6);
    putDefault(_rewardCooldownSec, 60);
    putDefault(_appOpenMinBackgroundMinutes, 4);
    putDefault(_appOpenMinIntervalMinutes, 10);
    unawaited(b.put(_enableBanner, true));
    unawaited(b.put(_enableNative, true));
    putDefault(_interstitialGraceMinutes, 3);
    putDefault(_interstitialMinIntervalMinutes, 5);
    putDefault(_interstitialDailyCap, 6);
    putDefault(_appOpenColdStartWaitSec, 3);
    unawaited(b.put(_enableInterstitial, true));
  }
}
