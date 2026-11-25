import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// LingAfriq Pan-African Design System
///
/// A comprehensive design system inspired by African cultures, art, and landscapes.
/// Built for Material Design 3 compliance with unique African aesthetic touches.
///
/// Color Philosophy:
/// - Greens: African forests, growth, prosperity
/// - Golds: African sunsets, wealth, success
/// - Earth tones: African soil, heritage, roots
/// - Vibrant accents: African textiles (Kente, Ankara, Kitenge)

@Deprecated('Use LingAfriqTokens. This file is a retired design system.')
class PanAfricanColors {
  PanAfricanColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY PALETTE - African Forest
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary green - Representing African forests and growth
  static const Color primary = LingAfriqTokens.hexFF1B7340;
  // Backward-compatible alias (older UI code expects this name).
  static const Color primaryGreen = primary;
  static const Color primaryLight = LingAfriqTokens.hexFF2BEE6C;
  static const Color primaryDark = LingAfriqTokens.hexFF0D4D29;
  static const Color primaryContainer = LingAfriqTokens.hexFFB7F5CD;
  static const Color onPrimaryContainer = LingAfriqTokens.hexFF002109;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECONDARY PALETTE - African Gold/Sunset
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gold - Representing African wealth, sunsets, and success
  static const Color secondary = LingAfriqTokens.hexFFF7CB46;
  static const Color secondaryLight = LingAfriqTokens.hexFFFFF3CD;
  static const Color secondaryDark = LingAfriqTokens.hexFFE8A817;
  static const Color secondaryContainer = LingAfriqTokens.hexFFFFF3CD;
  static const Color onSecondaryContainer = LingAfriqTokens.hexFF5C4A00;

  // ═══════════════════════════════════════════════════════════════════════════
  // TERTIARY PALETTE - African Sunset/Fire
  // ═══════════════════════════════════════════════════════════════════════════

  /// Orange/Red - Representing African sunsets and energy
  static const Color tertiary = LingAfriqTokens.hexFFEB8937;
  static const Color tertiaryDark = LingAfriqTokens.hexFFD45B0A;
  static const Color tertiaryContainer = LingAfriqTokens.hexFFFFE4D9;
  static const Color onTertiaryContainer = LingAfriqTokens.hexFF5C2100;

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCENT COLORS - African Textiles Inspired
  // ═══════════════════════════════════════════════════════════════════════════

  /// Accent color - Using secondary gold for vibrant accents
  static const Color accent = secondary;

  /// Kente Red
  static const Color kenteRed = LingAfriqTokens.hexFFC4413A;

  /// Kente-inspired gold accent (alias of [gold] for game/traditional UI).
  static const Color kenteGold = gold;

  /// Kente Blue
  static const Color kenteBlue = LingAfriqTokens.hexFF1CB0F6;

  /// Ankara Purple
  static const Color ankaraPurple = LingAfriqTokens.hexFF9B59B6;

  /// Kitenge Teal
  static const Color kitengeTeal = LingAfriqTokens.hexFF16A085;
  // Backward-compatible alias for earlier usage.
  static const Color kenteTeal = kitengeTeal;

