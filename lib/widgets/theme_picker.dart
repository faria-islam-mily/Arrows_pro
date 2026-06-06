import 'package:flutter/material.dart';

import '../data/palettes.dart';
import '../state/app_scope.dart';
import '../theme/game_colors.dart';
import 'ui_kit.dart';

const Color _panel = Color(0xFF3F5680);
const Color _tileOff = Color(0xFF34466B);

/// The premium "Pick a Theme" dialog: six distinct board themes (each with a
/// live mini-board preview) plus an always-visible arrow-colour picker.
Future<void> showThemePicker(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _ThemePickerDialog(),
  );
}

class _ThemePickerDialog extends StatelessWidget {
  const _ThemePickerDialog();

  @override
  Widget build(BuildContext context) {
    final state = context.appState; // subscribes → live selection updates
    final themeIdx = state.themeIndex;
    final schemeIdx = state.arrowSchemeIndex;
    final media = MediaQuery.of(context);
    final tileW = (media.size.width.clamp(0, 420) - 48 - 28 - 12) / 2;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.85, end: 1.0),
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              GameColors.headerBlue,
                              GameColors.headerBlueDark
                            ],
                          ),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: const Text('Pick a Theme',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2))
                                ])),
                      ),
                      // Body.
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: _panel,
                          borderRadius:
                              BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Theme grid (scrolls only if the screen is tiny).
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxHeight: media.size.height * 0.42),
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (var i = 0; i < kPalettes.length; i++)
                                        _ThemeCard(
                                          width: tileW.toDouble(),
                                          palette: kPalettes[i],
                                          selected: themeIdx == i,
                                          onTap: () => state.setTheme(i),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Pinned arrow-colour picker (always visible).
                              const _SectionLabel('ARROW COLOR'),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (var i = 0; i < kArrowSchemes.length; i++)
                                    _SchemeSwatch(
                                      scheme: kArrowSchemes[i],
                                      themeArrow: kPalettes[themeIdx].arrow,
                                      selected: schemeIdx == i,
                                      onTap: () => state.setArrowScheme(i),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: 200,
                                child: ChunkyButton(
                                  color: GameColors.green,
                                  depth: 7,
                                  radius: 18,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  onTap: () => Navigator.of(context).pop(),
                                  child: const Text('OKAY',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.w900,
                                          shadows: [
                                            Shadow(
                                                color: Color(0x66000000),
                                                offset: Offset(0, 2))
                                          ])),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: -10,
                    right: -8,
                    child: ChunkyCircleButton(
                      icon: Icons.close_rounded,
                      color: GameColors.red,
                      size: 40,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w900)),
    );
  }
}

/// A theme tile with a live mini-board preview, name, and selected check.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.width,
    required this.palette,
    required this.selected,
    required this.onTap,
  });
  final double width;
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: width,
          child: Container(
            decoration: BoxDecoration(
              color: _tileOff,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? GameColors.green : Colors.white24,
                width: selected ? 3 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: GameColors.green.withValues(alpha: 0.35),
                          blurRadius: 10)
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: SizedBox(
                      height: 74,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.background,
                          gradient: palette.gradient == null
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: palette.gradient!,
                                ),
                        ),
                        child: CustomPaint(painter: _PreviewPainter(palette)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.check_circle_rounded,
                            color: GameColors.green, size: 17),
                        const SizedBox(width: 4),
                      ],
                      Text(palette.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws premium sample arrows (thick rounded shafts + solid heads) in the
/// theme's signature colour, over a faint dot grid — so each theme card reads
/// as a distinct colour.
class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.palette);
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Faint dot grid behind the arrows.
    final dot = Paint()..color = palette.dot.withValues(alpha: 0.55);
    const cols = 7, rows = 4;
    final gx = w / (cols + 1), gy = h / (rows + 1);
    for (var r = 1; r <= rows; r++) {
      for (var c = 1; c <= cols; c++) {
        canvas.drawCircle(Offset(c * gx, r * gy), 1.3, dot);
      }
    }

    // The serpentine "loop" motif: a single rounded path that snakes right →
    // down → left → down → right, with an arrowhead on each horizontal run.
    final col = palette.arrow;
    final sw = (h * 0.09).clamp(4.0, 6.5);
    final stroke = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = col
      ..style = PaintingStyle.fill;

    final xL = w * 0.17, xR = w * 0.83;
    final yT = h * 0.27, yM = h * 0.5, yB = h * 0.73;
    final r = (h * 0.15).clamp(4.0, 12.0);

    final path = Path()
      ..moveTo(xL, yT)
      ..lineTo(xR - r, yT)
      ..quadraticBezierTo(xR, yT, xR, yT + r) // elbow down (right)
      ..lineTo(xR, yM - r)
      ..quadraticBezierTo(xR, yM, xR - r, yM)
      ..lineTo(xL + r, yM)
      ..quadraticBezierTo(xL, yM, xL, yM + r) // elbow down (left)
      ..lineTo(xL, yB - r)
      ..quadraticBezierTo(xL, yB, xL + r, yB)
      ..lineTo(xR, yB);
    canvas.drawPath(path, stroke);

    // Solid arrowheads on each run (top→right, middle→left, bottom→right).
    final hl = (h * 0.16).clamp(6.0, 13.0);
    final hw = (h * 0.12).clamp(5.0, 11.0);
    void head(Offset at, Offset dir) {
      final perp = Offset(-dir.dy, dir.dx);
      final apex = at + dir * hl;
      canvas.drawPath(
        Path()
          ..moveTo(apex.dx, apex.dy)
          ..lineTo(at.dx + perp.dx * hw, at.dy + perp.dy * hw)
          ..lineTo(at.dx - perp.dx * hw, at.dy - perp.dy * hw)
          ..close(),
        fill,
      );
    }

    head(Offset(xL + (xR - xL) * 0.48, yT), const Offset(1, 0));
    head(Offset(xR - (xR - xL) * 0.48, yM), const Offset(-1, 0));
    head(Offset(xR - hl, yB), const Offset(1, 0));
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => old.palette != palette;
}

/// A premium arrow-colour swatch: a colour bar (gradient for multicolour) with
/// a sample arrowhead, plus the scheme name. Selected gets a green ring.
class _SchemeSwatch extends StatelessWidget {
  const _SchemeSwatch({
    required this.scheme,
    required this.themeArrow,
    required this.selected,
    required this.onTap,
  });
  final ArrowScheme scheme;
  final Color themeArrow;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors =
        scheme.usesTheme ? [themeArrow] : scheme.colors;
    final barColors = colors.length == 1
        ? [colors.first, colors.first]
        : colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: SizedBox(
          width: 98,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _tileOff,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? GameColors.green : Colors.white24,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colour bar with a sample arrow.
                Container(
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: barColors),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check_circle_rounded,
                          color: GameColors.green, size: 13),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(scheme.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
