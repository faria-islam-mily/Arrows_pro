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
        final cell = min(min(cellW, cellH), 40.0);
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

  static const _strokeFactor = 0.16; // shaft width as a fraction of a cell

  /// Stroke a poly-line through [pts] (1-pt arrows get a short tail stub).
  void _shaftThrough(
      Canvas canvas, List<Offset> pts, Offset dir, Color col, double opacity) {
    final stroke = Paint()
      ..color = col.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * _strokeFactor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (pts.length == 1) {
      final tail = pts.first - dir * (cell * 0.34);
      path.moveTo(tail.dx, tail.dy);
      path.lineTo(pts.first.dx, pts.first.dy);
    } else {
      path.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, stroke);
  }

  /// A trim, solid arrowhead at [headCenter] pointing along [dir].
  void _headAt(
      Canvas canvas, Offset headCenter, Offset dir, Color col, double opacity) {
    final perp = Offset(-dir.dy, dir.dx);
    final apex = headCenter + dir * (cell * 0.34);
    final base = headCenter - dir * (cell * 0.04);
    final c1 = base + perp * (cell * 0.18);
    final c2 = base - perp * (cell * 0.18);
    final head = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..close();
    canvas.drawPath(
      head,
      Paint()
        ..color = col.withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawShaft(Canvas canvas, GridArrow a, Color col, double opacity,
      Offset shift) {
    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    _shaftThrough(
        canvas, a.cells.map((p) => _center(p) + shift).toList(), dir, col,
        opacity);
  }

  void _drawHead(Canvas canvas, GridArrow a, Color col, double opacity,
      Offset shift) {
    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    _headAt(canvas, a.cells.map((p) => _center(p) + shift).last, dir, col,
        opacity);
  }

  /// Exit: the arrow **slithers out head-first along its own path**, then
  /// straight off the board — like being pulled through a tube. Each point of
  /// the body follows the route the head took, so bent arrows curl out
  /// naturally instead of sliding sideways as a rigid shape.
  void _drawExiting(Canvas canvas, GridArrow a, double t) {
    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    final w = cell * game.cols + margin * 2;
    final h = cell * game.rows + margin * 2;

    var poly = a.cells.map((p) => _center(p)).toList();
    if (poly.length == 1) poly = [poly.first - dir * (cell * 0.5), poly.first];
    final head = poly.last;

    // Distance the head must travel along [dir] to clear the nearest edge.
    final headToEdge = switch (a.dir) {
      ArrowDir.up => head.dy,
      ArrowDir.down => h - head.dy,
      ArrowDir.left => head.dx,
      ArrowDir.right => w - head.dx,
    };

    // Travel curve = the body's own poly-line + a straight ray out past the head.
    final curve = [...poly, head + dir * (headToEdge + cell * 2)];
    final cum = <double>[0];
    for (var i = 1; i < curve.length; i++) {
      cum.add(cum[i - 1] + (curve[i] - curve[i - 1]).distance);
    }
    final origArc = cum.sublist(0, poly.length); // arc length of each body vertex
    final bodyLen = origArc.last;

    Offset along(double s) {
      s = s.clamp(0.0, cum.last);
      for (var i = 1; i < cum.length; i++) {
        if (s <= cum[i]) {
          final seg = cum[i] - cum[i - 1];
          final f = seg == 0 ? 0.0 : (s - cum[i - 1]) / seg;
          return Offset.lerp(curve[i - 1], curve[i], f)!;
        }
      }
      return curve.last;
    }

    // Slide every body vertex forward along the curve by the same arc-length.
    final maxOffset = bodyLen + headToEdge + cell * 2;
    final offset = (t * t) * maxOffset; // ease-in: gentle start, accelerates out
    final moved = [for (final s in origArc) along(s + offset)];
    final opacity = t < 0.82 ? 1.0 : (1 - (t - 0.82) / 0.18).clamp(0.0, 1.0);

    _shaftThrough(canvas, moved, dir, color, opacity);
    _headAt(canvas, moved.last, dir, color, opacity);
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