  /// Maasai Red
  static const Color maasaiRed = LingAfriqTokens.hexFFE74C3C;

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL PALETTE - African Earth
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color neutralDarkest = LingAfriqTokens.hexFF0D1B12;
  static const Color neutralDark = LingAfriqTokens.hexFF1A2E21;
  static const Color neutralMedium = LingAfriqTokens.hexFF4A5D52;
  static const Color neutralLight = LingAfriqTokens.hexFFB8C4BD;
  static const Color neutralLightest = LingAfriqTokens.hexFFF4F6F5;

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color success = LingAfriqTokens.hexFF2ECC71;
  static const Color error = LingAfriqTokens.hexFFE74C3C;
  static const Color warning = LingAfriqTokens.hexFFF39C12;
  static const Color info = LingAfriqTokens.hexFF3498DB;

  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACE COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  // Light Mode
  static const Color surface = LingAfriqTokens.hexFFFAFAFA;
  static const Color surfaceLight = LingAfriqTokens.hexFFFAFAFA;
  static const Color surfaceContainerLowestLight = LingAfriqTokens.hexFFFFFFFF;
  static const Color surfaceContainerLowLight = LingAfriqTokens.hexFFF5F7F5;
  static const Color surfaceContainerLight = LingAfriqTokens.hexFFF0F2F0;
  static const Color surfaceContainerHighLight = LingAfriqTokens.hexFFE8EBE8;
  static const Color surfaceContainerHighestLight = LingAfriqTokens.hexFFE0E4E0;
  static const Color cardLight = LingAfriqTokens.hexFFFFFFFF;
  static const Color borderLight = LingAfriqTokens.hexFFE0E4E0;
  static const Color outline = LingAfriqTokens.hexFFE0E4E0;

  // Dark Mode
  static const Color surfaceDark = LingAfriqTokens.hexFF0D1810;
  static const Color surfaceContainerLowestDark = LingAfriqTokens.hexFF0D1810;
  static const Color surfaceContainerLowDark = LingAfriqTokens.hexFF152419;
  static const Color surfaceContainerDark = LingAfriqTokens.hexFF1A2E21;
  static const Color surfaceContainerHighDark = LingAfriqTokens.hexFF253D2D;
  static const Color surfaceContainerHighestDark = LingAfriqTokens.hexFF2A4A35;
  static const Color cardDark = LingAfriqTokens.hexFF1F3527;
  static const Color borderDark = LingAfriqTokens.hexFF2A4A35;

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color textPrimary = LingAfriqTokens.hexFF0D1B12;
  static const Color textSecondary = LingAfriqTokens.hexFF4A5D52;
  static const Color textDark = LingAfriqTokens.hexFF0D1B12;
  static const Color textPrimaryLight = LingAfriqTokens.hexFF0D1B12;
  static const Color textSecondaryLight = LingAfriqTokens.hexFF4A5D52;
  /// Same ink as secondary text so disabled copy still meets 4.5:1.
  static const Color textDisabledLight = LingAfriqTokens.hexFF4A5D52;

  static const Color textPrimaryDark = LingAfriqTokens.hexFFF4F6F5;
  static const Color textSecondaryDark = LingAfriqTokens.hexFFB8C4BD;
  /// Light enough for 4.5:1 on every dark container, including the highest.
  static const Color textTertiaryDark = LingAfriqTokens.hexFFB8C4BD;
  static const Color textDisabledDark = LingAfriqTokens.hexFFB8C4BD;

  /// Dark enough for 4.5:1 on the lightest and the highest light containers.
  static const Color textTertiaryLight = LingAfriqTokens.hexFF4A5D52;

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKWARD-COMPATIBLE ALIASES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Background aliases for dark/light themes
  static const Color backgroundDark = surfaceDark;
  static const Color backgroundLight = surfaceLight;

  /// Gold accent - African wealth and success
  static const Color gold = LingAfriqTokens.hexFFF7CB46;
}

/// Pan-African Gradients (subtle, flat variants - no bold gradients)
class PanAfricanGradients {
  PanAfricanGradients._();

  static const Color _primary = LingAfriqTokens.hexFF1B7340;
  // ignore: unused_field
  static const Color _primaryDark = LingAfriqTokens.hexFF0D4D29;
  static const Color _primaryContainer = LingAfriqTokens.hexFFB7F5CD;
  static const Color _surface = LingAfriqTokens.hexFFFAFAFA;
  static const Color _neutralLightest = LingAfriqTokens.hexFFF4F6F5;

