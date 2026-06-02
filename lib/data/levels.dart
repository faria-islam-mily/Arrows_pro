import 'dart:math';

import '../game/level_generator.dart';
import '../models/grid_arrow.dart';
import '../models/level.dart';
import 'intricate_shapes.dart';
import 'shapes.dart';

/// Long winding arrows that fill the shape like a maze (few short stubs).
int _maxLenFor(int dim) => (dim * 1.6).round().clamp(16, 44);

Level _lvl(int n, String name, String difficulty, List<String> mask) {
  return Level(
    number: n,
    name: name,
    difficulty: difficulty,
    rows: mask.length,
    cols: mask[0].length,
    arrows: () => LevelGenerator.fromMask(
      mask,
      seed: n,
      maxLen: _maxLenFor(max(mask.length, mask[0].length)),
    ),
  );
}

/// A small, hand-curated set of distinct, named, densely-woven levels.
final List<Level> kLevels = [
  _lvl(1, 'Prism', 'Easy', Shapes.bigDiamond),
  _lvl(2, 'Heartbeat', 'Easy', Shapes.bigHeart),
  _lvl(3, 'Honeycomb', 'Easy', Shapes.hexagon),
  _lvl(4, 'Starfall', 'Medium', Shapes.star),
  _lvl(5, 'Cool Shades', 'Medium', Shapes.glasses),
  _lvl(6, 'Whiskers', 'Medium', Shapes.cat),
  _lvl(7, 'Phantom', 'Hard', Shapes.ghost),
  _lvl(8, 'Coronation', 'Hard', Shapes.crown),
  _lvl(9, 'All Smiles', 'Hard', Shapes.smiley),
  _lvl(10, 'Dragon', 'Expert', Shapes.dragon),
];

/// A once-a-day puzzle seeded by the calendar date.
Level dailyLevel([DateTime? when]) {
  final d = when ?? DateTime.now();
  final seed = d.year * 10000 + d.month * 100 + d.day;
  final mask = IntricateShapes.mask(seed, 14);
  return Level(
    number: seed,
    name: 'Daily Challenge',
    difficulty: 'Daily',
    rows: mask.length,
    cols: mask[0].length,
    arrows: () => LevelGenerator.fromMask(mask, seed: seed, maxLen: 22),
  );
}

/// Unused helper kept for hand-authored levels later.
List<GridArrow> noArrows() => <GridArrow>[];
