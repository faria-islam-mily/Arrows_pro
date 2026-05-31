import 'dart:math';

import '../models/grid_arrow.dart';

/// Generates dense, gap-free, guaranteed-solvable levels of **bent** arrows
/// (winding snakes) that fill a [mask] — matching the reference game's look.
///
/// ## Why it's always solvable
/// 1. Every cell is first given a direction **deepest-first**; the corridor
///    toward its nearest edge is always clear at that point (those cells are
///    shallower → unassigned), so a valid direction always exists. This yields
///    a full-coverage single-cell solution whose **removal order** (shallowest
///    first) clears each cell's corridor before deeper ones.
/// 2. Cells are then grouped into snakes where the **head is the earliest cell
///    in that removal order** and the body extends only to *later* (deeper)
///    cells. Removing a snake when its head's corridor is clear matches the
///    head's original step; the body cells (own) never block it, and removing
///    them early only frees other corridors. So solvability is preserved.
class LevelGenerator {
  static int _hash(int x, int y, int seed) =>
      ((x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)) & 0x7fffffff;

  static List<GridArrow> fromMask(
    List<String> mask, {
    required int seed,
    int maxLen = 7,
  }) {
    final rows = mask.length;
    final cols = mask[0].length;

    final inMask = <Point<int>>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < mask[r].length; c++) {
        if (mask[r][c] == '#') inMask.add(Point(c, r));
      }
    }

    int depth(Point<int> p) =>
        [p.y, rows - 1 - p.y, p.x, cols - 1 - p.x].reduce(min);

    final occupied = <Point<int>>{};
    bool corridorClear(Point<int> p, ArrowDir d) {
      var r = p.y + d.dRow;
      var c = p.x + d.dCol;
      while (r >= 0 && r < rows && c >= 0 && c < cols) {
        if (occupied.contains(Point(c, r))) return false;
        r += d.dRow;
        c += d.dCol;
      }
      return true;
    }

    // 1) Assign a direction to every cell, deepest-first.
    final order = inMask.toList()
      ..sort((a, b) {
        final byDepth = depth(b).compareTo(depth(a));
        if (byDepth != 0) return byDepth;
        return _hash(a.x, a.y, seed).compareTo(_hash(b.x, b.y, seed));
      });
    final cellDir = <Point<int>, ArrowDir>{};
    final assigned = <Point<int>>[];
    for (final p in order) {
      final clear = ArrowDir.values.where((d) => corridorClear(p, d)).toList();
      cellDir[p] = clear[_hash(p.x, p.y, seed) % clear.length];
      occupied.add(p);
      assigned.add(p);
    }

    // 2) Removal order = reverse of assignment (shallowest removed first).
    final n = assigned.length;
    final rank = <Point<int>, int>{};
    for (var i = 0; i < n; i++) {
      rank[assigned[i]] = n - 1 - i;
    }
    final byRank = assigned.reversed.toList(); // rank 0 (head-most) first

    // 3) Grow snakes: head = lowest-rank cell, body extends to higher-rank
    //    (deeper) neighbours, preferring to continue straight then bend.
    const dirs = ArrowDir.values;
    final used = <Point<int>>{};
    final arrows = <GridArrow>[];
    var id = 0;

    for (final head in byRank) {
      if (used.contains(head)) continue;
      final path = <Point<int>>[head];
      used.add(head);
      var cur = head;
      Point<int>? lastStep;

      while (path.length < maxLen) {
        final cands = <Point<int>>[];
        for (final d in dirs) {
          final nb = Point(cur.x + d.dCol, cur.y + d.dRow);
          if (inMask.contains(nb) &&
              !used.contains(nb) &&
              rank[nb]! > rank[cur]!) {
            cands.add(nb);
          }
        }
        if (cands.isEmpty) break;

        Point<int> next;
        final straight =
            lastStep == null ? null : Point(cur.x + lastStep.x, cur.y + lastStep.y);
        if (straight != null &&
            cands.contains(straight) &&
            _hash(cur.x, cur.y, seed) % 3 != 0) {
          next = straight; // mostly continue straight…
        } else {
          next = cands[_hash(cur.x, cur.y, seed + path.length) % cands.length];
        }
        lastStep = Point(next.x - cur.x, next.y - cur.y);
        path.add(next);
        used.add(next);
        cur = next;
      }

      // Ordered tail .. head (head last) for stroke drawing.
      arrows.add(GridArrow(
        id: id++,
        cells: path.reversed.toList(),
        dir: cellDir[head]!,
      ));
    }
    return arrows;
  }
}
