import 'package:flutter/material.dart';

/// Brand + path clay tokens (v3 DESIGN_BRIEF + LingAfriq Gold/Coral).
///
/// Colour conveys state, but every node also uses a distinct shape/icon so
/// colour is never the only cue (a11y upgrade from the reference pack).
abstract final class PathBrandColors {
  static const Color gold = Color(0xFFFFC53D);
  static const Color coral = Color(0xFFE5603B);
  static const Color parchment = Color(0xFFF6EAD3);
  static const Color parchmentDark = Color(0xFF2A241C);

  static const Color done = Color(0xFF5BC236);
  static const Color doneLip = Color(0xFF3F9A22);
  static const Color current = Color(0xFFFF9F1C);
  static const Color currentLip = Color(0xFFD9770A);
  static const Color reviewDue = Color(0xFF3DB2F0);
  static const Color reviewDueLip = Color(0xFF1F86C4);
  static const Color locked = Color(0xFFE6DAC6);
  static const Color lockedLip = Color(0xFFC7B79C);
  static const Color lockedLabel = Color(0xFFA08D6E);

  /// Candy Crush-style clay road fill (not a thin Duo dashed hairline).
  static const Color road = Color(0xFFE2D0A8);
  static const Color roadLip = Color(0xFFC4AE7E);
  static const Color roadTravelled = Color(0xFFE5603B);
}

/// Place theme for Candy Crush-style scenery chapters (no sacred objects).
enum PathPlaceTheme { market, village, coast }

/// Recipe geometry for the winding journey map (Mimo units + Candy Crush road).
abstract final class PathLayout {
  /// Node diameter (logical px before ScreenUtil).
  static const double nodeSize = 72;

  /// Vertical gap between consecutive node centres (recipe: 24 px apart).
  static const double nodeGap = 24;

  /// Sticky chrome heights.
  static const double stickyHeaderHeight = 56;
  static const double stickyBannerMinHeight = 72;

  /// Minimum tap target for header chips / Guide / dialect.
  static const double minTapTarget = 44;

  /// Header background fades in after this scroll delta.
  static const double headerFadeScrollPx = 8;

  /// Initial scroll places the current node near this fraction of the viewport.
  static const double currentNodeViewportFraction = 0.40;

  /// Scenery parallax factor relative to path scroll.
  static const double sceneryParallax = 0.3;

  /// Press scale + duration (recipe).
  static const double pressScale = 0.94;
  static const Duration pressDuration = Duration(milliseconds: 80);
  static const Duration popoverDuration = Duration(milliseconds: 200);
  static const Duration bannerSwapDuration = Duration(milliseconds: 250);
  static const Duration reducedMotionCrossfade = Duration(milliseconds: 150);
  static const Duration pulseDuration = Duration(milliseconds: 1400);

  /// Wide clay road stroke (Candy Crush journey, not Duo hairline).
  static const double roadWidth = 28;

  /// Horizontal sine offsets: 0, +48, +72, +48, 0, −48, −72, −48…
  static const List<double> sineOffsets = [
    0,
    48,
    72,
    48,
    0,
    -48,
    -72,
    -48,
  ];

  static double horizontalOffsetForIndex(int index) {
    if (index < 0) return 0;
    return sineOffsets[index % sineOffsets.length];
  }

  /// Checkpoint / chest every 5th lesson (1-based: 5, 10, 15…).
  static bool isCheckpoint(int lessonIndex) =>
      lessonIndex >= 0 && (lessonIndex + 1) % 5 == 0;

  /// Scenery sits on the outer side of the sine swing (Candy Crush map props).
  static bool sceneryOnEndSide(int lessonIndex) {
    final dx = horizontalOffsetForIndex(lessonIndex);
    return dx >= 0;
  }

  /// Row height for list extent math (node + gap + Start pill slack).
  static double get nodeRowExtent => nodeSize + nodeGap + 20;

  static PathPlaceTheme placeThemeForUnit(int unitOrdinal) {
    switch (unitOrdinal % 3) {
      case 0:
        return PathPlaceTheme.market;
      case 1:
        return PathPlaceTheme.village;
      default:
        return PathPlaceTheme.coast;
    }
  }
}

/// Unit ribbon colours — African place themes, not a generic green clone.
const List<Color> kPathUnitRibbonColors = [
  Color(0xFFC8650C), // market clay
  Color(0xFF1F7A5C), // coast / mangrove
  Color(0xFF8B3A2B), // village earth
  Color(0xFF5B4B8A), // dusk indigo
  Color(0xFFB45309), // savannah gold-edge
  Color(0xFF0E7490), // lagoon
];

Color pathUnitRibbonColor(int unitOrdinal) {
  if (unitOrdinal < 0) return kPathUnitRibbonColors.first;
  return kPathUnitRibbonColors[unitOrdinal % kPathUnitRibbonColors.length];
}

String pathPlaceThemeLabel(PathPlaceTheme theme) {
  switch (theme) {
    case PathPlaceTheme.market:
      return 'Market';
    case PathPlaceTheme.village:
      return 'Village';
    case PathPlaceTheme.coast:
      return 'Coast';
  }
}

/// Soft parchment wash tint per place theme (journey atmosphere).
Color pathPlaceWashColor(PathPlaceTheme theme, {required bool isDark}) {
  if (isDark) {
    switch (theme) {
      case PathPlaceTheme.market:
        return const Color(0xFF3A2A18);
      case PathPlaceTheme.village:
        return const Color(0xFF2C241C);
      case PathPlaceTheme.coast:
        return const Color(0xFF1C2A2E);
    }
  }
  switch (theme) {
    case PathPlaceTheme.market:
      return const Color(0xFFF3D9B0);
    case PathPlaceTheme.village:
      return const Color(0xFFE8DCC8);
    case PathPlaceTheme.coast:
      return const Color(0xFFD9E8E2);
  }
}

/// Language → flag emoji for the sticky header chip.
String pathLanguageFlagEmoji(String languageName) {
  final key = languageName.trim().toLowerCase();
  if (key.startsWith('yor') || key == 'yo') return '🇳🇬';
  if (key.startsWith('igb') || key == 'ig' || key == 'ibo') return '🇳🇬';
  if (key.startsWith('hau') || key == 'ha') return '🇳🇬';
  if (key.contains('pidgin') || key == 'pcm') return '🇳🇬';
  if (key.startsWith('zul') || key == 'zu') return '🇿🇦';
  if (key.startsWith('xho') || key == 'xh') return '🇿🇦';
  if (key.startsWith('swa') || key == 'sw') return '🇰🇪';
  if (key.startsWith('amh') || key == 'am') return '🇪🇹';
  if (key.startsWith('twi') || key == 'tw') return '🇬🇭';
  if (key.startsWith('wol')) return '🇸🇳';
  if (key.startsWith('ara') || key == 'ar') return '🇸🇦';
  return '🌍';
}
