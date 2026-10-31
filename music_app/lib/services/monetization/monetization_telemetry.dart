import 'package:flutter/foundation.dart';

/// Minimal analytics hooks; extend with Firebase/Sentry later.
class MonetizationTelemetry {
  MonetizationTelemetry._();

  static void log(String event, [Map<String, Object?>? params]) {
    if (kDebugMode) {
      debugPrint('telemetry.$event ${params ?? {}}');
    }
  }

  static void rewardStarted() => log('reward_started');
  static void rewardCompleted() => log('reward_completed');
  static void walletGranted(int extraMinutes) =>
      log('wallet_granted', {'minutes': extraMinutes});

  static void appOpenShown() => log('app_open_shown');
  static void appOpenSkipped(String reason) =>
      log('app_open_skipped_reason', {'reason': reason});

  static void iapSuccess(String productId) =>
      log('iap_purchase_success', {'productId': productId});
}
