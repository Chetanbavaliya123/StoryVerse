import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All visual constants for the premium onboarding experience.
/// No magic numbers in widget files — everything lives here.
abstract final class OBTokens {
  // ─── Colors ──────────────────────────────────────────────────────
  static const Color bgDeep = Color(0xFF0A0A0C);
  static const Color bgViolet = Color(0xFF1B0B3A);
  static const Color bgCrimson = Color(0xFF5A0F1E);
  static const Color bgWarmOrange = Color(0xFF3A1A08);

  static const Color crimsonStart = Color(0xFFE50914);
  static const Color crimsonEnd = Color(0xFFFF3D4A);
  static const Color violetAccent = Color(0xFF6D28D9);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFA1A1AA);

  static const Color glassWhiteFill = Color(0x14FFFFFF); // ~8%
  static const Color glassWhiteBorder = Color(0x1FFFFFFF); // ~12%
  static const Color glassWhiteSubtle = Color(0x0DFFFFFF); // ~5%

  static const Color dotInactive = Color(0x40FFFFFF); // 25%
  static const Color particleColor = Color(0x1AFFFFFF); // ~10%

  static const Color shimmerBase = Color(0x00FFFFFF);
  static const Color shimmerHighlight = Color(0x33FFFFFF);

  static const Color posterBorder = Color(0x1AFFFFFF); // 10% white
  static const Color posterGlow = Color(0x33E50914); // red glow 20%

  // ─── Gradients ───────────────────────────────────────────────────
  static const LinearGradient ctaGradient = LinearGradient(
    colors: [crimsonStart, crimsonEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient redTextGradient = LinearGradient(
    colors: [crimsonStart, crimsonEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Page background color stops for Color.lerp across 3 pages
  static const List<Color> pageBackgrounds = [bgDeep, bgViolet, bgCrimson];
  static const List<Color> pageBackgroundsSecondary = [
    bgDeep,
    bgCrimson,
    bgWarmOrange,
  ];

  // ─── Radii ───────────────────────────────────────────────────────
  static const double radiusXS = 8.0;
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusPill = 32.0;
  static const double radiusFull = 9999.0;

  // ─── Spacing ─────────────────────────────────────────────────────
  static const double spaceXXS = 4.0;
  static const double spaceXS = 8.0;
  static const double spaceSM = 12.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // ─── Sizes ───────────────────────────────────────────────────────
  static const double ctaHeight = 56.0;
  static const double ctaMinWidth = 160.0;
  static const double ctaExpandedWidth = 200.0;
  static const double dotSize = 8.0;
  static const double dotActiveWidth = 28.0;
  static const double dotSpacing = 8.0;
  static const double logoMarkSize = 32.0;
  static const double skipPillHeight = 34.0;
  static const double progressRingSize = 56.0;
  static const double progressRingStroke = 2.5;
  static const double topBarHeight = 56.0;

  // ─── Poster Card Sizes ───────────────────────────────────────────
  static const double posterWidth = 120.0;
  static const double posterHeight = 180.0;
  static const double posterCenterScale = 1.18;
  static const double posterSideRotation = 10.0; // degrees
  static const double posterSpacing = -20.0; // overlap

  // ─── Phone Mockup ────────────────────────────────────────────────
  static const double phoneWidth = 180.0;
  static const double phoneHeight = 340.0;
  static const double phoneRadius = 28.0;
  static const double phoneBorderWidth = 3.0;

  // ─── Blur ────────────────────────────────────────────────────────
  static const double glassBlur = 18.0;
  static const double backgroundOrbBlur = 60.0;

  // ─── Durations ───────────────────────────────────────────────────
  static const Duration entryTotal = Duration(milliseconds: 1200);
  static const Duration entryLogoDelay = Duration.zero;
  static const Duration entryLogoDuration = Duration(milliseconds: 500);
  static const Duration entryTopBarDelay = Duration(milliseconds: 150);
  static const Duration entryTopBarDuration = Duration(milliseconds: 400);
  static const Duration entryHeroDelay = Duration(milliseconds: 200);
  static const Duration entryHeroDuration = Duration(milliseconds: 600);
  static const Duration entryTitleWordDelay = Duration(milliseconds: 60);
  static const Duration entryTitleWordDuration = Duration(milliseconds: 350);
  static const Duration entrySubtitleDelay = Duration(milliseconds: 600);
  static const Duration entrySubtitleDuration = Duration(milliseconds: 400);
  static const Duration entryButtonDelay = Duration(milliseconds: 800);
  static const Duration entryButtonDuration = Duration(milliseconds: 400);

  static const Duration pageTransition = Duration(milliseconds: 400);
  static const Duration kenBurnsDuration = Duration(seconds: 12);
  static const Duration shimmerInterval = Duration(seconds: 4);
  static const Duration shimmerDuration = Duration(milliseconds: 1200);
  static const Duration exitDuration = Duration(milliseconds: 600);
  static const Duration particleDuration = Duration(seconds: 8);
  static const Duration orbDuration = Duration(seconds: 10);
  static const Duration bobbingDuration = Duration(seconds: 3);
  static const Duration chipPopDuration = Duration(milliseconds: 600);
  static const Duration progressFillLoop = Duration(seconds: 3);
  static const Duration orbitDuration = Duration(seconds: 8);

  // ─── Curves ──────────────────────────────────────────────────────
  static const Curve entryDefault = Curves.easeOutCubic;
  static const Curve entryLogo = Curves.easeOutBack;
  static const Curve pageSwipe = Curves.easeInOutCubic;
  static const Curve bobbing = Curves.easeInOut;
  static const Curve chipPop = Curves.elasticOut;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve ctaPress = Curves.easeOutCubic;

  // ─── Ken Burns ───────────────────────────────────────────────────
  static const double kenBurnsScaleStart = 1.0;
  static const double kenBurnsScaleEnd = 1.12;
  static const Offset kenBurnsPanStart = Offset.zero;
  static const Offset kenBurnsPanEnd = Offset(12.0, -6.0);

  // ─── Particles ───────────────────────────────────────────────────
  static const int particleCount = 25;
  static const double particleMinSize = 1.0;
  static const double particleMaxSize = 3.0;
  static const double particleMinOpacity = 0.08;
  static const double particleMaxOpacity = 0.25;
  static const double particleMinSpeed = 0.15;
  static const double particleMaxSpeed = 0.5;

  // ─── CTA Press Scale ─────────────────────────────────────────────
  static const double ctaPressScale = 0.96;
  static const double ctaArrowNudge = 4.0;

  // ─── Typography ──────────────────────────────────────────────────
  static TextStyle get titleStyle => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.1,
    color: textPrimary,
  );

  static TextStyle get subtitleStyle => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textMuted,
  );

  static TextStyle get wordmarkStyle => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.6,
    color: textPrimary,
  );

  static TextStyle get skipStyle => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: textMuted,
  );

  static TextStyle get ctaTextStyle => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: textPrimary,
  );

  static TextStyle get chipStyle => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: textPrimary,
  );

  static TextStyle get badgeStyle => GoogleFonts.plusJakartaSans(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: textPrimary,
  );

  static TextStyle get posterTitleStyle => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );

  static TextStyle get logoSVStyle => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );
}
