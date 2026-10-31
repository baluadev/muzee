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
      _box.get(_enableNative, defaultValue: false) as bool;

  static bool get enableInterstitial =>
      _box.get(_enableInterstitial, defaultValue: true) as bool;

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
    putDefault(_enableNative, false);
    unawaited(b.put(_enableInterstitial, true));
  }
}
