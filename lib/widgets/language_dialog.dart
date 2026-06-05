import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_scope.dart';
import '../theme/game_colors.dart';
import 'ui_kit.dart';

/// The languages the picker offers. (Selecting one saves the preference; full
/// string translation is a separate, future step.)
const List<String> kLanguages = [
  'English', 'French',
  'Spanish', 'Dutch',
  'German', 'Turkish',
  'Swedish', 'Italian',
  'Japanese', 'Korean',
  'Russian', 'Portuguese',
];

const Color _panel = Color(0xFF3F5680); // slate-blue inner panel
const Color _tileOff = Color(0xFF35496F); // unselected language tile
const Color _tileOn = Color(0xFF3E8BEC); // selected language tile

/// Present the Language selection dialog.
Future<void> showLanguageDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _LanguageDialog(),
  );
}

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog();

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  late String _selected = context.appState.language;

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
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            colors: [
                              GameColors.headerBlue,
                              GameColors.headerBlueDark
                            ],
                          ),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: Text(context.l10n.language,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2))
                                ])),
                      ),
                      // Body.
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: const BoxDecoration(
                            color: _panel,
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 360),
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final lang in kLanguages)
                                        _LangTile(
                                          label: lang,
                                          selected: _selected == lang,
                                          onTap: () =>
                                              setState(() => _selected = lang),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 220,
                                child: ChunkyButton(
                                  color: GameColors.green,
                                  depth: 7,
                                  radius: 18,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  onTap: () {
                                    context.appState.setLanguage(_selected);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(context.l10n.save,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                          shadows: [
                                            Shadow(
                                                color: Color(0x66000000),
                                                offset: Offset(0, 2))
                                          ])),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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

/// One language option. Selected tiles pop to a brighter blue and gently
/// scale up so the active choice is obvious and lively.
class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Two columns: (full width - inter-tile spacing) / 2.
    final w = (MediaQuery.of(context).size.width.clamp(0, 380) - 48 - 12) / 2;
    return AnimatedScale(
      scale: selected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: w.toDouble(),
        child: ChunkyButton(
          color: selected ? _tileOn : _tileOff,
          depth: 5,
          radius: 14,
          gradient: selected,
          shadowColor: selected ? null : const Color(0xFF223456),
          padding: const EdgeInsets.symmetric(vertical: 14),
          onTap: onTap,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              shadows: selected
                  ? const [Shadow(color: Color(0x66000000), offset: Offset(0, 1))]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
