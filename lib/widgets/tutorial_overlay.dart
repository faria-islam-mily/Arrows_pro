import 'package:flutter/material.dart';

import '../data/palettes.dart';
import '../state/app_scope.dart';

/// A one-time animated coach overlay that teaches the core rule. It lives inside
/// an opaque card (so the puzzle behind never clashes with the demo): a "Tap an
/// arrow" bubble over a small inset board where a hand moves in, taps, and an
/// arrow slides off — looping. Gate on `AppState.tutorialSeen`; tapping anywhere
/// dismisses it and marks the tutorial as seen.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

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
      duration: const Duration(milliseconds: 2400),
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Bubble(text: 'Tap an arrow', palette: palette),
                const SizedBox(height: 4),
                CustomPaint(
                  size: const Size(20, 11),
                  painter: _TailPainter(color: palette.background),
                ),
                const SizedBox(height: 16),
                // Inset mini-board so the demo reads as its own little puzzle.
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 236,
                    height: 168,
                    color: palette.background,
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) {
                        final t = _c.value;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DemoPainter(
                                  t: t,
                                  color: palette.arrow,
                                  highlight: palette.arrowActive,
                                ),
                              ),
                            ),
                            _hand(t),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Slide every arrow off the board.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.arrow,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap anywhere to start',
                  style: TextStyle(color: palette.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The finger, positioned and pressed along the loop. Its fingertip (top of
  // the icon) is aimed at the target arrow's shaft.
  Widget _hand(double t) {
    const start = Offset(196, 132);
    const press = Offset(170, 64);
    final approach = Curves.easeInOut.transform(_seg(t, 0.0, 0.36));
    final back = Curves.easeInOut.transform(_seg(t, 0.82, 1.0));
    final tip = Offset.lerp(Offset.lerp(start, press, approach)!, start, back)!;
    final dip = _seg(t, 0.36, 0.46) - _seg(t, 0.46, 0.56);
    final scale = 1.0 - 0.16 * dip;

    return Positioned(
      left: tip.dx - 22,
      top: tip.dy - 6,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Icon(
          Icons.touch_app,
          size: 48,
          color: const Color(0xFFF5EFE6),
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

double _seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

/// Rounded speech bubble (drawn in the board tone so it pops on the card).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: palette.accent,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The little triangle tail under the bubble.
class _TailPainter extends CustomPainter {
  _TailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) => old.color != color;
}

/// Draws three demo arrows; the right-hand one is "tapped" and slides down off
/// the board, then fades back — driven by [t] (0..1, looping).
class _DemoPainter extends CustomPainter {
  _DemoPainter({required this.t, required this.color, required this.highlight});

  final double t;
  final Color color;
  final Color highlight;

  static const _stroke = 8.0;

  void _arrow(Canvas canvas, List<Offset> pts, Offset dir, Color col,
      double opacity) {
    final paint = Paint()
      ..color = col.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);

    final head = pts.last;
    final perp = Offset(-dir.dy, dir.dx);
    final apex = head + dir * 15;
    final base = head - dir * 2;
    final tri = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(base.dx + perp.dx * 9, base.dy + perp.dy * 9)
      ..lineTo(base.dx - perp.dx * 9, base.dy - perp.dy * 9)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..color = col.withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Two static context arrows on the left.
    _arrow(canvas, [const Offset(52, 116), const Offset(52, 50)],
        const Offset(0, -1), color, 1);
    _arrow(
        canvas,
        [const Offset(100, 116), const Offset(100, 62), const Offset(132, 62)],
        const Offset(1, 0),
        color,
        1);

    // Target down-arrow: pulses gold as the hand arrives, then slides off.
    final slide =
        t >= 0.78 ? 0.0 : Curves.easeIn.transform(_seg(t, 0.46, 0.78)) * 90;
    final double opacity;
    if (t < 0.46) {
      opacity = 1;
    } else if (t < 0.78) {
      opacity = 1 - _seg(t, 0.46, 0.78);
    } else if (t < 0.9) {
      opacity = 0;
    } else {
      opacity = _seg(t, 0.9, 1.0);
    }
    final hot = (_seg(t, 0.28, 0.44) * (1 - _seg(t, 0.44, 0.5))).clamp(0.0, 1.0);
    final col = Color.lerp(color, highlight, hot)!;
    _arrow(
      canvas,
      [Offset(170, 40 + slide), Offset(170, 98 + slide)],
      const Offset(0, 1),
      col,
      opacity,
    );

    // Tap ripple at the press point.
    final rp = _seg(t, 0.4, 0.64);
    if (rp > 0 && rp < 1) {
      canvas.drawCircle(
        const Offset(170, 68),
        6 + rp * 20,
        Paint()
          ..color = highlight.withValues(alpha: (1 - rp) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DemoPainter old) => old.t != t;
}
