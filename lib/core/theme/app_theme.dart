import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFFB83830);
  static const secondary = Color(0xFF3898B8);
  static const accent = Color(0xFF58D0D8);
  static const background = Color(0xFF202628);
  static const surface = Color(0xFF303030);
  static const onPrimary = Color(0xFFE8FAFB);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.surface,
      onPrimary: AppColors.onPrimary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onPrimary,
        centerTitle: true,
      ),
      textTheme: Typography.whiteMountainView,
    );
  }
}
