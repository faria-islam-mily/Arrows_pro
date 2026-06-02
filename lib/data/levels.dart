import 'dart:math';

import '../game/level_generator.dart';
import '../models/grid_arrow.dart';
import '../models/level.dart';
import 'intricate_shapes.dart';
import 'shapes.dart';

/// Hand-drawn silhouettes placed at specific milestone levels.
final Map<int, List<String>> _special = {
  100: Shapes.dragon,
};

/// A solid rectangle mask (every cell filled with arrows).
List<String> _filled(int rows, int cols) =>
    List.generate(rows, (_) => '#' * cols);

/// Board size for level [n]: grows steadily, with a bump on every 10th "boss"
/// level, so later levels are big enough to overflow the screen (pan/zoom).
int _sizeFor(int n) {
  if (n <= 1) return 6; // gentle intro
  final base = 11 + ((n - 1) ~/ 12) * 2; // +2 cells every 12 levels
  final boss = (n % 10 == 0) ? 3 : 0;
  return (base + boss).clamp(9, 30);
}

String _difficultyFor(int n) {
  if (n == 1) return 'Tutorial';
  if (n <= 30) return 'Easy';
  if (n <= 90) return 'Medium';
  if (n <= 150) return 'Hard';
  return 'Expert';
}

/// Longer winding arrows on bigger boards.
int _maxLenFor(int size) => (size * 0.8).round().clamp(8, 22);

/// The mask for level [n]: a small filled square for the tutorial, a hand-drawn
/// silhouette at milestone levels, otherwise a unique procedural intricate one.
List<String> _maskFor(int n) {
  if (n == 1) return _filled(6, 6);
  return _special[n] ?? IntricateShapes.mask(n, _sizeFor(n));
}

/// 200-level pack. Each level is seeded by its number (deterministic), and
/// `GameController.solvable` is asserted for every one in the test-suite.
final List<Level> kLevels = List<Level>.generate(200, (i) {
  final n = i + 1;
  final mask = _maskFor(n);
  final maxLen = _maxLenFor(max(mask.length, mask[0].length));
  return Level(
    number: n,
    rows: mask.length,
    cols: mask[0].length,
    difficulty: _difficultyFor(n),
    arrows: () => LevelGenerator.fromMask(mask, seed: n, maxLen: maxLen),
  );
});

/// A once-a-day puzzle seeded by the calendar date — same for everyone that
/// day, different each day.
Level dailyLevel([DateTime? when]) {
  final d = when ?? DateTime.now();
  final seed = d.year * 10000 + d.month * 100 + d.day;
  final mask = IntricateShapes.mask(seed, 14);
  return Level(
    number: seed, // unique per day; not part of kLevels' 1..200 numbering
    rows: mask.length,
    cols: mask[0].length,
    difficulty: 'Daily',
    arrows: () => LevelGenerator.fromMask(mask, seed: seed, maxLen: 12),
  );
}

/// Unused helper kept for hand-authored levels later.
List<GridArrow> noArrows() => <GridArrow>[];
