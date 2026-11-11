import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Clinical Sapphire Palette
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryDark = Color(0xFF093257);
  static const Color primaryLight = Color(0xFF2563EB);
  static const Color accentSky = Color(0xFF0284C7);

  // Clean Modern Mobile Surfaces
  static const Color scaffoldBg = Color(0xFFF5F7FA);
  static const Color skySurface = Color(0xFFEFF6FF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5EAF2);
  static const Color divider = Color(0xFFEEF2F6);

  // Crisp Editorial Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Semantic Clinical Colors
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEF2F2);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);

  static const Color teal = Color(0xFF0D9488);
  static const Color tealSoft = Color(0xFFF0FDFA);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF5F3FF);

  // Diffused Ambient Shadow
  static const Color cardShadow = Color(0x0A0F172A);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B2545),
      Color(0xFF0F4C81),
      Color(0xFF1D6FA5),
    ],
  );

  static const LinearGradient splashSkyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE0ECFA),
      Color(0xFFF5F7FA),
      Color(0xFFFFFFFF),
    ],
  );
}

/// Exact 6 Personal Themes on `https://hospital.hrpocket.in/profile` -> `My Theme`
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
    this.scaffoldColor = const Color(0xFFF5F7FA),
    this.isDarkBody = false,
  });

  static const List<NursePersonalTheme> presets = [
    NursePersonalTheme(
      id: 'ocean_sapphire',
      name: 'Ocean Sapphire',
      subtitle: 'High-Trust Clinical Command',
      bannerGradient: [Color(0xFF0B2545), Color(0xFF13548A)],
      appBarColor: Color(0xFF0B2545),
      primaryColor: Color(0xFF0F4C81),
      scaffoldColor: Color(0xFFF5F7FA),
    ),
    NursePersonalTheme(
      id: 'bio_emerald',
      name: 'Bio-Emerald & Mint',
      subtitle: 'Fresh Wellness & Surgical Tech',
      bannerGradient: [Color(0xFF063729), Color(0xFF059669)],
      appBarColor: Color(0xFF064E3B),
      primaryColor: Color(0xFF059669),
      scaffoldColor: Color(0xFFF4F9F6),
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
      bannerGradient: [Color(0xFF090D16), Color(0xFF312E81)],
      appBarColor: Color(0xFF0F172A),
      primaryColor: Color(0xFF4F46E5),
      scaffoldColor: Color(0xFFF3F4F8),
      isDarkBody: true,
    ),
    NursePersonalTheme(
      id: 'sunrise_coral',
      name: 'Sunrise Coral',
      subtitle: 'Human, Warm & Welcoming',
      bannerGradient: [Color(0xFF431407), Color(0xFFEA580C)],
      appBarColor: Color(0xFF9A3412),
      primaryColor: Color(0xFFD9480F),
      scaffoldColor: Color(0xFFFAF6F3),
    ),
    NursePersonalTheme(
      id: 'royal_amethyst',
      name: 'Royal Amethyst',
      subtitle: 'Calm Precision & Authority',
      bannerGradient: [Color(0xFF240B36), Color(0xFF7C3AED)],
      appBarColor: Color(0xFF4C1D95),
      primaryColor: Color(0xFF6D28D9),
      scaffoldColor: Color(0xFFF7F5FA),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
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
          borderSide: BorderSide(color: primary, width: 1.5),
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
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
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
