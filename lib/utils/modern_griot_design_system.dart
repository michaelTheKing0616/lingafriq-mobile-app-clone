import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lingafriq/utils/pan_african_design_system.dart'
    show PanAfricanSpacing;

// ═══════════════════════════════════════════════════════════════════════════════
// THE MODERN GRIOT — LingAfriq Canonical Design System
// ═══════════════════════════════════════════════════════════════════════════════
//
// Design Philosophy:
//   The Modern Griot draws from West-African oral tradition — warm, earthy,
//   inviting — translated into Material 3 surface-based visual language.
//
// Design Rules (enforced by this system):
//   1. NO-LINE RULE        — 1px borders are prohibited for sectioning.
//   2. TONAL LAYERING      — Depth via surface levels, not elevation shadows.
//   3. GHOST BORDER        — outline_variant at 15% opacity, inputs ONLY.
//   4. NO PURE BLACK       — Always use on_surface (#322e25).
//   5. CARD RADIUS         — xl (24) minimum for all cards.
//   6. AMBIENT SHADOWS     — Warm-tinted, 30-40px blur, 8% opacity. No grey.
//   7. TYPOGRAPHY           — Plus Jakarta Sans everywhere, with diacritics
//                             fallback chain for African-language support.
// ═══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// LIGHT-MODE COLOR TOKENS
// ─────────────────────────────────────────────────────────────────────────────

/// Canonical light-mode color tokens for The Modern Griot theme.
///
/// Palette inspired by Sahel sunsets, laterite earth, and savanna canopy.
/// Every value is hand-picked to maintain WCAG AA contrast on its paired
/// surface while preserving warmth — no cool greys, no pure black.
class ModernGriotColors {
  ModernGriotColors._();

  // ── Primary ──────────────────────────────────────────────────────────────
  /// Earthy ochre / terracotta — brand anchor.
  static const Color primary = Color(0xFF9E3D00);

  /// Sun-glow orange — used for primary containers and vibrant fills.
  static const Color primaryContainer = Color(0xFFFF7A35);

  /// Text/icons on primary surfaces.
  static const Color onPrimary = Color(0xFFFFF0EA);

  /// Text/icons on primaryContainer.
  static const Color onPrimaryContainer = Color(0xFF3A1500);

  /// M3-style aliases for surfaces that pair with [primary] / [onPrimary].
  static const Color primaryFixed = primaryContainer;
  static const Color onPrimaryFixed = onPrimaryContainer;

  // ── Secondary ────────────────────────────────────────────────────────────
  /// Deep forest green — knowledge, growth.
  static const Color secondary = Color(0xFF526124);

  /// Text/icons on secondary surfaces.
  static const Color onSecondary = Color(0xFFE8FBAC);

  /// Lighter secondary fill for containers.
  static const Color secondaryContainer = Color(0xFFD6ED79);

  /// Text/icons on secondaryContainer.
  static const Color onSecondaryContainer = Color(0xFF192600);

  // ── Tertiary (accent) ────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF7B5733);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFDCC4);
  static const Color onTertiaryContainer = Color(0xFF2E1500);

  // ── Surface system (tonal layering, lightest → darkest) ──────────────────
  /// Warm parchment — main canvas.
  static const Color surface = Color(0xFFFEF6E7);

  /// Default container tint.
  static const Color surfaceContainer = Color(0xFFF0E7D6);

  /// Cards sitting low (slightly lighter than container).
  static const Color surfaceContainerLow = Color(0xFFF8F0E0);

  /// Elevated cards, modals.
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Between container and highest — subtle layering.
  static const Color surfaceContainerHigh = Color(0xFFE8DFD0);

  /// Input backgrounds, recessed areas.
  static const Color surfaceContainerHighest = Color(0xFFE5DCC9);

  /// Dimmed surface for overlays / scrims.
  static const Color surfaceDim = Color(0xFFDCD4C0);

  /// Variant surface — same role as highest, semantic alias.
  static const Color surfaceVariant = Color(0xFFE5DCC9);

