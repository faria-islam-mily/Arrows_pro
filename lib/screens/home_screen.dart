import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../state/main_nav.dart';
import '../theme/game_colors.dart';
import '../widgets/daily_reward_sheet.dart';
import '../widgets/level_map.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/theme_picker.dart';
import '../widgets/top_hud.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkedDaily = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Offer the daily reward once per app open (if not already collected today).
    if (_checkedDaily) return;
    _checkedDaily = true;
    final state = AppScope.read(context);
    if (state.canClaimDaily) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showDailyRewardSheet(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.homeBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopHud(
              onCoins: openShop,
              onLives: openShop,
              onSettings: () => showSettingsSheet(
                context,
                onTheme: () => showThemePicker(context),
              ),
            ),
            const Expanded(child: HomeMap()),
          ],
        ),
      ),
    );
  }
}
