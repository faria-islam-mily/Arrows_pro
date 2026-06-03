import 'dart:math';

import '../models/grid_arrow.dart';

/// Generates dense, gap-free, guaranteed-solvable levels of long winding arrows
/// whose heads always point straight (with a real tail — never an abrupt
/// sideways kink), like the reference "Arrows GO" mazes.
///
/// ## How (carve-from-the-edges)
/// We "eat" the shape one snake at a time. Each snake's HEAD is a still-present
/// cell whose straight corridor to the board edge is already empty (only
/// off-board or previously-carved cells). Its BODY then winds inward through
/// the remaining cells (space-filling), starting with a couple of straight
/// steps so the head has a straight tail.
///
/// Because a snake is carved only when its exit corridor is already clear, the
/// carve order IS a valid play order — the level is solvable by construction.
/// Every cell is eventually carved, so there are no gaps. The head's forward
/// cells are never part of its own body (they were already empty), so a head
/// is never swallowed by its own shape.
class LevelGenerator {
  LevelGenerator._();

  static final Map<String, List<GridArrow>> _cache = {};

  static int _hash(int x, int y, int seed) =>
      ((x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)) & 0x7fffffff;

  static List<GridArrow> _fresh(List<GridArrow> src) => [
        for (final a in src)
          GridArrow(id: a.id, cells: List<Point<int>>.of(a.cells), dir: a.dir),
      ];

