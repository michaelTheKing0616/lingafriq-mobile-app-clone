import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

class PanAfricanColors {
  PanAfricanColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY PALETTE - African Forest
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary green - Representing African forests and growth
  static const Color primary = Color(0xFF1B7340);
  // Backward-compatible alias (older UI code expects this name).
  static const Color primaryGreen = primary;
  static const Color primaryLight = Color(0xFF2BEE6C);
  static const Color primaryDark = Color(0xFF0D4D29);
  static const Color primaryContainer = Color(0xFFB7F5CD);
  static const Color onPrimaryContainer = Color(0xFF002109);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SECONDARY PALETTE - African Gold/Sunset
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Gold - Representing African wealth, sunsets, and success
  static const Color secondary = Color(0xFFF7CB46);
  static const Color secondaryLight = Color(0xFFFFF3CD);
  static const Color secondaryDark = Color(0xFFE8A817);
  static const Color secondaryContainer = Color(0xFFFFF3CD);
  static const Color onSecondaryContainer = Color(0xFF5C4A00);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TERTIARY PALETTE - African Sunset/Fire
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Orange/Red - Representing African sunsets and energy
  static const Color tertiary = Color(0xFFEB8937);
  static const Color tertiaryDark = Color(0xFFD45B0A);
  static const Color tertiaryContainer = Color(0xFFFFE4D9);
  static const Color onTertiaryContainer = Color(0xFF5C2100);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ACCENT COLORS - African Textiles Inspired
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Accent color - Using secondary gold for vibrant accents
  static const Color accent = secondary;
  
  /// Kente Red
  static const Color kenteRed = Color(0xFFC4413A);
  /// Kente Blue
  static const Color kenteBlue = Color(0xFF1CB0F6);
  /// Ankara Purple
  static const Color ankaraPurple = Color(0xFF9B59B6);
  /// Kitenge Teal
  static const Color kitengeTeal = Color(0xFF16A085);
  /// Maasai Red
  static const Color maasaiRed = Color(0xFFE74C3C);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL PALETTE - African Earth
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Color neutralDarkest = Color(0xFF0D1B12);
  static const Color neutralDark = Color(0xFF1A2E21);
  static const Color neutralMedium = Color(0xFF4A5D52);
  static const Color neutralLight = Color(0xFFB8C4BD);
  static const Color neutralLightest = Color(0xFFF4F6F5);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACE COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Light Mode
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceContainerLight = Color(0xFFF0F2F0);
  static const Color surfaceContainerHighLight = Color(0xFFE8EBE8);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE0E4E0);
  static const Color outline = Color(0xFFE0E4E0);
  
  // Dark Mode
  static const Color surfaceDark = Color(0xFF0D1810);
  static const Color surfaceContainerDark = Color(0xFF1A2E21);
  static const Color surfaceContainerHighDark = Color(0xFF253D2D);
  static const Color cardDark = Color(0xFF1F3527);
  static const Color borderDark = Color(0xFF2A4A35);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Color textPrimary = Color(0xFF0D1B12);
  static const Color textSecondary = Color(0xFF4A5D52);
  static const Color textDark = Color(0xFF0D1B12);
  static const Color textPrimaryLight = Color(0xFF0D1B12);
  static const Color textSecondaryLight = Color(0xFF4A5D52);
  static const Color textDisabledLight = Color(0xFF9CA8A0);
  
  static const Color textPrimaryDark = Color(0xFFF4F6F5);
  static const Color textSecondaryDark = Color(0xFFB8C4BD);
  static const Color textDisabledDark = Color(0xFF6B7D72);
}

/// Pan-African Gradients
class PanAfricanGradients {
  PanAfricanGradients._();
  
