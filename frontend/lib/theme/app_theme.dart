import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepLeafGreen = Color(0xFF2E7D32);
  static const Color freshGreen = Color(0xFF4CAF50);
  static const Color lightMint = Color(0xFFE8F5E9);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softGray = Color(0xFFF5F7F6);
  static const Color accentGold = Color(0xFFD4A017);
  static const Color darkGreen = Color(0xFF1B5E20);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepLeafGreen,
        primary: deepLeafGreen,
        secondary: freshGreen,
        background: softGray,
        surface: pureWhite,
      ),
      scaffoldBackgroundColor: softGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: pureWhite,
        foregroundColor: deepLeafGreen,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: deepLeafGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 2,
        shadowColor: deepLeafGreen.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepLeafGreen,
          foregroundColor: pureWhite,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: deepLeafGreen.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: deepLeafGreen.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: freshGreen, width: 2),
        ),
        labelStyle: TextStyle(color: deepLeafGreen.withOpacity(0.6)),
        floatingLabelStyle: const TextStyle(color: freshGreen),
      ),
    );
  }
}
