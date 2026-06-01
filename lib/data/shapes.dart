/// Picture masks for generated levels.
///
/// Legend: '#' = place an arrow here, anything else = empty cell.
/// All rows in a mask must be the same length. Keep shapes "solid" enough that
/// every cell can reach an edge — the generator guarantees solvability and the
/// test-suite re-checks every shipped level, so a bad mask fails loudly.
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

  /// A diamond (9 wide x 9 tall) — a gentle intro picture.
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

  /// A plus / cross (9 wide x 9 tall).
  static const cross = [
    '...###...',
    '...###...',
    '...###...',
    '#########',
    '#########',
    '#########',
    '...###...',
    '...###...',
    '...###...',
  ];

  /// A pyramid / triangle (9 wide x 5 tall).
  static const triangle = [
    '....#....',
    '...###...',
    '..#####..',
    '.#######.',
    '#########',
  ];

  /// A chevron / down-arrow (9 wide x 7 tall).
  static const chevron = [
    '##.....##',
    '###...###',
    '.###.###.',
    '..#####..',
    '...###...',
    '....#....',
    '....#....',
  ];

  /// All picture masks, used to sprinkle shape levels through the pack.
  static const pack = [diamond, heart, glasses, cross, triangle, chevron];
}