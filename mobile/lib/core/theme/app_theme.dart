import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData getThemeByName(String themeName) {
    switch (themeName) {
      case 'Cinematic Charcoal':
        return cinematicCharcoalTheme;
      case 'Dark Crimson':
        return darkCrimsonTheme;
      case 'OLED Pure Black':
      default:
        return oledPureBlackTheme;
    }
  }

  static ThemeData get darkTheme => oledPureBlackTheme;

  static ThemeData get oledPureBlackTheme {
    return _createTheme(
      background: const Color(0xFF000000),
      secondaryBackground: const Color(0xFF121212),
      surface: const Color(0xFF1A1A1A),
      accent: const Color(0xFFE53935),
      border: const Color(0xFF262626),
    );
  }

  static ThemeData get cinematicCharcoalTheme {
    return _createTheme(
      background: const Color(0xFF101318),
      secondaryBackground: const Color(0xFF171B22),
      surface: const Color(0xFF202630),
      accent: const Color(0xFFE53935),
      border: const Color(0xFF2C3442),
    );
  }

  static ThemeData get darkCrimsonTheme {
    return _createTheme(
      background: const Color(0xFF130709),
      secondaryBackground: const Color(0xFF1E0B0E),
      surface: const Color(0xFF2D1115),
      accent: const Color(0xFFFF2A4A),
      border: const Color(0xFF3F171D),
    );
  }

  static ThemeData _createTheme({
    required Color background,
    required Color secondaryBackground,
    required Color surface,
    required Color accent,
    required Color border,
  }) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: AppColors.darkAccent,
        onPrimary: AppColors.primaryText,
        onSecondary: AppColors.primaryText,
        onSurface: AppColors.primaryText,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        headlineLarge: AppTypography.headlineLarge,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelLarge: AppTypography.labelLarge,
        bodySmall: AppTypography.bodySmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        titleTextStyle: AppTypography.titleLarge,
      ),
      dividerColor: border,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: secondaryBackground,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.mutedText,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.primaryText,
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.mutedText,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
