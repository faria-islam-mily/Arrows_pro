import 'package:flutter/material.dart';

import '../data/daily_rewards.dart';
import '../services/audio_service.dart';
import '../state/app_scope.dart';

/// Shows the 7-day daily-streak reward grid. The player collects today's
/// reward; collected days are checked, today's is highlighted.
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

class _DailyRewardBodyState extends State<_DailyRewardBody> {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = context.palette;
    final claimable = state.canClaimDaily;
    final offered = state.offeredRewardDay;
    final collectedUpTo = claimable ? offered - 1 : offered;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: palette.accent, size: 40),
            const SizedBox(height: 6),
            Text(
              'Daily Reward',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: palette.arrow,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              claimable
                  ? 'Day $offered — collect your reward!'
                  : 'Come back tomorrow for Day '
                      '${offered >= 7 ? 1 : offered + 1}',
              style: TextStyle(color: palette.textMuted),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (var day = 1; day <= 7; day++)
                  _RewardCell(
                    reward: rewardForDay(day),
                    collected: day <= collectedUpTo,
                    isToday: claimable && day == offered,
                    big: day == 7,
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: claimable
                    ? () async {
                        final reward = await state.claimDailyReward();
                        if (reward != null) AudioService.instance.sfx('win');
                        if (context.mounted) setState(() {});
                      }
                    : () => Navigator.of(context).pop(),
                child: Text(claimable ? 'Collect' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCell extends StatelessWidget {
  const _RewardCell({
    required this.reward,
    required this.collected,
    required this.isToday,
    required this.big,
  });

  final DailyReward reward;
  final bool collected;
  final bool isToday;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final w = big ? 156.0 : 70.0;
    final accent = isToday ? palette.primary : palette.textMuted;

    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isToday
            ? palette.primary.withValues(alpha: 0.12)
            : palette.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? palette.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Day ${reward.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            reward.isCoins ? Icons.monetization_on : Icons.lightbulb,
            color: collected
                ? palette.textMuted.withValues(alpha: 0.5)
                : (reward.isCoins
                    ? const Color(0xFFF4B400)
                    : palette.accent),
            size: big ? 36 : 26,
          ),
          const SizedBox(height: 4),
          Text(
            collected ? '✓' : reward.label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: collected ? palette.textMuted : palette.arrow,
            ),
          ),
        ],
      ),
    );
  }
}
