import 'package:flutter/foundation.dart';

/// Globally selected bottom-nav tab: 0 = Shop, 1 = Home, 2 = Leaderboard.
/// Anything in the tree can switch tabs by setting this — e.g. a coin "+" badge
/// or a map side-rail button opening the Shop.
final ValueNotifier<int> kMainTab = ValueNotifier<int>(1);

/// Convenience: jump to the Shop tab.
void openShop() => kMainTab.value = 0;
