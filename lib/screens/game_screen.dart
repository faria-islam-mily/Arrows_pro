import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../game/game_controller.dart';
import '../models/level.dart';
import '../models/power_up.dart';
import '../services/feedback_service.dart';
import '../state/app_scope.dart';
import '../widgets/board_view.dart';
import '../widgets/booster_sheet.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/power_intro_overlay.dart';
import '../widgets/level_thumbnail.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/theme_picker.dart';
import '../widgets/tutorial_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameController _game;
  FeedbackService? _feedback;
  final BoardActions _boardActions = BoardActions();
  late final AnimationController _shake; // wrong-tap screen shake

  int _lives = 3;
  int? _hintId;
  bool _completed = false;
  bool _showConfetti = false;
  bool _showTutorial = false;
  PowerUp? _introPower; // power being introduced on this level (intro overlay)
  int _lastRemaining = 0;
  int _coinsEarned = 0;

  @override
  void initState() {
    super.initState();
    _game = GameController(widget.level)..addListener(_onChange);
    _lastRemaining = _game.remaining;
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  /// Horizontal shake offset (damped oscillation) for the current frame.
  double get _shakeDx {
    final t = _shake.value;
    if (t == 0) return 0;
    return math.sin(t * math.pi * 5) * 13 * (1 - t);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read app state once dependencies are available.
    final state = AppScope.read(context);
    _feedback ??= FeedbackService(state);
    final n = widget.level.number;
    // First-run coach: only on Level 1; highlights a movable arrow to tap.
    if (!state.tutorialSeen && !_showTutorial && n == 1) {
      _showTutorial = true;
      _hintId = _game.hintArrowId(); // spotlight an arrow to tap
    }
    // Power introduction: if this level unlocks a power not yet introduced.
    if (_introPower == null) {
      for (final p in PowerUp.values) {
        if (n == state.powerUnlockLevel(p) && !state.hasSeenIntro(p)) {
          _introPower = p;
          break;
        }
      }
    }
  }

  void _replayTutorial() => setState(() {
        _showTutorial = true;
        _hintId = _game.hintArrowId();
      });

  void _onChange() {
    // A successful tap reduces the remaining count; play the success feel.
    if (_game.remaining < _lastRemaining) {
      _feedback?.tapSuccess();
      // The coach completes only when the player actually clears an arrow.
      if (_showTutorial) _dismissTutorial();
    }
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

      // Coins by star tier (hearts left): 3★=50, 2★=35, 1★=20.
      _coinsEarned = switch (_lives) { 3 => 50, 2 => 35, _ => 20 };
      state.addCoins(_coinsEarned);

      _feedback?.win();
      setState(() => _showConfetti = true);
      Future.delayed(const Duration(milliseconds: 700), _showWin);
    }
    setState(() {});
  }

  void _onBlocked() {
    _feedback?.blocked(); // bump sound + haptic
    _shake.forward(from: 0); // jolt the screen on a wrong tap
    setState(() => _lives = (_lives - 1).clamp(0, 3));
    _feedback?.heartLost(); // distinct "heart lost" tone
    if (_lives == 0) _showFail();
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

  // Each power: if you own one, consume it and act; if you own none, open that
  // power's buy page.

  Future<void> _useHint() async {
    if (_game.hintArrowId() == null) {
      _toast('No hint available right now');
      return;
    }
    if (await AppScope.read(context).usePower(PowerUp.hint)) {
      _feedback?.tick();
      setState(() => _hintId = _game.hintArrowId());
    } else if (mounted) {
      showHintBoosterSheet(context);
    }
  }

  Future<void> _useEraser() async {
    if (AppScope.read(context).powerCount(PowerUp.eraser) <= 0) {
      showEraserBoosterSheet(context);
      return;
    }
    _boardActions.armEraser?.call();
    _feedback?.tick();
    _toast('Tap any arrow to erase it');
  }

  // Consume one eraser only when it's actually spent on an arrow.
  void _onEraserUsed() => AppScope.read(context).usePower(PowerUp.eraser);

  Future<void> _useMagic() async {
    if (_game.hintArrowId() == null) {
      _toast('No movable arrow right now');
      return;
    }
    if (await AppScope.read(context).usePower(PowerUp.magic)) {
      _boardActions.autoStep?.call();
      _feedback?.tick();
    } else if (mounted) {
      showMagicBoosterSheet(context);
    }
  }

  Future<void> _useUndo() async {
    if (!_game.canUndo) {
      _toast('Nothing to undo');
      return;
    }
    if (await AppScope.read(context).usePower(PowerUp.undo)) {
      _boardActions.undo?.call();
      _feedback?.tick();
    } else if (mounted) {
      showUndoBoosterSheet(context);
    }
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
    setState(() {
      _showTutorial = false;
      _hintId = null;
    });
  }

  /// The player tapped "Got it" on a power's intro: grant the first one + mark
  /// it seen so it never shows again.
  void _dismissIntro() {
    final p = _introPower;
    if (p == null) return;
    final state = AppScope.read(context);
    state.addPower(p, 1);
    state.markIntroSeen(p);
    _feedback?.tick();
    setState(() => _introPower = null);
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
              _nextLevelRoute(kLevels[next]),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  /// A lively transition to the next level: the new board scales + fades up
  /// while the old one fades out beneath it.
  Route<void> _nextLevelRoute(Level level) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 480),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => GameScreen(level: level),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showFail() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FailDialog(
        onWatchVideo: () {
          Navigator.of(context).pop();
          _continueWithVideo();
        },
        onRestart: () {
          Navigator.of(context).pop();
          _restart();
        },
      ),
    );
  }

  // Placeholder for a rewarded video ad: refill hearts and keep the current
  // board so the player continues right where they ran out (progress kept).
  // TODO: gate behind a real rewarded ad (AdMob / Unity Ads).
  void _continueWithVideo() {
    _feedback?.tick();
    setState(() {
      _lives = 3;
      _completed = false;
    });
  }

  /// Builds a bottom-bar tile: a locked card (dimmed + 🔒 + "Lv N") until the
  /// power is introduced, otherwise the normal use/buy tile.
  Widget _powerTile(
    PowerUp p,
    IconData icon,
    List<Color> colors,
    VoidCallback onUse,
    VoidCallback onBuy, {
    bool actionEnabled = true,
  }) {
    final st = context.appState;
    if (!st.isPowerUnlocked(p, widget.level.number)) {
      final lv = st.powerUnlockLevel(p);
      return _PowerButton(
        icon: icon,
        colors: colors,
        locked: true,
        unlockLevel: lv,
        onTap: () => _toast('${p.label} unlocks at Level $lv'),
      );
    }
    return _PowerButton(
      icon: icon,
      colors: colors,
      count: st.powerCount(p),
      plus: true,
      onPlus: onBuy,
      enabled: actionEnabled,
      onTap: onUse,
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    _game.removeListener(_onChange);
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progress = _game.progress;
    final state = context.appState;
    final coins = state.coins;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: palette.background,
      body: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeDx, 0),
          child: child,
        ),
        child: Stack(
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

          // Top controls overlay — a panel that fills the notch/status bar.
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(6, topInset + 6, 6, 12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
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
                                  : 'Level ${widget.level.number}',
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
                            onTheme: () => showThemePicker(context),
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
                      child: _powerTile(
                        PowerUp.hint,
                        Icons.lightbulb_rounded,
                        const [Color(0xFFFFC83D), Color(0xFFF4A100)],
                        _useHint,
                        () => showHintBoosterSheet(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _powerTile(
                        PowerUp.eraser,
                        Icons.cleaning_services_rounded,
                        const [Color(0xFFFF7A7A), Color(0xFFEE4B4B)],
                        _useEraser,
                        () => showEraserBoosterSheet(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _powerTile(
                        PowerUp.magic,
                        Icons.auto_awesome_rounded,
                        const [Color(0xFF8E8EF6), Color(0xFF4E5DF2)],
                        _useMagic,
                        () => showMagicBoosterSheet(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _powerTile(
                        PowerUp.undo,
                        Icons.undo_rounded,
                        const [Color(0xFF36C58E), Color(0xFF1E9E8A)],
                        _useUndo,
                        () => showUndoBoosterSheet(context),
                        actionEnabled: _game.canUndo,
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

          // First-run coach (interactive — closes only when you clear an arrow).
          if (_showTutorial) const TutorialOverlay(),

          // Power introduction (on the level a power unlocks).
          if (_introPower != null)
            PowerIntroOverlay(power: _introPower!, onDismiss: _dismissIntro),
        ],
        ),
      ),
    );
  }
}

class _ResultDialog extends StatefulWidget {
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
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double a, double b) => ((_c.value - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final stars = widget.stars;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final cardScale = Curves.easeOutBack.transform(_seg(0.0, 0.34));
        return Opacity(
          opacity: _seg(0.0, 0.18),
          child: Transform.scale(
            scale: cardScale,
            child: Dialog(
              backgroundColor: palette.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.pictureLevel != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: LevelThumbnail(
                          arrows: widget.pictureLevel!.arrows(),
                          rows: widget.pictureLevel!.rows,
                          cols: widget.pictureLevel!.cols,
                          color: palette.arrow,
                          size: 180,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.subtitle,
                        style: TextStyle(color: palette.textMuted)),
                    if (stars != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Transform.scale(
                              // Earned stars pop in one-by-one; empties stay put.
                              scale: i < stars
                                  ? Curves.easeOutBack.transform(
                                      _seg(0.34 + i * 0.18, 0.58 + i * 0.18))
                                  : 1.0,
                              child: Icon(
                                i < stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 42,
                                color: const Color(0xFFFFC83D),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (widget.coins > 0) ...[
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: _seg(0.82, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Color(0xFFF4B400), size: 22),
                            const SizedBox(width: 6),
                            Text(
                              '+${widget.coins}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: widget.onPrimary,
                          child: Text(widget.primaryLabel)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    this.count,
    this.plus = false,
    this.onPlus,
    this.enabled = true,
    this.locked = false,
    this.unlockLevel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final List<Color> colors;
  final int? count;
  final bool plus;
  final VoidCallback? onPlus;
  final bool enabled;
  final bool locked; // not yet introduced — shows a lock + "Lv N"
  final int? unlockLevel;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !locked;
    final grad = locked
        ? const [Color(0xFF565B66), Color(0xFF3C414B)] // greyed lock card
        : (enabled
            ? colors
            : const [Color(0xFF6B7280), Color(0xFF4B5563)]); // dimmed/disabled

    final Widget content;
    if (locked) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 22, color: Colors.white),
          const SizedBox(height: 4),
          _chip(child: Text('Lv $unlockLevel', style: _chipText)),
        ],
      );
    } else {
      final chip =
          count != null ? _chip(child: Text('x$count', style: _chipText)) : null;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: Colors.white),
          if (chip != null) ...[const SizedBox(height: 5), chip],
        ],
      );
    }

    return Opacity(
      opacity: locked ? 0.7 : (enabled ? 1 : 0.55),
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
                  onTap: (locked || enabled) ? onTap : null,
                  child: Center(child: content),
                ),
              ),
            ),
            if (plus && active)
              Positioned(
                top: -7,
                right: -7,
                child: GestureDetector(
                  onTap: onPlus,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2BB673),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, size: 15, color: Colors.white),
                  ),
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

/// Premium "Out of Lives" dialog: a broken-heart badge, and two clear choices —
/// watch a video to refill hearts and keep going, or restart the level.
class _FailDialog extends StatelessWidget {
  const _FailDialog({required this.onWatchVideo, required this.onRestart});

  final VoidCallback onWatchVideo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.8, end: 1.0),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Broken-heart badge with a warm red glow.
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A7A), Color(0xFFEE4B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEE4B4B).withValues(alpha: 0.5),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.heart_broken_rounded,
                    color: Colors.white, size: 46),
              ),
              const SizedBox(height: 18),
              Text(
                'Out of Lives',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: palette.arrow,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Watch a short video to refill your hearts and keep your '
                'progress — or start the level over.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textMuted,
                  height: 1.35,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Watch & Continue — chunky 3D gradient button with a video glyph.
              _FailButton(
                colors: const [Color(0xFF3FD17A), Color(0xFF27A35A)],
                icon: Icons.smart_display_rounded,
                label: 'Watch & Continue',
                onTap: onWatchVideo,
              ),
              const SizedBox(height: 10),
              // Restart — quieter secondary action.
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton.icon(
                  onPressed: onRestart,
                  icon: Icon(Icons.refresh_rounded, color: palette.textMuted),
                  label: Text(
                    'Restart',
                    style: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A chunky 3D-style gradient action button (matches the booster popup).
class _FailButton extends StatelessWidget {
  const _FailButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<Color> colors;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: colors.last, offset: const Offset(0, 4)),
          BoxShadow(
            color: colors.last.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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