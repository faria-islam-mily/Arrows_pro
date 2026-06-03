import 'dart:math';

import '../game/level_generator.dart';
import '../models/grid_arrow.dart';
import '../models/level.dart';
import 'intricate_shapes.dart';
import 'shapes.dart';

/// Long winding arrows that fill the shape like a maze (few short stubs).
int _maxLenFor(int dim) => (dim * 1.6).round().clamp(16, 44);

/// Upscale a mask by [k]: each cell becomes a k×k block. Turns a small,
/// low-resolution silhouette into a big one with many cells, so the maze fill
/// reads as a large dense puzzle that overflows the screen (pan/zoom).
List<String> _scale(List<String> mask, int k) {
  final out = <String>[];
  for (final row in mask) {
    final wide = StringBuffer();
    for (final ch in row.split('')) {
      wide.write(ch * k);
    }
    final line = wide.toString();
    for (var i = 0; i < k; i++) {
      out.add(line);
    }
  }
  return out;
}

/// Scale [base] up so its width reaches roughly [target] cells.
List<String> _big(List<String> base, int target) {
  final k = (target / base[0].length).round().clamp(2, 4);
  return _scale(base, k);
}

/// How much thinking a level demands (0..1) — see LevelGenerator.fromMask.
double _hardnessFor(String difficulty) => switch (difficulty) {
      'Easy' => 0.35,
      'Medium' => 0.6,
      'Hard' => 0.85,
      _ => 1.0, // Expert / anything tougher
    };

Level _lvl(int n, String name, String difficulty, List<String> base) {
  // Later levels are bigger (more arrows, more pan/zoom).
  final target = (26 + n * 1.8).round();
  final mask = _big(base, target);
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
      hardness: _hardnessFor(difficulty),
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
    arrows: () =>
        LevelGenerator.fromMask(mask, seed: seed, maxLen: 22, hardness: 0.8),
  );
}

/// Unused helper kept for hand-authored levels later.
List<GridArrow> noArrows() => <GridArrow>[];
