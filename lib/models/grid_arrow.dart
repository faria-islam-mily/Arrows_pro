import 'dart:math';

/// Direction an arrow points (the way it slides to escape).
enum ArrowDir { up, down, left, right }

extension ArrowDirX on ArrowDir {
  int get dRow => switch (this) {
        ArrowDir.up => -1,
        ArrowDir.down => 1,
        ArrowDir.left => 0,
        ArrowDir.right => 0,
      };

  int get dCol => switch (this) {
        ArrowDir.up => 0,
        ArrowDir.down => 0,
        ArrowDir.left => -1,
        ArrowDir.right => 1,
      };

  Point<int> get delta => Point(dCol, dRow);
}

/// A rigid arrow on the board, occupying one or more collinear cells and
/// pointing in [dir]. It escapes by sliding straight in [dir] when the corridor
/// ahead of its [head] is clear of other arrows.
///
/// Levels are built from single-cell arrows via [GridArrow.single]; the general
/// list form is kept for future multi-cell pieces (e.g. a 2-long block).
///
/// Cells use [Point] as (x = column, y = row).
class GridArrow {
  GridArrow({required this.id, required this.cells, required this.dir})
      : assert(cells.isNotEmpty);

  /// A single-cell arrow at [cell] pointing in [dir] — the standard piece.
  GridArrow.single({
    required this.id,
    required Point<int> cell,
    required this.dir,
  }) : cells = [cell];

  final int id;
  final List<Point<int>> cells; // tail .. head
  final ArrowDir dir;
  bool removed = false;

  Point<int> get head => cells.last;

  GridArrow clone() =>
      GridArrow(id: id, cells: List.of(cells), dir: dir)..removed = removed;
}