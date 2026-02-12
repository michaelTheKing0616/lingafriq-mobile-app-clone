import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pan_african_design_system.dart';

/// Polie & AI Chat design tokens — Afro-futurist, cinematic learning experience.
/// Heritage × intelligence × delight. Dark-first; light mode ceremonial.
/// Aligns with 4pt grid, Manrope/Inter typography, glass & glow surfaces.

class PolieColors {
  PolieColors._();

  // Primary: Midnight Indigo / Deep Obsidian
  static const Color primary = Color(0xFF1E1B4B);
  static const Color primaryDark = Color(0xFF0F0D24);
  static const Color obsidian = Color(0xFF0D0D0F);

  // Accents
  static const Color goldEmber = Color(0xFFE8A817);
  static const Color goldEmberLight = Color(0xFFF7CB46);
  static const Color electricTeal = Color(0xFF14B8A6);
  static const Color electricTealLight = Color(0xFF5EEAD4);
  static const Color royalAmethyst = Color(0xFF7C3AED);
  static const Color royalAmethystLight = Color(0xFFA78BFA);

  // States
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorMuted = Color(0xFF991B1B);

  // @deprecated — Glass-era tokens. Use surfaceContainer / surfaceContainerLight instead.
  static const Color surfaceGlass = Color(0x1FFFFFFF);
  static const Color surfaceGlassDark = Color(0x2BFFFFFF);
  static const Color surfaceContainer = Color(0xFF1E293B);
  static const Color surfaceContainerLight = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
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
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
  static List<BoxShadow> level2(BuildContext context, {Color? glowColor}) => [
        BoxShadow(
          color: (glowColor ?? PolieColors.royalAmethyst).withOpacity(0.25),
          blurRadius: 24,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> level3(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Typography: Manrope for headings, body modern grotesk (Inter-style).
/// When [useSerifForLanguageText] is true, language/learning text uses Noto Serif.
class PolieTypography {
  PolieTypography._();

  static bool useSerifForLanguageText = false;

  static void setUseSerifForLanguageText(bool value) {
    useSerifForLanguageText = value;
  }

  static TextStyle _baseStyle(double fontSize, double height, FontWeight weight, Color color, [double letterSpacing = 0]) {
    if (useSerifForLanguageText) {
      return GoogleFonts.notoSerif(
        fontSize: fontSize,
        height: height,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
    return TextStyle(
      fontSize: fontSize,
      height: height,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle h1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight;
    return _baseStyle(32.sp, 1.25, FontWeight.w700, color, -0.5);
  }

  static TextStyle h2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight;
    return _baseStyle(24.sp, 1.33, FontWeight.w600, color);
  }

  static TextStyle body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight;
    return _baseStyle(16.sp, 1.5, FontWeight.w400, color);
  }

  static TextStyle bodySmall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? PolieColors.textSecondary : PolieColors.textSecondaryLight;
    return _baseStyle(13.sp, 1.38, FontWeight.w400, color);
  }

  static TextStyle label(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? PolieColors.textSecondary : PolieColors.textSecondaryLight;
    return _baseStyle(14.sp, 1.3, FontWeight.w500, color);
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
