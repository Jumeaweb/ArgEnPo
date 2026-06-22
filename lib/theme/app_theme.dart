import 'package:flutter/material.dart';

class AppTheme {
  static const primaryGreen = Color(0xFF1B5E20);
  static const lightGreen = Color(0xFFE8F5E9);
  static const accentGreen = Color(0xFF2E7D32);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    primaryColor: primaryGreen,

    scaffoldBackgroundColor: lightGreen,

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentGreen,
        foregroundColor: Colors.white,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}