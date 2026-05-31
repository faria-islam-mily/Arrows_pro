import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import 'home_screen.dart';

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
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _logo = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _text = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 2800), _go);
  }

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeScreen(),
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
                child: FadeTransition(opacity: _logo, child: const _Logo()),
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

/// A small branded logo: a white rounded card with three colored arrows.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    void arrow(Offset a, Offset b, Color color) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.075
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawLine(a, b, p);
      final dir = (b - a) / (b - a).distance;
      final perp = Offset(-dir.dy, dir.dx);
      final tip = b + dir * (s * 0.02);
      final base = b - dir * (s * 0.07);
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo((base + perp * s * 0.06).dx, (base + perp * s * 0.06).dy)
        ..lineTo((base - perp * s * 0.06).dx, (base - perp * s * 0.06).dy)
        ..close();
      canvas.drawPath(head, Paint()..color = color);
    }

    // navy (up), blue (up), red (right) — echoes the genre's icon style.
    arrow(Offset(s * 0.34, s * 0.74), Offset(s * 0.34, s * 0.28),
        const Color(0xFF14243A));
    arrow(Offset(s * 0.56, s * 0.78), Offset(s * 0.56, s * 0.30),
        const Color(0xFF2D6CDF));
    arrow(Offset(s * 0.28, s * 0.58), Offset(s * 0.74, s * 0.58),
        const Color(0xFFE63946));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
