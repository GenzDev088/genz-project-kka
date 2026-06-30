import 'package:flutter/material.dart';
import '../constants/app_constants.dart';


class AppTheme {

  AppTheme._();


  static const Color primaryColor = Color(0xFF673AB7); // Deep Purple
  static const Color primaryVariant = Color(0xFF512DA8);
  static const Color secondaryColor = Color(0xFF3F51B5); // Indigo
  static const Color secondaryVariant = Color(0xFF303F9F);

  static const Color accentColor = Color(0xFFFF4081); // Pink Accent
  static const Color errorColor = Color(0xFFE57373);
  static const Color successColor = Color(0xFF81C784);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color infoColor = Color(0xFF64B5F6);


  static const Color playerXColor = Color(0xFF2196F3); // Blue
  static const Color playerOColor = Color(0xFFE53935); // Red
  static const Color gameGridColor = Color(0xFFE0E0E0);
  static const Color gameGridDisabledColor = Color(0xFFBDBDBD);


  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE0E0E0);


  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textDisabledColor = Color(0xFFBDBDBD);
  static const Color textOnPrimaryColor = Color(0xFFFFFFFF);
  static const Color textOnSecondaryColor = Color(0xFFFFFFFF);


  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),


      appBarTheme: const AppBarTheme(
        elevation: AppConstants.elevationLow,
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimaryColor,
        titleTextStyle: TextStyle(
          fontSize: AppConstants.fontXXL,
          fontWeight: FontWeight.w600,
          color: textOnPrimaryColor,
        ),
      ),


      cardTheme: CardThemeData(
        elevation: AppConstants.elevationMedium,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),


      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppConstants.elevationLow,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.fontXL,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),


      textTheme: _buildTextTheme(),


      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.spacingM),
      ),


      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),


      iconTheme: const IconThemeData(
        color: textPrimaryColor,
        size: AppConstants.iconM,
      ),


      primaryIconTheme: const IconThemeData(
        color: textOnPrimaryColor,
        size: AppConstants.iconM,
      ),
    );
  }


  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),


      appBarTheme: const AppBarTheme(
        elevation: AppConstants.elevationLow,
        centerTitle: true,
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: AppConstants.fontXXL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),


      cardTheme: CardThemeData(
        elevation: AppConstants.elevationMedium,
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),


      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppConstants.elevationLow,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.fontXL,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),


      textTheme: _buildTextTheme(isDark: true),


      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.spacingM),
      ),


      iconTheme: const IconThemeData(
        color: Colors.white,
        size: AppConstants.iconM,
      ),


      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: AppConstants.iconM,
      ),
    );
  }


  static TextTheme _buildTextTheme({bool isDark = false}) {
    final Color textColor = isDark ? Colors.white : textPrimaryColor;
    final Color textSecondary = isDark ? Colors.white70 : textSecondaryColor;

    return TextTheme(

      displayLarge: TextStyle(
        fontSize: AppConstants.fontDisplay,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: AppConstants.fontTitle,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: AppConstants.fontXXXL,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),


      headlineLarge: TextStyle(
        fontSize: AppConstants.fontXXL,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: AppConstants.fontXL,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: AppConstants.fontL,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),


      titleLarge: TextStyle(
        fontSize: AppConstants.fontXL,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: AppConstants.fontL,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: AppConstants.fontM,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),


      bodyLarge: TextStyle(
        fontSize: AppConstants.fontL,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: AppConstants.fontM,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: AppConstants.fontS,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),


      labelLarge: TextStyle(
        fontSize: AppConstants.fontM,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: AppConstants.fontS,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: AppConstants.fontS,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    );
  }
}


extension GameTheme on ThemeData {

  Color get playerXColor => AppTheme.playerXColor;


  Color get playerOColor => AppTheme.playerOColor;


  Color get gameGridColor => AppTheme.gameGridColor;


  Color get gameGridDisabledColor => AppTheme.gameGridDisabledColor;


  Color get successColor => AppTheme.successColor;


  Color get errorColor => AppTheme.errorColor;


  Color get warningColor => AppTheme.warningColor;


  Color get infoColor => AppTheme.infoColor;
}
