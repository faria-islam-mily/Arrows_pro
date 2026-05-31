import 'package:flutter/material.dart';

import '../data/palettes.dart';

class AppTheme {
  AppTheme._();

  static ThemeData fromPalette(AppPalette p) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: p.brightness,
        primary: p.primary,
        surface: p.surface,
      ),
      scaffoldBackgroundColor: p.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: p.arrow,
        displayColor: p.arrow,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