  /// African Sunset - Barely visible warm tint
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LingAfriqTokens.hexFFFFF8F0, LingAfriqTokens.hexFFFFFBF5],
  );

  /// African Forest - Restored contrast so white text remains readable.
  static const LinearGradient forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LingAfriqTokens.hexFF2A7A4C, LingAfriqTokens.hexFF1B7340],
  );

  /// Savanna Gold - Barely there warm tint
  static const LinearGradient savannaGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LingAfriqTokens.hexFFFFF8E7, LingAfriqTokens.hexFFFFFDF5],
  );

  /// Primary Header - Subtle green
  static const LinearGradient primaryHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _primary],
  );

  /// Kente - Subtle warm Kente-inspired gradient
  static const LinearGradient kente = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LingAfriqTokens.hexFFF7CB46, LingAfriqTokens.hexFFEB8937],
  );

  /// Kente Vibrant - Flat (primaryContainer)
  static const LinearGradient kenteVibrant = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primaryContainer, _primaryContainer],
  );

  /// Dark Mode Gradient - Subtle dark surface
  static const LinearGradient darkSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [LingAfriqTokens.hexFF1A2E21, LingAfriqTokens.hexFF0D1810],
  );

  /// App Bar Gradient (Dark) - Subtle
  static const LinearGradient appBarDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LingAfriqTokens.hexFF1F3527, LingAfriqTokens.hexFF0D1810],
  );

  /// Achievement/Celebration - Subtle green
  static const LinearGradient celebration = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primaryContainer, LingAfriqTokens.hexFFE8F5E9],
  );

  /// African Earth - Flat neutral
  static const LinearGradient earth = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_neutralLightest, _surface],
  );
}

/// Pan-African Spacing System (8pt grid)
class PanAfricanSpacing {
  PanAfricanSpacing._();

  static double get xxxs => 2.w;
  static double get xxs => 4.w;
  static double get xs => 8.w;
  static double get sm => 12.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;
  static double get xxxl => 64.w;
}

/// Responsive vertical spacing: on short screens (e.g. height <= 560) returns
/// smaller values so content is not pushed too far up/down and fits better.
class PanAfricanSpacingResponsive {
  PanAfricanSpacingResponsive._();

  static bool _isShortScreen(BuildContext context) {
    return MediaQuery.of(context).size.height <= 560;
  }

  static double verticalContent(BuildContext context) {
    return _isShortScreen(context) ? 8.w : 24.w;
  }

  static double screenPaddingVertical(BuildContext context) {
    return _isShortScreen(context) ? 8.w : 16.w;
  }
}

/// Screen width categories (logical px / dp) for adaptive layout.
/// Small: 320-360, Medium: 375-390, Large: 412-430, Tablet: 700+.
enum ScreenWidthCategory { small, medium, large, tablet }

/// 8px grid adaptive layout: side margins 16/24/32, section spacing 24-32,
/// card padding 16 (12 dense), min touch target 48dp. Safety zones handled by ResponsiveSafeArea.
class AdaptiveLayout {
  AdaptiveLayout._();

  static const double _grid4 = 4;
  static const double _grid8 = 8;
  static const double _grid16 = 16;
  static const double _grid24 = 24;
  static const double _grid32 = 32;
  static const double _grid40 = 40;

  static double get grid4 => _grid4;
  static double get grid8 => _grid8;
  static double get grid16 => _grid16;
  static double get grid24 => _grid24;
  static double get grid32 => _grid32;
  static double get grid40 => _grid40;

