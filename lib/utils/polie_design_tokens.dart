import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Polie & AI Chat design tokens — Afro-futurist, cinematic learning experience.
/// Heritage × intelligence × delight. Dark-first; light mode ceremonial.
/// Aligns with 4pt grid, Manrope/Inter typography, glass & glow surfaces.

@Deprecated('Use LingAfriqTokens. This file is a retired design system.')
class PolieColors {
  PolieColors._();

  // TSX parity palette (earth/amber/cream family)
  static const Color primary = LingAfriqTokens.hexFF2D1B0E;
  static const Color primaryDark = LingAfriqTokens.hexFF0F0A04;
  static const Color obsidian = LingAfriqTokens.hexFF0F0A04;

  // Accents
  static const Color goldEmber = LingAfriqTokens.hexFFD4822A;
  static const Color goldEmberLight = LingAfriqTokens.hexFFF2C14E;
  static const Color electricTeal = LingAfriqTokens.hexFF4A7C59;
  static const Color electricTealLight = LingAfriqTokens.hexFF5C9070;
  static const Color royalAmethyst = LingAfriqTokens.hexFFC4663A;
  static const Color royalAmethystLight = LingAfriqTokens.hexFFD27A53;

  // States
  static const Color success = LingAfriqTokens.hexFF22C55E;
  static const Color error = LingAfriqTokens.hexFFB91C1C;
  static const Color errorMuted = LingAfriqTokens.hexFF991B1B;

  // @deprecated — Glass-era tokens. Use surfaceContainer / surfaceContainerLight instead.
  static const Color surfaceGlass = LingAfriqTokens.hex1FFFFFFF;
  static const Color surfaceGlassDark = LingAfriqTokens.hex2BFFFFFF;
  static const Color surfaceContainer = LingAfriqTokens.hexFF1A130C;
  static const Color surfaceContainerLight = LingAfriqTokens.hexFFFAF3E0;

  // Surfaces — Light mode
  static const Color surfaceLight = LingAfriqTokens.hexFFFAF3E0;

  // Text
  static const Color textPrimary = LingAfriqTokens.hexFFFAF3E0;
  static const Color textSecondary = LingAfriqTokens.hexFFC4B7A6;
  static const Color textPrimaryLight = LingAfriqTokens.hexFF2D1B0E;
  static const Color textSecondaryLight = LingAfriqTokens.hexFF7A624C;
}

class PolieSpacing {
  PolieSpacing._();

  static double get xxxs => 2.w;
  static double get xxs => 4.w;
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;
}

class PolieRadius {
  PolieRadius._();

  static double get sm => 8.r;
  static double get md => 12.r;
  static double get lg => 20.r;
  static double get xl => 24.r;
  static double get pill => 100.r;
}

/// Elevation: 0 bg, 1 cards (blur 16), 2 active (blur 24 + glow), 3 modals (blur 32).
class PolieElevation {
  PolieElevation._();

  static List<BoxShadow> level0 = [];
  static List<BoxShadow> level1(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> level2(BuildContext context, {Color? glowColor}) => [
    BoxShadow(
      color: (glowColor ?? PolieColors.royalAmethyst).withValues(alpha: 0.25),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> level3(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Typography parity with TSX spec: Playfair + Nunito + JetBrains Mono.
/// When [useSerifForLanguageText] is true, language/learning text uses Noto Serif.
class PolieTypography {
  PolieTypography._();

  static bool useSerifForLanguageText = false;

  static void setUseSerifForLanguageText(bool value) {
    useSerifForLanguageText = value;
  }

  static TextStyle h1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return GoogleFonts.playfairDisplay(
      fontSize: 32.sp,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle h2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return GoogleFonts.playfairDisplay(
      fontSize: 24.sp,
      height: 1.33,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return LingAfriqFonts.roleStyle(
      fontSize: 16.sp,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textSecondary
        : PolieColors.textSecondaryLight;
    return LingAfriqFonts.roleStyle(
      fontSize: 13.sp,
      height: 1.38,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle label(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textSecondary
        : PolieColors.textSecondaryLight;
    return LingAfriqFonts.roleStyle(
      fontSize: 14.sp,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle h3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return GoogleFonts.playfairDisplay(
      fontSize: 20.sp,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle titleLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return GoogleFonts.playfairDisplay(
      fontSize: 22.sp,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return LingAfriqFonts.roleStyle(
      fontSize: 18.sp,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle titleSmall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return LingAfriqFonts.roleStyle(
      fontSize: 16.sp,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle bodyLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return LingAfriqFonts.roleStyle(
      fontSize: 18.sp,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle labelLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textSecondary
        : PolieColors.textSecondaryLight;
    return LingAfriqFonts.roleStyle(
      fontSize: 14.sp,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle button(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return LingAfriqFonts.roleStyle(
      fontSize: 16.sp,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.4,
    );
  }

  static TextStyle mono(BuildContext context, {double size = 13}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? PolieColors.textPrimary
        : PolieColors.textPrimaryLight;
    return GoogleFonts.jetBrainsMono(
      fontSize: size.sp,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }
}

/// Dynamic accent by language region (optional). Defaults to royal amethyst.
Color polieAccentForLanguage(String languageKey) {
  switch (languageKey.toLowerCase()) {
    case 'yoruba':
    case 'igbo':
    case 'hausa':
    case 'pidgin':
      return PolieColors.goldEmber;
    case 'swahili':
    case 'zulu':
    case 'xhosa':
      return PolieColors.electricTeal;
    case 'amharic':
    case 'somali':
    case 'wolof':
      return PolieColors.royalAmethyst;
    default:
      return PolieColors.royalAmethyst;
  }
}
