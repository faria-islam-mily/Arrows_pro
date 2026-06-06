import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/power_up.dart';
import '../theme/game_colors.dart';
import 'app_image.dart';
import 'ui_kit.dart';

/// Premium "power unlocked" reveal shown the first time a power is introduced.
/// A spotlit 3D icon floats in over a dimmed board with a pulsing glow and
/// twinkling sparkles; a chunky CLAIM button grants the first one.
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
    with TickerProviderStateMixin {
  late final AnimationController _loop; // idle: bob, glow, sparkles, pulse
  late final AnimationController _intro; // one-shot entrance

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
  }

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  /// Warm spotlight tint, lightly varied per power.
  Color get _glow => switch (widget.power) {
        PowerUp.hint => const Color(0xFFFFD23F),
        PowerUp.eraser => const Color(0xFFFF8AC4),
        PowerUp.magic => const Color(0xFFFFE066),
        PowerUp.undo => const Color(0xFF49E0C0),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // block taps to the board behind
        onTap: () {},
        child: Stack(
          children: [
            // Dimming gradient scrim (the colourful board shows faintly).
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xF20E1626), Color(0xFA0A0F1A)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    // Title + UNLOCKED!, sliding in from above.
                    _entrance(
                      slide: -26,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _OutlinedTitle(l10n.powerName(widget.power)),
                          const SizedBox(height: 4),
                          Text(
                            l10n.unlocked,
                            style: const TextStyle(
                              color: Color(0xFF6FB2FF),
                              fontSize: 26,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                    color: Color(0x99000000),
                                    offset: Offset(0, 2))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    _iconBlock(),
                    const Spacer(flex: 2),
                    _entrance(
                      slide: 20,
                      child: Text(
                        l10n.powerDesc(widget.power),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(color: Color(0x99000000), offset: Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    _claimButton(),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fades + slides [child] in on the entrance controller.
  Widget _entrance({required double slide, required Widget child}) {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, child) {
        final v = Curves.easeOut.transform(_intro.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, slide * (1 - v)), child: child),
        );
      },
      child: child,
    );
  }

  Widget _iconBlock() {
    return AnimatedBuilder(
      animation: Listenable.merge([_loop, _intro]),
      builder: (context, _) {
        final t = _loop.value;
        final bob = math.sin(t * math.pi * 2) * 9;
        final wob = math.sin(t * math.pi * 2) * 0.05;
        final glowPulse = 0.85 + 0.15 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
        final pop = Curves.easeOutBack.transform(_intro.value);
        return SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing radial spotlight.
              Transform.scale(
                scale: glowPulse * pop.clamp(0.0, 1.0),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _glow.withValues(alpha: 0.55),
                        _glow.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              ..._sparkles(t, pop),
              // The floating 3D icon.
              Transform.translate(
                offset: Offset(0, bob),
                child: Transform.rotate(
                  angle: wob,
                  child: Transform.scale(
                    scale: pop.clamp(0.0, 1.2),
                    child: PowerIcon(widget.power, size: 150),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _sparkles(double t, double pop) {
    const spots = [
      Offset(-110, -80),
      Offset(115, -55),
      Offset(95, 80),
      Offset(-95, 70),
      Offset(0, -120),
    ];
    return [
      for (var i = 0; i < spots.length; i++)
        Transform.translate(
          offset: spots[i] + Offset(0, math.sin(t * math.pi * 2 + i) * 4),
          child: Opacity(
            opacity: (pop *
                    (0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 2 + i * 1.7))))
                .clamp(0.0, 1.0),
            child: Icon(Icons.star_rounded,
                color: _glow.withValues(alpha: 0.95),
                size: 14 + (i.isEven ? 8 : 0)),
          ),
        ),
    ];
  }

  Widget _claimButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_loop, _intro]),
      builder: (context, child) {
        final pulse = 1 + 0.03 * math.sin(_loop.value * math.pi * 2);
        final inOpacity = Curves.easeOut.transform(_intro.value);
        return Opacity(
          opacity: inOpacity,
          child: Transform.scale(scale: pulse, child: child),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: ChunkyButton(
          color: GameColors.green,
          depth: 8,
          radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 16),
          onTap: widget.onDismiss,
          child: Text(
            context.l10n.claim,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 1,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Color(0x66000000), offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Big cartoon title: a thick-outlined yellow word (matches the promo titles).
class _OutlinedTitle extends StatelessWidget {
  const _OutlinedTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 1.05,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 8
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xFFB5761F),
            )),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: Color(0xFFFFD23F),
              shadows: [Shadow(color: Color(0x55000000), offset: Offset(0, 3))],
            )),
      ],
    );
  }
}
