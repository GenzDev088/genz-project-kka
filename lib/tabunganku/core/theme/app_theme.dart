import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.comicNeue().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.divider,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.comicNeue(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.comicNeue(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
        displaySmall: GoogleFonts.comicNeue(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.comicNeue(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.comicNeue(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.comicNeue(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.comicNeue(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        bodyLarge: GoogleFonts.comicNeue(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.comicNeue(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.comicNeue(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        labelStyle: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        errorStyle: GoogleFonts.comicNeue(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.error,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.comicNeue().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,
      dividerColor: AppColors.dividerDark,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.comicNeue(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: GoogleFonts.comicNeue(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimaryDark,
        ),
        displaySmall: GoogleFonts.comicNeue(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: GoogleFonts.comicNeue(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimaryDark,
        ),
        headlineSmall: GoogleFonts.comicNeue(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimaryDark,
        ),
        titleLarge: GoogleFonts.comicNeue(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        titleSmall: GoogleFonts.comicNeue(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryDark,
        ),
        bodyLarge: GoogleFonts.comicNeue(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDark,
        ),
        bodySmall: GoogleFonts.comicNeue(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDark,
        ),
        labelLarge: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: GoogleFonts.comicNeue(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimaryDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDark,
        ),
        labelStyle: GoogleFonts.comicNeue(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        errorStyle: GoogleFonts.comicNeue(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.error,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
    );
  }
}