  static ScreenWidthCategory widthCategory(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 700) return ScreenWidthCategory.tablet;
    if (w >= 412) return ScreenWidthCategory.large;
    if (w >= 375) return ScreenWidthCategory.medium;
    return ScreenWidthCategory.small;
  }

  /// Standard side margins: 16dp small/medium, 24dp large, 32dp tablet.
  static double sideMargin(BuildContext context) {
    switch (widthCategory(context)) {
      case ScreenWidthCategory.small:
      case ScreenWidthCategory.medium:
        return _grid16;
      case ScreenWidthCategory.large:
        return _grid24;
      case ScreenWidthCategory.tablet:
        return _grid32;
    }
  }

  /// Between large sections: 24dp or 32dp.
  static double sectionSpacing(BuildContext context) {
    return widthCategory(context) == ScreenWidthCategory.tablet
        ? _grid32
        : _grid24;
  }

  /// Card/list content padding: 16dp standard, 12dp for dense.
  static double cardPadding(BuildContext context, {bool dense = false}) {
    return dense ? 12 : _grid16;
  }

  /// Minimum touch target: 48dp (Android), 44px (iOS) — use 48 for consistency.
  static const double minTouchTarget = 48;
}

/// Pan-African Border Radius
class PanAfricanRadius {
  PanAfricanRadius._();

  static double get xs => 4.r;
  static double get sm => 8.r;
  static double get md => 12.r;
  static double get lg => 16.r;
  static double get xl => 24.r;
  static double get xxl => 32.r;
  static double get round => 100.r;
  static double get pill => round;

  static BorderRadius get xsBR => BorderRadius.circular(xs);
  static BorderRadius get smBR => BorderRadius.circular(sm);
  static BorderRadius get mdBR => BorderRadius.circular(md);
  static BorderRadius get lgBR => BorderRadius.circular(lg);
  static BorderRadius get xlBR => BorderRadius.circular(xl);
  static BorderRadius get xxlBR => BorderRadius.circular(xxl);
  static BorderRadius get roundBR => BorderRadius.circular(round);
}

/// Pan-African Shadows
class PanAfricanShadows {
  PanAfricanShadows._();

  static List<BoxShadow> get none => [];

  static List<BoxShadow> get sm => [
    BoxShadow(
      color: PanAfricanColors.neutralDarkest.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: PanAfricanColors.neutralDarkest.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: PanAfricanColors.neutralDarkest.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: PanAfricanColors.neutralDarkest.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  /// Elevated glow effect (neutered - no glows)
  static List<BoxShadow> glowGold(double opacity) => const [];
  static List<BoxShadow> glowGreen(double opacity) => const [];

  /// Generic glow method (neutered - no glows)
  static List<BoxShadow> glow(Color color) => const [];
}

/// Pan-African Typography
class PanAfricanTypography {
  PanAfricanTypography._();

  // Use Google Fonts for a modern look
  // Josefin Sans - Clean, modern, African-inspired
  // Lato - Clean body text
  static const List<String> _fontFallback = LingAfriqFonts.fallback;

  static TextStyle _withFallback(TextStyle style) =>
      style.copyWith(fontFamilyFallback: _fontFallback);

  static String get displayFont => LingAfriqFonts.display;
  static String get bodyFont => LingAfriqFonts.text;

  // Display Styles (Lato, lighter weights)
  static TextStyle displayLarge(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 57.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle displayMedium(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 45.sp,
        fontWeight: FontWeight.w600,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle displaySmall(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.w600,
        color: color ?? _textColor(context),
      ),
    );
  }

  // Headline Styles (Lato, lighter weights)
  static TextStyle headlineLarge(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w600,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle headlineMedium(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w500,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle headlineSmall(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w500,
        color: color ?? _textColor(context),
      ),
    );
  }

  // Title Styles
  static TextStyle titleLarge(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle titleMedium(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle titleSmall(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color ?? _textColor(context),
      ),
    );
  }

  // Body Styles
  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.textStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.textStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.45,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.textStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: color ?? _textSecondaryColor(context),
      ),
    );
  }

  // Label Styles
  static TextStyle labelLarge(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.displayStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle labelMedium(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.textStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? _textColor(context),
      ),
    );
  }

  static TextStyle labelSmall(BuildContext context, {Color? color}) {
    return _withFallback(
      LingAfriqFonts.textStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color ?? _textSecondaryColor(context),
      ),
    );
  }

  static Color _textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? PanAfricanColors.textPrimaryDark
        : PanAfricanColors.textPrimaryLight;
  }

  static Color _textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? PanAfricanColors.textSecondaryDark
        : PanAfricanColors.textSecondaryLight;
  }
}

