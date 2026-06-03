import 'package:flutter/material.dart';

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
  final BoardActions _boardActions = BoardActions();

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
    // First-run coach: only on Level 1, the natural first puzzle.
    if (!state.tutorialSeen && !_showTutorial && widget.level.number == 1) {
      _showTutorial = true;
    }
  }

  void _replayTutorial() => setState(() => _showTutorial = true);

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

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // Eraser: arm the board so the next tapped arrow is removed even if blocked.
  // We only bill the 40 coins once it's actually spent on an arrow.
  static const _eraserCost = 40;
  static const _magicCost = 25;
  static const _undoCost = 20;

  Future<void> _useEraser() async {
    final state = AppScope.read(context);
    if (state.coins < _eraserCost) {
      _toast('Need $_eraserCost coins for the Eraser');
      return;
    }
    _boardActions.armEraser?.call();
    _feedback?.tick();
    _toast('Tap any arrow to erase it');
  }

  void _onEraserUsed() {
    AppScope.read(context).spendCoins(_eraserCost);
  }

  // Magic: instantly slide out one currently-movable arrow.
  Future<void> _useMagic() async {
    if (_game.hintArrowId() == null) {
      _toast('No movable arrow right now');
      return;
    }
    final state = AppScope.read(context);
    if (!await state.spendCoins(_magicCost)) {
      _toast('Need $_magicCost coins for Magic');
      return;
    }
    _boardActions.autoStep?.call();
    _feedback?.tick();
  }

  // Undo: restore the last removed arrow.
  Future<void> _useUndo() async {
    if (!_game.canUndo) {
      _toast('Nothing to undo');
      return;
    }
    final state = AppScope.read(context);
    if (!await state.spendCoins(_undoCost)) {
      _toast('Need $_undoCost coins to Undo');
      return;
    }
    _boardActions.undo?.call();
    _feedback?.tick();
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
    final coins = context.appState.coins;

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
              actions: _boardActions,
              onEraserUsed: _onEraserUsed,
            ),
          ),

          // Top controls overlay (back, title, settings, hearts, progress).
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
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
                          child: Center(
                            child: Text(
                              widget.level.difficulty == 'Daily'
                                  ? 'Daily'
                                  : 'LVL ${widget.level.number}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                        _CoinChip(coins: coins),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => showSettingsSheet(
                            context,
                            onRestart: _restart,
                            onHowToPlay: _replayTutorial,
                          ),
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

          // Bottom power-up bar — four grounded square cards.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _PowerButton(
                        icon: Icons.lightbulb_rounded,
                        colors: const [Color(0xFFFFC83D), Color(0xFFF4A100)],
                        count: hints > 0 ? hints : null,
                        coinCost: hints > 0 ? null : 30,
                        plus: true,
                        onTap: _useHint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PowerButton(
                        icon: Icons.cleaning_services_rounded,
                        colors: const [Color(0xFFFF7A7A), Color(0xFFEE4B4B)],
                        coinCost: _eraserCost,
                        onTap: _useEraser,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PowerButton(
                        icon: Icons.auto_awesome_rounded,
                        colors: const [Color(0xFF8E8EF6), Color(0xFF4E5DF2)],
                        coinCost: _magicCost,
                        onTap: _useMagic,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PowerButton(
                        icon: Icons.undo_rounded,
                        colors: const [Color(0xFF36C58E), Color(0xFF1E9E8A)],
                        coinCost: _undoCost,
                        enabled: _game.canUndo,
                        onTap: _useUndo,
                      ),
                    ),
                  ],
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

/// One colorful power-up tile for the bottom bar: a vibrant gradient card (so
/// it pops on every theme, light or dark), a white icon, a cost/count chip, and
/// an optional green "+" badge (Hint). Disabled tiles desaturate + dim.
class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.icon,
    required this.onTap,
    required this.colors,
    this.coinCost,
    this.count,
    this.plus = false,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final List<Color> colors;
  final int? coinCost;
  final int? count;
  final bool plus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final grad = enabled
        ? colors
        : const [Color(0xFF6B7280), Color(0xFF4B5563)]; // grey when disabled

    // Info chip: a count (free uses) takes priority, else the coin cost.
    Widget? chip;
    if (count != null) {
      chip = _chip(child: Text('x$count', style: _chipText));
    } else if (coinCost != null) {
      chip = _chip(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, size: 11, color: Color(0xFFFFD23F)),
            const SizedBox(width: 3),
            Text('$coinCost', style: _chipText),
          ],
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: grad.last.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: enabled ? onTap : null,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 26, color: Colors.white),
                        if (chip != null) ...[
                          const SizedBox(height: 5),
                          chip,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (plus && enabled)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2BB673),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.add, size: 13, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _chipText = TextStyle(
    fontSize: 12,
    height: 1,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  Widget _chip({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(9),
        ),
        child: child,
      );
}

/// Live coin balance pill for the header. Rebuilds (and so visibly ticks down)
/// whenever coins are spent, since the screen subscribes to app state.
class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 18, color: Color(0xFFF4B400)),
          const SizedBox(width: 5),
          Text(
            '$coins',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: palette.arrow,
            ),
          ),
        ],
      ),
    );
  }
}