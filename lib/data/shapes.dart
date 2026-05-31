/// Picture masks for generated levels.
///
/// Legend: '#' = place an arrow here, anything else = empty cell.
/// All rows in a mask must be the same length.
class Shapes {
  Shapes._();

  /// A heart (11 wide x 9 tall).
  static const heart = [
    '.###...###.',
    '###########',
    '###########',
    '###########',
    '.#########.',
    '..#######..',
    '...#####...',
    '....###....',
    '.....#.....',
  ];

  /// Sunglasses (13 wide x 5 tall) with a nose bridge.
  static const glasses = [
    '.###.....###.',
    '#####.#.#####',
    '#####.#.#####',
    '#####...#####',
    '.###.....###.',
  ];

  /// A diamond (9 wide x 9 tall) — a gentler intro picture.
  static const diamond = [
    '....#....',
    '...###...',
    '..#####..',
    '.#######.',
    '#########',
    '.#######.',
    '..#####..',
    '...###...',
    '....#....',
  ];
}
