import 'package:flutter/material.dart';

import '../state/app_scope.dart';
// ignore: unused_import
import '../state/app_state.dart';

/// Bottom sheet with Sound / Vibration / Music toggles, plus an optional
/// Restart action (pass [onRestart] from the game screen). Mirrors the look of
/// the theme picker.
Future<void> showSettingsSheet(BuildContext context, {VoidCallback? onRestart}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SettingsBody(onRestart: onRestart),
  );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({this.onRestart});

  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final state = context.appState; // rebuilds toggles live
    final palette = context.palette;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: palette.arrow,
              ),
            ),
            const SizedBox(height: 12),
            _Toggle(
              icon: Icons.volume_up_outlined,
              label: 'Sound',
              value: state.soundOn,
              onChanged: state.setSound,
            ),
            _Toggle(
              icon: Icons.vibration,
              label: 'Vibration',
              value: state.vibrationOn,
              onChanged: state.setVibration,
            ),
            _Toggle(
              icon: Icons.music_note_outlined,
              label: 'Music',
              value: state.musicOn,
              onChanged: state.setMusic,
            ),
            if (onRestart != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRestart!();
                  },
                  child: const Text('Restart'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: palette.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: palette.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}