import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../models/grid_arrow.dart';
import '../state/app_scope.dart';

/// Renders the arrow board with thick rounded strokes + solid arrowheads,
/// handles taps (hit-testing cells), and slides arrows off-board when escaping.
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

  // Pan/zoom transform for the freely-draggable board.
  final TransformationController _tc = TransformationController();
  bool _didCenter = false; // center the board once on first layout

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
      duration: const Duration(milliseconds: 340),
    );
    // Ease-in so the arrow starts gently then accelerates as it shoots off the
    // board — a satisfying "released" feel rather than a linear slide.
    final curved = CurvedAnimation(parent: ctrl, curve: Curves.easeInCubic);
    _controllers[a.id] = ctrl;
    _exitingArrows[a.id] = a;
    curved.addListener(() => setState(() => _exitProgress[a.id] = curved.value));
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
    _tc.dispose();
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

        // Center the board once on first layout. After that the user is free to
        // drag it anywhere (we never re-center, so their pan isn't reset).
        if (!_didCenter) {
          _didCenter = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final dx = (cons.maxWidth - w) / 2;
            final dy = (cons.maxHeight - h) / 2;
            _tc.value = Matrix4.identity()..translateByDouble(dx, dy, 0, 1);
          });
        }

        return InteractiveViewer(
          transformationController: _tc,
          panEnabled: true,
          // Natural size so the board can be dragged freely anywhere on screen.
          constrained: false,
          minScale: 0.6,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
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
    final stroke = Paint()
      ..color = col.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = col.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    final perp = Offset(-dir.dy, dir.dx);
    final pts = a.cells.map((p) => _center(p) + shift).toList();
    final headCenter = pts.last;

    // Shaft: a clean line through every cell centre with a plain rounded tail.
    // It ends at the head cell, where the solid arrowhead takes over. (A
    // length-1 arrow gets a short stub so it still reads as an arrow.)
    final shaft = Path();
    if (pts.length == 1) {
      final tail = headCenter - dir * (cell * 0.42);
      shaft.moveTo(tail.dx, tail.dy);
      shaft.lineTo(headCenter.dx, headCenter.dy);
    } else {
      shaft.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        shaft.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(shaft, stroke);

    // Solid triangular arrowhead — bold and unambiguous, like the reference.
    // Sized to sit clearly wider than the thick shaft and pulled in so it stays
    // inside its cell rather than poking out.
    final apex = headCenter + dir * (cell * 0.46);
    final base = headCenter + dir * (cell * 0.02);
    final c1 = base + perp * (cell * 0.30);
    final c2 = base - perp * (cell * 0.30);
    final head = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..close();
    canvas.drawPath(head, fill);
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