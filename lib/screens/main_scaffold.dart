import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_scope.dart';
import '../state/main_nav.dart';
import '../theme/game_colors.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'shop_screen.dart';

/// The persistent shell: Shop / Home / Leaderboard with a bottom nav bar.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  @override
  void initState() {
    super.initState();
    kMainTab.addListener(_onTab);
  }

  @override
  void dispose() {
    kMainTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final index = kMainTab.value;
    return Scaffold(
      backgroundColor: GameColors.mapBackground,
      body: IndexedStack(
        index: index,
        children: const [
          ShopScreen(),
          HomeScreen(),
          LeaderboardScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: index,
        onTap: (i) => kMainTab.value = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GameColors.navBar,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.storefront_rounded,
                label: context.l10n.shop.toUpperCase(),
                active: index == 0,
                showDot: context.appState.canClaimDailyGift,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.home_rounded,
                label: context.l10n.home.toUpperCase(),
                active: index == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.leaderboard_rounded,
                label: context.l10n.ranks.toUpperCase(),
                active: index == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : const Color(0xFFAFC6E6);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active ? Colors.white.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 26),
                  if (showDot)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B3B),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: GameColors.navBar, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
