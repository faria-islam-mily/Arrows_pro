import 'package:flutter/material.dart';

/// A full color scheme for one selectable theme.
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
  });

  final String name;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color arrow; // arrow glyph color
  final Color arrowActive; // hinted / highlighted arrow
  final Color textMuted;
}

/// Selectable themes, including an eye-friendly (dark) option.
const List<AppPalette> kPalettes = [
  AppPalette(
    name: 'Mint',
    brightness: Brightness.light,
    background: Color(0xFFEAF6F2),
    surface: Color(0xFFF4FBF8),
    primary: Color(0xFF0E8B8B),
    accent: Color(0xFF5B5BE6),
    arrow: Color(0xFF14243A),
    arrowActive: Color(0xFFE63946),
    textMuted: Color(0xFF6B8079),
  ),
  AppPalette(
    name: 'Cream',
    brightness: Brightness.light,
    background: Color(0xFFF3ECDD),
    surface: Color(0xFFFBF7EC),
    primary: Color(0xFFB5762B),
    accent: Color(0xFF0E8B8B),
    arrow: Color(0xFF3A2E1E),
    arrowActive: Color(0xFFC0392B),
    textMuted: Color(0xFF8A7B63),
  ),
  AppPalette(
    name: 'Ocean',
    brightness: Brightness.light,
    background: Color(0xFFE7F0FB),
    surface: Color(0xFFF4F9FF),
    primary: Color(0xFF2D6CDF),
    accent: Color(0xFF1B9AAA),
    arrow: Color(0xFF14243A),
    arrowActive: Color(0xFFE63946),
    textMuted: Color(0xFF6B7A90),
  ),
  AppPalette(
    name: 'Midnight',
    brightness: Brightness.dark,
    background: Color(0xFF0F1A24),
    surface: Color(0xFF17242F),
    primary: Color(0xFF2AB7B7),
    accent: Color(0xFF7B7BF0),
    arrow: Color(0xFFE6EEF2),
    arrowActive: Color(0xFFFF6B6B),
    textMuted: Color(0xFF8AA0AD),
  ),
];
