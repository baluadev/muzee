import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:muzee/services/monetization/entitlement_service.dart';
import 'package:muzee/services/monetization/monetization_telemetry.dart';

/// Play Billing / StoreKit wrapper — MVP client-side entitlement.
class PremiumIapService {
  PremiumIapService._();
  static final PremiumIapService instance = PremiumIapService._();

  /// Muzee's one product: the one-time "remove ads" purchase sold since
  /// Muzee 1.x. Buying (or restoring) it unlocks Premium for good, so earlier
  /// buyers get Premium after updating.
  static const String lifetimeProductId = 'remove_ad';

  static const Set<String> productIds = {lifetimeProductId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> products = [];
  final ValueNotifier<bool> storeAvailable = ValueNotifier(false);

  Future<void> init() async {
    final available = await _iap.isAvailable();
    storeAvailable.value = available;
    if (!available) {
      developer.log('billing not available', name: 'PremiumIap');
      return;
    }

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e, StackTrace st) => developer.log(
        'purchaseStream error',
        error: e,
        stackTrace: st,
        name: 'PremiumIap',
      ),
    );

    await restorePurchases();
    await loadProducts();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> loadProducts() async {
    if (!storeAvailable.value) return;
    final response = await _iap.queryProductDetails(productIds);
    if (response.notFoundIDs.isNotEmpty) {
      developer.log(
        'missing products: ${response.notFoundIDs}',
        name: 'PremiumIap',
      );
    }
    products = response.productDetails;
  }

  Future<void> restorePurchases() async {
    if (!storeAvailable.value) return;
    await _iap.restorePurchases();
  }

  Future<bool> purchase(ProductDetails product) async {
    if (!storeAvailable.value) return false;
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (!productIds.contains(p.productID)) continue;

      if (p.status == PurchaseStatus.pending) continue;

      if (p.status == PurchaseStatus.error) {
        developer.log('Purchase error: ${p.error}', name: 'PremiumIap');
        continue;
      }

      if ((p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) &&
          p.productID == lifetimeProductId) {
        unawaited(
          EntitlementService.setPremiumLifetime(productId: p.productID),
        );
        MonetizationTelemetry.iapSuccess(p.productID);
      } else if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        DateTime? expiresAt;
        if (p.productID == 'premium_monthly') {
          expiresAt = DateTime.now().add(const Duration(days: 31));
        } else if (p.productID == 'premium_yearly') {
          expiresAt = DateTime.now().add(const Duration(days: 366));
        }

        unawaited(
          EntitlementService.setPremium(
            active: true,
            expiresAt: expiresAt,
            productId: p.productID,
          ),
        );
        MonetizationTelemetry.iapSuccess(p.productID);
      }

      if (p.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(p));
      }
    }
  }
}
