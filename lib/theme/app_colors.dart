import 'package:flutter/material.dart';

/// A selectable brand theme. The accent family drives buttons, highlights,
/// the hero gradient and active states. Semantic colours (success/warning/
/// danger/info) stay fixed so status meaning never changes with the theme.
class BrandTheme {
  final String id;
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final List<Color> heroGradient;

  const BrandTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.heroGradient,
  });
}

/// SuperLibrary palette. Brand accent colours are mutable so the whole app can
/// be re-skinned at runtime; semantic + surface colours are fixed constants.
class AppColors {
  AppColors._();

  // ---- Selectable brand presets (soothing + eye-catching) ----------------
  static const List<BrandTheme> presets = [
    BrandTheme(
      id: 'coral',
      name: 'Coral',
      primary: Color(0xFFEF3E36),
      primaryDark: Color(0xFFD32A22),
      primaryLight: Color(0xFFFF6B5E),
      heroGradient: [Color(0xFFFF5147), Color(0xFFE22219)],
    ),
    BrandTheme(
      id: 'indigo',
      name: 'Indigo',
      primary: Color(0xFF4F46E5),
      primaryDark: Color(0xFF3730A3),
      primaryLight: Color(0xFF818CF8),
      heroGradient: [Color(0xFF6366F1), Color(0xFF4338CA)],
    ),
    BrandTheme(
      id: 'emerald',
      name: 'Emerald',
      primary: Color(0xFF0EA371),
      primaryDark: Color(0xFF047857),
      primaryLight: Color(0xFF34D399),
      heroGradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    BrandTheme(
      id: 'violet',
      name: 'Violet',
      primary: Color(0xFF7C3AED),
      primaryDark: Color(0xFF5B21B6),
      primaryLight: Color(0xFFA78BFA),
      heroGradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    ),
    BrandTheme(
      id: 'ocean',
      name: 'Ocean',
      primary: Color(0xFF0284C7),
      primaryDark: Color(0xFF0369A1),
      primaryLight: Color(0xFF38BDF8),
      heroGradient: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
    ),
  ];

  static BrandTheme byId(String id) =>
      presets.firstWhere((p) => p.id == id, orElse: () => presets.first);

  // ---- Brand (mutable — set by ThemeController) --------------------------
  static Color primary = presets.first.primary;
  static Color primaryDark = presets.first.primaryDark;
  static Color primaryLight = presets.first.primaryLight;
  static List<Color> heroGradient = presets.first.heroGradient;

  static void apply(BrandTheme t) {
    primary = t.primary;
    primaryDark = t.primaryDark;
    primaryLight = t.primaryLight;
    heroGradient = t.heroGradient;
  }

  // ---- Surfaces ----------------------------------------------------------
  static const Color scaffold = Color(0xFFF6F7FB);
  static const Color card = Colors.white;
  static const Color cardAlt = Color(0xFFFBFBFD);

  // ---- Text --------------------------------------------------------------
  static const Color ink = Color(0xFF1B1D28);
  static const Color inkSoft = Color(0xFF5A5E6E);
  static const Color inkFaint = Color(0xFF9AA0B0);

  // ---- Semantic (fixed) --------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFE7F7EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFF4E0);
  static const Color danger = Color(0xFFEF3E36);
  static const Color dangerBg = Color(0xFFFDEAE9);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEAF1FE);

  // ---- Pastel tints ------------------------------------------------------
  static const Color tintBlue = Color(0xFFEAF1FE);
  static const Color tintGreen = Color(0xFFE7F7EE);
  static const Color tintAmber = Color(0xFFFFF3E0);
  static const Color tintPink = Color(0xFFFDEBF2);
  static const Color tintPurple = Color(0xFFF0ECFE);
  static const Color tintMint = Color(0xFFE6F7F1);

  static const Color border = Color(0xFFEDEEF3);
  static const Color divider = Color(0xFFF0F1F5);

  // ---- Radius scale (tightened for a crisper look) -----------------------
  static const double rSm = 8;
  static const double rMd = 10;
  static const double rLg = 12;
  static const double rXl = 14;
}
