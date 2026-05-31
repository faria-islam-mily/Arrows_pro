import 'dart:math';

/// Direction an arrow's head points (the way it slides to escape).
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

/// An arrow on the board: an ordered poly-line of grid cells (tail → head),
/// drawn as a thick rounded stroke with an arrowhead at [head]. A straight
/// arrow has collinear cells; a bent arrow turns. It escapes by sliding in
/// [dir] (the head's direction).
///
/// Cells use [Point] as (x = column, y = row).
class GridArrow {
  GridArrow({required this.id, required this.cells, required this.dir})
      : assert(cells.isNotEmpty);

  final int id;
  final List<Point<int>> cells; // tail .. head
  final ArrowDir dir;
  bool removed = false;

  Point<int> get head => cells.last;

  GridArrow clone() =>
      GridArrow(id: id, cells: List.of(cells), dir: dir)..removed = removed;
}
