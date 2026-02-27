import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const deepNavy = Color(0xFF1A2B4A);
  static const goldAccent = Color(0xFFC9A84C);
  static const warmOffWhite = Color(0xFFFAF8F5);
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFF57C00);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepNavy,
        primary: AppColors.deepNavy,
        secondary: AppColors.goldAccent,
        surface: AppColors.warmOffWhite,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        bodyLarge: GoogleFonts.plusJakartaSans(),
        bodyMedium: GoogleFonts.plusJakartaSans(),
        bodySmall: GoogleFonts.plusJakartaSans(),
        labelLarge: GoogleFonts.plusJakartaSans(),
        labelMedium: GoogleFonts.plusJakartaSans(),
        labelSmall: GoogleFonts.plusJakartaSans(),
      ),
      useMaterial3: true,
    );
  }
}
