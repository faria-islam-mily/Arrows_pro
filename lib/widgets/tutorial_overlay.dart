import 'package:flutter/material.dart';

import '../state/app_scope.dart';

/// First-level coach. It is NON-blocking (taps pass straight through to the
/// board) and purely visual: a "Tap the glowing arrow" bubble plus a premium
/// animated finger doing a tap gesture. The game removes it only once the
/// player actually clears an arrow — so it can't be dismissed by a stray tap.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Instruction bubble, gently bobbing near the top.
            Align(
              alignment: const Alignment(0, -0.45),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -4 + 4 * (_c.value)),
                  child: child,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'Tap the glowing arrow to slide it off!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            // Animated tapping finger + ripple, centred a little low.
            Align(
              alignment: const Alignment(0, 0.12),
              child: SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: _TapFingerPainter(_c.value),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a tapping finger: it presses down, a ripple ring expands from the
/// touch point, then it lifts — looping.
class _TapFingerPainter extends CustomPainter {
  _TapFingerPainter(this.t);
  final double t;

  double _seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);

    // Press: down in [0,0.28], up in [0.28,0.55], hold otherwise.
    final press = t < 0.28
        ? Curves.easeIn.transform(_seg(0.0, 0.28))
        : (t < 0.55 ? 1 - Curves.easeOut.transform(_seg(0.28, 0.55)) : 0.0);
    final touch = c + Offset(0, press * 12);

    // Ripple ring fires as the finger lands.
    final rp = _seg(0.22, 0.62);
    if (rp > 0 && rp < 1) {
      canvas.drawCircle(
        touch,
        8 + rp * 26,
        Paint()
          ..color = const Color(0xFFFFC83D).withValues(alpha: (1 - rp) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // The finger (a rounded pointer) with a soft shadow.
    final tip = touch;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(tip + const Offset(2, 5), 16, shadow);

    // Pointing-hand glyph drawn via TextPainter (uses the Material icon font).
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.touch_app_rounded.codePoint),
        style: TextStyle(
          fontSize: 54 * (1 - press * 0.08),
          fontFamily: Icons.touch_app_rounded.fontFamily,
          package: Icons.touch_app_rounded.fontPackage,
          color: const Color(0xFFF5EFE6),
          shadows: const [Shadow(color: Colors.black54, blurRadius: 5)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, tip - Offset(tp.width / 2, tp.height * 0.18));
  }

  @override
  bool shouldRepaint(covariant _TapFingerPainter old) => old.t != t;
}
