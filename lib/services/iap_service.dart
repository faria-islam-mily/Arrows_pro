import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/shop_catalog.dart';
import '../models/power_up.dart';
import '../state/app_state.dart';

/// Outcome of a purchase attempt, surfaced to the UI so it can show the right
/// dialog.
enum IapResult { success, failed, canceled, unavailable }

/// The price the UI should show for a product: the store's live, localized
/// price once loaded, otherwise the hardcoded catalog fallback. Lets every
/// shop tile / promo button say `product.displayPrice` and stay correct in
/// every country without touching the catalog.
extension ShopProductPrice on ShopProduct {
  String get displayPrice =>
      IapService.instance.priceFor(id) ?? priceLabel;
}

/// Grants everything a [ShopProduct] contains to the player's account.
/// Lives here (not in shop_service) because real deliveries must happen from
/// the store's purchase stream — including re-deliveries on a later launch if
/// the app died between "paid" and "granted".
Future<void> grantShopReward(AppState state, ShopProduct p) async {
  if (p.coins > 0) await state.addCoins(p.coins);
  if (p.infiniteHours > 0) {
    await state.grantInfiniteLives(Duration(hours: p.infiniteHours));
  }
  if (p.hint > 0) await state.addPower(PowerUp.hint, p.hint);
  if (p.eraser > 0) await state.addPower(PowerUp.eraser, p.eraser);
  if (p.magic > 0) await state.addPower(PowerUp.magic, p.magic);
  if (p.undo > 0) await state.addPower(PowerUp.undo, p.undo);
}

/// Wraps `in_app_purchase` for every store product: the non-consumable
/// "Remove Ads" plus all consumable coin packs / bundles / offers from
/// [shop_catalog].
///
/// Lifecycle:
///  * [init] is called once at startup. It checks store availability, starts
///    listening to the purchase stream, queries ALL products, and silently
///    re-applies any past Remove-Ads purchase the store reports (so reinstalls
///    restore for free).
///  * [buy] kicks off a purchase and resolves once the store reports a
///    terminal status for it. Delivery (granting coins / removing ads) happens
///    inside the stream handler — never in UI code — so purchases completed
///    while the app was killed are still delivered on the next launch.
///  * [restore] re-delivers past purchases through the stream (Remove Ads
///    only; consumed coin packs are gone by design).
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  /// Product ID — must match the non-consumable created in Google Play Console
  /// AND App Store Connect.
  static const String kRemoveAdsId = 'remove_ads';

  /// Every store product the app sells. IDs must match the products created in
  /// the store consoles exactly.
  static Set<String> get allProductIds => {
        kRemoveAdsId,
        for (final p in kCoinPacks) p.id,
        for (final p in kBundles) p.id,
        kSpecialOffer.id,
        kSafetyNetOffer.id,
      };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  AppState? _state;
  final Map<String, ProductDetails> _products = {};
  bool _available = false;
  Completer<IapResult>? _pending;
  String? _pendingId; // which product the in-flight completer belongs to

  /// The store is reachable and the core product loaded.
  bool get isAvailable => _available && _products.containsKey(kRemoveAdsId);

  /// True once the store has supplied details (incl. price) for [productId].
  bool hasProduct(String productId) => _products.containsKey(productId);

  /// Localised price string (e.g. "৳1,100.00") once the product is loaded,
  /// or null if the store hasn't supplied it (show the catalog fallback then).
  String? priceFor(String productId) => _products[productId]?.price;

  /// Back-compat: localised Remove-Ads price.
  String get removeAdsPrice => priceFor(kRemoveAdsId) ?? '';

  Future<void> init(AppState state) async {
    _state = state;
    _sub = _iap.purchaseStream.listen(
      _onPurchasesUpdated,
      onDone: () => _sub?.cancel(),
      onError: (_) {},
    );

    _available = await _iap.isAvailable();
    if (!_available) return;

    final response = await _iap.queryProductDetails(allProductIds);
    for (final d in response.productDetails) {
      _products[d.id] = d;
    }
  }

  /// Back-compat: buy the Remove Ads non-consumable.
  Future<IapResult> buyRemoveAds() => buy(kRemoveAdsId);

  /// Begin a purchase for any catalog product. Resolves when the store reports
  /// a terminal status (or immediately if the store/product isn't available).
  Future<IapResult> buy(String productId) async {
    final details = _products[productId];
    if (!_available || details == null) return IapResult.unavailable;
    // If a purchase is already in flight, reuse its future.
    if (_pending != null && !_pending!.isCompleted) return _pending!.future;

    final pending = Completer<IapResult>();
    _pending = pending;
    _pendingId = productId;
    final param = PurchaseParam(productDetails: details);
    try {
      if (productId == kRemoveAdsId) {
        await _iap.buyNonConsumable(purchaseParam: param);
      } else {
        // Consumable: autoConsume (the default) marks it consumed on
        // completePurchase, so coin packs can be bought again and again.
        await _iap.buyConsumable(purchaseParam: param);
      }
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

  /// The catalog entry for a store product id, or null if it isn't ours.
  ShopProduct? _catalogFor(String id) {
    for (final p in kCoinPacks) {
      if (p.id == id) return p;
    }
    for (final p in kBundles) {
      if (p.id == id) return p;
    }
    if (kSpecialOffer.id == id) return kSpecialOffer;
    if (kSafetyNetOffer.id == id) return kSafetyNetOffer;
    return null;
  }

  /// Apply what a confirmed purchase grants. Runs BEFORE completePurchase so
  /// that if the app dies mid-delivery, the store re-sends the purchase on the
  /// next launch and the player still gets their goods.
  Future<void> _deliver(PurchaseDetails p) async {
    final state = _state;
    if (state == null) return;
    if (p.productID == kRemoveAdsId) {
      await state.removeAds();
      return;
    }
    // Consumables are only granted on a fresh purchase. A "restored" event
    // must NOT re-grant old coin packs (Restore Purchase would print money).
    if (p.status == PurchaseStatus.restored) return;
    final product = _catalogFor(p.productID);
    if (product != null) await grantShopReward(state, product);
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          break; // keep showing "processing"
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver(p);
          // Must acknowledge/consume or Play refunds after ~3 days and keeps
          // re-sending the purchase.
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          if (p.productID == _pendingId) _complete(IapResult.success);
        case PurchaseStatus.error:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          if (p.productID == _pendingId) _complete(IapResult.failed);
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          if (p.productID == _pendingId) _complete(IapResult.canceled);
      }
    }
  }

  void _complete(IapResult result) {
    final pending = _pending;
    _pendingId = null;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  void dispose() => _sub?.cancel();
}
