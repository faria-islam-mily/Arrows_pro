import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../state/app_scope.dart';
import 'purchase_dialogs.dart';

/// Bottom sheet with Sound / Vibration / Music toggles, plus an optional
/// Restart action (pass [onRestart] from the game screen). Mirrors the look of
/// the theme picker.
Future<void> showSettingsSheet(BuildContext context,
    {VoidCallback? onRestart, VoidCallback? onHowToPlay, VoidCallback? onTheme}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SettingsBody(
      onRestart: onRestart,
      onHowToPlay: onHowToPlay,
      onTheme: onTheme,
    ),
  );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({this.onRestart, this.onHowToPlay, this.onTheme});

  final VoidCallback? onRestart;
  final VoidCallback? onHowToPlay;
  final VoidCallback? onTheme;

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
              onChanged: (v) {
                state.setMusic(v);
                AudioService.instance.setMusicEnabled(v);
              },
            ),
            if (onTheme != null) ...[
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.palette_outlined,
                label: 'Theme',
                onTap: () {
                  Navigator.of(context).pop();
                  onTheme!();
                },
              ),
            ],
            if (!state.adsRemoved) ...[
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.block_rounded,
                label: 'Remove ads',
                // Don't pop first — buyRemoveAds awaits and checks
                // context.mounted; the processing/result dialogs render above
                // the sheet via the root navigator, and this tile auto-hides
                // once removeAds() notifies.
                onTap: () => buyRemoveAds(context),
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.restore_rounded,
                label: 'Restore purchases',
                onTap: () {
                  IapService.instance.restore();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restoring your purchases…'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
            if (onHowToPlay != null) ...[
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.touch_app_outlined,
                label: 'How to play',
                onTap: () {
                  Navigator.of(context).pop();
                  onHowToPlay!();
                },
              ),
            ],
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: palette.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: palette.textMuted),
            ],
          ),
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