  // ── On-surface ───────────────────────────────────────────────────────────
  /// Warm dark — headings, primary text. NEVER pure black.
  static const Color onSurface = Color(0xFF322E25);

  /// Body text, secondary labels.
  static const Color onSurfaceVariant = Color(0xFF605B50);

  // ── Outline ──────────────────────────────────────────────────────────────
  /// Standard outline.
  static const Color outline = Color(0xFF8A8478);

  /// Ghost border for inputs — apply at 15% opacity only.
  static const Color outlineVariant = Color(0xFFB3AC9F);

  // ── Error ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // ── Inverse ──────────────────────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFF322E25);
  static const Color onInverseSurface = Color(0xFFFEF6E7);
  static const Color inversePrimary = Color(0xFFFFB68A);

  // ── Misc ─────────────────────────────────────────────────────────────────
  static const Color shadow = Color(0xFF322E25);
  static const Color scrim = Color(0xFF322E25);
  static const Color surfaceTint = primary;
}

// ─────────────────────────────────────────────────────────────────────────────
// DARK-MODE COLOR TOKENS
// ─────────────────────────────────────────────────────────────────────────────

/// Dark-mode palette — properly inverted while retaining warmth.
///
/// Surfaces use dark warm browns (never pure black / cool grey).
/// Primary shifts to lighter peach-orange for contrast.
class ModernGriotColorsDark {
  ModernGriotColorsDark._();

  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFFB68A);
  static const Color primaryContainer = Color(0xFF7C2D00);
  static const Color onPrimary = Color(0xFF532200);
  static const Color onPrimaryContainer = Color(0xFFFFDBC9);

  // ── Secondary ────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFBBD15F);
  static const Color onSecondary = Color(0xFF2A3400);
  static const Color secondaryContainer = Color(0xFF3D4A0E);
  static const Color onSecondaryContainer = Color(0xFFD6ED79);

  // ── Tertiary ─────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFFE6BF99);
  static const Color onTertiary = Color(0xFF462A0D);
  static const Color tertiaryContainer = Color(0xFF60401E);
  static const Color onTertiaryContainer = Color(0xFFFFDCC4);

  // ── Surface system (darkest → lightest) ──────────────────────────────────
  static const Color surface = Color(0xFF1C1A15);
  static const Color surfaceContainer = Color(0xFF252219);
  static const Color surfaceContainerLow = Color(0xFF201E17);
  static const Color surfaceContainerLowest = Color(0xFF16140F);
  static const Color surfaceContainerHigh = Color(0xFF2E2A22);
  static const Color surfaceContainerHighest = Color(0xFF3A352C);
  static const Color surfaceDim = Color(0xFF1C1A15);
  static const Color surfaceVariant = Color(0xFF4D4639);

  // ── On-surface ───────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFEDE0D0);
  static const Color onSurfaceVariant = Color(0xFFCFC5B4);

  // ── Outline ──────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF9A9080);
  static const Color outlineVariant = Color(0xFF4D4639);

  // ── Error ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ── Inverse ──────────────────────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFFEDE0D0);
  static const Color onInverseSurface = Color(0xFF322E25);
  static const Color inversePrimary = Color(0xFF9E3D00);

  // ── Misc ─────────────────────────────────────────────────────────────────
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  static const Color surfaceTint = primary;
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL 3 COLOR-SCHEME BUILDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Builds Material 3 [ColorScheme] instances from Modern Griot tokens.
class ModernGriotColorScheme {
  ModernGriotColorScheme._();

