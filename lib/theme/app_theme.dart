import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  /// Rebuilt whenever the brand theme changes (colours are read live).
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.lexendTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.scaffold,
      primaryColor: AppColors.primary,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: GoogleFonts.lexend(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.divider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: GoogleFonts.lexend(color: AppColors.inkFaint, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.rMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.rMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.rMd),
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.rLg)),
          textStyle:
              GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF1B1D28).withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.30),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ];
}