  /// [hardness] (0..1) controls how much thinking a level demands: higher means
  /// arrows exit the long way across the board (few are movable at any moment,
  /// so you must trace lines to find a legal move). Lower keeps exits short and
  /// obvious for gentle early levels.
  static List<GridArrow> fromMask(
    List<String> mask, {
    required int seed,
    int maxLen = 12,
    double hardness = 0.7,
  }) {
    final key = '$seed|$maxLen|${hardness.toStringAsFixed(2)}|${mask.join("/")}';
    final cached = _cache[key];
    if (cached != null) return _fresh(cached);

    final rows = mask.length;
    final cols = mask[0].length;
    final inMask = <Point<int>>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < mask[r].length; c++) {
        if (mask[r][c] == '#') inMask.add(Point(c, r));
      }
    }

    var arrows = _carve(inMask, rows, cols, seed, maxLen, hardness);
    // On harder levels, also flip free arrows inward (blocked until their
    // blockers clear) while keeping the board solvable. Skipped when easy (keep
    // it gentle) or on huge boards (per-flip solvability check is costly).
    if (inMask.length <= 1600 && hardness >= 0.45) {
      arrows = _addDependencies(arrows, rows, cols);
    }
    _cache[key] = arrows;
    return _fresh(arrows);
  }

  static List<GridArrow> _carve(Set<Point<int>> inMask, int rows, int cols,
      int seed, int maxLen, double hardness) {
    final remaining = <Point<int>>{...inMask};
    final arrows = <GridArrow>[];
    var id = 0;

    // Cells of `remaining` still adjacent (in dir) to this cell.
    int onward(Point<int> p) {
      var n = 0;
      for (final e in ArrowDir.values) {
        if (remaining.contains(Point(p.x + e.dCol, p.y + e.dRow))) n++;
      }
      return n;
    }

    // The straight corridor from the head out to the edge is free of remaining
    // cells (so it's already been carved / is off-board → clear at play time).
    bool corridorClear(Point<int> h, ArrowDir d) {
      var r = h.y + d.dRow;
      var c = h.x + d.dCol;
      while (r >= 0 && r < rows && c >= 0 && c < cols) {
        if (remaining.contains(Point(c, r))) return false;
        r += d.dRow;
        c += d.dCol;
      }
      return true;
    }

    int exitDist(Point<int> p, ArrowDir d) => switch (d) {
          ArrowDir.up => p.y,
          ArrowDir.down => rows - 1 - p.y,
          ArrowDir.left => p.x,
          ArrowDir.right => cols - 1 - p.x,
        };
    final maxDim = rows > cols ? rows : cols;

    while (remaining.isNotEmpty) {
      // Pick the next head: a cell with a clear exit corridor. Prefer one whose
      // tail cell (straight behind it) is still present so the head gets a
      // straight tail, then prefer the LONGEST clear exit — i.e. shoot across
      // the already-carved region. At the start of play that whole corridor is
      // still full of other arrows, so the arrow is blocked and the player must
      // trace a long line to realise it. That's what makes it a real puzzle.
      Point<int>? bestH;
      ArrowDir? bestD;
      var bestKey = 1 << 30;
      for (final cell in remaining) {
        for (final d in ArrowDir.values) {
          if (!corridorClear(cell, d)) continue;
          final hasTail =
              remaining.contains(Point(cell.x - d.dCol, cell.y - d.dRow));
          final ed = exitDist(cell, d);
          // Blend: hardness→1 prefers the LONGEST clear corridor (hard to
          // trace), hardness→0 prefers the shortest (obvious, gentle).
          final corridor = (maxDim - ed) * hardness + ed * (1 - hardness);
          final key = (hasTail ? 0 : 100000) +
              (corridor * 8).round() +
              (_hash(cell.x, cell.y, seed) & 7);
          if (key < bestKey) {
            bestKey = key;
            bestH = cell;
            bestD = d;
          }
        }
      }

      final h = bestH!;
      final d = bestD!;
      final back = Point<int>(-d.dCol, -d.dRow);

      final body = <Point<int>>[h];
      remaining.remove(h);
      var cur = h;
      var steps = 0;
      while (body.length < maxLen) {
        Point<int>? next;
        // First two steps go straight back, giving the head a straight tail.
        if (steps < 2) {
          final s = Point(cur.x + back.x, cur.y + back.y);
          if (remaining.contains(s)) {
            next = s;
          } else if (steps == 0) {
            break; // can't form a straight tail → keep it a clean 1-cell arrow
          }
        }
        if (next == null) {
          // Warnsdorff: wind into the neighbour with the fewest onward exits.
          final cands = <Point<int>>[];
          for (final e in ArrowDir.values) {
            final p = Point(cur.x + e.dCol, cur.y + e.dRow);
            if (remaining.contains(p)) cands.add(p);
          }
          if (cands.isEmpty) break;
          cands.sort((a, b) {
            final byDeg = onward(a) - onward(b);
            if (byDeg != 0) return byDeg;
            return _hash(a.x, a.y, seed) - _hash(b.x, b.y, seed);
          });
          next = cands.first;
        }
        remaining.remove(next);
        body.add(next);
        cur = next;
        steps++;
      }

      // body is head-first; reverse to tail..head so the head is last.
      arrows.add(GridArrow(id: id++, cells: body.reversed.toList(), dir: d));
    }
    return arrows;
  }

  static ArrowDir _vec(int dx, int dy) {
    if (dx > 0) return ArrowDir.right;
    if (dx < 0) return ArrowDir.left;
    if (dy > 0) return ArrowDir.down;
    return ArrowDir.up;
  }

  /// Reverse a snake so it points the OTHER way. Returns null if that would
  /// kink the head (no straight tail) or bury the head in its own body — so
  /// flipped arrows keep the same clean, straight heads as carved ones.
  static GridArrow? _flip(GridArrow a) {
    if (a.cells.length < 3) return null;
    final rev = a.cells.reversed.toList();
    final head = rev.last;
    final dx = head.x - rev[rev.length - 2].x;
    final dy = head.y - rev[rev.length - 2].y;
    if (rev.contains(Point(head.x + dx, head.y + dy))) return null; // on body
    var run = 1;
    for (var j = rev.length - 1; j >= 1; j--) {
      if (rev[j].x - rev[j - 1].x == dx && rev[j].y - rev[j - 1].y == dy) {
        run++;
      } else {
        break;
      }
    }
    if (run < 2) return null; // would kink right at the head
    return GridArrow(id: a.id, cells: rev, dir: _vec(dx, dy));
  }

  /// Can this arrow slide straight off the board through the current occupancy
  /// (its own cells don't block it)?
  static bool _canExit(
      GridArrow a, Set<Point<int>> occ, int rows, int cols) {
    final own = a.cells.toSet();
    var r = a.head.y + a.dir.dRow;
    var c = a.head.x + a.dir.dCol;
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      final p = Point(c, r);
      if (!own.contains(p) && occ.contains(p)) return false;
      r += a.dir.dRow;
      c += a.dir.dCol;
    }
    return true;
  }

  /// Greedy peel: removable as long as some present arrow has a clear exit.
  static bool _solvable(List<GridArrow> arrows, int rows, int cols) {
    final removed = <int>{};
    while (removed.length < arrows.length) {
      final occ = <Point<int>>{};
      for (final a in arrows) {
        if (!removed.contains(a.id)) occ.addAll(a.cells);
      }
      var progressed = false;
      for (final a in arrows) {
        if (removed.contains(a.id)) continue;
        if (_canExit(a, occ, rows, cols)) {
          removed.add(a.id);
          progressed = true;
          break;
        }
      }
      if (!progressed) return false;
    }
    return true;
  }

  static bool _blockedAtStart(
      List<GridArrow> arrows, int idx, int rows, int cols) {
    final occ = <Point<int>>{};
    for (final a in arrows) {
      occ.addAll(a.cells);
    }
    return !_canExit(arrows[idx], occ, rows, cols);
  }

  /// Turn the trivial outside-in peel into a real puzzle: repeatedly flip a
  /// free arrow so it points inward (blocked until its blockers move), keeping
  /// the move only if the whole board still solves. The result is densely
  /// inter-dependent yet always solvable.
  static List<GridArrow> _addDependencies(
      List<GridArrow> arrows, int rows, int cols) {
    for (var pass = 0; pass < 5; pass++) {
      var changed = false;
      for (var i = 0; i < arrows.length; i++) {
        if (_blockedAtStart(arrows, i, rows, cols)) continue; // already a dep
        final flipped = _flip(arrows[i]);
        if (flipped == null) continue;
        final trial = List<GridArrow>.of(arrows)..[i] = flipped;
        if (_blockedAtStart(trial, i, rows, cols) &&
            _solvable(trial, rows, cols)) {
          arrows = trial;
          changed = true;
        }
      }
      if (!changed) break;
    }
    return arrows;
  }
}
