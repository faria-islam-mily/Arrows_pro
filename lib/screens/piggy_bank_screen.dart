import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_images.dart';
import '../theme/game_colors.dart';
import '../widgets/app_image.dart';
import '../widgets/ui_kit.dart';

/// The Piggy Bank: coins accumulate here as you beat levels; once it holds
/// enough you can BREAK it to collect them all at once.
class PiggyBankScreen extends StatelessWidget {
  const PiggyBankScreen({super.key});

  static const Color _bg = Color(0xFF5B3Fb0);
  static const Color _bgDark = Color(0xFF4A3192);

  Future<void> _break(BuildContext context) async {
    final state = AppScope.read(context);
    if (!state.canBreakPiggy) return;
    final amount = await state.breakPiggy();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Piggy smashed! +$amount coins 🎉'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final piggy = state.piggyCoins;
    final canBreak = state.canBreakPiggy;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [_bg, _bgDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: info + close.
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    ChunkyCircleButton(
                      icon: Icons.priority_high_rounded,
                      color: GameColors.blue,
                      size: 38,
                      onTap: () => _showInfo(context),
                    ),
                    const Spacer(),
                    ChunkyCircleButton(
                      icon: Icons.close_rounded,
                      color: GameColors.red,
                      size: 40,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const _PiggyTitle(),
              const Spacer(),
              // Piggy.
              const AppImage(
                AppImages.piggyBank,
                size: 220,
                fallback: Text('🐷', style: TextStyle(fontSize: 150)),
              ),
              const SizedBox(height: 24),
              _PiggyProgress(value: piggy, cap: AppState.kPiggyCap),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
                child: ChunkyButton(
                  color: canBreak ? GameColors.green : const Color(0xFFB9C2D6),
                  depth: 7,
                  radius: 18,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: canBreak ? () => _break(context) : null,
                  child: Text(
                    context.l10n.breakWord,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent, // the overlay paints its own backdrop
      builder: (ctx) => Material(
        color: const Color(0xFF1A1430), // fully opaque so the page can't bleed
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          behavior: HitTestBehavior.opaque,
          child: const SafeArea(child: _PiggyInfo()),
        ),
      ),
    );
  }
}

/// Chunky 3D "game" title text — a coloured fill over a thick outline + shadow.
class _GameText extends StatelessWidget {
  const _GameText(
    this.text, {
    required this.fill,
    required this.stroke,
    required this.fontSize,
  });

  final String text;
  final Color fill;
  final Color stroke;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
      height: 0.95,
    );
    return Stack(
      children: [
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
            shadows: const [
              Shadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 3),
            ],
          ),
        ),
        Text(text, style: base.copyWith(color: fill)),
      ],
    );
  }
}

class _PiggyTitle extends StatelessWidget {
  const _PiggyTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GameText(context.l10n.piggy,
            fill: const Color(0xFFFFC72E),
            stroke: const Color(0xFF7A4E00),
            fontSize: 46),
        Transform.translate(
          offset: const Offset(0, -10),
          child: _GameText(context.l10n.bankWord,
              fill: Colors.white,
              stroke: const Color(0xFF3A5BC0),
              fontSize: 52),
        ),
      ],
    );
  }
}

class _PiggyProgress extends StatelessWidget {
  const _PiggyProgress({required this.value, required this.cap});
  final int value;
  final int cap;

