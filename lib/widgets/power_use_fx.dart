import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/power_up.dart';
import 'app_image.dart';

/// A short, non-blocking "power activated" flourish: the power's 3D icon pops
/// out of the button it was tapped, arcs up toward the board, grows, and bursts
/// a glowing ring + sparkles before fading. Calls [onDone] when finished.
class PowerUseFxOverlay extends StatefulWidget {
  const PowerUseFxOverlay({
    super.key,
    required this.power,
    required this.from,
    required this.onDone,
  });

  final PowerUp power;
  final Offset from; // global position the icon launches from (button centre)
  final VoidCallback onDone;

  @override
  State<PowerUseFxOverlay> createState() => _PowerUseFxOverlayState();
}

class _PowerUseFxOverlayState extends State<PowerUseFxOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const Color _glow = Color(0xFFFFE066);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final target = Offset(size.width / 2, size.height * 0.40);
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final p = Curves.easeOutCubic.transform(t);
            final pos = Offset.lerp(widget.from, target, p)!;
            final lift = math.sin(p * math.pi) * 46; // arc up
            final at = Offset(pos.dx, pos.dy - lift);
            final scale = 0.55 + 1.25 * Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
            final op = t < 0.12
                ? t / 0.12
                : (t > 0.72 ? (1 - (t - 0.72) / 0.28).clamp(0.0, 1.0) : 1.0);
            final ringT = ((t - 0.45) / 0.55).clamp(0.0, 1.0);

            return Stack(
              children: [
                // Burst ring at the target.
                if (ringT > 0)
                  Positioned(
                    left: target.dx - 90,
                    top: target.dy - 90,
                    child: CustomPaint(
                      size: const Size(180, 180),
                      painter: _RingPainter(ringT, _glow),
                    ),
                  ),
                // Flying glowing icon.
                Positioned(
                  left: at.dx - 56,
                  top: at.dy - 56,
                  child: Opacity(
                    opacity: op.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  _glow.withValues(alpha: 0.55),
                                  _glow.withValues(alpha: 0.0),
                                ]),
                              ),
                              child: const SizedBox(width: 112, height: 112),
                            ),
                            PowerIcon(widget.power, size: 72),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color);
  final double t; // 0..1
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = 14 + 76 * t;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * (1 - t) + 1
      ..color = color.withValues(alpha: (1 - t) * 0.9);
    canvas.drawCircle(c, r, paint);
    // A few sparkles flying outward.
    final spark = Paint()..color = color.withValues(alpha: (1 - t));
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final rr = 18 + 70 * t;
      canvas.drawCircle(
          c + Offset(math.cos(a) * rr, math.sin(a) * rr), 3 * (1 - t) + 0.5, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.t != t;
}
