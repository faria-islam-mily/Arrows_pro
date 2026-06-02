import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_pro/data/levels.dart';
import 'package:arrow_pro/data/shapes.dart';
import 'package:arrow_pro/game/game_controller.dart';
import 'package:arrow_pro/game/level_generator.dart';
import 'package:arrow_pro/models/grid_arrow.dart';

void main() {
  group('Level pack', () {
    for (final level in kLevels) {
      test('Level ${level.number} (${level.difficulty}) is solvable', () {
        expect(GameController.solvable(level), isTrue);
      });
    }

    test('pack has 10 distinctly named levels', () {
      expect(kLevels.length, 10);
      for (final l in kLevels) {
        expect(l.name, isNotEmpty);
      }
    });

    test('no arrow head sits on its own body', () {
      for (final level in kLevels) {
        for (final a in level.arrows()) {
          final fwd = Point(a.head.x + a.dir.dCol, a.head.y + a.dir.dRow);
          expect(a.cells.contains(fwd), isFalse,
              reason: 'Level ${level.number}: arrow ${a.id} head points into '
                  'its own body at $fwd');
        }
      }
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
