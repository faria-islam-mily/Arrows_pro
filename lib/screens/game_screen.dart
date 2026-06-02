import 'package:flutter/material.dart';

import '../data/level_titles.dart';
import '../data/levels.dart';
import '../game/game_controller.dart';
import '../models/level.dart';
import '../services/feedback_service.dart';
import '../state/app_scope.dart';
import '../widgets/board_view.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/level_thumbnail.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/tutorial_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _game;
  FeedbackService? _feedback;

  int _lives = 3;
  int? _hintId;
  bool _completed = false;
  bool _showConfetti = false;
  bool _showTutorial = false;
  int _lastRemaining = 0;
  int _coinsEarned = 0;

  @override
  void initState() {
    super.initState();
    _game = GameController(widget.level)..addListener(_onChange);
    _lastRemaining = _game.remaining;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read app state once dependencies are available.
    final state = AppScope.read(context);
    _feedback ??= FeedbackService(state);
    if (!state.tutorialSeen && !_showTutorial) {
      _showTutorial = true;
    }
  }

  void _onChange() {
    // A successful tap reduces the remaining count; play the success feel.
    if (_game.remaining < _lastRemaining) _feedback?.tapSuccess();
    _lastRemaining = _game.remaining;

    if (_game.isComplete && !_completed) {
      _completed = true;
      final state = AppScope.read(context);
      state.completeLevel(widget.level.number);
      // Daily levels aren't part of the 1..100 pack; only star-rate real ones.
      final inPack =
          widget.level.number >= 1 && widget.level.number <= kLevels.length;
      if (inPack) state.recordStars(widget.level.number, _lives);
      if (widget.level.difficulty == 'Daily') state.markDailyDone();

      // Coins: base + a bonus per heart still held (rewards clean solves).
      _coinsEarned = 10 + _lives * 5;
      state.addCoins(_coinsEarned);

      _feedback?.win();
      setState(() => _showConfetti = true);
      Future.delayed(const Duration(milliseconds: 700), _showWin);
    }
    setState(() {});
  }

  void _onBlocked() {
    _feedback?.blocked();
    setState(() => _lives = (_lives - 1).clamp(0, 3));
    if (_lives == 0) _showFail();
  }

  Future<void> _useHint() async {
    if (_game.hintArrowId() == null) return; // nothing to reveal
    final state = AppScope.read(context);
    // Spend a hint token; fall back to 30 coins.
    final ok = await state.useHint() || await state.spendCoins(30);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hints — collect a daily reward or earn coins.'),
        ),
      );
      return;
    }
    _feedback?.tick();
    setState(() => _hintId = _game.hintArrowId());
  }

  void _restart() {
    setState(() {
      _game.reset();
      _lives = 3;
      _hintId = null;
      _completed = false;
      _showConfetti = false;
      _lastRemaining = _game.remaining;
    });
  }

  void _dismissTutorial() {
    AppScope.read(context).markTutorialSeen();
    setState(() => _showTutorial = false);
  }

  void _showWin() {
    if (!mounted) return;
    final next = widget.level.number;
    final inPack = next >= 1 && next <= kLevels.length;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        title: _lives >= 3
            ? 'Splendid!'
            : _lives == 2
                ? 'Impressive!'
                : 'You Did It!',
        subtitle: 'Level ${widget.level.number} completed!',
        pictureLevel: widget.level,
        stars: _lives,
        coins: _coinsEarned,
        primaryLabel: (inPack && next < kLevels.length) ? 'Next Level' : 'Home',
        onPrimary: () {
          Navigator.of(context).pop();
          if (inPack && next < kLevels.length) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => GameScreen(level: kLevels[next])),
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
          _restart();
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
    final hints = context.appState.hints;

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

          // Top controls overlay (back, title, settings, hearts, progress).
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                color: palette.background.withValues(alpha: 0.92),
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
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
                                widget.level.name.isNotEmpty
                                    ? widget.level.name
                                    : levelTitle(widget.level.number,
                                        total: kLevels.length),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                'Level ${widget.level.number} · '
                                '${widget.level.difficulty}',
                                style: TextStyle(
                                  color: palette.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () =>
                              showSettingsSheet(context, onRestart: _restart),
                          icon: Icon(Icons.settings_outlined,
                              color: palette.arrow),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.favorite,
                                size: 22,
                                color: i < _lives
                                    ? const Color(0xFFE63946)
                                    : palette.textMuted.withValues(alpha: 0.3),
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
                  label: Text(hints > 0 ? 'Hint · $hints' : 'Hint · 30 coins'),
                ),
              ),
            ),
          ),

          // Win celebration.
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiOverlay(
                onComplete: () {
                  if (mounted) setState(() => _showConfetti = false);
                },
              ),
            ),

          // First-run coach overlay.
          if (_showTutorial) TutorialOverlay(onDismiss: _dismissTutorial),
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
    this.stars,
    this.coins = 0,
    this.pictureLevel,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final int? stars; // 1..3 to show a rating; null hides it
  final int coins; // coins earned this level; 0 hides the row
  final Level? pictureLevel; // show the cleared picture when set

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
            if (pictureLevel != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: LevelThumbnail(
                  arrows: pictureLevel!.arrows(),
                  rows: pictureLevel!.rows,
                  cols: pictureLevel!.cols,
                  color: palette.arrow,
                  size: 180,
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: palette.textMuted)),
            if (stars != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < stars! ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: const Color(0xFFE9C46A),
                    ),
                ],
              ),
            ],
            if (coins > 0) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFFF4B400), size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '+$coins',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            ),
          ],
        ),
      ),
    );
  }
}