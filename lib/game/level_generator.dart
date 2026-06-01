import 'dart:math';

import '../models/grid_arrow.dart';

/// Generates dense, gap-free, guaranteed-solvable levels of **long winding
/// arrows** that fill a [mask] and connect into a maze, like the reference
/// "Arrows GO" puzzles. Every arrow is a single stroke ending in one arrowhead
/// and has a straight run-up at the head, so its direction is always obvious
/// and never kinks sideways at the tip.
///
/// ## Why it's always solvable
/// 1. Every cell is given a direction, deepest-first; at that moment the
///    corridor toward its nearest edge is clear, so a valid direction always
///    exists. Every direction recorded in [clearDirs] is clear of all deeper
///    cells. This yields a removal order — shallowest first — that clears each
///    cell's corridor before any deeper cell needs to move.
/// 2. Cells are grouped into arrows whose **head is the earliest cell in that
///    order**, with the head's exit direction chosen from its clear directions
///    and the body running only into later (deeper) cells. Removing an arrow
///    when its head's corridor is clear matches the head's original step, so a
///    greedy clear always succeeds — `GameController.solvable` returns true
///    (verified for every shipped level by the test-suite).
class LevelGenerator {
  /// Cells the body must run straight back from the head before it may bend, so
  /// every arrowhead gets a clear, readable run-up.
  static const _headRun = 2;

  static int _hash(int x, int y, int seed) =>
      ((x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)) & 0x7fffffff;

  static List<GridArrow> fromMask(
    List<String> mask, {
    required int seed,
    int maxLen = 8,
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

    // 1) Assign a direction to every cell, deepest-first, and remember ALL of
    //    each cell's clear (valid) exit directions for later head selection.
    final order = inMask.toList()
      ..sort((a, b) {
        final byDepth = depth(b).compareTo(depth(a));
        if (byDepth != 0) return byDepth;
        return _hash(a.x, a.y, seed).compareTo(_hash(b.x, b.y, seed));
      });
    final clearDirs = <Point<int>, List<ArrowDir>>{};
    final cellDir = <Point<int>, ArrowDir>{};
    final assigned = <Point<int>>[];
    for (final p in order) {
      final clear = ArrowDir.values.where((d) => corridorClear(p, d)).toList();
      clearDirs[p] = clear.isEmpty ? [_towardNearestEdge(p, rows, cols)] : clear;
      cellDir[p] = clearDirs[p]![_hash(p.x, p.y, seed) % clearDirs[p]!.length];
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

    // 3) Grow each arrow. Pick the head's exit direction (among its valid clear
    //    directions) so that the cell directly behind the head is a free deeper
    //    neighbour — that lets the body run straight back and gives a clean head
    //    instead of fragmenting. For the first `_headRun` cells the body MUST go
    //    straight (or the arrow ends, never bending at the head); after that it
    //    mostly keeps running straight and winds into a connected maze.
    const dirs = ArrowDir.values;
    final used = <Point<int>>{};
    final arrows = <GridArrow>[];
    var id = 0;

    bool freeDeeper(Point<int> p, Point<int> from) =>
        inMask.contains(p) && !used.contains(p) && rank[p]! > rank[from]!;

    for (final head in byRank) {
      if (used.contains(head)) continue;

      // Choose an exit direction whose straight-back cell is currently free.
      final opts = List<ArrowDir>.of(clearDirs[head]!)
        ..sort((a, b) => _hash(head.x, head.y, seed * 7 + a.index)
            .compareTo(_hash(head.x, head.y, seed * 7 + b.index)));
      var hd = cellDir[head]!;
      for (final d in opts) {
        final back = Point(head.x - d.dCol, head.y - d.dRow);
        if (freeDeeper(back, head)) {
          hd = d;
          break;
        }
      }

      final path = <Point<int>>[head];
      used.add(head);
      var cur = head;
      var lastStep = Point(-hd.dCol, -hd.dRow); // "straight" = directly behind

      while (path.length < maxLen) {
        final cands = <Point<int>>[];
        for (final d in dirs) {
          final nb = Point(cur.x + d.dCol, cur.y + d.dRow);
          if (freeDeeper(nb, cur)) cands.add(nb);
        }
        if (cands.isEmpty) break;

        final straight = Point(cur.x + lastStep.x, cur.y + lastStep.y);
        final hasStraight = cands.contains(straight);

        Point<int> next;
        if (path.length <= _headRun) {
          if (!hasStraight) break; // never bend during the head's run-up
          next = straight;
        } else if (hasStraight && _hash(cur.x, cur.y, seed) % 3 != 0) {
          next = straight;
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
        dir: hd,
      ));
    }
    return arrows;
  }

  static ArrowDir _towardNearestEdge(Point<int> p, int rows, int cols) {
    final dists = <ArrowDir, int>{
      ArrowDir.up: p.y,
      ArrowDir.down: rows - 1 - p.y,
      ArrowDir.left: p.x,
      ArrowDir.right: cols - 1 - p.x,
    };
    return dists.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }
}