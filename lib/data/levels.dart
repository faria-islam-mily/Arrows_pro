import '../game/level_generator.dart';
import '../models/grid_arrow.dart';
import '../models/level.dart';
import 'shapes.dart';

/// A solid rectangle mask (every cell filled with arrows).
List<String> _filled(int rows, int cols) =>
    List.generate(rows, (_) => '#' * cols);

Level _gen(int number, String difficulty, List<String> mask, {int maxLen = 6}) {
  return Level(
    number: number,
    rows: mask.length,
    cols: mask[0].length,
    difficulty: difficulty,
    arrows: () => LevelGenerator.fromMask(mask, seed: number, maxLen: maxLen),
  );
}

/// Level pack — dense, picture-forming, all solvable by construction.
final List<Level> kLevels = [
  _gen(1, 'Tutorial', _filled(3, 3), maxLen: 2),
  _gen(2, 'Easy', _filled(5, 5), maxLen: 3),
  _gen(3, 'Easy', Shapes.diamond, maxLen: 4),
  _gen(4, 'Medium', _filled(7, 7), maxLen: 5),
  _gen(5, 'Medium', _filled(9, 9), maxLen: 6),
  _gen(6, 'Hard', Shapes.heart, maxLen: 6),
  _gen(7, 'Hard', Shapes.glasses, maxLen: 6),
];

/// Unused helper kept for hand-authored levels later.
List<GridArrow> noArrows() => <GridArrow>[];
