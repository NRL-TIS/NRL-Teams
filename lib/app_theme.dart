import 'package:flutter/material.dart';

class AppTheme {
  static const Color _brand = Color.fromARGB(255, 254, 1, 172);

  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: Brightness.dark,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs.copyWith(primary: _brand, secondary: _brand),
      scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
      cardTheme: CardTheme(
        color: const Color(0xFF151518),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF151518),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _brand, width: 1.2),
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _brand,
        ),
      ),
    );
  }

  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: Brightness.light,
    );
    return ThemeData(useMaterial3: true, colorScheme: cs);
  }
}
