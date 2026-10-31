import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Premium IAP entitlement — ads off + premium-only features.
class EntitlementService {
  EntitlementService._();

  static const String _premiumActive = 'entitlement_premium_active';
  static const String _premiumExpiresMs = 'entitlement_premium_expires_ms';
  static const String _premiumProductId = 'entitlement_premium_product_id';

  static final ValueNotifier<bool> isPremium = ValueNotifier(false);

  static Box<dynamic> get _box => Hive.box('monetization');

  static DateTime? get premiumExpiresAt {
    final ms = _box.get(_premiumExpiresMs) as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  static String? get premiumProductId => _box.get(_premiumProductId) as String?;

  static Future<void> loadFromStorage() async {
    final active = _box.get(_premiumActive, defaultValue: false) as bool;
    final expires = premiumExpiresAt;
    final now = DateTime.now();

    if (!active) {
      isPremium.value = false;
      return;
    }

    if (expires != null && expires.isBefore(now)) {
      await _box.put(_premiumActive, false);
      await _box.delete(_premiumExpiresMs);
      isPremium.value = false;
      return;
    }

    isPremium.value = true;
  }

  /// Called from IAP layer when purchase restores / updates.
  static Future<void> setPremium({
    required bool active,
    DateTime? expiresAt,
    String? productId,
  }) async {
    await _box.put(_premiumActive, active);
    if (expiresAt != null) {
      await _box.put(
        _premiumExpiresMs,
        expiresAt.toUtc().millisecondsSinceEpoch,
      );
    } else if (!active) {
      await _box.delete(_premiumExpiresMs);
    }
    if (productId != null) {
      await _box.put(_premiumProductId, productId);
    }
    await loadFromStorage();
  }

  /// Non-subscription lifetime SKU — no expiry.
  static Future<void> setPremiumLifetime({String? productId}) async {
    await _box.put(_premiumActive, true);
    await _box.delete(_premiumExpiresMs);
    if (productId != null) await _box.put(_premiumProductId, productId);
    await loadFromStorage();
  }
}