  static ColorScheme get light => const ColorScheme(
        brightness: Brightness.light,
        primary: ModernGriotColors.primary,
        onPrimary: ModernGriotColors.onPrimary,
        primaryContainer: ModernGriotColors.primaryContainer,
        onPrimaryContainer: ModernGriotColors.onPrimaryContainer,
        secondary: ModernGriotColors.secondary,
        onSecondary: ModernGriotColors.onSecondary,
        secondaryContainer: ModernGriotColors.secondaryContainer,
        onSecondaryContainer: ModernGriotColors.onSecondaryContainer,
        tertiary: ModernGriotColors.tertiary,
        onTertiary: ModernGriotColors.onTertiary,
        tertiaryContainer: ModernGriotColors.tertiaryContainer,
        onTertiaryContainer: ModernGriotColors.onTertiaryContainer,
        error: ModernGriotColors.error,
        onError: ModernGriotColors.onError,
        errorContainer: ModernGriotColors.errorContainer,
        onErrorContainer: ModernGriotColors.onErrorContainer,
        surface: ModernGriotColors.surface,
        onSurface: ModernGriotColors.onSurface,
        surfaceContainerHighest: ModernGriotColors.surfaceContainerHighest,
        surfaceContainerHigh: ModernGriotColors.surfaceContainerHigh,
        surfaceContainer: ModernGriotColors.surfaceContainer,
        surfaceContainerLow: ModernGriotColors.surfaceContainerLow,
        surfaceContainerLowest: ModernGriotColors.surfaceContainerLowest,
        onSurfaceVariant: ModernGriotColors.onSurfaceVariant,
        outline: ModernGriotColors.outline,
        outlineVariant: ModernGriotColors.outlineVariant,
        shadow: ModernGriotColors.shadow,
        scrim: ModernGriotColors.scrim,
        inverseSurface: ModernGriotColors.inverseSurface,
        onInverseSurface: ModernGriotColors.onInverseSurface,
        inversePrimary: ModernGriotColors.inversePrimary,
        surfaceTint: ModernGriotColors.surfaceTint,
      );

  static ColorScheme get dark => const ColorScheme(
        brightness: Brightness.dark,
        primary: ModernGriotColorsDark.primary,
        onPrimary: ModernGriotColorsDark.onPrimary,
        primaryContainer: ModernGriotColorsDark.primaryContainer,
        onPrimaryContainer: ModernGriotColorsDark.onPrimaryContainer,
        secondary: ModernGriotColorsDark.secondary,
        onSecondary: ModernGriotColorsDark.onSecondary,
        secondaryContainer: ModernGriotColorsDark.secondaryContainer,
        onSecondaryContainer: ModernGriotColorsDark.onSecondaryContainer,
        tertiary: ModernGriotColorsDark.tertiary,
        onTertiary: ModernGriotColorsDark.onTertiary,
        tertiaryContainer: ModernGriotColorsDark.tertiaryContainer,
        onTertiaryContainer: ModernGriotColorsDark.onTertiaryContainer,
        error: ModernGriotColorsDark.error,
        onError: ModernGriotColorsDark.onError,
        errorContainer: ModernGriotColorsDark.errorContainer,
        onErrorContainer: ModernGriotColorsDark.onErrorContainer,
        surface: ModernGriotColorsDark.surface,
        onSurface: ModernGriotColorsDark.onSurface,
        surfaceContainerHighest: ModernGriotColorsDark.surfaceContainerHighest,
        surfaceContainerHigh: ModernGriotColorsDark.surfaceContainerHigh,
        surfaceContainer: ModernGriotColorsDark.surfaceContainer,
        surfaceContainerLow: ModernGriotColorsDark.surfaceContainerLow,
        surfaceContainerLowest: ModernGriotColorsDark.surfaceContainerLowest,
        onSurfaceVariant: ModernGriotColorsDark.onSurfaceVariant,
        outline: ModernGriotColorsDark.outline,
        outlineVariant: ModernGriotColorsDark.outlineVariant,
        shadow: ModernGriotColorsDark.shadow,
        scrim: ModernGriotColorsDark.scrim,
        inverseSurface: ModernGriotColorsDark.inverseSurface,
        onInverseSurface: ModernGriotColorsDark.onInverseSurface,
        inversePrimary: ModernGriotColorsDark.inversePrimary,
        surfaceTint: ModernGriotColorsDark.surfaceTint,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────

/// Plus Jakarta Sans type scale with diacritics/emoji fallback chain.
///
/// Body text defaults to [ModernGriotColors.onSurfaceVariant] for comfortable
/// reading; headings default to [ModernGriotColors.onSurface] for emphasis.
/// Labels use wider letter-spacing to support uppercase chip styling.
class ModernGriotTypography {
  ModernGriotTypography._();

  static const List<String> _fontFallback = [
    'Noto Sans',
    'Roboto',
    'Segoe UI',
    'Arial Unicode MS',
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Noto Color Emoji',
  ];

  static TextStyle _base(TextStyle style, {Color? color}) =>
      style.copyWith(fontFamilyFallback: _fontFallback, color: color);

  // ── Display ────────────────────────────────────────────────────────────

  static TextStyle displayLarge({BuildContext? context, Color? color}) =>
      _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 57.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          height: 1.12,
        ),
        color: color ?? _headingColor(context),
      );