  /// African Sunset - Warm gradient for headers and CTAs
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEB8937), Color(0xFFF7CB46)],
  );
  
  /// African Forest - Cool gradient for backgrounds
  static const LinearGradient forest = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B7340), Color(0xFF0D4D29)],
  );
  
  /// Savanna Gold - Premium feel
  static const LinearGradient savannaGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7CB46), Color(0xFFE8A817), Color(0xFFF7CB46)],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Kente Vibrant - Celebratory/achievement gradient
  static const LinearGradient kenteVibrant = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC4413A), // Red
      Color(0xFFF7CB46), // Gold
      Color(0xFF1B7340), // Green
    ],
  );
  
  /// Dark Mode Gradient
  static const LinearGradient darkSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A2E21), Color(0xFF0D1810)],
  );
  
  /// App Bar Gradient (Dark)
  static const LinearGradient appBarDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F3527), Color(0xFF0D1810)],
  );
  
  /// Achievement/Celebration
  static const LinearGradient celebration = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7CB46), Color(0xFFEB8937)],
  );
  
  /// African Earth - Warm brown gradient for grounding elements
  static const LinearGradient earth = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5E3C), Color(0xFF5D3A1A)],
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
    return widthCategory(context) == ScreenWidthCategory.tablet ? _grid32 : _grid24;
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
      color: PanAfricanColors.neutralDarkest.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get md => [
    BoxShadow(
      color: PanAfricanColors.neutralDarkest.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: PanAfricanColors.neutralDarkest.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get xl => [
    BoxShadow(
      color: PanAfricanColors.neutralDarkest.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
  
  /// Elevated glow effect for highlighted items
  static List<BoxShadow> glowGold(double opacity) => [
    BoxShadow(
      color: PanAfricanColors.secondary.withOpacity(opacity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
  
  static List<BoxShadow> glowGreen(double opacity) => [
    BoxShadow(
      color: PanAfricanColors.primary.withOpacity(opacity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
  
  /// Generic glow method
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}

/// Pan-African Typography
class PanAfricanTypography {
  PanAfricanTypography._();
  
  // Use Google Fonts for a modern look
  // Josefin Sans - Clean, modern, African-inspired
  // Lato - Clean body text
  static const List<String> _fontFallback = <String>[
    'Noto Sans',
    'NotoSans',
    'Roboto',
    'Segoe UI',
    'Arial Unicode MS',
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Segoe UI Symbol',
    'Noto Color Emoji',
  ];

  static TextStyle _withFallback(TextStyle style) =>
      style.copyWith(fontFamilyFallback: _fontFallback);
  
  static String get displayFont => 'Josefin Sans';
  static String get bodyFont => 'Lato';
  
  // Display Styles
  static TextStyle displayLarge(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.josefinSans(
      fontSize: 57.sp,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle displayMedium(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.josefinSans(
      fontSize: 45.sp,
      fontWeight: FontWeight.w700,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle displaySmall(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.josefinSans(
      fontSize: 36.sp,
      fontWeight: FontWeight.w600,
      color: color ?? _textColor(context),
    ));
  }
  
  // Headline Styles
  static TextStyle headlineLarge(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.josefinSans(
      fontSize: 32.sp,
      fontWeight: FontWeight.w700,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle headlineMedium(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.josefinSans(
      fontSize: 28.sp,
      fontWeight: FontWeight.w600,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle headlineSmall(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.josefinSans(
      fontSize: 24.sp,
      fontWeight: FontWeight.w600,
      color: color ?? _textColor(context),
    ));
  }
  
  // Title Styles
  static TextStyle titleLarge(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 22.sp,
      fontWeight: FontWeight.w700,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle titleMedium(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle titleSmall(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: color ?? _textColor(context),
    ));
  }
  
  // Body Styles
  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 16.sp,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 14.sp,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.4,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 12.sp,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: color ?? _textSecondaryColor(context),
    ));
  }
  
  // Label Styles
  static TextStyle labelLarge(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle labelMedium(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: color ?? _textColor(context),
    ));
  }
  
  static TextStyle labelSmall(BuildContext context, {Color? color}) {
    return _withFallback(GoogleFonts.lato(
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: color ?? _textSecondaryColor(context),
    ));
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
    onPrimary: Colors.white,
    primaryContainer: PanAfricanColors.primaryContainer,
    onPrimaryContainer: PanAfricanColors.onPrimaryContainer,
    secondary: PanAfricanColors.secondary,
    onSecondary: PanAfricanColors.neutralDarkest,
    secondaryContainer: PanAfricanColors.secondaryContainer,
    onSecondaryContainer: PanAfricanColors.onSecondaryContainer,
    tertiary: PanAfricanColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: PanAfricanColors.tertiaryContainer,
    onTertiaryContainer: PanAfricanColors.onTertiaryContainer,
    error: PanAfricanColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: PanAfricanColors.surfaceLight,
    onSurface: PanAfricanColors.textPrimaryLight,
    surfaceContainerHighest: PanAfricanColors.surfaceContainerHighLight,
    onSurfaceVariant: PanAfricanColors.textSecondaryLight,
    outline: PanAfricanColors.borderLight,
    outlineVariant: PanAfricanColors.neutralLight,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: PanAfricanColors.neutralDark,
    onInverseSurface: PanAfricanColors.textPrimaryDark,
    inversePrimary: PanAfricanColors.primaryLight,
  );
  
  static ColorScheme get dark => const ColorScheme(
    brightness: Brightness.dark,
    primary: PanAfricanColors.primaryLight,
    onPrimary: PanAfricanColors.primaryDark,
    primaryContainer: PanAfricanColors.primaryDark,
    onPrimaryContainer: PanAfricanColors.primaryContainer,
    secondary: PanAfricanColors.secondary,
    onSecondary: PanAfricanColors.neutralDarkest,
    secondaryContainer: PanAfricanColors.secondaryDark,
    onSecondaryContainer: PanAfricanColors.secondaryContainer,
    tertiary: PanAfricanColors.tertiary,
    onTertiary: PanAfricanColors.tertiaryDark,
    tertiaryContainer: PanAfricanColors.tertiaryDark,
    onTertiaryContainer: PanAfricanColors.tertiaryContainer,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: PanAfricanColors.surfaceDark,
    onSurface: PanAfricanColors.textPrimaryDark,
    surfaceContainerHighest: PanAfricanColors.surfaceContainerHighDark,
    onSurfaceVariant: PanAfricanColors.textSecondaryDark,
    outline: PanAfricanColors.borderDark,
    outlineVariant: PanAfricanColors.neutralMedium,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: PanAfricanColors.neutralLightest,
    onInverseSurface: PanAfricanColors.textPrimaryLight,
    inversePrimary: PanAfricanColors.primary,
  );
}

/// Extension for easy access to Pan-African design tokens
extension PanAfricanContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  
  Color get panPrimary => isDark ? PanAfricanColors.primaryLight : PanAfricanColors.primary;
  Color get panSecondary => PanAfricanColors.secondary;
  Color get panTertiary => PanAfricanColors.tertiary;
  
  Color get panSurface => isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight;
  Color get panCard => isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight;
  Color get panBorder => isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight;
  
  Color get panTextPrimary => isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight;
  Color get panTextSecondary => isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight;
  
  LinearGradient get panHeaderGradient => isDark ? PanAfricanGradients.appBarDark : PanAfricanGradients.forest;
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

