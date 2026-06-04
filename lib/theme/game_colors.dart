import 'package:flutter/material.dart';

/// Fixed bright "casual game" palette for the app shell — the home map, shop,
/// HUD, and dialogs. This is intentionally NOT theme-dependent: only the puzzle
/// board itself follows the selectable [AppPalette] themes. Everything around it
/// uses these constants so the whole UI keeps the glossy, consistent look from
/// the reference design.
class GameColors {
  GameColors._();

  // Dialog / header.
  static const Color headerBlue = Color(0xFF3E9BEC);
  static const Color headerBlueDark = Color(0xFF2C7FD0);

  // Primary action (green).
  static const Color green = Color(0xFF58C42B);
  static const Color greenDark = Color(0xFF43A11C);

  // Cards / accents.
  static const Color purple = Color(0xFF8B45D6);
  static const Color purpleDark = Color(0xFF6E33B0);
  static const Color blue = Color(0xFF3E7BE8);
  static const Color blueDark = Color(0xFF2C5FC0);

  // Destructive / close.
  static const Color red = Color(0xFFE5524A);
  static const Color redDark = Color(0xFFC23A33);

  // Resources.
  static const Color coin = Color(0xFFF7B500);
  static const Color coinDark = Color(0xFFD99400);
  static const Color heart = Color(0xFFFF4D6D);
  static const Color heartDark = Color(0xFFD83356);
  static const Color star = Color(0xFFFFC02E);
  static const Color starDark = Color(0xFFE0941C);

  // Surfaces / text.
  static const Color mapBackground = Color(0xFFEAF1FA);
  static const Color homeBackground = Color(0xFF2E3A5E); // premium dark navy map
  static const Color homeLine = Color(0xFF45517A); // faint path on dark bg
  static const Color panel = Colors.white;
  static const Color hudPill = Color(0xFF222C46); // dark navy HUD pill
  static const Color hudPillBorder = Color(0xFF3A4668);
  static const Color ink = Color(0xFF2B3A67); // deep blue body text
  static const Color inkMuted = Color(0xFF8DA0C2);
  static const Color navBar = Color(0xFF2F7FD0);

  /// A slightly darker shade of [c] for button bevels / bottom lips.
  static Color darken(Color c, [double amount = 0.16]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// A slightly lighter shade of [c] for the top of a gradient.
  static Color lighten(Color c, [double amount = 0.08]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}
