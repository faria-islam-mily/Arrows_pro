import 'dart:async';

import 'package:flutter/material.dart';

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
  required VoidCallback onGiveUp, // X -> replay (lose a life)
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
      onGiveUp: onGiveUp,
      onOffer: onOffer,
      buyCost: buyCost,
    ),
  );
}

class _LevelFailedOverlay extends StatefulWidget {
  const _LevelFailedOverlay({
    required this.onWatch,
    required this.onBuy,
    required this.onGiveUp,
    required this.onOffer,
    required this.buyCost,
  });
  final VoidCallback onWatch, onBuy, onGiveUp, onOffer;
  final int buyCost;

  @override
  State<_LevelFailedOverlay> createState() => _LevelFailedOverlayState();
}

class _LevelFailedOverlayState extends State<_LevelFailedOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                  _HudPill(icon: const CoinIcon(size: 30), label: '${state.coins}'),
                  _HudPill(
                    icon: const HeartIcon(size: 30),
                    label: '${state.lives}',
                    trailing: lifeRight,
                  ),
                ],
              ),
              Expanded(child: Center(child: _panel())),
              _SafetyNetTile(buyCost: 'BDT 700', onBuy: widget.onOffer),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [GameColors.headerBlue, GameColors.headerBlueDark],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: const Text('Level Failed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Colors.black26, offset: Offset(0, 2))
                        ])),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: const BoxDecoration(
                  color: _failPanel,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(26)),
                ),
                child: Column(
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
                            actionTop: 'GET',
                            actionBottom: 'FREE',
                            video: true,
                            onTap: widget.onWatch,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ReviveTile(
                            color: GameColors.green,
                            amount: '+3',
                            actionTop: 'GET',
                            actionBottom: '${widget.buyCost}',
                            coin: true,
                            onTap: widget.onBuy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 30,
            right: -6,
            child: ChunkyCircleButton(
              icon: Icons.close_rounded,
              color: GameColors.red,
              size: 38,
              onTap: () {
                Navigator.of(context).pop();
                widget.onGiveUp();
              },
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

/// One revive option — a heart "+N" badge beside a GET / value action.
class _ReviveTile extends StatelessWidget {
  const _ReviveTile({
    required this.color,
    required this.amount,
    required this.actionTop,
    required this.actionBottom,
    required this.onTap,
    this.video = false,
    this.coin = false,
  });
  final Color color;
  final String amount;
  final String actionTop;
  final String actionBottom;
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
          radius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heart + amount badge.
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const HeartIcon(size: 34),
                    Text(amount,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Color(0x99000000), blurRadius: 2)
                            ])),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionTop,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (coin) ...[
                          const CoinIcon(size: 16),
                          const SizedBox(width: 3),
                        ],
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(actionBottom,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (video)
          Positioned(
            top: -10,
            left: -6,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFF3E7BE8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }
}

/// The bottom "SAFETY NET OFFER" upsell tile.
class _SafetyNetTile extends StatelessWidget {
  const _SafetyNetTile({required this.buyCost, required this.onBuy});
  final String buyCost;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GameColors.purple,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameColors.star, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title tab.
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: GameColors.star,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('SAFETY NET OFFER',
                style: TextStyle(
                    color: Color(0xFF7A4E00),
                    fontSize: 15,
                    fontWeight: FontWeight.w900)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppImage(AppImages.pack50000,
                        size: 60,
                        fallback: Text('💰', style: TextStyle(fontSize: 40))),
                    Text('2400',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(width: 8),
                const _OfferPerk(),
                const Spacer(),
                ChunkyButton(
                  color: GameColors.green,
                  depth: 5,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onTap: onBuy,
                  child: Text(buyCost,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferPerk extends StatelessWidget {
  const _OfferPerk();
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Perk(PowerUp.magic),
        _Perk(PowerUp.hint),
        _Perk(PowerUp.eraser),
      ],
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.power);
  final PowerUp power;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 26, height: 26, child: PowerIcon(power, size: 26)),
          const Text('x1',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