/// Material 3 Color Scheme for Pan-African Theme
class PanAfricanColorScheme {
  PanAfricanColorScheme._();

  static ColorScheme get light => const ColorScheme(
    brightness: Brightness.light,
    primary: PanAfricanColors.primary,
    onPrimary: LingAfriqTokens.hexFFFFFFFF,
    primaryContainer: PanAfricanColors.primaryContainer,
    onPrimaryContainer: PanAfricanColors.onPrimaryContainer,
    // Gold on a light surface is 1.55:1. Ochre meets 4.5:1 as text and as a fill.
    secondary: LingAfriqTokens.hexFF735C00,
    onSecondary: LingAfriqTokens.hexFFFFFFFF,
    secondaryContainer: PanAfricanColors.secondaryContainer,
    onSecondaryContainer: PanAfricanColors.onSecondaryContainer,
    // Sunset orange on white is 2.57:1. Terracotta meets 4.5:1 with white text.
    tertiary: LingAfriqTokens.hexFF9E3D00,
    onTertiary: LingAfriqTokens.hexFFFFFFFF,
    tertiaryContainer: PanAfricanColors.tertiaryContainer,
    onTertiaryContainer: PanAfricanColors.onTertiaryContainer,
    error: LingAfriqTokens.hexFFC4413A,
    onError: LingAfriqTokens.hexFFFFFFFF,
    errorContainer: LingAfriqTokens.hexFFFFDAD6,
    onErrorContainer: LingAfriqTokens.hexFF410002,
    surface: PanAfricanColors.surfaceLight,
    onSurface: PanAfricanColors.textPrimaryLight,
    surfaceContainerHighest: PanAfricanColors.surfaceContainerHighestLight,
    surfaceContainerHigh: PanAfricanColors.surfaceContainerHighLight,
    surfaceContainer: PanAfricanColors.surfaceContainerLight,
    surfaceContainerLow: PanAfricanColors.surfaceContainerLowLight,
    surfaceContainerLowest: PanAfricanColors.surfaceContainerLowestLight,
    onSurfaceVariant: PanAfricanColors.textSecondaryLight,
    outline: PanAfricanColors.borderLight,
    outlineVariant: PanAfricanColors.neutralLight,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: PanAfricanColors.neutralDark,
    onInverseSurface: PanAfricanColors.textPrimaryDark,
    inversePrimary: PanAfricanColors.primaryLight,
    surfaceTint: PanAfricanColors.primary,
  );

  static ColorScheme get dark => const ColorScheme(
    brightness: Brightness.dark,
    primary: PanAfricanColors.primaryLight,
    onPrimary: PanAfricanColors.primaryDark,
    primaryContainer: PanAfricanColors.primaryDark,
    onPrimaryContainer: PanAfricanColors.primaryContainer,
    secondary: PanAfricanColors.secondary,
    onSecondary: PanAfricanColors.neutralDarkest,
    secondaryContainer: LingAfriqTokens.hexFF735C00,
    onSecondaryContainer: LingAfriqTokens.hexFFFFFFFF,
    tertiary: LingAfriqTokens.roleDarkWarning,
    onTertiary: LingAfriqTokens.roleDarkOnWarning,
    tertiaryContainer: LingAfriqTokens.hexFF9E3D00,
    onTertiaryContainer: LingAfriqTokens.hexFFFFFFFF,
    error: LingAfriqTokens.hexFFFFB4AB,
    onError: LingAfriqTokens.hexFF690005,
    errorContainer: LingAfriqTokens.hexFF93000A,
    onErrorContainer: LingAfriqTokens.hexFFFFDAD6,
    surface: PanAfricanColors.surfaceDark,
    onSurface: PanAfricanColors.textPrimaryDark,
    surfaceContainerHighest: PanAfricanColors.surfaceContainerHighestDark,
    surfaceContainerHigh: PanAfricanColors.surfaceContainerHighDark,
    surfaceContainer: PanAfricanColors.surfaceContainerDark,
    surfaceContainerLow: PanAfricanColors.surfaceContainerLowDark,
    surfaceContainerLowest: PanAfricanColors.surfaceContainerLowestDark,
    onSurfaceVariant: PanAfricanColors.textSecondaryDark,
    outline: PanAfricanColors.borderDark,
    outlineVariant: PanAfricanColors.neutralMedium,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: PanAfricanColors.neutralLightest,
    onInverseSurface: PanAfricanColors.textPrimaryLight,
    inversePrimary: PanAfricanColors.primary,
    surfaceTint: PanAfricanColors.primaryLight,
  );
}

