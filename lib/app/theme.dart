import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0E1415);
  static const surface = Color(0xFF0E1415);
  static const surfaceContainer = Color(0xFF1B2121);
  static const surfaceContainerHigh = Color(0xFF252B2B);
  static const surfaceContainerHighest = Color(0xFF303636);

  static const outlineVariant = Color(0xFF3C494A);

  static const onBackground = Color(0xFFDEE4E4);
  static const onSurfaceVariant = Color(0xFFBBC9CA);

  static const primary = Color(0xFF55D8E1);
  static const primaryContainer = Color(0xFF00ADB5);

  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);

  static const tertiary = Color(0xFFFFB68D);
  static const tertiaryContainer = Color(0xFFE2844A);
}

ThemeData buildDarkTheme() {
  final colorScheme = const ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Color(0xFF003739),
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: Color(0xFF003A3D),

    surface: AppColors.surface,
    onSurface: AppColors.onBackground,

    error: AppColors.error,
    onError: Color(0xFF690005),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primary,
      centerTitle: true,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
      ),
    ),

    dividerColor: AppColors.outlineVariant.withOpacity(0.2),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainer,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
    ),
  );
}