import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:muzee/services/database/local_store.dart';

class InAppService {
  static final InAppService inst = InAppService._internal();
  factory InAppService() => inst;
  InAppService._internal();

  // ID sản phẩm trong App Store / Google Play
  static const String removeAdsId = 'remove_ad';

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _isAvailable = false;
  bool _isAdsRemoved = false;
  bool get isAdsRemoved => _isAdsRemoved;

  ProductDetails? _removeAdsProduct;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;

  Future<void> init() async {
    _isAdsRemoved = LocalStore.inst.adsRemoved;
    _isAvailable = await _iap.isAvailable();

    if (_isAvailable) {
      _subscription =
          _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () {
        _subscription.cancel();
      }, onError: (e) {
        debugPrint('Purchase error: $e');
      });

      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({removeAdsId});
    if (response.error != null) {
      debugPrint('Error loading product: ${response.error}');
    } else {
      _removeAdsProduct = response.productDetails.firstWhere(
        (p) => p.id == removeAdsId,
        orElse: () => throw Exception('Product not found'),
      );
    }
  }

  Future<void> buyRemoveAds() async {
    if (_removeAdsProduct == null) return;
    final purchaseParam = PurchaseParam(productDetails: _removeAdsProduct!);
    
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.productID == removeAdsId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          final isValid = await _verifyPurchase(purchase);
          if (isValid) {
            await _saveRemoveAdsStatus(true);
            _iap.completePurchase(purchase);
          }
        } else if (purchase.status == PurchaseStatus.error) {
          debugPrint('Purchase failed: ${purchase.error}');
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    return true; // Giả định hợp lệ
  }

  Future<void> _saveRemoveAdsStatus(bool value) async {
    _isAdsRemoved = value;
    await LocalStore.inst.setAdsRemoved(value);
  }

  void dispose() {
    _subscription.cancel();
  }
}
