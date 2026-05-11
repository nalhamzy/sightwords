import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_constants.dart';

typedef PurchaseDeliveryCallback = void Function(PurchaseDetails details);

/// Wraps in_app_purchase for Sight Words Flash Cards.
/// No RevenueCat — see SPEC §3.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  PurchaseDeliveryCallback? onPurchaseDelivered;
  List<ProductDetails> _products = [];

  List<ProductDetails> get products => List.unmodifiable(_products);

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object e) {
        debugPrint('IapService: purchaseStream error: $e');
      },
    );

    await queryProducts();
    // Silently restore on launch to refresh cached entitlements.
    await restorePurchases();
  }

  Future<List<ProductDetails>> queryProducts() async {
    final response = await _iap.queryProductDetails(SightWordsProductIds.all);
    if (response.error != null) {
      debugPrint('IapService: queryProducts error: ${response.error}');
    }
    _products = response.productDetails;
    return _products;
  }

  Future<void> buyNonConsumable(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> buySubscription(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: false);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> updates) {
    for (final details in updates) {
      if (details.status == PurchaseStatus.purchased ||
          details.status == PurchaseStatus.restored) {
        _deliverPurchase(details);
      } else if (details.status == PurchaseStatus.error) {
        debugPrint(
          'IapService: purchase error for ${details.productID}: '
          '${details.error?.message}',
        );
      }
      if (details.pendingCompletePurchase) {
        _iap.completePurchase(details);
      }
    }
  }

  Future<void> _deliverPurchase(PurchaseDetails details) async {
    final prefs = await SharedPreferences.getInstance();
    if (details.productID == SightWordsProductIds.fullUnlock) {
      await prefs.setBool(SightWordsPrefsKeys.iapFullUnlock, true);
    } else if (details.productID == SightWordsProductIds.familyAnnual) {
      await prefs.setBool(SightWordsPrefsKeys.iapFamilyActive, true);
    }
    onPurchaseDelivered?.call(details);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
