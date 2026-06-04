import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-screen "PROCESSING" spinner shown during a purchase / store round-trip.
/// Show it with [showProcessing] and dismiss with [hideProcessing].
void showProcessing(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    useRootNavigator: true,
    builder: (_) => const ProcessingOverlay(),
  );
}

void hideProcessing(BuildContext context) {
  Navigator.of(context, rootNavigator: true).maybePop();
}

class ProcessingOverlay extends StatefulWidget {
  const ProcessingOverlay({super.key});

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) =>
                  CustomPaint(painter: _SpinnerPainter(_c.value)),
            ),
            const Text(
              'PROCESSING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two green arcs sweeping around — matches the store's processing spinner.
class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width * 0.42;
    final rect = Rect.fromCircle(center: center, radius: r);
    final paint = Paint()
      ..color = const Color(0xFF2EA843)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final base = t * 2 * math.pi;
    const sweep = 1.9; // ~110°
    canvas.drawArc(rect, base, sweep, false, paint);
    canvas.drawArc(rect, base + math.pi, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter old) => old.t != t;
}
