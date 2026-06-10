import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A big "LEVEL N" reveal that swooshes across the screen when a level opens —
/// it slides in from the left, holds centre (with a gentle breathe), then exits
/// to the right. Non-blocking; calls [onDone] when finished so the board's
/// arrow cascade can take over.
class LevelIntroBanner extends StatefulWidget {
  const LevelIntroBanner({
    super.key,
    required this.label,
    required this.onDone,
  });

  final String label; // e.g. "LEVEL 7" or "DAILY"
  final VoidCallback onDone;

  @override
  State<LevelIntroBanner> createState() => _LevelIntroBannerState();
}

class _LevelIntroBannerState extends State<LevelIntroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            double dx, op, scale;
            if (t < 0.2) {
              final u = t / 0.2; // enter from the left
              dx = (-1 + Curves.easeOutCubic.transform(u)) * w;
              op = u;
              scale = 0.9 + 0.1 * u;
            } else if (t < 0.62) {
              dx = 0; // hold, with a tiny breathe
              op = 1;
              scale = 1 + 0.02 * math.sin((t - 0.2) / 0.42 * math.pi);
            } else {
              final u = (t - 0.62) / 0.38; // exit to the right
              dx = Curves.easeInCubic.transform(u) * w;
              op = 1 - u;
              scale = 1;
            }
            return Center(
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Opacity(
                  opacity: op.clamp(0.0, 1.0),
                  child: Transform.scale(scale: scale, child: child),
                ),
              ),
            );
          },
          child: _Band(label: widget.label),
        ),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.55),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
        border: const Border(
          top: BorderSide(color: Color(0x66FFD23F), width: 2),
          bottom: BorderSide(color: Color(0x66FFD23F), width: 2),
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outline.
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 9
                  ..strokeJoin = StrokeJoin.round
                  ..color = const Color(0xFFB5761F),
              ),
            ),
            // Fill.
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Color(0xFFFFD23F),
                shadows: [
                  Shadow(color: Color(0x99000000), offset: Offset(0, 4))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
