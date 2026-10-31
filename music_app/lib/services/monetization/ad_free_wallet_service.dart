import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzee/services/monetization/monetization_remote_config.dart';

/// Earned “no ads” window from rewarded completions only — not Premium IAP.
class AdFreeWalletService {
  AdFreeWalletService._();

  static const String _adFreeUntilMs = 'wallet_ad_free_until_ms';
  static const String _lastRewardCompletedMs =
      'wallet_last_reward_completed_ms';

  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Box<dynamic> get _box => Hive.box('monetization');

  static DateTime? get adFreeUntil {
    final ms = _box.get(_adFreeUntilMs) as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  static bool get isAdFreeActive {
    final end = adFreeUntil;
    return end != null && DateTime.now().isBefore(end);
  }

  static DateTime? get lastRewardCompletedAt {
    final ms = _box.get(_lastRewardCompletedMs) as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  static Duration? timeUntilCooldownEnds() {
    final last = lastRewardCompletedAt;
    if (last == null) return null;
    final end = last.add(MonetizationRemoteConfig.rewardCooldown);
    final now = DateTime.now();
    if (!now.isBefore(end)) return null;
    return end.difference(now);
  }

  static bool get isRewardCooldownActive {
    final left = timeUntilCooldownEnds();
    return left != null && left > Duration.zero;
  }

  /// Extends ad-free window by [duration], capped from now by [MonetizationRemoteConfig.walletCap].
  static Future<void> grant(Duration duration) async {
    final now = DateTime.now();
    final cap = MonetizationRemoteConfig.walletCap;
    final maxEnd = now.add(cap);

    final currentEnd = adFreeUntil;
    final base = (currentEnd != null && currentEnd.isAfter(now))
        ? currentEnd
        : now;

    var nextEnd = base.add(duration);
    if (nextEnd.isAfter(maxEnd)) nextEnd = maxEnd;

    await _box.put(_adFreeUntilMs, nextEnd.toUtc().millisecondsSinceEpoch);
    revision.value++;
  }

  static Future<void> markRewardCompleted() async {
    await _box.put(
      _lastRewardCompletedMs,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
    revision.value++;
  }
}
