import 'dart:async';

import 'package:flutter/material.dart';

import '../data/shop_catalog.dart';
import '../models/power_up.dart';
import '../services/ads_service.dart';
import '../state/app_scope.dart';
import '../state/main_nav.dart';
import '../theme/app_images.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'ui_kit.dart';

/// Coin cost to replay an already-cleared level without spending a life.
const int kReplayCoinCost = 450;

/// Coin cost to buy a revive (continue from the same state) on a level fail.
const int kReviveCost = 900;

/// A broken heart that gently pulses and wobbles — adds life to the
/// fail / out-of-lives dialogs.
class _PulseHeart extends StatefulWidget {
  const _PulseHeart({this.size = 64});
  final double size;

  @override
  State<_PulseHeart> createState() => _PulseHeartState();
}

class _PulseHeartState extends State<_PulseHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.rotate(
        angle: 0.05 * (_c.value - 0.5),
        child: Transform.scale(scale: 1.0 + 0.08 * _c.value, child: child),
      ),
      child: HeartBrokenIcon(size: widget.size),
    );
  }
}

/// Shown when the player taps an already-completed level. Big stars overhang the
/// header; two ways to replay — pay coins (keep your life) or replay free
/// (costs a life). [onReplay] launches the level once a cost is paid.
Future<void> showReplayLevel(
  BuildContext context, {
  required int level,
  required int stars,
  required VoidCallback onReplay,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _ReplayDialog(level: level, stars: stars, onReplay: onReplay),
  );
}

class _ReplayDialog extends StatelessWidget {
  const _ReplayDialog({
    required this.level,
    required this.stars,
    required this.onReplay,
  });

  final int level;
  final int stars;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final message = stars >= 3
        ? 'You already have 3 stars!\nReplay to master the skill!'
        : 'Replay this level to earn\nmore stars and master it!';

