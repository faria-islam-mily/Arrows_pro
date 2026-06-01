import 'dart:math';

import 'package:flutter/material.dart';

/// A one-shot confetti burst that rains colourful pieces down the screen, then
/// removes itself. Drop it into a [Stack] (e.g. `Positioned.fill`) when a level
/// is cleared. Pure Flutter — no packages.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.pieceCount = 90,
    this.duration = const Duration(milliseconds: 2200),
    this.onComplete,
  });

  final int pieceCount;
  final Duration duration;
  final VoidCallback? onComplete;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Piece> _pieces;
  final _rng = Random();

  static const _colors = [
    Color(0xFFE63946),
    Color(0xFFF4A261),
    Color(0xFF2A9D8F),
    Color(0xFF457B9D),
    Color(0xFFE9C46A),
    Color(0xFF7B7BF0),
    Color(0xFFEF476F),
  ];

  @override
  void initState() {
    super.initState();
    _pieces = List.generate(widget.pieceCount, (_) {
      return _Piece(
        x: _rng.nextDouble(),
        startY: -_rng.nextDouble() * 0.25,
        fallSpeed: 0.7 + _rng.nextDouble() * 0.6,
        drift: (_rng.nextDouble() - 0.5) * 0.4,
        size: 6 + _rng.nextDouble() * 8,
        color: _colors[_rng.nextInt(_colors.length)],
        spin: (_rng.nextDouble() - 0.5) * 12,
        phase: _rng.nextDouble() * pi * 2,
      );
    });
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}))
      ..forward().whenComplete(() => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_pieces, _ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.startY,
    required this.fallSpeed,
    required this.drift,
    required this.size,
    required this.color,
    required this.spin,
    required this.phase,
  });

  final double x; // 0..1 horizontal start
  final double startY; // 0..-0.25 (just above screen)
  final double fallSpeed;
  final double drift;
  final double size;
  final Color color;
  final double spin;
  final double phase;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1.0 - (t - 0.7) / 0.3).clamp(0.0, 1.0); // fade out near end
    for (final p in pieces) {
      final y = (p.startY + p.fallSpeed * t) * size.height;
      if (y < -20 || y > size.height + 20) continue;
      final x = (p.x + p.drift * t + 0.02 * sin(p.phase + t * 10)) * size.width;
      final angle = p.phase + p.spin * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}