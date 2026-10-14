import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class StoryVerseThemeTokens extends ThemeExtension<StoryVerseThemeTokens> {
  // Spacing
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double spaceXxl;

  // Radii
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusPill;

  // Colors
  final Color bg;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceGlass;
  final Color border;
  final Color accent;
  final Color accentGlow;
  final Color textPrimary;
  final Color textMuted;

  // Typography
  final TextStyle displayTitle;
  final TextStyle sectionHeader;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle caption;

  // Shadows
  final List<BoxShadow> glowShadow;
  final List<BoxShadow> softShadow;

  const StoryVerseThemeTokens({
    this.spaceXs = 4.0,
    this.spaceSm = 8.0,
    this.spaceMd = 16.0,
    this.spaceLg = 24.0,
    this.spaceXl = 32.0,
    this.spaceXxl = 48.0,
    this.radiusSm = 8.0,
    this.radiusMd = 12.0,
    this.radiusLg = 16.0,
    this.radiusXl = 24.0,
    this.radiusPill = 999.0,
    required this.bg,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceGlass,
    required this.border,
    required this.accent,
    required this.accentGlow,
    required this.textPrimary,
    required this.textMuted,
    required this.displayTitle,
    required this.sectionHeader,
    required this.cardTitle,
    required this.body,
    required this.caption,
    required this.glowShadow,
    required this.softShadow,
  });

  static StoryVerseThemeTokens get oled => StoryVerseThemeTokens(
        bg: const Color(0xFF000000),
        surface: const Color(0xFF121214),
        surfaceElevated: const Color(0xFF1E1E24),
        surfaceGlass: const Color(0x1AFFFFFF),
        border: const Color(0xFF262626),
        accent: const Color(0xFFE50914),
        accentGlow: const Color(0x33E50914),
        textPrimary: Colors.white,
        textMuted: const Color(0xFFA1A1AA),
        displayTitle: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        sectionHeader: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        cardTitle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        body: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFA1A1AA),
          height: 1.5,
        ),
        caption: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFA1A1AA),
        ),
        glowShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
        softShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static StoryVerseThemeTokens get charcoal => StoryVerseThemeTokens(
        bg: const Color(0xFF101318),
        surface: const Color(0xFF171B22),
        surfaceElevated: const Color(0xFF202630),
        surfaceGlass: const Color(0x1EFFFFFF),
        border: const Color(0xFF2C3442),
        accent: const Color(0xFFE53935),
        accentGlow: const Color(0x33E53935),
        textPrimary: Colors.white,
        textMuted: const Color(0xFF9EABB8),
        displayTitle: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        sectionHeader: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        cardTitle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        body: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF9EABB8),
          height: 1.5,
        ),
        caption: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF9EABB8),
        ),
        glowShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
        softShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static StoryVerseThemeTokens get crimson => StoryVerseThemeTokens(
        bg: const Color(0xFF130709),
        surface: const Color(0xFF1E0B0E),
        surfaceElevated: const Color(0xFF2D1115),
        surfaceGlass: const Color(0x22FF2A4A),
        border: const Color(0xFF3F171D),
        accent: const Color(0xFFFF2A4A),
        accentGlow: const Color(0x33FF2A4A),
        textPrimary: Colors.white,
        textMuted: const Color(0xFFD4A5AB),
        displayTitle: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        sectionHeader: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        cardTitle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        body: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFD4A5AB),
          height: 1.5,
        ),
        caption: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFD4A5AB),
        ),
        glowShadow: [
          BoxShadow(
            color: const Color(0xFFFF2A4A).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        softShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  StoryVerseThemeTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceGlass,
    Color? border,
    Color? accent,
    Color? accentGlow,
    Color? textPrimary,
    Color? textMuted,
    TextStyle? displayTitle,
    TextStyle? sectionHeader,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? caption,
    List<BoxShadow>? glowShadow,
    List<BoxShadow>? softShadow,
  }) {
    return StoryVerseThemeTokens(
      spaceXs: spaceXs,
      spaceSm: spaceSm,
      spaceMd: spaceMd,
      spaceLg: spaceLg,
      spaceXl: spaceXl,
      spaceXxl: spaceXxl,
      radiusSm: radiusSm,
      radiusMd: radiusMd,
      radiusLg: radiusLg,
      radiusXl: radiusXl,
      radiusPill: radiusPill,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentGlow: accentGlow ?? this.accentGlow,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      displayTitle: displayTitle ?? this.displayTitle,
      sectionHeader: sectionHeader ?? this.sectionHeader,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      glowShadow: glowShadow ?? this.glowShadow,
      softShadow: softShadow ?? this.softShadow,
    );
  }

  @override
  StoryVerseThemeTokens lerp(
    covariant ThemeExtension<StoryVerseThemeTokens>? other,
    double t,
  ) {
    if (other is! StoryVerseThemeTokens) return this;
    return StoryVerseThemeTokens(
      spaceXs: spaceXs,
      spaceSm: spaceSm,
      spaceMd: spaceMd,
      spaceLg: spaceLg,
      spaceXl: spaceXl,
      spaceXxl: spaceXxl,
      radiusSm: radiusSm,
      radiusMd: radiusMd,
      radiusLg: radiusLg,
      radiusXl: radiusXl,
      radiusPill: radiusPill,
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t) ?? surfaceElevated,
      surfaceGlass:
          Color.lerp(surfaceGlass, other.surfaceGlass, t) ?? surfaceGlass,
      border: Color.lerp(border, other.border, t) ?? border,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t) ?? accentGlow,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      displayTitle:
          TextStyle.lerp(displayTitle, other.displayTitle, t) ?? displayTitle,
      sectionHeader:
          TextStyle.lerp(sectionHeader, other.sectionHeader, t) ?? sectionHeader,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t) ?? cardTitle,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
      glowShadow: other.glowShadow,
      softShadow: other.softShadow,
    );
  }
}

extension StoryVerseThemeTokensContext on BuildContext {
  StoryVerseThemeTokens get tokens =>
      Theme.of(this).extension<StoryVerseThemeTokens>() ??
      StoryVerseThemeTokens.oled;
}
