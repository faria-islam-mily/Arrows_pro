/// One purchasable shop item and the reward it grants. Prices shown here are
/// fallback display labels; once the matching products are created in the
/// stores, the real localized price replaces them.
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.title,
    required this.priceLabel,
    this.coins = 0,
    this.infiniteHours = 0,
    this.hint = 0,
    this.eraser = 0,
    this.magic = 0,
    this.undo = 0,
  });

  /// Store product ID — must match Play Console / App Store Connect when wired.
  final String id;
  final String title;
  final String priceLabel;
  final int coins;
  final int infiniteHours; // hours of infinite lives granted
  final int hint;
  final int eraser;
  final int magic;
  final int undo;

  bool get hasPowers => hint > 0 || eraser > 0 || magic > 0 || undo > 0;
}

/// Pure coin packs (consumables).
const List<ShopProduct> kCoinPacks = [
  ShopProduct(id: 'coins_1000', title: '1000', priceLabel: 'BDT 290', coins: 1000),
  ShopProduct(id: 'coins_5000', title: '5000', priceLabel: 'BDT 1,100', coins: 5000),
  ShopProduct(id: 'coins_10000', title: '10000', priceLabel: 'BDT 2,100', coins: 10000),
  ShopProduct(id: 'coins_25000', title: '25000', priceLabel: 'BDT 4,200', coins: 25000),
  ShopProduct(id: 'coins_50000', title: '50000', priceLabel: 'BDT 7,700', coins: 50000),
  ShopProduct(id: 'coins_100000', title: '100000', priceLabel: 'BDT 14,000', coins: 100000),
];

/// The big timed "special offer" at the top of the shop.
const ShopProduct kSpecialOffer = ShopProduct(
  id: 'special_offer',
  title: 'SPECIAL OFFER',
  priceLabel: 'BDT 2,100',
  coins: 10000,
  infiniteHours: 5,
  hint: 2,
  eraser: 2,
  magic: 2,
  undo: 2,
);

/// Value bundles (coins + infinite lives + power-ups).
const List<ShopProduct> kBundles = [
  ShopProduct(
    id: 'classic_bundle',
    title: 'CLASSIC BUNDLE',
    priceLabel: 'BDT 1,400',
    coins: 6000,
    infiniteHours: 1,
    hint: 1,
    eraser: 1,
    magic: 1,
    undo: 1,
  ),
  ShopProduct(
    id: 'elite_bundle',
    title: 'ELITE BUNDLE',
    priceLabel: 'BDT 2,800',
    coins: 10000,
    infiniteHours: 5,
    hint: 3,
    eraser: 3,
    magic: 3,
    undo: 3,
  ),
  ShopProduct(
    id: 'epic_bundle',
    title: 'EPIC BUNDLE',
    priceLabel: 'BDT 4,200',
    coins: 16000,
    infiniteHours: 6,
    hint: 10,
    eraser: 10,
    magic: 10,
    undo: 10,
  ),
];

/// Reward for watching a rewarded video.
const int kWatchAdCoins = 50;

/// Our custom "safety net" upsell shown on the Level-Failed screen — a strong
/// 2x-value bundle: a big coin stack, 1h of infinite lives, and every power-up.
const ShopProduct kSafetyNetOffer = ShopProduct(
  id: 'safety_net',
  title: 'Rescue Pack',
  priceLabel: 'BDT 490',
  coins: 5000,
  infiniteHours: 1,
  magic: 2,
  hint: 2,
  eraser: 2,
);
