import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Nurse Portal Royal Blue Palette (Ocean Sapphire default)
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

  // Soft Card Shadow
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

/// Exact 6 Personal Themes on `https://hospital.hrpocket.in/profile` -> `My Theme` (image-12)
class NursePersonalTheme {
  final String id;
  final String name;
  final String subtitle;
  final List<Color> bannerGradient;
  final Color appBarColor;
  final Color appBarForeground;
  final Color primaryColor;
  final Color scaffoldColor;
  final bool isDarkBody;

  const NursePersonalTheme({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.bannerGradient,
    required this.appBarColor,
    this.appBarForeground = Colors.white,
    required this.primaryColor,
    this.scaffoldColor = const Color(0xFFF1F6FD),
    this.isDarkBody = false,
  });

  static const List<NursePersonalTheme> presets = [
    NursePersonalTheme(
      id: 'ocean_sapphire',
      name: 'Ocean Sapphire',
      subtitle: 'High-Trust Clinical Command',
      bannerGradient: [Color(0xFF042240), Color(0xFF026AA7)],
      appBarColor: Color(0xFF0A4D78),
      primaryColor: Color(0xFF0A4D78),
      scaffoldColor: Color(0xFFF1F6FD),
    ),
    NursePersonalTheme(
      id: 'bio_emerald',
      name: 'Bio-Emerald & Mint',
      subtitle: 'Fresh Wellness & Surgical Tech',
      bannerGradient: [Color(0xFF042F24), Color(0xFF059669)],
      appBarColor: Color(0xFF065F46),
      primaryColor: Color(0xFF047857),
      scaffoldColor: Color(0xFFF0FDF4),
    ),
    NursePersonalTheme(
      id: 'glacier_blue',
      name: 'Glacier Blue',
      subtitle: 'Bright Focus for Busy Teams',
      bannerGradient: [Color(0xFFFFFFFF), Color(0xFFE0F2FE)],
      appBarColor: Color(0xFFE0F2FE),
      appBarForeground: Color(0xFF0F172A),
      primaryColor: Color(0xFF0284C7),
      scaffoldColor: Color(0xFFF8FAFC),
    ),
    NursePersonalTheme(
      id: 'midnight_obsidian',
      name: 'Midnight Obsidian',
      subtitle: 'Sleek OLED Night Mode',
      bannerGradient: [Color(0xFF090A10), Color(0xFF3730A3)],
      appBarColor: Color(0xFF0D101C),
      primaryColor: Color(0xFF4F46E5),
      scaffoldColor: Color(0xFFEEF2FF),
      isDarkBody: true,
    ),
    NursePersonalTheme(
      id: 'sunrise_coral',
      name: 'Sunrise Coral',
      subtitle: 'Human, Warm & Welcoming',
      bannerGradient: [Color(0xFF3B1208), Color(0xFFEA580C)],
      appBarColor: Color(0xFF9A3412),
      primaryColor: Color(0xFFC2410C),
      scaffoldColor: Color(0xFFFFF7ED),
    ),
    NursePersonalTheme(
      id: 'royal_amethyst',
      name: 'Royal Amethyst',
      subtitle: 'Calm Precision & Authority',
      bannerGradient: [Color(0xFF1E0B36), Color(0xFF7E22CE)],
      appBarColor: Color(0xFF4C1D95),
      primaryColor: Color(0xFF6D28D9),
      scaffoldColor: Color(0xFFFAF5FF),
    ),
  ];

  static NursePersonalTheme byId(String? id) {
    if (id == null || id.isEmpty) return presets.first;
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return presets.first;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme =>
      fromPersonalTheme(NursePersonalTheme.presets.first);

  static ThemeData fromPersonalTheme(NursePersonalTheme preset) {
    final primary = preset.primaryColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: primary,
      surface: AppColors.cardSurface,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: preset.scaffoldColor,
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
          vertical: 14,
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
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
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
