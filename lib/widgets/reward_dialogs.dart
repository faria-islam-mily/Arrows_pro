import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/level.dart';
import '../theme/app_images.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'level_thumbnail.dart';
import 'ui_kit.dart';

const Color _panel = Color(0xFF26314E);
const Color _rewardBg = Color(0xFF1B2236);

// ---------------------------------------------------------------------------
// Level complete (the celebratory win screen)
// ---------------------------------------------------------------------------

/// The lively "LEVEL N COMPLETED!" reveal: stars bounce in, a gold reward card
/// slides up showing coins + piggy, and a pulsing NEXT/HOME button.
Future<void> showLevelComplete(
  BuildContext context, {
  required int level,
  required int stars,
  required int coins,
  required int piggy,
  required bool hasNext,
  required VoidCallback onNext,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.35), // confetti shows through
    builder: (_) => _LevelCompleteDialog(
      level: level,
      stars: stars,
      coins: coins,
      piggy: piggy,
      hasNext: hasNext,
      onNext: onNext,
    ),
  );
}

class _LevelCompleteDialog extends StatefulWidget {
  const _LevelCompleteDialog({
    required this.level,
    required this.stars,
    required this.coins,
    required this.piggy,
    required this.hasNext,
    required this.onNext,
  });
  final int level, stars, coins, piggy;
  final bool hasNext;
  final VoidCallback onNext;

  @override
  State<_LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<_LevelCompleteDialog>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  double _seg(double start, double end) =>
      Interval(start, end, curve: Curves.easeOutBack).transform(_intro.value);

  double _fade(double start) =>
      Interval(start, (start + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut)
          .transform(_intro.value);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _stars(),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: _fade(0.35),
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - _fade(0.35))),
                      child: _banner(l10n),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Opacity(
                    opacity: _fade(0.5),
                    child: Transform.translate(
                      offset: Offset(0, 28 * (1 - _fade(0.5))),
                      child: _rewardCard(l10n),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Opacity(opacity: _fade(0.72), child: _nextButton(l10n)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stars() {
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset((i - 1) * 78.0, i == 1 ? -14 : 0),
              child: _star(i),
            ),
        ],
      ),
    );
  }

  Widget _star(int i) {
    final t = _seg(0.05 + i * 0.13, 0.5 + i * 0.13).clamp(0.0, 1.2);
    final earned = i < widget.stars;
    final size = i == 1 ? 84.0 : 70.0;
    return Transform.scale(
      scale: t,
      child: earned
          ? StarIcon(size: size)
          : Icon(Icons.star_rounded, size: size, color: const Color(0xFF3C4A6B)),
    );
  }

  Widget _banner(L10n l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text('${l10n.level.toUpperCase()} ${widget.level}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 8),
        Text(l10n.completed,
            style: const TextStyle(
                color: Color(0xFFFFD23F),
                fontSize: 28,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Color(0x66000000), offset: Offset(0, 2))])),
      ],
    );
  }

  Widget _rewardCard(L10n l10n) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          decoration: BoxDecoration(
            color: _rewardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GameColors.star, width: 2.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _rewardItem(
                const AppImage(AppImages.pack5000,
                    size: 64, fallback: Text('🪙', style: TextStyle(fontSize: 46))),
                '+${widget.coins}',
              ),
              _rewardItem(
                const AppImage(AppImages.piggyBank,
                    size: 64, fallback: Text('🐷', style: TextStyle(fontSize: 46))),
                '+${widget.piggy}',
              ),
            ],
          ),
        ),
        // "REWARD" tab on the top border.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          decoration: BoxDecoration(
            color: _rewardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GameColors.star, width: 2.5),
          ),
          child: Text(l10n.reward,
              style: const TextStyle(
                  color: GameColors.star,
                  fontSize: 15,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _rewardItem(Widget icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: GameColors.star,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Color(0x66000000), offset: Offset(0, 2))])),
      ],
    );
  }

  Widget _nextButton(L10n l10n) {
    final pulse = 1 + 0.03 * math.sin(_loop.value * math.pi * 2);
    return Transform.scale(
      scale: pulse,
      child: SizedBox(
        width: double.infinity,
        child: ChunkyButton(
          color: GameColors.green,
          depth: 8,
          radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 16),
          onTap: widget.onNext,
          child: Text(widget.hasNext ? l10n.next : l10n.home.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Color(0x66000000), offset: Offset(0, 2))
                  ])),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level start (tap an unplayed level / "Next" from the map)
// ---------------------------------------------------------------------------

/// A "ready to play" popup for an unplayed level: a preview of the puzzle and a
/// big PLAY button.
Future<void> showLevelStart(
  BuildContext context, {
  required Level level,
  required Color arrowColor,
  required VoidCallback onPlay,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _LevelStartDialog(
      level: level,
      arrowColor: arrowColor,
      onPlay: onPlay,
    ),
  );
}

