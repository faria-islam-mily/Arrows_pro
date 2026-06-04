import 'dart:math';

import '../game/level_generator.dart';
import '../models/grid_arrow.dart';
import '../models/level.dart';
import 'boss_shapes.dart';
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

/// Candy-Crush-style difficulty: the tier cycles every 5 levels — a gentle
/// breather after each Expert — so the challenge loops instead of climbing
/// forever. Each completed loop drifts a little harder.
/// Powers roll out over the first [kLearnUntil] levels; difficulty stays gentle
/// there (Easy/Medium) so the player can learn, then ramps up toward 1000.
const int kLearnUntil = 38;
const List<String> _learnCycle = ['Easy', 'Easy', 'Medium', 'Easy', 'Medium'];
const List<String> _rampCycle = ['Easy', 'Medium', 'Medium', 'Hard', 'Expert'];

String _difficultyFor(int n) =>
    (n <= kLearnUntil ? _learnCycle : _rampCycle)[(n - 1) % 5];

double _baseHardness(String difficulty) => switch (difficulty) {
      'Easy' => 0.35,
      'Medium' => 0.6,
      'Hard' => 0.85,
      _ => 1.0, // Expert
    };

/// How much thinking a level demands (0..1). After the learning phase the
/// challenge creeps up so it gets harder and harder toward level 1000.
double _hardnessFor(int n) {
  var ramp = n <= kLearnUntil ? 0.0 : (n - kLearnUntil) * 0.0004;
  if (ramp > 0.32) ramp = 0.32;
  final h = _baseHardness(_difficultyFor(n)) + ramp;
  return h > 1.0 ? 1.0 : h;
}

/// The total number of levels in the pack.
const int kLevelCount = 1000;

/// Curated names + shapes for the polished opening run; beyond this the pack
/// rotates through [Shapes.catalog] (+ the occasional procedural shape).
const List<(String, List<String>)> _intro = [
  ('Prism', Shapes.bigDiamond), ('Heartbeat', Shapes.bigHeart),
  ('Honeycomb', Shapes.hexagon), ('Starfall', Shapes.star),
  ('Cool Shades', Shapes.glasses), ('Whiskers', Shapes.cat),
  ('Phantom', Shapes.ghost), ('Coronation', Shapes.crown),
  ('All Smiles', Shapes.smiley), ('Dragon', Shapes.dragon),
  ('Jet Stream', Shapes.airplane), ('Sweet Tooth', Shapes.iceCream),
  ('Master Key', Shapes.key), ('Flutter', Shapes.butterfly),
  ('Champion', Shapes.trophy), ('Splash', Shapes.fish),
  ('Riff', Shapes.guitar), ('Café', Shapes.coffeeCup),
  ('Snapshot', Shapes.camera), ('Stronghold', Shapes.castle),
];

const List<String> _procNames = [
  'Labyrinth', 'Mosaic', 'Lattice', 'Spiral', 'Nebula', 'Maze', 'Tangle',
];

/// Board target width — modest during the learning phase, then grows steadily
/// so the puzzles get bigger and bigger toward level 1000.
int _targetFor(int n) {
  final w = n <= kLearnUntil
      ? 28 + n * 0.22 // ~34..38 across the learning phase
      : 38 + (n - kLearnUntil) * 0.022; // 38..~59 by level 1000
  return w.round().clamp(26, 60).toInt();
}

/// The picture (name + mask + boss flag) for level [n]. Every 50th level is a
/// big, intricate "boss" with a hand-tuned mask used at full size (no upscale)
/// and max hardness — they grow toward level 1000, the hardest of all.
({String name, List<String> base, bool boss}) _shapeFor(int n) {
  if (n % 50 == 0) {
    final i = (n ~/ 50 - 1) % kBossShapes.length;
    return (name: 'Boss · ${kBossNames[i]}', base: kBossShapes[i], boss: true);
  }
  if (n <= _intro.length) {
    final e = _intro[n - 1];
    return (name: e.$1, base: e.$2, boss: false);
  }
  // Mostly recognizable objects; sprinkle a procedural shape every 13th level
  // for occasional variety without diluting the "real object" feel.
  if (n % 13 == 0) {
    return (
      name: _procNames[(n ~/ 13) % _procNames.length],
      base: IntricateShapes.mask(n * 911 + 17, 13),
      boss: false,
    );
  }
  final e = Shapes.catalog[(n - 1) % Shapes.catalog.length];
  return (name: e.$1, base: e.$2, boss: false);
}

Level _genLevel(int n) {
  final s = _shapeFor(n);
  // Bosses are already large — use the mask as-is; others upscale to target.
  final mask = s.boss ? s.base : _big(s.base, _targetFor(n));
  return Level(
    number: n,
    name: s.name,
    difficulty: _difficultyFor(n),
    rows: mask.length,
    cols: mask[0].length,
    arrows: () => LevelGenerator.fromMask(
      mask,
      seed: n,
      maxLen: _maxLenFor(max(mask.length, mask[0].length)),
      hardness: s.boss ? 1.0 : _hardnessFor(n),
    ),
  );
}

/// 1000 levels. Each builds its puzzle lazily (only when played), so creating
/// the list is cheap. Difficulty loops every 5 (see [_difficultyFor]); pictures
/// cycle through the shape catalog so each level shows a distinct silhouette.
final List<Level> kLevels =
    List.generate(kLevelCount, (i) => _genLevel(i + 1));

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
