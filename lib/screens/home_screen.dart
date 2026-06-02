import 'package:flutter/material.dart';

import '../data/level_titles.dart';
import '../data/levels.dart';
import '../state/app_scope.dart';
import '../widgets/daily_reward_sheet.dart';
import '../widgets/theme_picker.dart';
import 'game_screen.dart';

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
    final state = context.appState; // rebuilds on coins/progress/theme change
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  _Chip(
                    icon: Icons.local_fire_department,
                    iconColor: palette.accent,
                    label: '${state.streak}',
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.monetization_on,
                    iconColor: const Color(0xFFF4B400),
                    label: '${state.coins}',
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.lightbulb,
                    iconColor: palette.accent,
                    label: '${state.hints}',
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Daily reward',
                    onPressed: () => showDailyRewardSheet(context),
                    icon: Icon(Icons.card_giftcard, color: palette.primary),
                  ),
                  IconButton(
                    tooltip: 'Theme',
                    onPressed: () => showThemePicker(context),
                    icon: Icon(Icons.palette_outlined, color: palette.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Icon(Icons.swap_calls, size: 56, color: palette.primary),
            const SizedBox(height: 10),
            const Text(
              'Arrow Pro',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Clear every arrow. Find your calm.',
              style: TextStyle(color: palette.textMuted),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: kLevels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final level = kLevels[i];
                  final unlocked = state.isUnlocked(level.number);
                  final stars = state.starsFor(level.number);
                  return Material(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      enabled: unlocked,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            unlocked ? palette.primary : palette.textMuted,
                        child: unlocked
                            ? Text(
                                '${level.number}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : const Icon(Icons.lock,
                                size: 18, color: Colors.white),
                      ),
                      title: Text(levelTitle(level.number)),
                      subtitle: Text('Level ${level.number} · ${level.difficulty}'),
                      trailing: unlocked
                          ? (stars > 0
                              ? _Stars(stars: stars)
                              : Icon(Icons.play_arrow, color: palette.primary))
                          : null,
                      onTap: unlocked
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(level: level),
                                ),
                              )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.iconColor, required this.label});

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star : Icons.star_border,
            size: 16,
            color: const Color(0xFFF4B400),
          ),
      ],
    );
  }
}