class _LevelStartDialog extends StatefulWidget {
  const _LevelStartDialog({
    required this.level,
    required this.arrowColor,
    required this.onPlay,
  });
  final Level level;
  final Color arrowColor;
  final VoidCallback onPlay;

  @override
  State<_LevelStartDialog> createState() => _LevelStartDialogState();
}

class _LevelStartDialogState extends State<_LevelStartDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.85, end: 1.0),
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              type: MaterialType.transparency,
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
                            colors: [
                              GameColors.headerBlue,
                              GameColors.headerBlueDark
                            ],
                          ),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: Text('${l10n.level.toUpperCase()} ${widget.level.number}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(color: Colors.black26, offset: Offset(0, 2))
                                ])),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        decoration: const BoxDecoration(
                          color: _panel,
                          borderRadius:
                              BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Puzzle preview.
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SizedBox(
                                height: 120,
                                child: LevelThumbnail(
                                  arrows: widget.level.arrows(),
                                  rows: widget.level.rows,
                                  cols: widget.level.cols,
                                  color: widget.arrowColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            AnimatedBuilder(
                              animation: _loop,
                              builder: (context, child) => Transform.scale(
                                scale: 1 + 0.03 * math.sin(_loop.value * math.pi * 2),
                                child: child,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ChunkyButton(
                                  color: GameColors.green,
                                  depth: 8,
                                  radius: 18,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    widget.onPlay();
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_arrow_rounded,
                                          color: Colors.white, size: 28),
                                      const SizedBox(width: 6),
                                      Text(l10n.play,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              letterSpacing: 1,
                                              fontWeight: FontWeight.w900,
                                              shadows: [
                                                Shadow(
                                                    color: Color(0x66000000),
                                                    offset: Offset(0, 2))
                                              ])),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                      size: 38,
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
// Daily gift reward (with a watch-video 2× offer)
// ---------------------------------------------------------------------------

/// Shown after claiming the daily gift: the coins received + a "watch for 2×"
/// offer. [onWatch2x] plays the rewarded video and returns whether it doubled.
Future<void> showDailyGiftReward(
  BuildContext context, {
  required int coins,
  required Future<bool> Function() onWatch2x,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _DailyGiftRewardDialog(coins: coins, onWatch2x: onWatch2x),
  );
}

class _DailyGiftRewardDialog extends StatefulWidget {
  const _DailyGiftRewardDialog({required this.coins, required this.onWatch2x});
  final int coins;
  final Future<bool> Function() onWatch2x;

  @override
  State<_DailyGiftRewardDialog> createState() => _DailyGiftRewardDialogState();
}

class _DailyGiftRewardDialogState extends State<_DailyGiftRewardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  bool _busy = false;
  int _total = 0;
  bool _doubled = false;

  @override
  void initState() {
    super.initState();
    _total = widget.coins;
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  Future<void> _watch() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await widget.onWatch2x();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _doubled = true;
        _total = widget.coins * 2;
      }
    });
    if (ok) {
      // brief beat to show the doubled total, then close.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.85, end: 1.0),
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              type: MaterialType.transparency,
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
                            colors: [
                              GameColors.headerBlue,
                              GameColors.headerBlueDark
                            ],
                          ),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: Text(l10n.collectGift,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(color: Colors.black26, offset: Offset(0, 2))
                                ])),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        decoration: const BoxDecoration(
                          color: _panel,
                          borderRadius:
                              BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _loop,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(
                                    0, math.sin(_loop.value * math.pi * 2) * 4),
                                child: child,
                              ),
                              child: const AppImage(AppImages.pack5000,
                                  size: 96,
                                  fallback:
                                      Text('🪙', style: TextStyle(fontSize: 64))),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CoinIcon(size: 26),
                                const SizedBox(width: 6),
                                Text('+$_total',
                                    style: TextStyle(
                                        color: _doubled
                                            ? const Color(0xFF6FD63B)
                                            : GameColors.star,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (!_doubled)
                              SizedBox(
                                width: double.infinity,
                                child: ChunkyButton(
                                  color: GameColors.purple,
                                  depth: 6,
                                  radius: 16,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  onTap: _busy ? null : _watch,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_fill_rounded,
                                          color: Colors.white, size: 22),
                                      const SizedBox(width: 8),
                                      Text(l10n.watchDouble,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ChunkyButton(
                                color: GameColors.green,
                                depth: 6,
                                radius: 16,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                onTap: () => Navigator.of(context).pop(),
                                child: Text(l10n.collect,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
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
                      size: 38,
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