  @override
  Widget build(BuildContext context) {
    final frac = (value / cap).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Milestone labels.
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Milestone(label: '2500'),
                SizedBox(width: 36),
                _Milestone(label: '3500'),
              ],
            ),
          ),
          Row(
            children: [
              const CoinIcon(size: 30),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: GameColors.purpleDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: frac == 0 ? 0.02 : frac,
                        child: Container(
                          decoration: BoxDecoration(
                            color: GameColors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$value',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CoinIcon(size: 18),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

/// The "!" tutorial overlay: beat levels → fill piggy → unlock rewards. The
/// steps slide in one-by-one, the icons gently bob, and animated gold chevrons
/// "flow" downward between each step.
class _PiggyInfo extends StatefulWidget {
  const _PiggyInfo();

  @override
  State<_PiggyInfo> createState() => _PiggyInfoState();
}

class _PiggyInfoState extends State<_PiggyInfo>
    with TickerProviderStateMixin {
  // One-shot staggered entrance.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  // Looping idle life: bobbing icons, marching chevrons, pulsing prompt.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Entrance(anim: _intro, order: 0, child: const _PiggyTitle()),
            const SizedBox(height: 28),
            _Entrance(
              anim: _intro,
              order: 1,
              child: _InfoStep(
                icon: const Text('🎯', style: TextStyle(fontSize: 52)),
                label: context.l10n.beatLevels,
                loop: _loop,
                phase: 0.0,
              ),
            ),
            _Entrance(anim: _intro, order: 2, child: _FlowArrow(loop: _loop)),
            _Entrance(
              anim: _intro,
              order: 3,
              child: _InfoStep(
                icon: const AppImage(
                  AppImages.piggyBank,
                  size: 66,
                  fallback: Text('🐷', style: TextStyle(fontSize: 52)),
                ),
                label: context.l10n.fillPiggy,
                loop: _loop,
                phase: 0.33,
              ),
            ),
            _Entrance(anim: _intro, order: 4, child: _FlowArrow(loop: _loop)),
            _Entrance(
              anim: _intro,
              order: 5,
              child: _InfoStep(
                icon: const AppImage(
                  AppImages.offerSpecial,
                  size: 62,
                  fallback: Text('💰', style: TextStyle(fontSize: 52)),
                ),
                label: context.l10n.unlockRewards,
                loop: _loop,
                phase: 0.66,
              ),
            ),
            const SizedBox(height: 28),
            _Entrance(
              anim: _intro,
              order: 6,
              child: Text(context.l10n.breakPiggyToCollect,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 16),
            _PulseText(loop: _loop, text: context.l10n.tapToContinue),
          ],
        ),
      ),
    );
  }
}

/// Fades + slides its [child] up, on a delay derived from [order].
class _Entrance extends StatelessWidget {
  const _Entrance({
    required this.anim,
    required this.order,
    required this.child,
  });
  final Animation<double> anim;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (order * 0.1).clamp(0.0, 0.7);
    final curved = CurvedAnimation(
      parent: anim,
      curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final v = curved.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 26 * (1 - v)), child: child),
        );
      },
      child: child,
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({
    required this.icon,
    required this.label,
    required this.loop,
    this.phase = 0,
  });
  final Widget icon;
  final String label;
  final Animation<double> loop;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 62,
          height: 62,
          child: Center(
            child: AnimatedBuilder(
              animation: loop,
              builder: (context, child) {
                final bob = math.sin((loop.value + phase) * math.pi * 2) * 4;
                return Transform.translate(offset: Offset(0, bob), child: child);
              },
              child: icon,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

/// Three gold chevrons that "flow" downward to link the steps — a bright
/// highlight marches through them so the progression always feels alive.
class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.loop});
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) _chevron(i),
            ],
          );
        },
      ),
    );
  }

  Widget _chevron(int i) {
    // A smooth wave travelling 0→1→2 (wrapping) brightens each chevron in turn.
    final pos = loop.value * 3;
    final d = (pos - i).abs();
    final wrapped = math.min(d, 3 - d);
    final bright = (1.0 - wrapped).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(0, -i * 6.0), // overlap into a connected arrow
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 30 + bright * 8,
        color: GameColors.star.withValues(alpha: 0.3 + 0.7 * bright),
      ),
    );
  }
}

/// Text that gently breathes (scale pulse) to draw the eye.
class _PulseText extends StatelessWidget {
  const _PulseText({required this.loop, required this.text});
  final Animation<double> loop;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final s = 1 + 0.06 * math.sin(loop.value * math.pi * 2);
        return Transform.scale(scale: s, child: child);
      },
      child: Text(text,
          style: const TextStyle(
              color: GameColors.star,
              fontSize: 21,
              fontWeight: FontWeight.w900)),
    );
  }
}
