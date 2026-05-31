import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/levels.dart';
import '../game/game_controller.dart';
import '../models/level.dart';
import '../state/app_scope.dart';
import '../widgets/board_view.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _game;
  int _lives = 3;
  int? _hintId;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _game = GameController(widget.level)..addListener(_onChange);
  }

  void _onChange() {
    if (_game.isComplete && !_completed) {
      _completed = true;
      AppScope.read(context).completeLevel(widget.level.number);
      Future.delayed(const Duration(milliseconds: 350), _showWin);
    }
    setState(() {});
  }

  void _onBlocked() {
    HapticFeedback.heavyImpact();
    setState(() => _lives = (_lives - 1).clamp(0, 3));
    if (_lives == 0) _showFail();
  }

  void _useHint() => setState(() => _hintId = _game.hintArrowId());

  void _showWin() {
    if (!mounted) return;
    final next = widget.level.number;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        title: 'You Did It!',
        subtitle: 'Level ${widget.level.number} completed!',
        primaryLabel: next < kLevels.length ? 'Next Level' : 'Home',
        onPrimary: () {
          Navigator.of(context).pop();
          if (next < kLevels.length) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => GameScreen(level: kLevels[next])),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  void _showFail() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        title: 'Out of Lives',
        subtitle: 'Give it another go.',
        primaryLabel: 'Retry',
        onPrimary: () {
          Navigator.of(context).pop();
          setState(() {
            _game.reset();
            _lives = 3;
            _hintId = null;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _game.removeListener(_onChange);
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progress = _game.progress;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          // Full-screen, freely pannable board behind everything.
          Positioned.fill(
            child: BoardView(
              game: _game,
              hintId: _hintId,
              onBlocked: _onBlocked,
            ),
          ),

          // Top controls overlay (back, title, hearts, progress).
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                color: palette.background.withValues(alpha: 0.92),
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(Icons.arrow_back, color: palette.arrow),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Level ${widget.level.number}',
                                style: TextStyle(
                                  color: palette.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                widget.level.difficulty,
                                style: TextStyle(
                                  color: palette.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.favorite,
                              size: 22,
                              color: i < _lives
                                  ? palette.arrowActive
                                  : palette.arrowActive.withValues(alpha: 0.22),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor:
                                  palette.primary.withValues(alpha: 0.15),
                              color: palette.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${(progress * 100).round()}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Hint button overlay (bottom).
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.icon(
                  onPressed: _useHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Hint'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Dialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: palette.textMuted)),
            const SizedBox(height: 24),
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
          ],
        ),
      ),
    );
  }
}
