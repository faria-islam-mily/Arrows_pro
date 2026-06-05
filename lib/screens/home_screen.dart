import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_scope.dart';
import '../state/main_nav.dart';
import '../theme/game_colors.dart';
import '../widgets/daily_reward_sheet.dart';
import '../widgets/level_map.dart';
import '../widgets/profile_dialogs.dart';
import '../widgets/promo_dialogs.dart';
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
                onLives: () => showLivesDialog(context),
                onProfile: () => showProfileDialog(context),
                onSettings: () => showSettingsDialog(context),
              ),
            ),
          ),
          // Attention-grabbing "FREE GIFT!" notification — points at the Shop
          // tab. Only shown while the daily gift is ready to claim.
          if (context.appState.canClaimDailyGift)
            const Positioned(
              left: 12,
              bottom: 10,
              child: SafeArea(
                top: false,
                child: _FreeGiftBubble(onTap: openShop),
              ),
            ),
        ],
      ),
    );
  }
}

/// A bouncing "FREE GIFT!" speech bubble that nudges the player toward the
/// Shop to claim their daily free coins.
class _FreeGiftBubble extends StatefulWidget {
  const _FreeGiftBubble({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_FreeGiftBubble> createState() => _FreeGiftBubbleState();
}

class _FreeGiftBubbleState extends State<_FreeGiftBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.translate(
            offset: Offset(0, -4 * t),
            child: Transform.rotate(
              angle: (t - 0.5) * 0.10, // gentle wobble
              child: Transform.scale(scale: 1 + 0.05 * t, child: child),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.freeGift,
                    style: const TextStyle(
                      color: GameColors.blue,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 18),
              child: CustomPaint(size: Size(18, 9), painter: _TailPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

/// The little downward tail that turns the pill into a speech bubble.
class _TailPainter extends CustomPainter {
  const _TailPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.25, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) => false;
}
