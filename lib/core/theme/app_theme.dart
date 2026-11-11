import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Nurse Portal Royal Blue Palette (matching Nurse Portal UI design)
  static const Color primary = Color(0xFF0B53A6);
  static const Color primaryDark = Color(0xFF073B7A);
  static const Color primaryLight = Color(0xFF1E74D6);
  static const Color accentSky = Color(0xFF3B8EEA);

  // Backgrounds & Surfaces
  static const Color scaffoldBg = Color(0xFFF1F6FD);
  static const Color skySurface = Color(0xFFE6F0FC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF5F8FD);
  static const Color border = Color(0xFFDCE7F5);
  static const Color divider = Color(0xFFE7EFFA);

  // Typography
  static const Color textPrimary = Color(0xFF0F2544);
  static const Color textSecondary = Color(0xFF566B88);
  static const Color textMuted = Color(0xFF889BB5);

  // Clinical Semantic Status Colors
  static const Color success = Color(0xFF1F9D55);
  static const Color successSoft = Color(0xFFE6F6ED);

  static const Color warning = Color(0xFFEA7A18);
  static const Color warningSoft = Color(0xFFFFF2E2);

  static const Color danger = Color(0xFFD93036);
  static const Color dangerSoft = Color(0xFFFDEAEB);

  static const Color info = Color(0xFF1565C0);
  static const Color infoSoft = Color(0xFFE4F0FE);

  static const Color teal = Color(0xFF0D9488);
  static const Color tealSoft = Color(0xFFE2F7F5);

  static const Color purple = Color(0xFF6D28D9);
  static const Color purpleSoft = Color(0xFFF0E9FE);

  // Soft Card Shadow (zero-warning constant alpha)
  static const Color cardShadow = Color(0x140B4F9E);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF08428A),
      Color(0xFF0E5BB5),
      Color(0xFF1C75D8),
    ],
  );

  static const LinearGradient splashSkyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFCDE2FC),
      Color(0xFFEAF3FE),
      Color(0xFFFFFFFF),
    ],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accentSky,
      surface: AppColors.cardSurface,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 0.9),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
