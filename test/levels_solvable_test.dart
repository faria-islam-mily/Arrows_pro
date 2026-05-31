import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_pro/data/levels.dart';
import 'package:arrow_pro/data/shapes.dart';
import 'package:arrow_pro/game/game_controller.dart';
import 'package:arrow_pro/game/level_generator.dart';

void main() {
  group('Level pack', () {
    for (final level in kLevels) {
      test('Level ${level.number} (${level.difficulty}) is solvable', () {
        expect(GameController.solvable(level), isTrue);
      });
    }

    test('first level is the tutorial', () {
      expect(kLevels.first.difficulty, 'Tutorial');
    });

    test('levels are deterministic', () {
      final a = kLevels.last.arrows();
      final b = kLevels.last.arrows();
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].dir, b[i].dir);
        expect(a[i].cells, b[i].cells);
      }
    });
  });

  group('Picture generator', () {
    for (final entry in {
      'diamond': Shapes.diamond,
      'heart': Shapes.heart,
      'glasses': Shapes.glasses,
    }.entries) {
      test('${entry.key} covers EVERY mask cell (no gaps)', () {
        final maskCells = entry.value
            .fold<int>(0, (n, row) => n + '#'.allMatches(row).length);
        final arrows = LevelGenerator.fromMask(entry.value, seed: 1);
        final cells = <Object>{};
        for (final a in arrows) {
          cells.addAll(a.cells);
        }
        // No overlaps and no gaps: covered cells == mask cells exactly.
        expect(arrows.fold<int>(0, (n, a) => n + a.cells.length), maskCells);
        expect(cells.length, maskCells);
      });
    }
  });
}
