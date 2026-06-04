/// Paths to the 3D PNG art assets. Files live in `assets/images/` (declared in
/// pubspec). Until a file is added, widgets that use it fall back to a
/// Flutter-drawn placeholder via [AppImage]'s errorBuilder — so it's always
/// safe to reference a path before the art exists.
class AppImages {
  AppImages._();

  static const String _base = 'assets/images';

  // Core icons.
  static const String coin = '$_base/coin.png';
  static const String heart = '$_base/heart.png';
  static const String heartBroken = '$_base/heart_broken.png';
  static const String star = '$_base/star.png';
  static const String starEmpty = '$_base/star_empty.png';
  static const String starBroken = '$_base/star_broken.png';
  static const String powerMagic = '$_base/power_magic.png';
  static const String powerHint = '$_base/power_hint.png';
  static const String powerEraser = '$_base/power_eraser.png';
  static const String powerUndo = '$_base/power_undo.png';

  // Shop heroes.
  static const String pack1000 = '$_base/pack_1000.png';
  static const String pack5000 = '$_base/pack_5000.png';
  static const String pack10000 = '$_base/pack_10000.png';
  static const String pack25000 = '$_base/pack_25000.png';
  static const String pack50000 = '$_base/pack_50000.png';
  static const String pack100000 = '$_base/pack_100000.png';
  static const String bundleClassic = '$_base/bundle_classic.png';
  static const String bundleElite = '$_base/bundle_elite.png';
  static const String bundleEpic = '$_base/bundle_epic.png';
  static const String offerSpecial = '$_base/offer_special.png';

  // Characters & misc.
  static const String avatarPlayer = '$_base/avatar_player.png';
  static const String piggyBank = '$_base/piggy_bank.png';
  static const String gift = '$_base/gift.png';
  static const String noAds = '$_base/no_ads.png';
  static const String lockChains = '$_base/lock_chains.png';

  // World avatars (round mascots — optional).
  static const String worldSandyShore = '$_base/world_sandy_shore.png';
  static const String worldCrabCove = '$_base/world_crab_cove.png';
  static const String worldPoolParty = '$_base/world_pool_party.png';
  static const String worldNightCity = '$_base/world_night_city.png';
  static const String worldFrostpeak = '$_base/world_frostpeak.png';
  static const String worldDeepSpace = '$_base/world_deep_space.png';

  // World background scenes (full-screen, one per world band).
  static const String bgSandyShore = '$_base/bg_sandy_shore.jpg';
  static const String bgCrabCove = '$_base/bg_crab_cove.jpg';
  static const String bgPoolParty = '$_base/bg_pool_party.jpg';
  static const String bgNightCity = '$_base/bg_night_city.jpg';
  static const String bgFrostpeak = '$_base/bg_frostpeak.jpg';
  static const String bgDeepSpace = '$_base/bg_deep_space.jpg';
}
