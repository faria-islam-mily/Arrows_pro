import 'grid_arrow.dart';

/// A puzzle definition: a grid of a given size populated with arrows.
class Level {
  const Level({
    required this.number,
    required this.rows,
    required this.cols,
    required this.arrows,
    this.difficulty = 'Easy',
  });

  final int number;
  final int rows;
  final int cols;
  final String difficulty;

  /// Factory builders so each access gives fresh, mutable arrows.
  final List<GridArrow> Function() arrows;
}
