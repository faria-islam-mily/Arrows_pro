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

// ---- Difficulty + shape curve: a sawtooth in blocks of 5 --------------------
//
// Difficulty climbs across each block of five levels then resets, and EVERY
// level is a different silhouette (square, diamond, heart, star, hexagon, …)
// drawn from a size-tiered gallery. The size tier grows within a block to a big
// picture "boss" on the 5th level, then drops back for the next block, with a
// slow drift so deep blocks are bigger/harder than early ones. The result reads
// as visibly growing, varied puzzles that need progressively more thinking.

int _pos(int n) => (n - 1) % 5; // 0..4 within the block (4 = the picture peak)
int _block(int n) => (n - 1) ~/ 5; // 0,1,2,... which block of five

String _difficultyFor(int n) {
  if (n == 1) return 'Tutorial';
  const ladder = ['Easy', 'Medium', 'Hard', 'Expert'];
  const within = [0, 0, 1, 1, 2]; // Easy,Easy,Medium,Medium,Hard inside a block
  final drift = _block(n) ~/ 3; // bump the whole block up a notch every 3 blocks
  return ladder[(within[_pos(n)] + drift).clamp(0, ladder.length - 1)];
}

/// Size tier (0 tiny .. 3 big) for level n: grows within a block to a big peak
/// on the 5th level, resets, and drifts up slowly over the run.
int _tierFor(int n) {
  const within = [0, 1, 1, 2, 3]; // tiny, small, small, medium, BIG peak
  final drift = _block(n) ~/ 3;
  return (within[_pos(n)] + drift).clamp(0, Shapes.tiers.length - 1);
}

/// The silhouette for level n. Every level is a distinct shape; rotating the
/// index by the tier keeps neighbouring levels from repeating a shape.
List<String> _maskFor(int n) {
  if (n == 1) return Shapes.tiers[0][0]; // tiny square tutorial knot
  final t = _tierFor(n);
  final gallery = Shapes.tiers[t];
  return gallery[(n + t * 3) % gallery.length];
}

/// Longer winding arrows on bigger boards so the shape weaves densely.
int _maxLenFor(List<String> mask) {
  final side = mask.length > mask[0].length ? mask.length : mask[0].length;
  return (side + 4).clamp(8, 18);
}

/// 100-level pack. Each level is seeded by its number, so generation is
/// deterministic, and `GameController.solvable` is asserted for every one of
/// them in the test-suite.
final List<Level> kLevels = List<Level>.generate(100, (i) {
  final n = i + 1;
  final mask = _maskFor(n);
  return _gen(n, _difficultyFor(n), mask, maxLen: _maxLenFor(mask));
});

/// A once-a-day puzzle seeded by the calendar date — same for everyone that
/// day, different each day.
Level dailyLevel([DateTime? when]) {
  final d = when ?? DateTime.now();
  final seed = d.year * 10000 + d.month * 100 + d.day;
  return Level(
    number: seed, // unique per day; not part of kLevels' 1..100 numbering
    rows: 8,
    cols: 8,
    difficulty: 'Daily',
    arrows: () => LevelGenerator.fromMask(_filled(8, 8), seed: seed, maxLen: 12),
  );
}

/// Unused helper kept for hand-authored levels later.
List<GridArrow> noArrows() => <GridArrow>[];