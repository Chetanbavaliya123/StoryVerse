import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignTokens {
  // Colors
  static const Color background = Color(0xFF0A0A0C);
  static const Color backgroundTop = Color(0xFF140608);
  static const Color primaryAccent = Color(0xFFE50914);
  static const Color primaryAccentDark = Color(0xFFB9232D);
  static const Color textPrimary = Colors.white;
  static const Color textMuted = Color(0xFFA1A1AA);
  
  // Surfaces
  static const Color surfaceGlass = Color(0x11FFFFFF);
  static const Color surfaceGlassBorder = Color(0x1AFFFFFF);

  // Radii
  static const double radiusSmall = 14.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 24.0;

  // Spacing
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;

  // Typography
  static TextStyle titleStyle = GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  static TextStyle sectionHeadingStyle = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle bodyStyle = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.5,
  );
  
  static TextStyle labelStyle = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: primaryAccent,
    letterSpacing: 1.0,
  );

  // Shadows
  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primaryAccent.withValues(alpha: 0.2),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
  
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
