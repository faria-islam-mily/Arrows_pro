import 'package:flutter/material.dart';

import '../data/daily_rewards.dart';
import '../l10n/strings.dart';
import '../services/audio_service.dart';
import '../state/app_scope.dart';

/// Icon for each reward kind (coins + the four power-ups).
IconData _rewardIcon(DailyReward r) => switch (r.kind) {
      RewardKind.coins => Icons.monetization_on,
      RewardKind.hint => Icons.lightbulb_rounded,
      RewardKind.eraser => Icons.cleaning_services_rounded,
      RewardKind.magic => Icons.auto_awesome_rounded,
      RewardKind.undo => Icons.undo_rounded,
    };

Color _rewardColor(DailyReward r) => switch (r.kind) {
      RewardKind.coins => const Color(0xFFF4B400),
      RewardKind.hint => const Color(0xFFFFC83D),
      RewardKind.eraser => const Color(0xFFEE4B4B),
      RewardKind.magic => const Color(0xFF6E7BF2),
      RewardKind.undo => const Color(0xFF27A35A),
    };

/// Shows the 7-day daily-streak reward grid. Today's reward pulses; collecting
/// it plays a little bounce + reward burst. Collected days are checked, future
/// days dimmed, and Day 7 is a golden chest.
Future<void> showDailyRewardSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _DailyRewardBody(),
  );
}

class _DailyRewardBody extends StatefulWidget {
  const _DailyRewardBody();

  @override
  State<_DailyRewardBody> createState() => _DailyRewardBodyState();
}

class _DailyRewardBodyState extends State<_DailyRewardBody>
    with TickerProviderStateMixin {
  late final AnimationController _pulse; // glow on today's cell
  late final AnimationController _pop; // one-shot claim burst
  DailyReward? _justClaimed;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pop.dispose();
    super.dispose();
  }

  Future<void> _collect(dynamic state) async {
    final reward = await state.claimDailyReward();
    if (reward == null) return;
    AudioService.instance.sfx('win');
    setState(() => _justClaimed = reward);
    _pulse.stop();
    _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;
    final claimable = state.canClaimDaily;
    final offered = state.offeredRewardDay;
    final collectedUpTo = claimable ? offered - 1 : offered;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing gradient flame badge — always the warm "fire" gold→orange
            // (matches the Arcade theme) regardless of the active palette.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC83D), Color(0xFFF4A100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF4A100).withValues(alpha: 0.5),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.local_fire_department,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.dailyReward,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: palette.arrow,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              claimable
                  ? '${context.l10n.weekLabel(state.rewardCycle % rewardWeekCount + 1)} · '
                      '${context.l10n.dayTapCollect(offered)}'
                  : context.l10n
                      .comeBackForDay(offered >= 7 ? 1 : offered + 1),
              style: TextStyle(color: palette.textMuted),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      _cell(
                        palette: palette,
                        reward: rewardForDay(day, state.rewardCycle),
                        collected: day <= collectedUpTo,
                        isToday: claimable && day == offered,
                        big: day == 7,
                      ),
                  ],
                ),
                if (_justClaimed != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _RewardBurst(reward: _justClaimed!, anim: _pop),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: claimable
                  ? _GradientButton(
                      label: context.l10n.collect,
                      icon: Icons.card_giftcard,
                      colors: [palette.primary, palette.accent],
                      onTap: () => _collect(state),
                    )
                  : FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.continueWord),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({
    required dynamic palette,
    required DailyReward reward,
    required bool collected,
    required bool isToday,
    required bool big,
  }) {
    final cell = _RewardCell(
      reward: reward,
      collected: collected,
      isToday: isToday,
      big: big,
      palette: palette,
    );
    if (!isToday) return cell;
    // Pulsing glow + gentle breathing scale on the claimable day.
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final g = _pulse.value;
        return Transform.scale(
          scale: 1 + 0.04 * g,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.25 + 0.45 * g),
                  blurRadius: 8 + 14 * g,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: cell,
    );
  }
}

class _RewardCell extends StatelessWidget {
  const _RewardCell({
    required this.reward,
    required this.collected,
    required this.isToday,
    required this.big,
    required this.palette,
  });

  final DailyReward reward;
  final bool collected;
  final bool isToday;
  final bool big;
  final dynamic palette;

  @override
  Widget build(BuildContext context) {
    final w = big ? 156.0 : 70.0;
    final isChest = big && !collected;

    // Background per state.
    final BoxDecoration deco;
    if (isChest) {
      deco = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD23F), Color(0xFFF2A000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A100).withValues(alpha: 0.4),
            blurRadius: 12,
          ),
        ],
      );
    } else if (isToday) {
      deco = BoxDecoration(
        color: palette.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.primary, width: 2),
      );
    } else {
      deco = BoxDecoration(
        color: palette.background.withValues(alpha: collected ? 0.45 : 0.7),
        borderRadius: BorderRadius.circular(16),
      );
    }

    final labelColor = isChest ? Colors.white : palette.arrow;
    final dayColor = isChest
        ? Colors.white.withValues(alpha: 0.9)
        : (isToday ? palette.primary : palette.textMuted);

    return Opacity(
      opacity: collected ? 0.55 : 1,
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: deco,
        child: Column(
          children: [
            Text(
              context.l10n.dayLabel(reward.day),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: dayColor,
              ),
            ),
            const SizedBox(height: 6),
            if (collected)
              Container(
                width: big ? 38 : 28,
                height: big ? 38 : 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF2BB673),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              )
            else
              Icon(
                _rewardIcon(reward),
                color: isChest ? Colors.white : _rewardColor(reward),
                size: big ? 38 : 26,
              ),
            const SizedBox(height: 4),
            Text(
              collected ? context.l10n.claimed : reward.label,
              style: TextStyle(
                fontSize: big ? 15 : 13,
                fontWeight: FontWeight.w800,
                color: collected ? palette.textMuted : labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "+reward" burst that pops over the grid right after collecting.
class _RewardBurst extends StatelessWidget {
  const _RewardBurst({required this.reward, required this.anim});

  final DailyReward reward;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final t = anim.value;
        if (t == 0) return const SizedBox.shrink();
        // Scale: small → overshoot → settle; rise + fade near the end.
        final scale = t < 0.5
            ? Curves.easeOutBack.transform(t / 0.5)
            : 1.0;
        final rise = Curves.easeOut.transform(t) * 26;
        final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
        return Center(
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, -rise),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2230),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 20),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_rewardIcon(reward),
                          color: _rewardColor(reward), size: 30),
                      const SizedBox(width: 8),
                      Text(
                        '+${reward.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A gradient pill button with an icon.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
