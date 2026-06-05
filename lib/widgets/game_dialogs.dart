import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../state/app_scope.dart';
import '../state/main_nav.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'ui_kit.dart';

/// Coin cost to replay an already-cleared level without spending a life.
const int kReplayCoinCost = 450;

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
        const HeartBrokenIcon(size: 56),
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
Future<void> showLevelFailed(
  BuildContext context, {
  required VoidCallback onContinue,
  required VoidCallback onReplay,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => GameDialog(
      title: 'Level Failed',
      headerColor: GameColors.headerBlue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeartBrokenIcon(size: 64),
          const SizedBox(height: 4),
          const Text(
            'You will lose a life',
            style: TextStyle(
              color: GameColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ChunkyButton(
            color: GameColors.purple,
            depth: 6,
            onTap: onContinue,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('WATCH & CONTINUE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            color: GameColors.green,
            depth: 6,
            onTap: onReplay,
            child: const Text('REPLAY',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
          ),
        ],
      ),
    ),
  );
}
