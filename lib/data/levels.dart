import '../game/level_generator.dart';
import '../models/grid_arrow.dart';
import '../models/level.dart';
import 'shapes.dart';

/// A solid rectangle mask (every cell filled with arrows).
List<String> _filled(int rows, int cols) =>
    List.generate(rows, (_) => '#' * cols);

Level _gen(int number, String difficulty, List<String> mask, {int maxLen = 8}) {
  return Level(
    number: number,
    rows: mask.length,
    cols: mask[0].length,
    difficulty: difficulty,
    arrows: () => LevelGenerator.fromMask(mask, seed: number, maxLen: maxLen),
  );
}

// ---- Difficulty curve -------------------------------------------------------

String _difficultyFor(int n) {
  if (n == 1) return 'Tutorial';
  if (n <= 15) return 'Easy';
  if (n <= 45) return 'Medium';
  if (n <= 80) return 'Hard';
  return 'Expert';
}

/// Grid side length grows with level number (3 for the tutorial, then 5 → 13).
int _sizeFor(int n) {
  if (n == 1) return 3;
  return (5 + n ~/ 7).clamp(5, 13);
}

/// Longer winding arrows as levels get harder (7 → 16).
int _maxLenFor(int n) => (6 + n ~/ 5).clamp(7, 16);

/// 100-level pack with a smooth ramp. Every 6th level (from 6 on) is a picture
/// level cycled from [Shapes.pack]; the rest are square grids that grow in size
/// and arrow length. Each level is seeded by its number, so generation is
/// deterministic, and `GameController.solvable` is asserted for all of them in
/// the test-suite.
final List<Level> kLevels = List<Level>.generate(100, (i) {
  final n = i + 1;
  final difficulty = _difficultyFor(n);
  final maxLen = _maxLenFor(n);

  // Picture level on every 6th step (keeps level 1 a clean square tutorial).
  if (n >= 6 && n % 6 == 0) {
    final shape = Shapes.pack[(n ~/ 6 - 1) % Shapes.pack.length];
    return _gen(n, difficulty, shape, maxLen: maxLen);
  }

  final s = _sizeFor(n);
  return _gen(n, difficulty, _filled(s, s), maxLen: maxLen);
});

/// A once-a-day puzzle seeded by the calendar date — same for everyone that
/// day, different each day. Medium-sized so it's a satisfying daily ritual.
Level dailyLevel([DateTime? when]) {
  final d = when ?? DateTime.now();
  final seed = d.year * 10000 + d.month * 100 + d.day;
  return Level(
    number: seed, // unique per day; not part of kLevels' 1..100 numbering
    rows: 8,
    cols: 8,
    difficulty: 'Daily',
    arrows: () => LevelGenerator.fromMask(_filled(8, 8), seed: seed, maxLen: 9),
  );
}

/// Unused helper kept for hand-authored levels later.
List<GridArrow> noArrows() => <GridArrow>[];