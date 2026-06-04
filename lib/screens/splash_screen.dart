import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import 'main_scaffold.dart';

/// Animated opening screen: the logo eases in, then a mindful quote fades up,
/// before auto-advancing to Home. Tap anywhere to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _logo;
  late final Animation<double> _text;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _logo = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOutBack),
    );
    _text = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.62, 1.0, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 3100), _go);
  }

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const MainScaffold(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: _go,
      child: Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logo,
                child: FadeTransition(
                  opacity: _logo,
                  child: _Logo(progress: _c),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _text,
                child: const Text(
                  'Arrow Pro',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _text,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      Text(
                        'Clear the arrows,\nclear your mind.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.4,
                          color: palette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '— Arrow Pro',
                        style: TextStyle(
                          fontSize: 15,
                          color: palette.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A branded logo: a white rounded card with three colored arrows that shoot
/// into place head-first (staggered) as the splash opens.
class _Logo extends StatelessWidget {
  const _Logo({required this.progress});

  final Animation<double> progress; // 0..1 splash controller

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFEFF3F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6CDF).withValues(alpha: 0.18),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: CustomPaint(painter: _LogoPainter(progress.value)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.t);

  final double t; // splash controller value 0..1

  double _seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Each arrow is "drawn" head-first: the shaft grows from tail toward head
    // and the arrowhead rides the leading tip, settling at the head at frac=1.
    void arrow(Offset a, Offset b, Color color, double frac) {
      if (frac <= 0) return;
      final dir = (b - a) / (b - a).distance;
      final perp = Offset(-dir.dy, dir.dx);
      final tip = a + (b - a) * frac;

      canvas.drawLine(
        a,
        tip,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.085
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Head pops to full size within the first sliver of the draw.
      final hs = (frac / 0.12).clamp(0.0, 1.0);
      final apex = tip + dir * (s * 0.02 * hs);
      final base = tip - dir * (s * 0.07 * hs);
      final head = Path()
        ..moveTo(apex.dx, apex.dy)
        ..lineTo((base + perp * s * 0.065 * hs).dx,
            (base + perp * s * 0.065 * hs).dy)
        ..lineTo((base - perp * s * 0.065 * hs).dx,
            (base - perp * s * 0.065 * hs).dy)
        ..close();
      canvas.drawPath(head, Paint()..color = color);
    }

    // navy (up), blue (up), red (right) — staggered shoot-in.
    arrow(Offset(s * 0.34, s * 0.74), Offset(s * 0.34, s * 0.28),
        const Color(0xFF14243A), Curves.easeOut.transform(_seg(0.30, 0.58)));
    arrow(Offset(s * 0.56, s * 0.78), Offset(s * 0.56, s * 0.30),
        const Color(0xFF2D6CDF), Curves.easeOut.transform(_seg(0.42, 0.70)));
    arrow(Offset(s * 0.28, s * 0.58), Offset(s * 0.74, s * 0.58),
        const Color(0xFFE63946), Curves.easeOut.transform(_seg(0.56, 0.86)));
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.t != t;
}
