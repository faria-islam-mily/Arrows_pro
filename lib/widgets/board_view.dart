import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../models/grid_arrow.dart';
import '../state/app_scope.dart';

/// Renders the arrow board with thick rounded strokes + arrowheads, handles
/// taps (hit-testing cells), and slides arrows off-board when they escape.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.game,
    required this.hintId,
    required this.onBlocked,
  });

  final GameController game;
  final int? hintId;
  final VoidCallback onBlocked;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> with TickerProviderStateMixin {
  // Arrows currently animating off-board: id -> (arrow, progress 0..1).
  final _exitingArrows = <int, GridArrow>{};
  final _exitProgress = <int, double>{};
  final _controllers = <int, AnimationController>{};

  int? _blockedId; // arrow flashing red after a blocked tap
  Timer? _blockTimer;

  void _handleTapCell(int row, int col) {
    final a = widget.game.arrowAt(row, col);
    if (a == null) return;
    if (widget.game.canExit(a)) {
      widget.game.tap(a); // marks removed + notifies (progress/win)
      _startExit(a);
    } else {
      // Blocked: flash the arrow red and tell the parent to drop a life.
      setState(() => _blockedId = a.id);
      widget.onBlocked();
      _blockTimer?.cancel();
      _blockTimer = Timer(const Duration(milliseconds: 550), () {
        if (mounted) setState(() => _blockedId = null);
      });
    }
  }

  void _startExit(GridArrow a) {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _controllers[a.id] = ctrl;
    _exitingArrows[a.id] = a;
    ctrl.addListener(() => setState(() => _exitProgress[a.id] = ctrl.value));
    ctrl.forward().whenComplete(() {
      ctrl.dispose();
      setState(() {
        _controllers.remove(a.id);
        _exitingArrows.remove(a.id);
        _exitProgress.remove(a.id);
      });
    });
  }

  @override
  void dispose() {
    _blockTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final g = widget.game;

    return LayoutBuilder(
      builder: (ctx, cons) {
        const pad = 24.0;
        final fit = min(
          (cons.maxWidth - pad * 2) / g.cols,
          (cons.maxHeight - pad * 2) / g.rows,
        );
        final cell = min(fit, 44.0);
        // Pad the canvas so edge arrowheads have room and aren't clipped.
        final margin = cell * 0.6;
        final w = cell * g.cols + margin * 2;
        final h = cell * g.rows + margin * 2;

        return Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.6,
            maxScale: 5,
            // Free movement across the whole screen (drag the puzzle anywhere).
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final col = ((d.localPosition.dx - margin) / cell).floor();
                final row = ((d.localPosition.dy - margin) / cell).floor();
                if (row >= 0 && row < g.rows && col >= 0 && col < g.cols) {
                  _handleTapCell(row, col);
                }
              },
              child: CustomPaint(
                size: Size(w, h),
                painter: _BoardPainter(
                  game: g,
                  cell: cell,
                  margin: margin,
                  hintId: widget.hintId,
                  blockedId: _blockedId,
                  color: palette.arrow,
                  hintColor: palette.arrowActive,
                  exitingArrows: _exitingArrows,
                  exitProgress: _exitProgress,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.game,
    required this.cell,
    required this.margin,
    required this.hintId,
    required this.blockedId,
    required this.color,
    required this.hintColor,
    required this.exitingArrows,
    required this.exitProgress,
  });

  static const _blockedColor = Color(0xFFE63946); // red flash on blocked tap

  final GameController game;
  final double cell;
  final double margin;
  final int? hintId;
  final int? blockedId;
  final Color color;
  final Color hintColor;
  final Map<int, GridArrow> exitingArrows;
  final Map<int, double> exitProgress;

  Offset _center(Point<int> p) =>
      Offset((p.x + 0.5) * cell + margin, (p.y + 0.5) * cell + margin);

  void _drawArrow(Canvas canvas, GridArrow a, Color col, double opacity,
      Offset shift) {
    final paint = Paint()
      ..color = col.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    final perp = Offset(-dir.dy, dir.dx);
    final pts = a.cells.map((p) => _center(p) + shift).toList();

    // Shaft: tail back-edge → every cell centre → the arrow tip.
    final start = pts.first - dir * (cell * 0.28);
    final tip = pts.last + dir * (cell * 0.40);
    final shaft = Path()..moveTo(start.dx, start.dy);
    for (final p in pts) {
      shaft.lineTo(p.dx, p.dy);
    }
    shaft.lineTo(tip.dx, tip.dy);
    canvas.drawPath(shaft, paint);

    // Open chevron arrowhead (same stroke weight) — two barbs angling back
    // from the tip, like the reference game (not a filled triangle).
    const back = 0.26;
    const spread = 0.20;
    final b1 = tip - dir * (cell * back) + perp * (cell * spread);
    final b2 = tip - dir * (cell * back) - perp * (cell * spread);
    final chevron = Path()
      ..moveTo(b1.dx, b1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(b2.dx, b2.dy);
    canvas.drawPath(chevron, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Active arrows.
    for (final a in game.arrows) {
      if (a.removed) continue;
      final col = a.id == blockedId
          ? _blockedColor
          : a.id == hintId
              ? hintColor
              : color;
      _drawArrow(canvas, a, col, 1, Offset.zero);
    }
    // Arrows sliding off-board.
    final travel = cell * (game.rows + game.cols);
    for (final entry in exitingArrows.entries) {
      final a = entry.value;
      final t = exitProgress[entry.key] ?? 0;
      final shift = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble()) *
          (t * travel);
      _drawArrow(canvas, a, color, 1 - t, shift);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
