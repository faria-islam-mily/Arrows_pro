import 'dart:math' as m;

/// Procedurally generates large, intricate, symmetric masks so every level is a
/// distinct dense pattern. Bigger sizes intentionally overflow the screen — the
/// player pans/zooms to read the arrows. ANY mask is valid: the level generator
/// guarantees a solvable, gap-free, non-self-touching layout and the test-suite
/// re-checks every shipped level.
///
/// Five families, varied by the level index, give 100s of unique silhouettes:
/// mandala (flowers/webs), lattice (circuit/grid mesh), concentric (nested
/// rings/diamonds), organic (mirrored sine blobs), and starburst (radial arms).
class IntricateShapes {
  IntricateShapes._();

  static const _hash = '#'; // filled
  static const _gap = '.'; // empty

  static List<String> mask(int index, int size) {
    final n = size < 5 ? 5 : size;
    final grid = List.generate(n, (_) => List<bool>.filled(n, false));

    switch (index % 5) {
      case 0:
        _mandala(grid, index);
      case 1:
        _lattice(grid, index);
      case 2:
        _concentric(grid, index);
      case 3:
        _organic(grid, index);
      default:
        _starburst(grid, index);
    }
    _ensureDense(grid);

    return [
      for (final row in grid)
        row.map((f) => f ? _hash : _gap).join(),
    ];
  }

  static double _c(int n) => (n - 1) / 2;

  /// Flower / web mandala: petal boundary in polar coords with ring texture.
  static void _mandala(List<List<bool>> g, int index) {
    final n = g.length;
    final c = _c(n);
    final petals = 3 + index % 6;
    final ringFreq = 2 + index % 3;
    final phase = (index % 8) * 0.45;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final dx = x - c, dy = y - c;
        final r = m.sqrt(dx * dx + dy * dy) / (n / 2);
        if (r > 1.02) continue;
        final ang = m.atan2(dy, dx);
        final petalR = 0.55 + 0.42 * m.cos(petals * ang + phase);
        final ring = m.cos(r * ringFreq * 2 * m.pi) > -0.4;
        g[y][x] = r < 0.22 || (r <= petalR && ring);
      }
    }
  }

  /// Circuit / grid mesh: crossing bars with a solid frame.
  static void _lattice(List<List<bool>> g, int index) {
    final n = g.length;
    final block = 2 + index % 3;
    final period = block + (1 + index % 2);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        g[y][x] = (x % period) < block || (y % period) < block;
      }
    }
    for (var i = 0; i < n; i++) {
      g[0][i] = g[n - 1][i] = g[i][0] = g[i][n - 1] = true;
    }
  }

  /// Nested rings or diamonds filling the board in alternating bands.
  static void _concentric(List<List<bool>> g, int index) {
    final n = g.length;
    final c = _c(n);
    final thick = 2 + index % 2;
    final diamond = index % 2 == 0;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final dx = (x - c).abs(), dy = (y - c).abs();
        final d = diamond ? (dx + dy) : m.max(dx, dy);
        g[y][x] = ((d / thick).floor() % 2) == 0;
      }
    }
  }

  /// Mirrored sine field → an organic, symmetric blob inside a disk.
  static void _organic(List<List<bool>> g, int index) {
    final n = g.length;
    final c = _c(n);
    final f1 = 0.55 + (index % 4) * 0.18;
    final f2 = 0.5 + (index % 3) * 0.22;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final mx = x <= c ? x : (n - 1 - x); // 4-fold symmetry
        final my = y <= c ? y : (n - 1 - y);
        final v = m.sin(mx * f1 + index) * m.cos(my * f2) +
            m.sin((mx + my) * 0.5);
        final dx = x - c, dy = y - c;
        final r = m.sqrt(dx * dx + dy * dy) / (n / 2);
        g[y][x] = r < 1.0 && v > -0.25;
      }
    }
  }

  /// Many radial arms from a solid core.
  static void _starburst(List<List<bool>> g, int index) {
    final n = g.length;
    final c = _c(n);
    final arms = 6 + index % 8;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final dx = x - c, dy = y - c;
        final r = m.sqrt(dx * dx + dy * dy) / (n / 2);
        if (r > 1.02) continue;
        final ang = m.atan2(dy, dx);
        final spike = 0.38 + 0.6 * (0.5 + 0.5 * m.cos(arms * ang));
        g[y][x] = r < 0.28 || r <= spike;
      }
    }
  }

  /// Guarantee a substantial number of cells (never a near-empty board).
  static void _ensureDense(List<List<bool>> g) {
    final n = g.length;
    var count = 0;
    for (final row in g) {
      for (final f in row) {
        if (f) count++;
      }
    }
    if (count >= n * n * 0.2) return;
    final c = _c(n);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if ((x - c).abs() + (y - c).abs() <= n * 0.5) g[y][x] = true;
      }
    }
  }
}
