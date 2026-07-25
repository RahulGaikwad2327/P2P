import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color obsidianBlack = Color(0xFF060606);
  static const Color cardDark = Color(0xFF0F0F0F);
  static const Color cardBorder = Color(0x33FFFFFF);
  static const Color pumpkinOrange = Color(0xFFFF5500); // Intense Cyber Orange matching reference image
  static const Color orangeGlow = Color(0x66FF5500);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFAAAAAA);
  static const Color textDim = Color(0xFF555555);
  static const Color successGreen = Color(0xFF00FF66);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color warningYellow = Color(0xFFFFBB00);
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final monoFont = GoogleFonts.spaceMono().fontFamily;

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.obsidianBlack,
      primaryColor: AppColors.pumpkinOrange,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.pumpkinOrange,
        secondary: AppColors.white,
        surface: AppColors.cardDark,
        error: AppColors.errorRed,
        onPrimary: AppColors.obsidianBlack,
        onSecondary: AppColors.obsidianBlack,
        onSurface: AppColors.white,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.spaceMono(
          color: AppColors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.spaceMono(
          color: AppColors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.spaceMono(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        labelSmall: GoogleFonts.spaceMono(
          color: AppColors.pumpkinOrange,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1.0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: TextStyle(fontFamily: monoFont, color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
          side: const BorderSide(color: AppColors.pumpkinOrange),
        ),
      ),
    );
  }
}