  static TextStyle displayMedium({BuildContext? context, Color? color}) =>
      _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 45.sp,
          fontWeight: FontWeight.w700,
          height: 1.16,
        ),
        color: color ?? _headingColor(context),
      );

  static TextStyle displaySmall({BuildContext? context, Color? color}) =>
      _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 36.sp,
          fontWeight: FontWeight.w600,
          height: 1.22,
        ),
        color: color ?? _headingColor(context),
      );

  // ── Headline ───────────────────────────────────────────────────────────

  static TextStyle headlineLarge({BuildContext? context, Color? color}) =>
      _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 32.sp,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        color: color ?? _headingColor(context),
      );

  static TextStyle headlineMedium({BuildContext? context, Color? color}) =>
      _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 28.sp,
          fontWeight: FontWeight.w500,
          height: 1.29,
        ),
        color: color ?? _headingColor(context),
      );

  static TextStyle headlineSmall({BuildContext? context, Color? color}) =>
      _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 24.sp,
          fontWeight: FontWeight.w500,
          height: 1.33,
        ),
        color: color ?? _headingColor(context),
      );

  // ── Title ──────────────────────────────────────────────────────────────

  static TextStyle titleLarge({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          height: 1.27,
        ),
        color: color ?? _headingColor(context),
      );

  static TextStyle titleMedium({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        color: color ?? _headingColor(context),
      );

  static TextStyle titleSmall({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        color: color ?? _headingColor(context),
      );

  // ── Body ───────────────────────────────────────────────────────────────

  static TextStyle bodyLarge({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        color: color ?? _bodyColor(context),
      );

  static TextStyle bodyMedium({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.43,
        ),
        color: color ?? _bodyColor(context),
      );

  static TextStyle bodySmall({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.33,
        ),
        color: color ?? _bodyColor(context),
      );

  // ── Label (wider spacing for uppercase chip / badge styling) ───────────

  static TextStyle labelLarge({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        color: color ?? _headingColor(context),
      );

  static TextStyle labelMedium({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.33,
        ),
        color: color ?? _headingColor(context),
      );

  static TextStyle labelSmall({BuildContext? context, Color? color}) => _base(
        GoogleFonts.plusJakartaSans(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.45,
        ),
        color: color ?? _bodyColor(context),
      );

  // ── Internal helpers ──────────────────────────────────────────────────

  static Color _headingColor(BuildContext? context) {
    if (context == null) return ModernGriotColors.onSurface;
    return Theme.of(context).brightness == Brightness.dark
        ? ModernGriotColorsDark.onSurface
        : ModernGriotColors.onSurface;
  }

  static Color _bodyColor(BuildContext? context) {
    if (context == null) return ModernGriotColors.onSurfaceVariant;
    return Theme.of(context).brightness == Brightness.dark
        ? ModernGriotColorsDark.onSurfaceVariant
        : ModernGriotColors.onSurfaceVariant;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-built gradients rooted in the Modern Griot palette.
class ModernGriotGradients {
  ModernGriotGradients._();

  /// Primary → primaryContainer. CTAs, hero headers, feature cards.
  static const LinearGradient signatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ModernGriotColors.primary,
      ModernGriotColors.primaryContainer,
    ],
  );

  /// Secondary range — success states, progress indicators.
  static const LinearGradient forestGrowth = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ModernGriotColors.secondary,
      Color(0xFF7A8C3A),
    ],
  );

  /// Dark surface gradient — dark-mode hero / app-bar backgrounds.
  static const LinearGradient darkSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ModernGriotColorsDark.surfaceContainerHigh,
      ModernGriotColorsDark.surface,
    ],
  );

  /// Warm sunset — light-mode hero sections and onboarding.
  static const LinearGradient sunsetWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ModernGriotColors.surface,
      Color(0xFFFDE8D0),
    ],
  );

  /// Surface at 80% opacity — glassmorphism panels.
  static LinearGradient glassSurface({bool isDark = false}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                ModernGriotColorsDark.surfaceContainer.withAlpha(204),
                ModernGriotColorsDark.surfaceContainerHigh.withAlpha(204),
              ]
            : [
                ModernGriotColors.surfaceContainerLowest.withAlpha(204),
                ModernGriotColors.surfaceContainerLow.withAlpha(204),
              ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────────────────────────────────────

/// Warm ambient shadows — tinted with [ModernGriotColors.onSurface] at 8%
/// opacity, 30-40 px blur. No traditional grey drop-shadows.
class ModernGriotShadows {
  ModernGriotShadows._();

  static final Color _ambient = ModernGriotColors.onSurface.withAlpha(20);

  /// Subtle elevation — lighter than [sm].
  static List<BoxShadow> get xs => [
        BoxShadow(color: _ambient, blurRadius: 4, offset: const Offset(0, 1)),
      ];

  static List<BoxShadow> get sm => [
        BoxShadow(color: _ambient, blurRadius: 8, offset: const Offset(0, 2)),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(color: _ambient, blurRadius: 20, offset: const Offset(0, 4)),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
            color: _ambient, blurRadius: 30, offset: const Offset(0, 8)),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
            color: _ambient, blurRadius: 40, offset: const Offset(0, 12)),
      ];

  /// FAB shadow — tinted with primary at 15% opacity for brand warmth.
  static List<BoxShadow> get fab => [
        BoxShadow(
          color: ModernGriotColors.primary.withAlpha(38),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Colored glow (e.g. success badge, warning).
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withAlpha(38),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACING — reuse PanAfricanSpacing, re-exported above
// ─────────────────────────────────────────────────────────────────────────────
//
// Spacing is provided by [PanAfricanSpacing] from pan_african_design_system.dart.
//   PanAfricanSpacing.xxxs  → 2
//   PanAfricanSpacing.xxs   → 4
//   PanAfricanSpacing.xs    → 8
//   PanAfricanSpacing.sm    → 12
//   PanAfricanSpacing.md    → 16
//   PanAfricanSpacing.lg    → 24
//   PanAfricanSpacing.xl    → 32
//   PanAfricanSpacing.xxl   → 48
//   PanAfricanSpacing.xxxl  → 64
//
// Import this file and use PanAfricanSpacing directly.

// ─────────────────────────────────────────────────────────────────────────────
// RADIUS
// ─────────────────────────────────────────────────────────────────────────────

/// Border-radius tokens. Cards use [xl] (24) minimum per design rules.
class ModernGriotRadius {
  ModernGriotRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  /// The signature "organic" radius — 24dp / 1.5rem.
  static const double xl = 24;
  static const double xxl = 32;

  /// Full pill / stadium shape.
  static const double full = 999;
  static const double pill = 999;

  // ── BorderRadius getters ─────────────────────────────────────────────

  static BorderRadius get borderXs => BorderRadius.circular(xs);
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderXxl => BorderRadius.circular(xxl);
  static BorderRadius get borderFull => BorderRadius.circular(full);
  static BorderRadius get borderPill => BorderRadius.circular(pill);
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME EXTENSION
// ─────────────────────────────────────────────────────────────────────────────

/// Custom theme extension carrying Modern Griot design tokens that don't map
/// cleanly into the standard [ColorScheme] / [TextTheme].
///
/// Access via `Theme.of(context).extension<ModernGriotThemeExtension>()`.
class ModernGriotThemeExtension
    extends ThemeExtension<ModernGriotThemeExtension> {
  const ModernGriotThemeExtension({
    required this.signatureGradient,
    required this.glassColor,
    required this.glassBlur,
    required this.ambientShadowColor,
    required this.patternOpacity,
  });

  /// CTAs and hero gradient.
  final LinearGradient signatureGradient;

  /// Glassmorphism surface tint.
  final Color glassColor;

  /// Blur sigma for glassmorphism.
  final double glassBlur;

  /// Base color for ambient box-shadows (apply at 8% alpha).
  final Color ambientShadowColor;

  /// Opacity for decorative SVG patterns (background textures).
  final double patternOpacity;

  // ── Presets ────────────────────────────────────────────────────────────

  static const ModernGriotThemeExtension light = ModernGriotThemeExtension(
    signatureGradient: ModernGriotGradients.signatureGradient,
    glassColor: Color(0xCCFFFFFF),
    glassBlur: 24.0,
    ambientShadowColor: ModernGriotColors.onSurface,
    patternOpacity: 0.03,
  );

  static const ModernGriotThemeExtension dark = ModernGriotThemeExtension(
    signatureGradient: ModernGriotGradients.signatureGradient,
    glassColor: Color(0xCC252219),
    glassBlur: 24.0,
    ambientShadowColor: Color(0xFF000000),
    patternOpacity: 0.05,
  );

  // ── ThemeExtension contract ────────────────────────────────────────────

  @override
  ModernGriotThemeExtension copyWith({
    LinearGradient? signatureGradient,
    Color? glassColor,
    double? glassBlur,
    Color? ambientShadowColor,
    double? patternOpacity,
  }) =>
      ModernGriotThemeExtension(
        signatureGradient: signatureGradient ?? this.signatureGradient,
        glassColor: glassColor ?? this.glassColor,
        glassBlur: glassBlur ?? this.glassBlur,
        ambientShadowColor: ambientShadowColor ?? this.ambientShadowColor,
        patternOpacity: patternOpacity ?? this.patternOpacity,
      );

  @override
  ModernGriotThemeExtension lerp(
    covariant ModernGriotThemeExtension? other,
    double t,
  ) {
    if (other is! ModernGriotThemeExtension) return this;
    return ModernGriotThemeExtension(
      signatureGradient:
          LinearGradient.lerp(signatureGradient, other.signatureGradient, t)!,
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t)!,
      ambientShadowColor:
          Color.lerp(ambientShadowColor, other.ambientShadowColor, t)!,
      patternOpacity: lerpDouble(patternOpacity, other.patternOpacity, t)!,
    );
  }
}

/// Interpolates between two doubles (mirrors [dart:ui.lerpDouble]).
double? lerpDouble(double? a, double? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVENIENCE EXTENSION ON BuildContext
// ─────────────────────────────────────────────────────────────────────────────

/// Quick access to Modern Griot tokens from any widget tree.
extension ModernGriotContext on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get griotPrimary =>
      _isDark ? ModernGriotColorsDark.primary : ModernGriotColors.primary;
  Color get griotOnSurface =>
      _isDark ? ModernGriotColorsDark.onSurface : ModernGriotColors.onSurface;
  Color get griotOnSurfaceVariant => _isDark
      ? ModernGriotColorsDark.onSurfaceVariant
      : ModernGriotColors.onSurfaceVariant;
  Color get griotSurface =>
      _isDark ? ModernGriotColorsDark.surface : ModernGriotColors.surface;
  Color get griotSurfaceContainer => _isDark
      ? ModernGriotColorsDark.surfaceContainer
      : ModernGriotColors.surfaceContainer;

  ModernGriotThemeExtension? get griotExt =>
      Theme.of(this).extension<ModernGriotThemeExtension>();
}
