import 'package:flutter/material.dart';

import '../screens/support_screen.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../state/app_scope.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'language_dialog.dart';
import 'theme_picker.dart';
import 'ui_kit.dart';

const String _kVersion = 'v1.0.0';
const Color _panel = Color(0xFF3F5680); // slate-blue inner panel
const Color _ctl = Color(0xFF3E7BE8); // control blue
const Color _orange = Color(0xFFF2A33C);

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
  );
}

/// Home "Settings" dialog.
Future<void> showSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _SettingsScaffold(
      title: 'Settings',
      children: [
        const _ControlsBlock(),
        const SizedBox(height: 16),
        const _LanguageButton(),
        const SizedBox(height: 10),
        _PillButton(
          label: 'SUPPORT',
          icon: Icons.help_outline_rounded,
          onTap: () {
            final nav = Navigator.of(context);
            nav.pop(); // close settings, then open the help center
            nav.push(
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            );
          },
        ),
        const SizedBox(height: 14),
        _LinkButton(
          'RESTORE PURCHASE',
          onTap: () {
            IapService.instance.restore();
            _toast(context, 'Restoring your purchases…');
          },
        ),
        const SizedBox(height: 6),
        _LinkButton('PRIVACY POLICY',
            onTap: () => _toast(context, 'Privacy policy coming soon.')),
        const SizedBox(height: 10),
        const _Version(),
      ],
    ),
  );
}

/// In-game "Paused" dialog. [onRestart] / [onHome] fire after the pause dialog
/// closes (the game screen routes them through the quit confirmation).
Future<void> showPauseDialog(
  BuildContext context, {
  required VoidCallback onRestart,
  required VoidCallback onHome,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _SettingsScaffold(
      title: 'Paused',
      children: [
        const _ControlsBlock(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SquareButton(
                icon: Icons.refresh_rounded,
                color: _orange,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onRestart();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SquareButton(
                icon: Icons.home_rounded,
                color: _orange,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onHome();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PillButton(
          label: 'RESUME',
          onTap: () => Navigator.of(ctx).pop(),
        ),
        const SizedBox(height: 10),
        const _Version(),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Frame
// ---------------------------------------------------------------------------

/// Confirmation shown when leaving a level mid-play (restart / home): costs a
/// life. [confirmIcon] is the action glyph; [onConfirm] runs if they accept.
Future<void> showQuitConfirm(
  BuildContext context, {
  required String title,
  required IconData confirmIcon,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _SettingsScaffold(
      title: title,
      showClose: false,
      children: [
        const _LoseLifeArt(),
        const SizedBox(height: 10),
        const Text('YOU WILL LOSE A LIFE!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: _SquareButton(
                icon: confirmIcon,
                color: _orange,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onConfirm();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PillButton(
                label: 'RESUME',
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LoseLifeArt extends StatelessWidget {
  const _LoseLifeArt();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const HeartBrokenIcon(size: 78),
          Positioned(
            right: 70,
            top: 6,
            child: Text('-1',
                style: TextStyle(
                  color: GameColors.star,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 2)),
                  ],
                )),
          ),
        ],
      ),
    );
  }
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({
    required this.title,
    required this.children,
    this.showClose = true,
  });
  final String title;
  final List<Widget> children;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.85, end: 1.0),
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [GameColors.headerBlue, GameColors.headerBlueDark],
                          ),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black26, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),
                      // Body.
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          decoration: const BoxDecoration(
                            color: _panel,
                            borderRadius:
                                BorderRadius.all(Radius.circular(24)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showClose)
                    Positioned(
                      top: -10,
                      right: -8,
                      child: ChunkyCircleButton(
                        icon: Icons.close_rounded,
                        color: GameColors.red,
                        size: 40,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared controls (sound/music/vibration + notifications + theme)
// ---------------------------------------------------------------------------

class _ControlsBlock extends StatelessWidget {
  const _ControlsBlock();

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _IconToggle(
              icon: Icons.volume_up_rounded,
              on: state.soundOn,
              onTap: () => state.setSound(!state.soundOn),
            ),
            _IconToggle(
              icon: Icons.music_note_rounded,
              on: state.musicOn,
              onTap: () {
                final next = !state.musicOn;
                state.setMusic(next);
                AudioService.instance.setMusicEnabled(next);
              },
            ),
            _IconToggle(
              icon: Icons.vibration_rounded,
              on: state.vibrationOn,
              onTap: () => state.setVibration(!state.vibrationOn),
            ),
          ],
        ),
        const _Divider(),
        _ToggleRow(
          label: 'NOTIFICATIONS',
          value: state.notificationsOn,
          onChanged: state.setNotifications,
        ),
        const _Divider(),
        _ThemeRow(),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.white.withValues(alpha: 0.12),
      );
}

class _IconToggle extends StatelessWidget {
  const _IconToggle(
      {required this.icon, required this.on, required this.onTap});
  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: on ? _ctl : const Color(0xFF566A8E),
      depth: 5,
      radius: 16,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Icon(icon,
            color: on ? Colors.white : Colors.white38, size: 30),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17)),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 58,
            height: 32,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? _ctl : const Color(0xFF2B3A5C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final name = context.palette.name;
    return Row(
      children: [
        const Expanded(
          child: Text('THEME',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17)),
        ),
        ChunkyButton(
          color: _ctl,
          depth: 4,
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          onTap: () => showThemePicker(context),
          child: Text(name.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

/// The language row in Settings — shows the saved language and opens the
/// picker. Reads [context.appState] so it updates live after a new pick.
class _LanguageButton extends StatelessWidget {
  const _LanguageButton();
  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: context.appState.language.toUpperCase(),
      icon: Icons.translate_rounded,
      onTap: () => showLanguageDialog(context),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, this.icon, required this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ChunkyButton(
        color: GameColors.green,
        depth: 6,
        padding: const EdgeInsets.symmetric(vertical: 13),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: color,
      depth: 6,
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14),
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
        ),
      ),
    );
  }
}

class _Version extends StatelessWidget {
  const _Version();
  @override
  Widget build(BuildContext context) => Text(
        _kVersion,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      );
}