/// Extension for easy access to Pan-African design tokens
extension PanAfricanContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get panPrimary =>
      isDark ? PanAfricanColors.primaryLight : PanAfricanColors.primary;
  Color get panSecondary => isDark
      ? PanAfricanColors.secondary
      : LingAfriqTokens.hexFF735C00;
  Color get panTertiary => isDark
      ? LingAfriqTokens.roleDarkWarning
      : LingAfriqTokens.hexFF9E3D00;
  Color get panSuccess => isDark
      ? LingAfriqTokens.roleDarkSuccess
      : LingAfriqTokens.hexFF1B7340;
  Color get panWarning => isDark
      ? LingAfriqTokens.roleDarkWarning
      : LingAfriqTokens.hexFF735C00;
  Color get panError => isDark
      ? LingAfriqTokens.roleDarkDanger
      : LingAfriqTokens.hexFFBA1A1A;
  Color get panInfo => isDark
      ? LingAfriqTokens.roleDarkInfo
      : LingAfriqTokens.roleLightInfo;

  Color get panSurface =>
      isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight;
  Color get panCard =>
      isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight;
  Color get panBorder =>
      isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight;

  Color get panTextPrimary => isDark
      ? PanAfricanColors.textPrimaryDark
      : PanAfricanColors.textPrimaryLight;
  Color get panTextSecondary => isDark
      ? PanAfricanColors.textSecondaryDark
      : PanAfricanColors.textSecondaryLight;

  LinearGradient get panHeaderGradient =>
      isDark ? PanAfricanGradients.appBarDark : PanAfricanGradients.forest;
}

/// Unified icon set for bottom nav and key screens (outlined / rounded pairs).
class PanAfricanIcons {
  PanAfricanIcons._();

  static const IconData home = Icons.home_outlined;
  static const IconData homeSelected = Icons.home_rounded;
  static const IconData courses = Icons.folder_copy_outlined;
  static const IconData coursesSelected = Icons.folder_copy_rounded;
  static const IconData standings = Icons.bar_chart_outlined;
  static const IconData standingsSelected = Icons.bar_chart_rounded;
  static const IconData profile = Icons.person_outline;
  static const IconData profileSelected = Icons.person_rounded;
  static const IconData ai = Icons.auto_awesome_outlined;
  static const IconData aiSelected = Icons.auto_awesome_rounded;
  static const IconData social = Icons.people_outline;
  static const IconData socialSelected = Icons.people_rounded;
  static const IconData menu = Icons.menu_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData loading = Icons.hourglass_empty_rounded;

  // Drawer / app menu (unified with pan_african_components semantics)
  static const IconData book = Icons.menu_book;
  static const IconData lesson = Icons.school;
  static const IconData quiz = Icons.quiz;
  static const IconData magazine = Icons.article;
  static const IconData chat = Icons.chat;
  static const IconData community = Icons.people;
  static const IconData tribe = Icons.group;
  static const IconData badge = Icons.workspace_premium;
  static const IconData trophy = Icons.emoji_events;
  static const IconData settings = Icons.settings;
}
