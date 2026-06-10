import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../data/palettes.dart';
import '../data/shop_catalog.dart';
import '../game/game_controller.dart';
import '../l10n/strings.dart';
import '../models/level.dart';
import '../models/power_up.dart';
import '../services/ads_service.dart';
import '../services/feedback_service.dart';
import '../services/shop_service.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_image.dart';
import '../widgets/board_view.dart';
import '../widgets/booster_sheet.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/power_intro_overlay.dart';
import '../widgets/power_tutorial_overlay.dart';
import '../widgets/power_use_fx.dart';
import '../widgets/level_intro_banner.dart';
import '../widgets/reward_dialogs.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/ui_kit.dart';

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
  bool _showLevelIntro = true; // big "LEVEL N" reveal banner on open
  PowerUp? _introPower; // power being introduced on this level (intro overlay)
  PowerUp? _tutorialPower; // power whose USAGE tutorial is showing (after CLAIM)
  // A key per power tile, so the tutorial spotlight + use-FX can locate them.
  final Map<PowerUp, GlobalKey> _powerKeys = {
    for (final p in PowerUp.values) p: GlobalKey(),
  };
  PowerUp? _fxPower; // power whose use-activation FX is playing
  Offset? _fxFrom; // global launch point for the FX (the button centre)
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

  // Leaving a level mid-play costs a life — confirm first (unless infinite).
  void _confirmRestart() {
    final state = AppScope.read(context);
    if (state.hasInfiniteLives) {
      _restart();
      return;
    }
    showQuitConfirm(
      context,
      title: context.l10n.restartQ,
      confirmIcon: Icons.refresh_rounded,
      onConfirm: () {
        state.loseLife();
        _restart();
      },
    );
  }

  void _confirmHome() {
    final state = AppScope.read(context);
    if (state.hasInfiniteLives) {
      Navigator.of(context).pop();
      return;
    }
    showQuitConfirm(
      context,
      title: context.l10n.quitGame,
      confirmIcon: Icons.home_rounded,
      onConfirm: () {
        state.loseLife();
        Navigator.of(context).pop();
      },
    );
  }

  /// System back button: route through the same confirm-and-lose-a-life flow as
  /// Home (never a silent exit). Overlays take priority over leaving.
  void _onSystemBack() {
    if (_introPower != null) return; // must CLAIM the reveal first
    if (_tutorialPower != null) {
      setState(() => _tutorialPower = null); // back skips the usage tutorial
      return;
    }
    _confirmHome();
  }

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
    _endTutorial(PowerUp.hint);
    if (_game.hintArrowId() == null) {
      _toast('No hint available right now');
      return;
    }
    if (await AppScope.read(context).usePower(PowerUp.hint)) {
      _feedback?.tick();
      _playFx(PowerUp.hint);
      setState(() => _hintId = _game.hintArrowId());
    } else if (mounted) {
      showHintBoosterSheet(context);
    }
  }

  Future<void> _useEraser() async {
    _endTutorial(PowerUp.eraser);
    if (AppScope.read(context).powerCount(PowerUp.eraser) <= 0) {
      showEraserBoosterSheet(context);
      return;
    }
    _boardActions.armEraser?.call();
    _feedback?.tick();
    _playFx(PowerUp.eraser);
    _toast('Tap any arrow to erase it');
  }

  // Consume one eraser only when it's actually spent on an arrow.
  void _onEraserUsed() => AppScope.read(context).usePower(PowerUp.eraser);

  Future<void> _useMagic() async {
    _endTutorial(PowerUp.magic);
    if (_game.hintArrowId() == null) {
      _toast('No movable arrow right now');
      return;
    }
    if (await AppScope.read(context).usePower(PowerUp.magic)) {
      _boardActions.autoStep?.call();
      _feedback?.tick();
      _playFx(PowerUp.magic);
    } else if (mounted) {
      showMagicBoosterSheet(context);
    }
  }

  Future<void> _useUndo() async {
    _endTutorial(PowerUp.undo);
    if (!_game.canUndo) {
      _toast('Nothing to undo');
      return;
    }
    if (await AppScope.read(context).usePower(PowerUp.undo)) {
      _boardActions.undo?.call();
      _feedback?.tick();
      _playFx(PowerUp.undo);
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

  /// CLAIM on a power's intro: grant 3 free to try, mark it seen, then start
  /// the in-place usage tutorial.
  void _dismissIntro() {
    final p = _introPower;
    if (p == null) return;
    final state = AppScope.read(context);
    state.addPower(p, 3);
    state.markIntroSeen(p);
    _feedback?.tick();
    setState(() {
      _introPower = null;
      _tutorialPower = p; // now teach how to use it
    });
  }

  /// The usage tutorial ends the instant the player taps the highlighted power.
  void _endTutorial(PowerUp p) {
    if (_tutorialPower == p) setState(() => _tutorialPower = null);
  }

  /// Play the "power activated" flourish, launching from the power's button.
  void _playFx(PowerUp p) {
    final box = _powerKeys[p]?.currentContext?.findRenderObject();
    Offset from;
    if (box is RenderBox && box.hasSize) {
      from = box.localToGlobal(box.size.center(Offset.zero));
    } else {
      final size = MediaQuery.of(context).size;
      from = Offset(size.width / 2, size.height * 0.85);
    }
    setState(() {
      _fxPower = p;
      _fxFrom = from;
    });
  }

  void _showWin() {
    if (!mounted) return;
    final n = widget.level.number;
    final inPack = n >= 1 && n <= kLevels.length;
    final hasNext = inPack && n < kLevels.length;
    showLevelComplete(
      context,
      level: n,
      stars: _lives,
      coins: _coinsEarned,
      piggy: AppState.kPiggyPerLevel,
      hasNext: hasNext,
      onNext: () async {
        Navigator.of(context).pop(); // close the complete dialog
        // A full-screen ad at the level break — skipped for Remove Ads owners,
        // and only on every other break (see maybeShowInterstitial).
        if (!AppScope.read(context).adsRemoved) {
          await AdsService.maybeShowInterstitial();
        }
        if (!mounted) return;
        // Back to the home map; `true` tells it to open the start popup for the
        // next level (false / daily levels just return home).
        Navigator.of(context).pop(hasNext);
      },
    );
  }

  void _showFail() {
    showLevelFailed(
      context,
      buyCost: kReviveCost,
      // Free rewarded video → continue with 1 life.
      onWatch: () async {
        final earned = await AdsService.showRewarded();
        if (!mounted) return;
        if (earned) {
          Navigator.of(context).pop();
          _continue(1);
        } else {
          _toast('Ad not ready yet — try again in a moment.');
        }
      },
      // Spend coins → continue with full lives.
      onBuy: () async {
        final state = AppScope.read(context);
        if (await state.spendCoins(kReviveCost)) {
          if (!mounted) return;
          Navigator.of(context).pop();
          _continue(3);
        } else if (mounted) {
          _toast('Not enough coins.');
        }
      },
      // RESUME on the failed page → retry the level from the start. The life
      // was already taken by the overlay's warning step, so just reset the
      // board (the overlay has already popped itself).
      onResume: _restart,
      // Final X on the failed page → back to the level map. No extra confirm
      // or life loss here; the overlay already handled both.
      onHome: () => Navigator.of(context).pop(),
      // Safety-net upsell: buy the bundle (grants coins + power-ups).
      onOffer: () => buyShopProduct(context, kSafetyNetOffer),
    );
  }

  // Continue from the current board with [lives] in-level hearts (progress kept).
  void _continue(int lives) {
    _feedback?.tick();
    setState(() {
      _lives = lives;
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
        key: _powerKeys[p],
        icon: icon,
        power: p,
        colors: colors,
        locked: true,
        unlockLevel: lv,
        onTap: () => _toast('${p.label} unlocks at Level $lv'),
      );
    }
    return _PowerButton(
      key: _powerKeys[p],
      icon: icon,
      power: p,
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
    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      // Intercept the Android system back so leaving mid-level goes through the
      // same "lose a life" confirmation as the Home button (never a silent exit).
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onSystemBack();
      },
      child: Scaffold(
      backgroundColor: palette.background,
      body: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeDx, 0),
          child: child,
        ),
        child: Stack(
          children: [
          // Premium themes paint a gradient behind the (transparent) board.
          if (palette.gradient != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: palette.gradient!,
                  ),
                ),
              ),
            ),
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
              // Pull the content up into the notch band — the centre (where a
              // cutout sits) is empty, so only the side label rises beside it
              // while the progress row stays just below the cutout.
              padding: EdgeInsets.fromLTRB(16, (topInset - 16).clamp(8.0, 999.0),
                  12, 10),
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
              child: Row(
                children: [
                  // Left: small level label over the hearts + progress bar.
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.level.difficulty == 'Daily'
                              ? context.l10n.daily
                              : '${context.l10n.level} ${widget.level.number}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: _HeartPip(alive: i < _lives, palette: palette),
                              ),
                            const SizedBox(width: 4),
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
                            Text('${(progress * 100).round()}%',
                                style: TextStyle(
                                    color: palette.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right: chunky, themed pause button.
                  ChunkyCircleButton(
                    icon: Icons.pause_rounded,
                    color: palette.primary,
                    size: 46,
                    iconSize: 26,
                    onTap: () => showPauseDialog(
                      context,
                      onRestart: _confirmRestart,
                      onHome: _confirmHome,
                    ),
                  ),
                ],
              ),
              ),
            ),

          // Bottom power-up bar — four grounded square cards — with the ad
          // banner grounded beneath it (collapses when ads are removed).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SafeArea(
                  top: false,
                  bottom: state.adsRemoved,
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
                const AdBanner(),
              ],
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

          // Big "LEVEL N" reveal that swooshes in on open (skipped on levels
          // that show the power-unlock takeover instead). The board's arrows
          // cascade in as it leaves.
          if (_showLevelIntro && _introPower == null)
            LevelIntroBanner(
              label: widget.level.difficulty == 'Daily'
                  ? context.l10n.daily.toUpperCase()
                  : '${context.l10n.level.toUpperCase()} ${widget.level.number}',
              onDone: () {
                if (mounted) setState(() => _showLevelIntro = false);
              },
            ),

          // First-run coach (interactive — closes only when you clear an arrow).
          if (_showTutorial) const TutorialOverlay(),

          // Power introduction (on the level a power unlocks).
          if (_introPower != null)
            PowerIntroOverlay(power: _introPower!, onDismiss: _dismissIntro),

          // Usage tutorial — spotlight the new power button until it's tapped.
          if (_tutorialPower != null)
            PowerTutorialOverlay(
              power: _tutorialPower!,
              targetKey: _powerKeys[_tutorialPower!]!,
              onSkip: () => setState(() => _tutorialPower = null),
            ),

          // Power-activation flourish (icon flies out + bursts on use).
          if (_fxPower != null && _fxFrom != null)
            PowerUseFxOverlay(
              power: _fxPower!,
              from: _fxFrom!,
              onDone: () {
                if (mounted) {
                  setState(() {
                    _fxPower = null;
                    _fxFrom = null;
                  });
                }
              },
            ),
        ],
        ),
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
    super.key,
    required this.icon,
    required this.onTap,
    required this.colors,
    this.power,
    this.count,
    this.plus = false,
    this.onPlus,
    this.enabled = true,
    this.locked = false,
    this.unlockLevel,
  });

  final IconData icon;
  final PowerUp? power;
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
          power != null
              ? PowerIcon(power!, size: 26)
              : Icon(icon, size: 26, color: Colors.white),
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

/// A single life pip in the header — a glossy 3D heart when alive, a dimmed
/// outline when lost. Pops/scales as the alive state changes for liveliness.
class _HeartPip extends StatelessWidget {
  const _HeartPip({required this.alive, required this.palette});

  final bool alive;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      scale: alive ? 1.0 : 0.82,
      child: alive
          ? const HeartIcon(size: 22)
          : Icon(Icons.favorite_rounded,
              size: 22, color: palette.textMuted.withValues(alpha: 0.3)),
    );
  }
}

