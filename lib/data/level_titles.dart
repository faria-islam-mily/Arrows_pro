/// Evocative names for levels, ordered roughly easy → brutal. `levelTitle`
/// maps a level number across the whole pack so early levels get the tamer
/// organic/geometric names and the final levels hit the "Extreme" ones.
const List<String> kLevelTitles = [
  // Organic / gentle
  'Honeycomb Maze', 'Coral Reef', 'Vine Tangle', 'Root Network',
  'Mushroom Colony', 'Tree of Life', 'Crystal Cave', 'Thorn Crown',
  'Ant Colony', 'Spider Nest',
  // Geometric
  'Double Diamond', 'Hex Nexus', 'Radial Grid', 'Octagonal Web',
  'Triple Spiral', 'Interlocking Rings', 'Penrose Loop', 'Mobius Ring',
  'Sierpinski Triangle', 'Fractal Tree',
  // Technology
  'Circuit Board', 'Processor Core', 'Data Cluster', 'Network Mesh',
  'Logic Matrix', 'Server Rack', 'Mainframe', 'Quantum Grid',
  'Binary Nexus', 'Hypercube',
  // Expert
  'Labyrinth', 'Spider Web', 'Infinity Loop', 'Double Helix', 'Nexus',
  'Hive', 'Hourglass', 'Fracture', 'Constellation', 'Gridlock',
  // Master
  'Dragon Spine', 'Quantum Maze', 'Neural Network', 'Black Hole',
  'Singularity', 'Crystal Matrix', 'Iron Fortress', 'Tangled Roots',
  'Obsidian Crown', 'Phantom Circuit',
  // Extreme
  'Chaos Engine', 'Leviathan', 'Hydra', 'The Citadel', 'Eclipse',
  'The Core', 'Cataclysm', 'The Archive', 'Pandora', 'Entropy',
];

/// A themed name for level [n] (1-based), spread across [total] levels so the
/// difficulty of the name tracks progress. Level 1 is the gentle intro.
String levelTitle(int n, {int total = 100}) {
  if (n <= 1) return 'First Steps';
  final span = total - 1; // levels 2..total map across the list
  final idx = ((n - 2) * kLevelTitles.length) ~/ (span < 1 ? 1 : span);
  return kLevelTitles[idx.clamp(0, kLevelTitles.length - 1)];
}
