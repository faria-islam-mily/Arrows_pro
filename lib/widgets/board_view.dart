import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../models/grid_arrow.dart';
import '../state/app_scope.dart';

/// A handle the bottom power-up bar uses to drive the board (the board owns the
/// exit animations, so power-ups route through it). BoardView fills these in.
class BoardActions {
  VoidCallback? armEraser;
  VoidCallback? undo;
  VoidCallback? autoStep;
}

/// Renders the arrow board with thick rounded strokes + solid arrowheads,
/// handles taps (hit-testing cells), and slides arrows off-board when escaping.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.game,
    required this.hintId,
    required this.onBlocked,
    this.actions,
    this.onEraserUsed,
  });

  final GameController game;
  final int? hintId;
  final VoidCallback onBlocked;

  /// Optional handle the power-up bar uses to trigger board actions.
  final BoardActions? actions;

  /// Called when an armed Eraser is actually spent on an arrow.
  final VoidCallback? onEraserUsed;

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

  int? _blockedId; // arrow currently doing the "blocked" lunge
  int _blockedGap = 0; // clear cells between its head and the blocker ahead
  late final AnimationController _blockCtrl;
  bool _eraserArmed = false; // next tapped arrow is erased even if blocked
  int? _previewId; // arrow being long-pressed (shows its exit guide line)

  @override
  void initState() {
    super.initState();
    // Drives the blocked-arrow lunge: forward into the blocker, then recoil.
    _blockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _blockedId = null);
        }
      });
    _bindActions();
  }

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);
    if (old.actions != widget.actions) _bindActions();
  }

  void _bindActions() {
    final act = widget.actions;
    if (act == null) return;
    act.armEraser = () => setState(() => _eraserArmed = true);
    act.undo = _undo;
    act.autoStep = _autoStep;
  }

  /// Restore the last removed arrow (Undo power-up).
  void _undo() {
    widget.game.undo();
    setState(() {});
  }

  /// Slide out one currently-movable arrow, exactly like a tap (Magic power-up).
  void _autoStep() {
    final id = widget.game.hintArrowId();
    if (id == null) return;
    final a = widget.game.arrows.firstWhere((x) => x.id == id);
    widget.game.tap(a);
    _startExit(a);
  }

  void _handleTapCell(int row, int col) {
    final a = widget.game.arrowAt(row, col);
    if (a == null) return;
    if (_eraserArmed) {
      // Eraser: remove this arrow even if it's blocked, then disarm + bill it.
      setState(() => _eraserArmed = false);
      widget.game.forceRemove(a);
      _startExit(a);
      widget.onEraserUsed?.call();
      return;
    }
    if (widget.game.canExit(a)) {
      widget.game.tap(a); // marks removed + notifies (progress/win)
      _startExit(a);
    } else {
      // Blocked: lunge the arrow forward into the blocker, recoil, flash red,
      // buzz (heavyImpact via onBlocked), and drop a life.
      _blockedGap = _gapToBlocker(a);
      setState(() => _blockedId = a.id);
      widget.onBlocked();
      _blockCtrl.forward(from: 0);
    }
  }

  /// Clear cells between [a]'s head and the first arrow blocking its straight
  /// exit. Caps how far the lunge travels so it bumps the blocker rather than
  /// sliding off into open space.
  int _gapToBlocker(GridArrow a) {
    var gap = 0;
    var r = a.head.y + a.dir.dRow;
    var c = a.head.x + a.dir.dCol;
    while (r >= 0 && r < widget.game.rows && c >= 0 && c < widget.game.cols) {
      final hit = widget.game.arrowAt(r, c);
      if (hit != null && hit.id != a.id) break; // the blocker
      gap++;
      r += a.dir.dRow;
      c += a.dir.dCol;
    }
    return gap;
  }

  /// Id of the arrow under a local board position, or null.
  int? _arrowIdAt(Offset local, double cell, double margin) {
    final col = ((local.dx - margin) / cell).floor();
    final row = ((local.dy - margin) / cell).floor();
    if (row < 0 || row >= widget.game.rows || col < 0 || col >= widget.game.cols) {
      return null;
    }
    return widget.game.arrowAt(row, col)?.id;
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
    _blockCtrl.dispose();
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
        // Clamp the cell size: capped so small boards aren't giant, and given a
        // FLOOR so big boards keep readable, tappable arrows and deliberately
        // overflow the screen — the player pans/pinch-zooms (down to 0.6x) to
        // read them. That "explore a maze bigger than the screen" feel is the
        // intended experience for the large intricate levels.
        const minCell = 32.0;
        final cell = min(cellW, cellH).clamp(minCell, 40.0);
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
          // Allow zooming far out so even the biggest boards fit fully on screen.
          minScale: 0.25,
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
            // Long-press an arrow to preview its exit path (a guide line shows
            // where it would travel). Dragging while held previews others.
            onLongPressStart: (d) => setState(
                () => _previewId = _arrowIdAt(d.localPosition, cell, margin)),
            onLongPressMoveUpdate: (d) {
              final id = _arrowIdAt(d.localPosition, cell, margin);
              if (id != _previewId) setState(() => _previewId = id);
            },
            onLongPressEnd: (_) => setState(() => _previewId = null),
            onLongPressCancel: () => setState(() => _previewId = null),
            child: CustomPaint(
              size: Size(w, h),
              painter: _BoardPainter(
                game: g,
                cell: cell,
                margin: margin,
                hintId: widget.hintId,
                blockedId: _blockedId,
                blockedT: _blockCtrl.value,
                blockedGap: _blockedGap,
                previewId: _previewId,
                color: palette.arrow,
                hintColor: palette.arrowActive,
                dotColor: palette.textMuted,
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
    required this.blockedT,
    required this.blockedGap,
    required this.previewId,
    required this.color,
    required this.hintColor,
    required this.dotColor,
    required this.exitingArrows,
    required this.exitProgress,
  });

  static const _blockedColor = Color(0xFFE63946); // red flash on blocked tap

  final GameController game;
  final double cell;
  final double margin;
  final int? hintId;
  final int? blockedId;
  final double blockedT; // 0..1 lunge progress for the blocked arrow
  final int blockedGap; // clear cells ahead of the blocked arrow's head
  final int? previewId; // long-pressed arrow showing its exit guide line
  final Color color;
  final Color hintColor;
  final Color dotColor;
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
  /// straight off the board — like being pulled through a tube.
  void _drawExiting(Canvas canvas, GridArrow a, double t) {
    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    final w = cell * game.cols + margin * 2;
    final h = cell * game.rows + margin * 2;

    var poly = a.cells.map((p) => _center(p)).toList();
    if (poly.length == 1) poly = [poly.first - dir * (cell * 0.5), poly.first];
    final head = poly.last;

    final headToEdge = switch (a.dir) {
      ArrowDir.up => head.dy,
      ArrowDir.down => h - head.dy,
      ArrowDir.left => head.dx,
      ArrowDir.right => w - head.dx,
    };
    var bodyLen = 0.0;
    for (var i = 1; i < poly.length; i++) {
      bodyLen += (poly[i] - poly[i - 1]).distance;
    }
    final rayLen = headToEdge + cell * 2;
    final offset = (t * t) * (bodyLen + rayLen); // ease-in, accelerates out
    final opacity = t < 0.82 ? 1.0 : (1 - (t - 0.82) / 0.18).clamp(0.0, 1.0);

    _slither(canvas, a, offset, rayLen, color, opacity);
  }

  /// Draws [a]'s body advanced [offset] arc-length along its OWN poly-line (a
  /// straight [rayLen] ray extends past the head to slide into). The body is
  /// traced through every bend of the curve inside the moving window — so it
  /// follows its own path faithfully and never cuts a corner while sliding.
  /// A negative [offset] recoils it back along the same path.
  void _slither(Canvas canvas, GridArrow a, double offset, double rayLen,
      Color col, double opacity) {
    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    var poly = a.cells.map((p) => _center(p)).toList();
    if (poly.length == 1) poly = [poly.first - dir * (cell * 0.5), poly.first];
    final head = poly.last;
    final curve = [...poly, head + dir * rayLen];
    final cum = <double>[0];
    for (var i = 1; i < curve.length; i++) {
      cum.add(cum[i - 1] + (curve[i] - curve[i - 1]).distance);
    }
    final bodyLen = cum[poly.length - 1];

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

    // The visible body spans arc [a0 (tail) .. a1 (head)]. Trace the curve
    // through that window, KEEPING every bend vertex it passes through.
    final a0 = offset.clamp(0.0, cum.last);
    final a1 = (offset + bodyLen).clamp(0.0, cum.last);
    final body = <Offset>[along(a0)];
    for (var i = 0; i < curve.length; i++) {
      if (cum[i] > a0 && cum[i] < a1) body.add(curve[i]);
    }
    body.add(along(a1));

    _shaftThrough(canvas, body, dir, col, opacity);
    _headAt(canvas, body.last, dir, col, opacity);
  }

  /// Arc-length the blocked arrow advances forward along its own path at
  /// [blockedT]: a quick lunge into the blocker, then a smooth retreat back
  /// along the path to its rest position. Always >= 0 (it can't slide behind
  /// its own tail), so the body never compresses — it just goes out and back.
  double _blockedOffset() {
    final t = blockedT;
    if (t <= 0 || t >= 1) return 0;
    // Travel up to the blocker (capped) plus a little press against it.
    final maxF = (min(blockedGap, 2) + 0.42) * cell;
    if (t < 0.32) {
      return Curves.easeOut.transform(t / 0.32) * maxF; // lunge in
    }
    final u = (t - 0.32) / 0.68; // 0..1 retreat back to rest
    return maxF * (1 - Curves.easeInOut.transform(u));
  }

  /// The blocked arrow: slithers head-first along its own path into the blocker
  /// by [_blockedOffset] arc-length, then recoils back along it — drawn red.
  void _drawBlocked(Canvas canvas, GridArrow a) {
    final rayLen = (min(blockedGap, 2) + 1.2) * cell;
    _slither(canvas, a, _blockedOffset(), rayLen, _blockedColor, 1.0);
  }

  /// Long-press guide: a thin line from [a]'s head straight out to the board
  /// edge along its heading — shows where the arrow would travel.
  void _drawGuide(Canvas canvas, GridArrow a) {
    final dir = Offset(a.dir.dCol.toDouble(), a.dir.dRow.toDouble());
    final head = _center(a.cells.last);
    final w = cell * game.cols + margin * 2;
    final h = cell * game.rows + margin * 2;
    final toEdge = switch (a.dir) {
      ArrowDir.up => head.dy,
      ArrowDir.down => h - head.dy,
      ArrowDir.left => head.dx,
      ArrowDir.right => w - head.dx,
    };
    final end = head + dir * toEdge;
    canvas.drawLine(
      head,
      end,
      Paint()
        ..color = hintColor.withValues(alpha: 0.55)
        ..strokeWidth = (cell * 0.05).clamp(1.5, 4.0)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Faint dot grid: a dot marks every board cell, revealed wherever an arrow
    // has slid away (occupied cells are covered by their arrow). This is the
    // satisfying "trail of dots" that appears as you clear the board.
    final occupied = <Point<int>>{};
    final allCells = <Point<int>>{};
    for (final a in game.arrows) {
      allCells.addAll(a.cells);
      if (!a.removed) occupied.addAll(a.cells);
    }
    // Crisp, clearly-visible dots (not a faint haze) — like the reference.
    final dotPaint = Paint()..color = dotColor.withValues(alpha: 0.55);
    final dotR = cell * 0.075;
    for (final c in allCells) {
      if (occupied.contains(c)) continue;
      canvas.drawCircle(_center(c), dotR, dotPaint);
    }

    // Active arrows: all shafts first, then all heads, so no arrow's body is
    // ever painted over another arrow's head. The blocked arrow is skipped here
    // and redrawn below with its lunge (it slithers along its own path).
    final lunging = blockedId != null && blockedT > 0 && blockedT < 1;
    final draws = <(GridArrow, Color)>[];
    for (final a in game.arrows) {
      if (a.removed) continue;
      if (lunging && a.id == blockedId) continue;
      final col = a.id == blockedId
          ? _blockedColor
          : (a.id == hintId || a.id == previewId)
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

    // Long-press preview: a thin guide line from the held arrow's head straight
    // out to the board edge, on top so the whole path reads end-to-end.
    if (previewId != null) {
      for (final a in game.arrows) {
        if (!a.removed && a.id == previewId) {
          _drawGuide(canvas, a);
          break;
        }
      }
    }

    // Blocked arrow: slither head-first along its own path into the blocker,
    // then recoil back along that same path — like a failed exit.
    if (lunging) {
      for (final a in game.arrows) {
        if (!a.removed && a.id == blockedId) {
          _drawBlocked(canvas, a);
          break;
        }
      }
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