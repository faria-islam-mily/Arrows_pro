import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../state/app_state.dart';

/// Outcome of a purchase attempt, surfaced to the UI so it can show the right
/// dialog.
enum IapResult { success, failed, canceled, unavailable }

/// Wraps `in_app_purchase` for the single non-consumable "Remove Ads" product.
///
/// Lifecycle:
///  * [init] is called once at startup. It checks store availability, starts
///    listening to the purchase stream, queries the product, and silently
///    re-applies any past purchase the store reports (so reinstalls restore for
///    free).
///  * [buyRemoveAds] kicks off a purchase and resolves once the store reports a
///    terminal status for it.
///  * [restore] re-delivers past purchases through the stream.
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  /// Product ID — must match the non-consumable created in Google Play Console
  /// AND App Store Connect.
  static const String kRemoveAdsId = 'remove_ads';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  AppState? _state;
  ProductDetails? _removeAdsProduct;
  bool _available = false;
  Completer<IapResult>? _pending;

  bool get isAvailable => _available && _removeAdsProduct != null;

  /// Localised price string (e.g. "৳1,100.00") once the product is loaded.
  String get removeAdsPrice => _removeAdsProduct?.price ?? '';

  Future<void> init(AppState state) async {
    _state = state;
    _sub = _iap.purchaseStream.listen(
      _onPurchasesUpdated,
      onDone: () => _sub?.cancel(),
      onError: (_) {},
    );

    _available = await _iap.isAvailable();
    if (!_available) return;

    final response = await _iap.queryProductDetails({kRemoveAdsId});
    if (response.productDetails.isNotEmpty) {
      _removeAdsProduct = response.productDetails.first;
    }
  }

  /// Begin the Remove Ads purchase. Resolves when the store reports a terminal
  /// status (or immediately if the store/product isn't available).
  Future<IapResult> buyRemoveAds() async {
    if (!isAvailable) return IapResult.unavailable;
    // If a purchase is already in flight, reuse its future.
    if (_pending != null && !_pending!.isCompleted) return _pending!.future;

    final pending = Completer<IapResult>();
    _pending = pending;
    final param = PurchaseParam(productDetails: _removeAdsProduct!);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (_) {
      _complete(IapResult.failed);
    }
    return pending.future;
  }

  /// Re-deliver past purchases (Apple requires an explicit "Restore" action).
  Future<void> restore() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != kRemoveAdsId) {
        // Not ours — still must be acknowledged or the store keeps re-sending it.
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        continue;
      }
      switch (p.status) {
        case PurchaseStatus.pending:
          break; // keep showing "processing"
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _state?.removeAds();
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          _complete(IapResult.success);
        case PurchaseStatus.error:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          _complete(IapResult.failed);
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          _complete(IapResult.canceled);
      }
    }
  }

  void _complete(IapResult result) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  void dispose() => _sub?.cancel();
}
