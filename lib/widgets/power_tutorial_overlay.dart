import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/power_up.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'ui_kit.dart';

/// Teaches the player to USE a just-unlocked power. Spotlights the power button
/// (dimming everything else), shows a coach card, and bounces a tapping hand on
/// it. Purely a visual guide (IgnorePointer) — the game stays interactive, so
/// it auto-dismisses the moment the player taps the highlighted power.
class PowerTutorialOverlay extends StatefulWidget {
  const PowerTutorialOverlay({
    super.key,
    required this.power,
    required this.targetKey,
    required this.onSkip,
  });

  final PowerUp power;
  final GlobalKey targetKey;
  final VoidCallback onSkip;

  @override
  State<PowerTutorialOverlay> createState() => _PowerTutorialOverlayState();
}

class _PowerTutorialOverlayState extends State<PowerTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // The target tile is laid out a frame after we appear — recompute then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Rect? _targetRect() {
    final box = widget.targetKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned.fill(
      child: Stack(
        children: [
          // Visual guide — never intercepts taps, so the player can use the
          // power right through it (which dismisses the tutorial).
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final rect = _targetRect();
                  final t = _c.value;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _SpotlightPainter(rect, t)),
                      ),
                      Positioned(
                        top: topInset + 54,
                        left: 18,
                        right: 18,
                        child: _CoachCard(power: widget.power),
                      ),
                      if (rect != null) _hand(rect, t),
                    ],
                  );
                },
              ),
            ),
          ),
          // Skip button (tappable).
          Positioned(
            top: topInset + 6,
            right: 12,
            child: ChunkyCircleButton(
              icon: Icons.close_rounded,
              color: GameColors.red,
              size: 38,
              onTap: widget.onSkip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hand(Rect rect, double t) {
    // A tapping cycle: hover, then press down + shrink, then release.
    final press = (math.sin(t * math.pi * 2) * 0.5 + 0.5); // 0..1
    return Positioned(
      left: rect.center.dx - 6,
      top: rect.center.dy - 10 + press * 8,
      child: Transform.scale(
        scale: 1.0 - press * 0.12,
        child: const Icon(
          Icons.touch_app_rounded,
          size: 52,
          color: Colors.white,
          shadows: [
            Shadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.power});
  final PowerUp power;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xF21B2336),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          PowerIcon(power, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.powerName(power),
                  style: const TextStyle(
                    color: Color(0xFFFFD23F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.powerTutorial(power),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims the whole screen except a rounded "spotlight" hole around [rect], with
/// a soft pulsing green ring to draw the eye to the power button.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.rect, this.t);
  final Rect? rect;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xC20A0F1A);
    if (rect == null) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }
    final hole = rect!.inflate(8);
    final rr = RRect.fromRectAndRadius(hole, const Radius.circular(18));
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rr)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);

    // Pulsing glow ring around the cutout.
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = GameColors.green.withValues(alpha: 0.5 + 0.4 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 3 * pulse),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.t != t || old.rect != rect;
}
