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
      duration: const Duration(milliseconds: 420),
    );
    _controllers[a.id] = ctrl;
    _exitingArrows[a.id] = a;
    // Raw 0..1 progress; the cinematic shaping (anticipation, acceleration,
    // scale pop, late fade) is applied in the painter so it can use board
    // geometry. setState each tick to redraw the slide.
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
        // Reserve room for the top HUD (back / title / hearts / progress) and
        // the bottom Hint bar, then fit the WHOLE board — cells plus the canvas
        // margin that keeps edge arrowheads from clipping — inside what's left.
        // Because the margin is part of the divisor, bigger boards get smaller
        // cells (and smaller arrows), so the puzzle scales down to fit on screen
        // instead of running under the HUD. The board stays pannable/zoomable,
        // so these reserves are just sensible defaults.
        const reservedTop = 150.0;
        const reservedBottom = 120.0;
        const pad = 16.0;
        const marginFactor = 0.5; // canvas padding measured in cells

        final availW = (cons.maxWidth - pad * 2).clamp(1.0, double.infinity);
        final visibleH = cons.maxHeight - reservedTop - reservedBottom;
        final availH = (visibleH - pad * 2).clamp(1.0, double.infinity);

        final cellW = availW / (g.cols + 2 * marginFactor);
        final cellH = availH / (g.rows + 2 * marginFactor);
        // Cap so small early boards stay bold rather than ballooning.
        final cell = min(min(cellW, cellH), 46.0);
        final margin = cell * marginFactor;
        final w = cell * g.cols + margin * 2;
        final h = cell * g.rows + margin * 2;

        // Center the board once on first layout (in the visible band between the
        // HUD and the Hint bar). After that the user is free to drag it anywhere
        // (we never re-center, so their pan isn't reset).
        if (!_didCenter) {
          _didCenter = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final dx = (cons.maxWidth - w) / 2;
            final dy = reservedTop + (visibleH - h) / 2;
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

  void _drawShaft(Canvas canvas, GridArrow a, Color col, double opacity,
      Offset shift) {
    final stroke = Paint()
      ..color = col.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    final pts = a.cells.map((p) => _center(p) + shift).toList();
    final headCenter = pts.last;

    // A clean line through every cell centre. It stops a touch short of the
    // head cell's leading edge so the solid head reads as a distinct tip rather
    // than blending into whatever sits in front of it. (Length-1 arrows get a
    // short stub so they still read as an arrow.)
    final shaft = Path();
    if (pts.length == 1) {
      final tail = headCenter - dir * (cell * 0.38);
      shaft.moveTo(tail.dx, tail.dy);
      shaft.lineTo(headCenter.dx, headCenter.dy);
    } else {
      shaft.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        shaft.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(shaft, stroke);
  }

  void _drawHead(Canvas canvas, GridArrow a, Color col, double opacity,
      Offset shift) {
    final fill = Paint()
      ..color = col.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    final perp = Offset(-dir.dy, dir.dx);
    final headCenter = a.cells.map((p) => _center(p) + shift).last;

    // Solid triangular arrowhead. The tip is pulled in to ~0.36 of the cell so
    // there's always a visible gap to the next cell — the head never appears to
    // merge with the body it's pointing at. Drawn in a second pass (after every
    // shaft) so a neighbouring arrow can never paint over a head.
    final apex = headCenter + dir * (cell * 0.36);
    final base = headCenter - dir * (cell * 0.06);
    final c1 = base + perp * (cell * 0.28);
    final c2 = base - perp * (cell * 0.28);
    final head = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..close();
    canvas.drawPath(head, fill);
  }

  /// Slide-out the player can actually SEE: the whole arrow glides, as one
  /// rigid piece, straight in the direction its head points — starting from
  /// rest at its spot and **accelerating** off the board (a "released" feel),
  /// covering exactly the distance needed to clear the nearest edge over the
  /// full animation. Clipped to the board (see paint) so it vanishes cleanly at
  /// the grid edge, like being pulled out of the maze, with a soft fade at the
  /// very end.
  void _drawExiting(Canvas canvas, GridArrow a, double t) {
    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    final w = cell * game.cols + margin * 2;
    final h = cell * game.rows + margin * 2;

    // Distance (px) each cell must travel in [dir] to fully clear the edge;
    // take the max so the whole snake leaves, plus one cell of buffer.
    double clearDist(Point<int> p) {
      final c = _center(p);
      return switch (a.dir) {
        ArrowDir.up => c.dy + cell,
        ArrowDir.down => h - c.dy + cell,
        ArrowDir.left => c.dx + cell,
        ArrowDir.right => w - c.dx + cell,
      };
    }

    final travel = a.cells.map(clearDist).reduce(max);
    final eased = t * t; // ease-in: visible at first, then accelerates away
    final off = dir * (travel * eased);
    final opacity = t < 0.78 ? 1.0 : (1 - (t - 0.78) / 0.22).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(off.dx, off.dy);
    _drawShaft(canvas, a, color, opacity, Offset.zero);
    _drawHead(canvas, a, color, opacity, Offset.zero);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Active arrows: all shafts first, then all heads, so no arrow's body is
    // ever painted over another arrow's head.
    final draws = <(GridArrow, Color)>[];
    for (final a in game.arrows) {
      if (a.removed) continue;
      final col = a.id == blockedId
          ? _blockedColor
          : a.id == hintId
              ? hintColor
              : color;
      draws.add((a, col));
    }
    for (final d in draws) {
      _drawShaft(canvas, d.$1, d.$2, 1.0, Offset.zero);
    }
    for (final d in draws) {
      _drawHead(canvas, d.$1, d.$2, 1.0, Offset.zero);
    }

    // Escaping arrows slide on top, clipped to the board so they vanish exactly
    // at the grid edge rather than floating into empty space.
    if (exitingArrows.isNotEmpty) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
      for (final entry in exitingArrows.entries) {
        _drawExiting(canvas, entry.value, exitProgress[entry.key] ?? 0);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}