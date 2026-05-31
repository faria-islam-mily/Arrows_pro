import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/grid_arrow.dart';
import '../models/level.dart';

/// Live state + rules for one puzzle.
class GameController extends ChangeNotifier {
  GameController(this.level) {
    _arrows = level.arrows();
  }

  final Level level;
  late List<GridArrow> _arrows;

  List<GridArrow> get arrows => _arrows;
  int get rows => level.rows;
  int get cols => level.cols;

  int get total => _arrows.length;
  int get remaining => _arrows.where((a) => !a.removed).length;
  bool get isComplete => remaining == 0;
  double get progress => total == 0 ? 0 : (total - remaining) / total;

  /// Cell → the active arrow occupying it (for hit-testing + blocking).
  Map<Point<int>, GridArrow> _occupancy() {
    final map = <Point<int>, GridArrow>{};
    for (final a in _arrows) {
      if (a.removed) continue;
      for (final c in a.cells) {
        map[c] = a;
      }
    }
    return map;
  }

  /// The arrow at a tapped cell, or null.
  GridArrow? arrowAt(int row, int col) => _occupancy()[Point(col, row)];

  /// An arrow escapes by slithering out through its head, so it can exit when
  /// the straight corridor from its [head] in [dir] to the board edge is free
  /// of other arrows (its own body trails out along its path).
  bool canExit(GridArrow a) {
    if (a.removed) return false;
    final occ = _occupancy();
    final own = a.cells.toSet();
    var r = a.head.y + a.dir.dRow;
    var c = a.head.x + a.dir.dCol;
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      final p = Point(c, r);
      if (!own.contains(p) && occ.containsKey(p)) return false;
      r += a.dir.dRow;
      c += a.dir.dCol;
    }
    return true;
  }

  /// Returns true if the arrow left the board.
  bool tap(GridArrow a) {
    if (!canExit(a)) return false;
    a.removed = true;
    notifyListeners();
    return true;
  }

  void reset() {
    _arrows = level.arrows();
    notifyListeners();
  }

  /// Any currently-exitable arrow id, for the Hint button.
  int? hintArrowId() {
    for (final a in _arrows) {
      if (!a.removed && canExit(a)) return a.id;
    }
    return null;
  }

  /// True if the level can be fully cleared by always removing some exitable
  /// arrow (greedy is complete here: removing an arrow only frees corridors).
  static bool solvable(Level level) {
    final sim = GameController(level);
    while (!sim.isComplete) {
      final id = sim.hintArrowId();
      if (id == null) return false;
      sim._arrows.firstWhere((a) => a.id == id).removed = true;
    }
    return true;
  }
}
