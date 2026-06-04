import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/power_up.dart';
import '../state/app_scope.dart';

/// Premium "new power unlocked" overlay shown the first time a power is
/// introduced. It pops in, shows the power's glowing badge, a one-liner, and a
/// looping mini-demo that ANIMATES what the power actually does. "Got it" grants
/// the first one (handled by the caller).
class PowerIntroOverlay extends StatefulWidget {
  const PowerIntroOverlay({
    super.key,
    required this.power,
    required this.onDismiss,
  });

  final PowerUp power;
  final VoidCallback onDismiss;

  @override
  State<PowerIntroOverlay> createState() => _PowerIntroOverlayState();
}

class _PowerIntroOverlayState extends State<PowerIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop; // drives the mini-demo

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  ({List<Color> colors, IconData icon, String tagline}) get _info {
    switch (widget.power) {
      case PowerUp.hint:
        return (
          colors: const [Color(0xFFFFD23F), Color(0xFFF4A100)],
          icon: Icons.lightbulb_rounded,
          tagline: 'Reveals an arrow you can move right now.',
        );
      case PowerUp.undo:
        return (
          colors: const [Color(0xFF36C58E), Color(0xFF1E9E8A)],
          icon: Icons.undo_rounded,
          tagline: 'Took a wrong turn? Take back your last move.',
        );
      case PowerUp.eraser:
        return (
          colors: const [Color(0xFFFF7A7A), Color(0xFFEE4B4B)],
          icon: Icons.cleaning_services_rounded,
          tagline: 'Force-remove ANY arrow — even a blocked one.',
        );
      case PowerUp.magic:
        return (
          colors: const [Color(0xFF8E8EF6), Color(0xFF4E5DF2)],
          icon: Icons.auto_awesome_rounded,
          tagline: 'Instantly slides a movable arrow off the board.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final info = _info;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // block taps to the board behind
        onTap: () {},
        child: Container(
          color: Colors.black.withValues(alpha: 0.72),
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.8, end: 1.0),
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEW POWER',
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Glowing badge.
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: info.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: info.colors.last.withValues(alpha: 0.55),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(info.icon, color: Colors.white, size: 46),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.power.label,
                    style: TextStyle(
                      color: palette.arrow,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Looping mini-demo of the effect.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 220,
                      height: 116,
                      color: palette.background,
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (context, _) => CustomPaint(
                          painter: _PowerDemoPainter(
                            power: widget.power,
                            t: _loop.value,
                            color: palette.arrow,
                            accent: info.colors.first,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _GotItButton(
                      colors: info.colors,
                      onTap: widget.onDismiss,
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

class _GotItButton extends StatelessWidget {
  const _GotItButton({required this.colors, required this.onTap});
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors.last, offset: const Offset(0, 4)),
          BoxShadow(
            color: colors.last.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: const Center(
            child: Text(
              'Got it!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws three up-arrows; the middle one demonstrates the power's effect,
/// looping with [t] (0..1).
class _PowerDemoPainter extends CustomPainter {
  _PowerDemoPainter({
    required this.power,
    required this.t,
    required this.color,
    required this.accent,
  });

  final PowerUp power;
  final double t;
  final Color color;
  final Color accent;

  double _seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  void _arrow(Canvas canvas, double x, double yBottom, double height, Color col,
      {double opacity = 1, double scale = 1}) {
    final top = yBottom - height;
    canvas.drawLine(
      Offset(x, yBottom),
      Offset(x, top + 9 * scale),
      Paint()
        ..color = col.withValues(alpha: opacity)
        ..strokeWidth = 6 * scale
        ..strokeCap = StrokeCap.round,
    );
    final head = Path()
      ..moveTo(x, top)
      ..lineTo(x - 9 * scale, top + 12 * scale)
      ..lineTo(x + 9 * scale, top + 12 * scale)
      ..close();
    canvas.drawPath(head, Paint()..color = col.withValues(alpha: opacity));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final yB = size.height - 22.0;
    const h = 64.0;
    const gap = 46.0;

    // Side arrows (static context).
    _arrow(canvas, cx - gap, yB, h, color);
    _arrow(canvas, cx + gap, yB, h, color);

    switch (power) {
      case PowerUp.hint:
        // Middle arrow pulses bright + a glow ring.
        final pulse = 0.5 + 0.5 * math.cos(t * math.pi * 2);
        final col = Color.lerp(color, accent, pulse)!;
        canvas.drawCircle(
          Offset(cx, yB - h / 2),
          18 + pulse * 14,
          Paint()
            ..color = accent.withValues(alpha: pulse * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        _arrow(canvas, cx, yB, h, col, scale: 1 + pulse * 0.12);

      case PowerUp.undo:
        // Slides up and out, then comes back — "take it back".
        final out = _seg(0.0, 0.42);
        final back = _seg(0.58, 1.0);
        final lift = (out - back) * (h + 26); // up then return
        final op = (1 - out + back).clamp(0.0, 1.0);
        _arrow(canvas, cx, yB - lift, h, color, opacity: op);

      case PowerUp.eraser:
        // Blocked (red), then "poof" away with a ring, then reappears.
        final poof = _seg(0.32, 0.6);
        final back = _seg(0.78, 1.0);
        final scale = (1 - poof) + back; // shrink to 0, then grow back
        if (poof > 0 && poof < 1) {
          canvas.drawCircle(
            Offset(cx, yB - h / 2),
            10 + poof * 26,
            Paint()
              ..color = accent.withValues(alpha: (1 - poof) * 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
        final op = (poof < 1 ? 1 - poof : 0.0) + back;
        if (scale > 0.02) {
          _arrow(canvas, cx, yB, h, accent,
              opacity: op.clamp(0.0, 1.0), scale: scale.clamp(0.0, 1.0));
        }

      case PowerUp.magic:
        // Auto-slides off (with a sparkle), then reappears.
        final out = _seg(0.0, 0.5);
        final back = _seg(0.72, 1.0);
        final lift = out * (h + 30);
        final op = (1 - out).clamp(0.0, 1.0);
        if (op > 0.02) _arrow(canvas, cx, yB - lift, h, color, opacity: op);
        if (back > 0) _arrow(canvas, cx, yB, h, color, opacity: back);
        // sparkle near the head as it leaves
        if (out > 0.1 && out < 0.95) {
          final s = (math.sin(t * math.pi * 6) * 0.5 + 0.5);
          canvas.drawCircle(
            Offset(cx + 12, yB - lift - h),
            2 + s * 3,
            Paint()..color = accent.withValues(alpha: (1 - out) * 0.9),
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _PowerDemoPainter old) =>
      old.t != t || old.power != power;
}
