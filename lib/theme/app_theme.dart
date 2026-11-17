import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static const primaryGreen = AppColors.primary;
  static const lightGreen = AppColors.lightGreen;
  static const accentGreen = AppColors.secondary;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    primaryColor: primaryGreen,

    scaffoldBackgroundColor: lightGreen,

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: AppColors.textLight,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentGreen,
        foregroundColor: AppColors.textLight,
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
