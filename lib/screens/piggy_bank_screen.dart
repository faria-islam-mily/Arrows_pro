import 'package:flutter/material.dart';

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
                  child: const Text(
                    'BREAK',
                    style: TextStyle(
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
        const _GameText('PIGGY',
            fill: Color(0xFFFFC72E),
            stroke: Color(0xFF7A4E00),
            fontSize: 46),
        Transform.translate(
          offset: const Offset(0, -10),
          child: const _GameText('BANK',
              fill: Colors.white,
              stroke: Color(0xFF3A5BC0),
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

/// The "!" tutorial overlay: beat levels → fill piggy → unlock rewards, with
/// curved gold arrows linking the steps.
class _PiggyInfo extends StatelessWidget {
  const _PiggyInfo();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PiggyTitle(),
            SizedBox(height: 28),
            _InfoStep(
              icon: Text('🎯', style: TextStyle(fontSize: 52)),
              label: 'Beat Levels!',
            ),
            _CurveArrow(),
            _InfoStep(
              icon: AppImage(
                AppImages.piggyBank,
                size: 66,
                fallback: Text('🐷', style: TextStyle(fontSize: 52)),
              ),
              label: 'Fill Piggy!',
            ),
            _CurveArrow(flip: true),
            _InfoStep(
              icon: AppImage(
                AppImages.offerSpecial,
                size: 62,
                fallback: Text('💰', style: TextStyle(fontSize: 52)),
              ),
              label: 'Unlock Rewards!',
            ),
            SizedBox(height: 28),
            Text('Break Piggy to collect coins!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 16),
            Text('Tap to Continue',
                style: TextStyle(
                    color: GameColors.star,
                    fontSize: 21,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({required this.icon, required this.label});
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 62, height: 62, child: Center(child: icon)),
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

/// A curved gold arrow linking two tutorial steps. [flip] mirrors it.
class _CurveArrow extends StatelessWidget {
  const _CurveArrow({this.flip = false});
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(flip ? -1.0 : 1.0, 1.0, 1.0),
        child: const SizedBox(
          width: 90,
          height: 46,
          child: CustomPaint(painter: _ArrowPainter()),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // A bold curved hook (cubic Bézier).
    final p0 = Offset(w * 0.18, h * 0.08);
    final p1 = Offset(w * 0.74, h * -0.04);
    final p2 = Offset(w * 0.94, h * 0.46);
    final p3 = Offset(w * 0.56, h * 0.80); // arrow tip

    final stroke = Paint()
      ..color = GameColors.star
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy),
      stroke,
    );

    // Filled triangular arrowhead, oriented along the end tangent (p3 - p2).
    var dir = p3 - p2;
    final len = dir.distance == 0 ? 1.0 : dir.distance;
    dir = Offset(dir.dx / len, dir.dy / len);
    final perp = Offset(-dir.dy, dir.dx);
    const headLen = 20.0, headW = 13.0;
    final base = p3 - dir * headLen;
    final fill = Paint()
      ..color = GameColors.star
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(p3.dx, p3.dy)
        ..lineTo(base.dx + perp.dx * headW, base.dy + perp.dy * headW)
        ..lineTo(base.dx - perp.dx * headW, base.dy - perp.dy * headW)
        ..close(),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => false;
}
