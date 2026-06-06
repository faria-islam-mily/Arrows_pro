import 'package:flutter/material.dart';

/// A full color scheme for one selectable board theme. Themes only style the
/// in-game puzzle (board background, arrows, dots, grid) — the home/shop have
/// their own art. Ordered minimalist → gorgeous in [kPalettes].
class AppPalette {
  const AppPalette({
    required this.name,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.arrow,
    required this.arrowActive,
    required this.textMuted,
    required this.dot,
    this.gradient,
    this.glow = false,
  });

  final String name;
  final Brightness brightness;
  final Color background; // solid board background (and gradient fallback)
  final Color surface; // in-game HUD card / panels
  final Color primary; // themed buttons (pause, progress bar)
  final Color accent; // secondary accent
  final Color arrow; // default arrow glyph color (the "Theme" arrow scheme)
  final Color arrowActive; // hinted / highlighted arrow
  final Color textMuted;
  final Color dot; // the trail-of-dots colour (tuned for contrast)
  final List<Color>? gradient; // optional premium background gradient
  final bool glow; // soft neon glow under arrows (gorgeous themes)
}

/// The six selectable themes. Each has a DISTINCT colour identity — a unique
/// background hue and a signature arrow colour — so they never look alike.
const List<AppPalette> kPalettes = [
  // 1 — Paper: crisp neutral light, ink-navy arrows.
  AppPalette(
    name: 'Paper',
    brightness: Brightness.light,
    background: Color(0xFFF4F3EF),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF3E7BE8),
    accent: Color(0xFFF2A33C),
    arrow: Color(0xFF2A3350),
    arrowActive: Color(0xFFE5524A),
    textMuted: Color(0xFF9AA0AE),
    dot: Color(0xFFBFC4D0),
  ),
  // 2 — Mint: fresh green light, teal arrows.
  AppPalette(
    name: 'Mint',
    brightness: Brightness.light,
    background: Color(0xFFD8F0E7),
    surface: Color(0xFFEEFBF6),
    primary: Color(0xFF0E9B8E),
    accent: Color(0xFF5B5BE6),
    arrow: Color(0xFF0C857A),
    arrowActive: Color(0xFFE5524A),
    textMuted: Color(0xFF5E8B81),
    dot: Color(0xFF8FC2B5),
  ),
  // 3 — Ocean: sky-blue light, strong blue arrows.
  AppPalette(
    name: 'Ocean',
    brightness: Brightness.light,
    background: Color(0xFFD6E8FB),
    surface: Color(0xFFEDF5FF),
    primary: Color(0xFF2D6CDF),
    accent: Color(0xFF1B9AAA),
    arrow: Color(0xFF1D4ED8),
    arrowActive: Color(0xFFE5524A),
    textMuted: Color(0xFF6E7E94),
    dot: Color(0xFF9FBEE2),
  ),
  // 4 — Midnight: clean blue-dark, near-white arrows (max contrast).
  AppPalette(
    name: 'Midnight',
    brightness: Brightness.dark,
    background: Color(0xFF0E1622),
    surface: Color(0xFF18242F),
    primary: Color(0xFF2AB7B7),
    accent: Color(0xFFFFC83D),
    arrow: Color(0xFFEAF1F6),
    arrowActive: Color(0xFFFF6B6B),
    textMuted: Color(0xFF8AA0AD),
    dot: Color(0xFF3C4D60),
  ),
  // 5 — Arcade: deep indigo gradient, vivid coral arrows + glow.
  AppPalette(
    name: 'Arcade',
    brightness: Brightness.dark,
    background: Color(0xFF1B1740),
    surface: Color(0xFF2A2D55),
    primary: Color(0xFF4E5DF2),
    accent: Color(0xFFFFC83D),
    arrow: Color(0xFFFF6B4A),
    arrowActive: Color(0xFFFFD23F),
    textMuted: Color(0xFF9590C0),
    dot: Color(0xFF4A4480),
    gradient: [Color(0xFF2C2860), Color(0xFF161031)],
  ),
  // 6 — Neon: dark magenta, hot-pink arrows + glow.
  AppPalette(
    name: 'Neon',
    brightness: Brightness.dark,
    background: Color(0xFF1A0E2A),
    surface: Color(0xFF2A1840),
    primary: Color(0xFFC24DD6),
    accent: Color(0xFF22D3EE),
    arrow: Color(0xFFFF49A0),
    arrowActive: Color(0xFF22D3EE),
    textMuted: Color(0xFFA48ABF),
    dot: Color(0xFF553466),
    gradient: [Color(0xFF2A1140), Color(0xFF130A22)],
  ),
];

/// An arrow-colour scheme, chosen independently of the board theme. An empty
/// [colors] list means "follow the theme's [AppPalette.arrow]" (mono).
class ArrowScheme {
  const ArrowScheme(this.name, this.colors);
  final String name;
  final List<Color> colors;

  bool get usesTheme => colors.isEmpty;

  /// Colour for the arrow with the given [seed] (its id) — cycles a multicolour
  /// set, or returns the single colour for a mono scheme.
  Color colorFor(int seed, Color themeArrow) {
    if (colors.isEmpty) return themeArrow;
    return colors[seed % colors.length];
  }
}

/// Selectable arrow colours. Chosen to stay readable on both light and dark
/// boards (no pale yellows/whites that vanish on a light theme).
const List<ArrowScheme> kArrowSchemes = [
  ArrowScheme('Theme', []), // mono — follows the board theme
  ArrowScheme('Vibrant', [
    Color(0xFF17B6C9),
    Color(0xFFFF7A2F),
    Color(0xFFF0444B),
    Color(0xFF7C5CFF),
    Color(0xFF2BB763),
    Color(0xFFE8951E),
  ]),
  ArrowScheme('Ocean', [Color(0xFF2E8BFF)]),
  ArrowScheme('Sunset', [Color(0xFFFF6A3D)]),
  ArrowScheme('Candy', [
    Color(0xFFFF6FB5),
    Color(0xFF36C6C0),
    Color(0xFF9B7BFF),
    Color(0xFFFF9F45),
    Color(0xFF4FA8FF),
  ]),
];
