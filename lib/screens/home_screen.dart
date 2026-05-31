import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../state/app_scope.dart';
import '../widgets/theme_picker.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.appState; // rebuilds on theme/progress change
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  _StreakChip(streak: state.streak),
                  const Spacer(),
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
            const SizedBox(height: 12),
            const Text(
              'Arrow Pro',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Clear every arrow. Find your calm.',
              style: TextStyle(color: palette.textMuted),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: kLevels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final level = kLevels[i];
                  final unlocked = state.isUnlocked(level.number);
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
                      title: Text('Level ${level.number}'),
                      subtitle: Text(level.difficulty),
                      trailing: unlocked
                          ? Icon(Icons.play_arrow, color: palette.primary)
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

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: palette.accent, size: 20),
          const SizedBox(width: 6),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
