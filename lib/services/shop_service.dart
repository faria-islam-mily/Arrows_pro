import 'package:flutter/material.dart';

import '../data/shop_catalog.dart';
import '../models/power_up.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/processing_overlay.dart';
import '../widgets/purchase_dialogs.dart';
import 'ads_service.dart';

/// While true, coin-pack / bundle purchases are GRANTED locally (dev/testing)
/// after a fake processing delay, so the economy is fully testable before the
/// real store products exist. Flip to false (and wire IapService for these
/// product IDs, like remove_ads) to require real purchases.
const bool kShopDevGrant = true;

/// Grants everything a [ShopProduct] contains to the player's account.
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

/// Buy a coin pack or bundle. Shows the processing spinner, then a success /
/// failed dialog. (NO ADS uses [buyRemoveAds] directly — it's a real IAP.)
Future<void> buyShopProduct(BuildContext context, ShopProduct p) async {
  if (!kShopDevGrant) {
    // TODO: route through IapService.buyConsumable(p.id) and grant on confirm.
    showPurchaseFailed(context,
        message: 'This item isn\'t available yet.\nPlease try again later.');
    return;
  }
  final state = AppScope.read(context);
  showProcessing(context);
  await Future<void>.delayed(const Duration(milliseconds: 1400));
  if (!context.mounted) return;
  hideProcessing(context);
  await grantShopReward(state, p);
  if (context.mounted) showPurchaseSuccess(context);
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
