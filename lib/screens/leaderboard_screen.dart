import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../state/app_scope.dart';
import '../theme/game_colors.dart';

/// A simple stats / progress board. A real online leaderboard needs a backend
/// (Play Games / Game Center / a server); this shows the player's own progress
/// for now and is the natural place to slot a real leaderboard later.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final cleared = (state.unlockedLevel - 1).clamp(0, kLevelCount);
    const maxStars = kLevelCount * 3;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'Your Progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                _StatCard(
                  icon: Icons.star_rounded,
                  iconColor: GameColors.star,
                  label: 'Total Stars',
                  value: '${state.starTotal} / $maxStars',
                ),
                _StatCard(
                  icon: Icons.flag_rounded,
                  iconColor: GameColors.green,
                  label: 'Levels Cleared',
                  value: '$cleared / $kLevelCount',
                ),
                _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: GameColors.red,
                  label: 'Day Streak',
                  value: '${state.streak}',
                ),
                _StatCard(
                  icon: Icons.monetization_on_rounded,
                  iconColor: GameColors.coin,
                  label: 'Coins',
                  value: '${state.coins}',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color: GameColors.star, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Global leaderboards coming soon!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GameColors.inkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: GameColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: GameColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
