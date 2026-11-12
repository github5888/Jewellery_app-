import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  // Executive Clinical Sapphire Palette
  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryDark = Color(0xFF082849);
  static const Color primaryLight = Color(0xFF2563EB);
  static const Color accentSky = Color(0xFF0284C7);

  // Studio-Lit Layered Surfaces
  static const Color scaffoldBg = Color(0xFFF4F7FB);
  static const Color skySurface = Color(0xFFEFF5FF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5ECF4);
  static const Color divider = Color(0xFFEDF2F7);

  // Editorial Ink Typography
  static const Color textPrimary = Color(0xFF0B1528);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Semantic Clinical Accents
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);

  static const Color danger = Color(0xFFE11D48);
  static const Color dangerSoft = Color(0xFFFFF1F2);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);

  static const Color teal = Color(0xFF0D9488);
  static const Color tealSoft = Color(0xFFF0FDFA);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF5F3FF);

  // Multi-layer Diffused Ambient Shadows
  static const Color cardShadow = Color(0x0B0F172A);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF071B34),
      Color(0xFF0F4C81),
      Color(0xFF1B6CA8),
    ],
  );

  static const LinearGradient splashSkyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFDFECFA),
      Color(0xFFF4F7FB),
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
    this.scaffoldColor = const Color(0xFFF4F7FB),
    this.isDarkBody = false,
  });

  static const List<NursePersonalTheme> presets = [
    NursePersonalTheme(
      id: 'ocean_sapphire',
      name: 'Ocean Sapphire',
      subtitle: 'High-Trust Clinical Command',
      bannerGradient: [
        Color(0xFF071A33),
        Color(0xFF0E3F6E),
        Color(0xFF1B6CA8),
      ],
      appBarColor: Color(0xFF08203E),
      primaryColor: Color(0xFF0F4C81),
      scaffoldColor: Color(0xFFF4F7FB),
    ),
    NursePersonalTheme(
      id: 'bio_emerald',
      name: 'Bio-Emerald & Mint',
      subtitle: 'Fresh Wellness & Surgical Tech',
      bannerGradient: [
        Color(0xFF052920),
        Color(0xFF065F46),
        Color(0xFF059669),
      ],
      appBarColor: Color(0xFF064E3B),
      primaryColor: Color(0xFF059669),
      scaffoldColor: Color(0xFFF3F8F6),
    ),
    NursePersonalTheme(
      id: 'glacier_blue',
      name: 'Glacier Blue',
      subtitle: 'Bright Focus for Busy Teams',
      bannerGradient: [Color(0xFFFFFFFF), Color(0xFFE0F2FE)],
      appBarColor: Color(0xFFE0F2FE),
      appBarForeground: Color(0xFF0B1528),
      primaryColor: Color(0xFF0284C7),
      scaffoldColor: Color(0xFFF4F8FC),
    ),
    NursePersonalTheme(
      id: 'midnight_obsidian',
      name: 'Midnight Obsidian',
      subtitle: 'Sleek OLED Night Mode',
      bannerGradient: [
        Color(0xFF070B14),
        Color(0xFF1E1B4B),
        Color(0xFF3730A3),
      ],
      appBarColor: Color(0xFF0F172A),
      primaryColor: Color(0xFF4F46E5),
      scaffoldColor: Color(0xFFF3F5FA),
      isDarkBody: true,
    ),
    NursePersonalTheme(
      id: 'sunrise_coral',
      name: 'Sunrise Coral',
      subtitle: 'Human, Warm & Welcoming',
      bannerGradient: [
        Color(0xFF3B1106),
        Color(0xFF9A3412),
        Color(0xFFEA580C),
      ],
      appBarColor: Color(0xFF9A3412),
      primaryColor: Color(0xFFD9480F),
      scaffoldColor: Color(0xFFFAF6F4),
    ),
    NursePersonalTheme(
      id: 'royal_amethyst',
      name: 'Royal Amethyst',
      subtitle: 'Calm Precision & Authority',
      bannerGradient: [
        Color(0xFF230A44),
        Color(0xFF5B21B6),
        Color(0xFF7C3AED),
      ],
      appBarColor: Color(0xFF4C1D95),
      primaryColor: Color(0xFF6D28D9),
      scaffoldColor: Color(0xFFF6F4FB),
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

  static const List<FontFeature> tabularNums = [FontFeature.tabularFigures()];

  static ThemeData get lightTheme =>
      fromPersonalTheme(NursePersonalTheme.presets.first);

  static ThemeData fromPersonalTheme(NursePersonalTheme preset) {
    final primary = preset.primaryColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: AppColors.accentSky,
      surface: AppColors.cardSurface,
      error: AppColors.danger,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: preset.scaffoldColor,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
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
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          backgroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primary.withAlpha(22),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