    void close() => Navigator.of(context).pop();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.85, end: 1.0),
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header (stars overhang its top).
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
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
                        'LEVEL $level',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GameColors.star,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(color: Colors.black38, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                    // Body.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: const BoxDecoration(
                        color: GameColors.panel,
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(26)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F0FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GameColors.inkMuted,
                                fontSize: 16,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ReplayCoinButton(
                                  onTap: () async {
                                    if (await state.spendCoins(kReplayCoinCost)) {
                                      if (context.mounted) close();
                                      onReplay();
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Not enough coins.'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ReplayFreeButton(
                                  onTap: () async {
                                    if (!state.canPlay) {
                                      close();
                                      if (context.mounted) showOutOfLives(context);
                                      return;
                                    }
                                    await state.loseLife();
                                    if (context.mounted) close();
                                    onReplay();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Big stars overhanging the header.
                Positioned(
                  top: -18,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StarIcon(size: 58, filled: stars >= 1),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: StarIcon(size: 66, filled: stars >= 2),
                      ),
                      StarIcon(size: 58, filled: stars >= 3),
                    ],
                  ),
                ),
                Positioned(
                  top: 36,
                  right: -4,
                  child: ChunkyCircleButton(
                    icon: Icons.close_rounded,
                    color: GameColors.red,
                    size: 38,
                    onTap: close,
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

class _ReplayCoinButton extends StatelessWidget {
  const _ReplayCoinButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: GameColors.green,
      depth: 6,
      padding: const EdgeInsets.symmetric(vertical: 12),
      onTap: onTap,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('REPLAY',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoinIcon(size: 18),
              SizedBox(width: 4),
              Text('$kReplayCoinCost',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplayFreeButton extends StatelessWidget {
  const _ReplayFreeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      // passthrough so the button fills the Expanded width (it's the
      // non-positioned child); otherwise the Stack hands it loose constraints
      // and it shrinks to its content.
      fit: StackFit.passthrough,
      children: [
        ChunkyButton(
          color: const Color(0xFFF2A33C),
          depth: 6,
          padding: const EdgeInsets.symmetric(vertical: 12),
          onTap: onTap,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('REPLAY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 2),
              Text('FREE',
                  style: TextStyle(
                      color: Color(0xFFFFE0B2),
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        // -1 life badge, tucked at the top-right corner clear of the text.
        Positioned(
          top: -10,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: GameColors.heart,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1)),
              ],
            ),
            child: const Text('-1',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

/// Shown when the player has no lives left and tries to start a level. Offers a
/// rewarded life, a trip to the shop for infinite lives, and shows the live
/// regen countdown.
Future<void> showOutOfLives(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => GameDialog(
      title: 'Out of Lives!',
      headerColor: GameColors.red,
      onClose: () => Navigator.of(ctx).pop(),
      child: const _OutOfLivesBody(),
    ),
  );
}

class _OutOfLivesBody extends StatefulWidget {
  const _OutOfLivesBody();

  @override
  State<_OutOfLivesBody> createState() => _OutOfLivesBodyState();
}

class _OutOfLivesBodyState extends State<_OutOfLivesBody> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final next = state.timeToNextLife;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PulseHeart(size: 56),
        const SizedBox(height: 6),
        Text(
          next == null
              ? 'Your lives will be back soon.'
              : 'Next life in ${_fmt(next)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GameColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        // Rewarded life — only granted if the video is actually watched.
        ChunkyButton(
          color: GameColors.green,
          depth: 6,
          onTap: () async {
            final state = AppScope.read(context);
            final earned = await AdsService.showRewarded();
            if (!context.mounted) return;
            if (earned) {
              await state.addLives(1);
              if (context.mounted) Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ad not ready yet — try again in a moment.'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('WATCH AD · +1 LIFE',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ChunkyButton(
          color: GameColors.purple,
          depth: 6,
          onTap: () {
            Navigator.of(context).pop();
            openShop();
          },
          child: const Text('GET INFINITE LIVES',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
        ),
      ],
    );
  }
}

/// The in-level "you ran out of moves" dialog: keep playing by watching a video,
/// or replay (which costs a life). Premium reskin of the old fail dialog.
const Color _failPanel = Color(0xFF2C3858);
const Color _failInner = Color(0xFF3B4668);

/// The "Level Failed" overlay (styled after the Out-of-Stars reference): a
/// coins+lives HUD on top, a fail panel with two ways to keep playing from the
/// same state (free video life / buy a life), and a safety-net offer below.
Future<void> showLevelFailed(
  BuildContext context, {
  required VoidCallback onWatch, // free rewarded video -> continue
  required VoidCallback onBuy, // spend coins -> continue
  required VoidCallback onResume, // RESUME on the failed page -> retry
  required VoidCallback onHome, // final X -> back to the level map
  required VoidCallback onOffer, // buy the safety-net bundle -> continue
  required int buyCost,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => _LevelFailedOverlay(
      onWatch: onWatch,
      onBuy: onBuy,
      onResume: onResume,
      onHome: onHome,
      onOffer: onOffer,
      buyCost: buyCost,
    ),
  );
}

class _LevelFailedOverlay extends StatefulWidget {
  const _LevelFailedOverlay({
    required this.onWatch,
    required this.onBuy,
    required this.onResume,
    required this.onHome,
    required this.onOffer,
    required this.buyCost,
  });
  final VoidCallback onWatch, onBuy, onResume, onHome, onOffer;
  final int buyCost;

  @override
  State<_LevelFailedOverlay> createState() => _LevelFailedOverlayState();
}

class _LevelFailedOverlayState extends State<_LevelFailedOverlay> {
  Timer? _timer;
  // 0 = out of lives, 1 = "you'll lose a life" warning, 2 = level failed.
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Ticks the "time to next life" countdown shown in the HUD pill.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // The escalating close behaviour the user asked for:
  // out of lives -> warning -> (lose a life) -> level failed -> home.
  Future<void> _onX() async {
    if (_step == 0) {
      setState(() => _step = 1);
    } else if (_step == 1) {
      final app = context.appState;
      await app.loseLife(); // confirming the warning costs the life
      if (mounted) setState(() => _step = 2);
    } else {
      Navigator.of(context).pop();
      widget.onHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final String lifeRight;
    if (state.hasInfiniteLives) {
      lifeRight = '∞';
    } else {
      final t = state.timeToNextLife;
      if (t == null) {
        lifeRight = 'FULL';
      } else {
        final m = t.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = t.inSeconds.remainder(60).toString().padLeft(2, '0');
        lifeRight = '$m:$s';
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Coins + lives HUD.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HudPill(
                      icon: const CoinIcon(size: 30), label: '${state.coins}'),
                  _HudPill(
                    icon: const HeartIcon(size: 30),
                    label: '${state.lives}',
                    trailing: lifeRight,
                  ),
                ],
              ),
              // Card + offer move together as one centred group, so the offer
              // sits directly under the card instead of pinned to the bottom.
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    // Don't clip — the close X floats just outside the card's
                    // top-right corner and must not be cropped.
                    clipBehavior: Clip.none,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Breathing room so the close X (which floats above the
                        // card's top edge) isn't clipped by the scroll view.
                        const SizedBox(height: 16),
                        // The card slides in from the side as the step changes.
                        // The X lives in this outer Stack — NOT inside the
                        // AnimatedSwitcher — so its internal clip can't crop it.
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topRight,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 360),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: _slideFromSide,
                              child: KeyedSubtree(
                                key: ValueKey(_step),
                                child: _panelForStep(),
                              ),
                            ),
                            Positioned(
                              top: -10,
                              right: -6,
                              child: ChunkyCircleButton(
                                icon: Icons.close_rounded,
                                color: GameColors.red,
                                size: 38,
                                onTap: _onX,
                              ),
                            ),
                          ],
                        ),
                        // The custom offer sits just below the card on the
                        // decision pages, but slides away during the warning.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: _slideFromSide,
                          child: _step == 1
                              ? const SizedBox(key: ValueKey('no-offer'), width: 1)
                              : Padding(
                                  key: const ValueKey('offer'),
                                  padding: const EdgeInsets.only(top: 14),
                                  child: _SafetyNetTile(onBuy: widget.onOffer),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Incoming card enters from the right and fades in; the outgoing one leaves
  // to the right too, so each step feels like it "comes from the side".
  Widget _slideFromSide(Widget child, Animation<double> animation) {
    final offset = Tween<Offset>(
      begin: const Offset(0.55, 0),
      end: Offset.zero,
    ).animate(animation);
    return ClipRect(
      child: SlideTransition(
        position: offset,
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _panelForStep() {
    switch (_step) {
      case 1:
        return _warningPanel();
      case 2:
        return _failedPanel();
      default:
        return _outOfLivesPanel();
    }
  }

  /// Shared card frame: coloured header + dark body. The close X is drawn
  /// separately in [build] (outside the AnimatedSwitcher/scroll clip) so it can
  /// float over the corner without being cropped.
  Widget _card({
    required String title,
    required List<Color> headerColors,
    required Widget body,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: headerColors,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(color: Colors.black26, offset: Offset(0, 2))
                    ])),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: const BoxDecoration(
              color: _failPanel,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: body,
          ),
        ],
      ),
    );
  }

  // Step 0 — out of lives: two ways to keep playing from the same state.
  Widget _outOfLivesPanel() {
    return _card(
      title: 'OUT OF LIVES',
      headerColors: const [GameColors.headerBlue, GameColors.headerBlueDark],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _failInner,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const _PulseHeart(size: 72),
          ),
          const SizedBox(height: 12),
          const Text('GET MORE LIVES!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ReviveTile(
                  color: GameColors.purple,
                  amount: '+1',
                  action: 'GET',
                  value: 'FREE',
                  video: true,
                  onTap: widget.onWatch,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReviveTile(
                  color: GameColors.green,
                  amount: '+3',
                  action: 'GET',
                  value: '${widget.buyCost}',
                  coin: true,
                  onTap: widget.onBuy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 1 — the "you'll lose a life" warning. A friendly way back, or X to
  // confirm leaving (which costs the life).
  Widget _warningPanel() {
    return _card(
      title: 'WAIT!',
      headerColors: const [Color(0xFFF2A33C), Color(0xFFD9822B)],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          const _PulseHeart(size: 64),
          const SizedBox(height: 12),
          const Text('You’ll lose a life\nif you leave now!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ChunkyButton(
              color: GameColors.green,
              depth: 6,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: () => setState(() => _step = 0),
              child: const Text('GO BACK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Tap ✕ to leave anyway',
              style: TextStyle(
                  color: Color(0xFFAEB9D4),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // Step 2 — level failed: a single big RESUME option, or X to the level map.
  Widget _failedPanel() {
    return _card(
      title: 'LEVEL FAILED',
      headerColors: const [Color(0xFFE85C5C), Color(0xFFC23B3B)],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          const _PulseHeart(size: 64),
          const SizedBox(height: 12),
          const Text('Don’t give up —\ntry this level again!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ChunkyButton(
              color: GameColors.green,
              depth: 6,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: () {
                Navigator.of(context).pop();
                widget.onResume();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('RESUME',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.icon, required this.label, this.trailing});
  final Widget icon;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 4, right: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF202A44),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17)),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(trailing!,
                style: const TextStyle(
                    color: Color(0xFFAEB9D4),
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// One revive option — a big heart "+N" badge above a GET / value action.
/// Laid out vertically and large so the tile reads full, not "empty".
class _ReviveTile extends StatelessWidget {
  const _ReviveTile({
    required this.color,
    required this.amount,
    required this.action,
    required this.value,
    required this.onTap,
    this.video = false,
    this.coin = false,
  });
  final Color color;
  final String amount;
  final String action;
  final String value;
  final VoidCallback onTap;
  final bool video;
  final bool coin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        ChunkyButton(
          color: color,
          depth: 6,
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big heart + amount badge.
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const HeartIcon(size: 56),
                    Text(amount,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Color(0x99000000), blurRadius: 2)
                            ])),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(action,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (coin) ...[
                    const CoinIcon(size: 22),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (video)
          Positioned(
            top: -10,
            left: -6,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF3E7BE8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x55000000), blurRadius: 4)
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
      ],
    );
  }
}

/// The bottom upsell tile — our own customized "Rescue Pack" offer
/// ([kSafetyNetOffer]). Big, full, and gently pulsing to catch the eye.
class _SafetyNetTile extends StatefulWidget {
  const _SafetyNetTile({required this.onBuy});
  final VoidCallback onBuy;

  @override
  State<_SafetyNetTile> createState() => _SafetyNetTileState();
}

class _SafetyNetTileState extends State<_SafetyNetTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const offer = kSafetyNetOffer;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(scale: 1 + t * 0.02, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C53D4), Color(0xFF5B3BC0)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GameColors.star, width: 3),
          boxShadow: [
            BoxShadow(
              color: GameColors.star.withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title tab.
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
              decoration: BoxDecoration(
                color: GameColors.star,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 4)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFF7A4E00), size: 20),
                  const SizedBox(width: 5),
                  Text(offer.title.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF7A4E00),
                          fontSize: 17,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Row(
                children: [
                  // Coin stack reward.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppImage(AppImages.pack50000,
                          size: 72,
                          fallback: Text('💰', style: TextStyle(fontSize: 52))),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CoinIcon(size: 20),
                          const SizedBox(width: 4),
                          Text('${offer.coins}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Power-up + infinite-lives perks.
                  const Expanded(child: _OfferPerks(offer)),
                  const SizedBox(width: 6),
                  // Buy button — pulsing glow ties it to the tile animation.
                  ChunkyButton(
                    color: GameColors.green,
                    depth: 6,
                    radius: 16,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    onTap: widget.onBuy,
                    child: Text(offer.priceLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The grid of perks granted by an offer (infinite lives + power-ups).
class _OfferPerks extends StatelessWidget {
  const _OfferPerks(this.offer);
  final ShopProduct offer;

  @override
  Widget build(BuildContext context) {
    final perks = <Widget>[
      if (offer.infiniteHours > 0)
        _Perk(
            icon: const HeartIcon(size: 30),
            label: '∞${offer.infiniteHours}h'),
      if (offer.magic > 0)
        _Perk(icon: const PowerIcon(PowerUp.magic, size: 30), label: 'x${offer.magic}'),
      if (offer.hint > 0)
        _Perk(icon: const PowerIcon(PowerUp.hint, size: 30), label: 'x${offer.hint}'),
      if (offer.eraser > 0)
        _Perk(icon: const PowerIcon(PowerUp.eraser, size: 30), label: 'x${offer.eraser}'),
      if (offer.undo > 0)
        _Perk(icon: const PowerIcon(PowerUp.undo, size: 30), label: 'x${offer.undo}'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: perks,
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.label});
  final Widget icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 30, height: 30, child: Center(child: icon)),
        const SizedBox(height: 1),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}
