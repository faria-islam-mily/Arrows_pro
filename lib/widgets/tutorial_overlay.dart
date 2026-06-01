import 'package:flutter/material.dart';

import '../state/app_scope.dart';

/// A one-time coach overlay that teaches the core rule. Show it on the first
/// play (gate on `AppState.tutorialSeen`); tapping "Got it" dismisses it and
/// marks the tutorial as seen.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_outlined, size: 48, color: palette.primary),
                const SizedBox(height: 14),
                Text(
                  'Tap an arrow',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: palette.arrow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'An arrow slides off the board only when its path to the edge '
                  'is clear. Clear them all in the right order to reveal the '
                  'picture. A blocked tap costs a heart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textMuted, height: 1.35),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onDismiss,
                    child: const Text('Got it'),
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