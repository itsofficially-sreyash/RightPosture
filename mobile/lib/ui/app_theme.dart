import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF131316);
  static const surface = Color(0xFF1F1F22);
  static const surfaceElevated = Color(0xFF1C1C21);
  static const surfaceContainerHigh = Color(0xFF2A2A2D);
  static const surfaceGlass = Color(0xF21C1C21);
  static const outlineVariant = Color(0xFF444933);
  static const lime = Color(0xFFC3F400);
  static const cyan = Color(0xFF9CF0FF);
  static const success = Color(0xFF22C55E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFBEBEC6);
  static const warning = Color(0xFFFFB84D);
  static const degraded = Color(0xFFFF5A5A);
}

abstract final class AppSpacing {
  static const base = 4.0;
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const extraLarge = 32.0;
}

abstract final class AppRadius {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 24.0;
  static const pill = 999.0;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.lime,
    brightness: Brightness.dark,
    surface: AppColors.surface,
    error: AppColors.degraded,
  );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 64,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 34,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textMuted,
        fontSize: 14,
        height: 1.5,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.background,
        minimumSize: const Size(48, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        side: const BorderSide(color: AppColors.outlineVariant),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.lime,
      height: 72,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
      ),
    ),
  );
}
