import 'dart:math';

import 'package:flutter/material.dart';

import '../models/grid_arrow.dart';

/// A small static rendering of a level's full arrow layout — used on the
/// level-complete screen to "reveal" the picture the player just cleared.
class LevelThumbnail extends StatelessWidget {
  const LevelThumbnail({
    super.key,
    required this.arrows,
    required this.rows,
    required this.cols,
    required this.color,
    this.size = 200,
  });

  final List<GridArrow> arrows;
  final int rows;
  final int cols;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ThumbPainter(arrows, rows, cols, color),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.arrows, this.rows, this.cols, this.color);

  final List<GridArrow> arrows;
  final int rows;
  final int cols;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = min(size.width / cols, size.height / rows);
    final ox = (size.width - cell * cols) / 2;
    final oy = (size.height - cell * rows) / 2;
    Offset c(Point<int> p) =>
        Offset(ox + (p.x + 0.5) * cell, oy + (p.y + 0.5) * cell);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final a in arrows) {
      final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
      final pts = a.cells.map(c).toList();

      final shaft = Path();
      if (pts.length == 1) {
        final tail = pts.first - dir * (cell * 0.34);
        shaft.moveTo(tail.dx, tail.dy);
        shaft.lineTo(pts.first.dx, pts.first.dy);
      } else {
        shaft.moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts.skip(1)) {
          shaft.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(shaft, stroke);

      final head = pts.last;
      final perp = Offset(-dir.dy, dir.dx);
      final apex = head + dir * (cell * 0.34);
      final base = head - dir * (cell * 0.04);
      canvas.drawPath(
        Path()
          ..moveTo(apex.dx, apex.dy)
          ..lineTo((base + perp * cell * 0.18).dx,
              (base + perp * cell * 0.18).dy)
          ..lineTo((base - perp * cell * 0.18).dx,
              (base - perp * cell * 0.18).dy)
          ..close(),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) =>
      old.arrows != arrows || old.color != color;
}
