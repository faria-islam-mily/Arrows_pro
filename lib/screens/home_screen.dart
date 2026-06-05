import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../state/main_nav.dart';
import '../theme/game_colors.dart';
import '../widgets/daily_reward_sheet.dart';
import '../widgets/level_map.dart';
import '../widgets/profile_dialogs.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/top_hud.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkedOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedOpen) return;
    _checkedOpen = true;
    final state = AppScope.read(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!state.profileDone) {
        // First run: pick a name, then an avatar.
        showUsernameDialog(context, onDone: () {
          if (!mounted) return;
          showProfileDialog(context,
              onDone: () => AppScope.read(context).markProfileDone());
        });
      } else if (state.canClaimDaily) {
        showDailyRewardSheet(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.homeBackground,
      body: Stack(
        // expand makes the map (non-positioned) fill the whole screen, so its
        // scene shows behind the header too (edge-to-edge premium look).
        fit: StackFit.expand,
        children: [
          const HomeMap(),
          // The HUD floats over the scene at the top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: TopHud(
                onCoins: openShop,
                onLives: openShop,
                onProfile: () => showProfileDialog(context),
                onSettings: () => showSettingsDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
