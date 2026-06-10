import 'package:flutter/material.dart';

import '../data/shop_catalog.dart';
import '../state/app_scope.dart';
import '../widgets/processing_overlay.dart';
import '../widgets/purchase_dialogs.dart';
import 'ads_service.dart';
import 'iap_service.dart';

// grantShopReward moved to iap_service.dart (deliveries must run from the
// store's purchase stream); re-exported here so existing imports keep working.
// ShopProductPrice gives every catalog product a `.displayPrice` getter.
export 'iap_service.dart' show grantShopReward, ShopProductPrice;

/// While true, coin-pack / bundle purchases are GRANTED locally (dev/testing)
/// after a fake processing delay, so the economy is fully testable before the
/// real store products exist. Flip to false once the products are created and
/// ACTIVE in Play Console / App Store Connect — purchases then go through the
/// real store via [IapService].
const bool kShopDevGrant = true;

/// Buy a coin pack or bundle. Shows the processing spinner, then a success /
/// failed dialog. (NO ADS uses [buyRemoveAds] directly — same machinery.)
Future<void> buyShopProduct(BuildContext context, ShopProduct p) async {
  if (kShopDevGrant) {
    final state = AppScope.read(context);
    showProcessing(context);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!context.mounted) return;
    hideProcessing(context);
    await grantShopReward(state, p);
    if (context.mounted) showPurchaseSuccess(context);
    return;
  }

  // Real store purchase. The actual delivery (coins / lives / powers) happens
  // inside IapService's purchase-stream handler when the store confirms; here
  // we only drive the spinner and the result dialog.
  showProcessing(context);
  final result = await IapService.instance.buy(p.id);
  if (!context.mounted) return;
  hideProcessing(context);

  switch (result) {
    case IapResult.success:
      showPurchaseSuccess(context);
    case IapResult.canceled:
      break; // user backed out of the store sheet — no dialog needed
    case IapResult.unavailable:
      showPurchaseFailed(context,
          message:
              'This item isn\'t available yet.\nPlease try again later.');
    case IapResult.failed:
      showPurchaseFailed(context);
  }
}

/// Show a real rewarded video; grant the coin bonus only if it was watched.
Future<void> watchAdForCoins(BuildContext context) async {
  final state = AppScope.read(context);
  final earned = await AdsService.showRewarded();
  if (!context.mounted) return;
  if (!earned) {
    _snack(context, 'Ad not ready yet — try again in a moment.');
    return;
  }
  await state.addCoins(kWatchAdCoins);
  if (!context.mounted) return;
  _snack(context, '+$kWatchAdCoins coins!');
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
