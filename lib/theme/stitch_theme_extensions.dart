import 'package:flutter/material.dart';

/// Stitch / FLB editorial tokens from
/// `Elite Features/.../f_l_b_heritage/DESIGN.md` (The Digital Curator).
@immutable
class FlbEditorialTheme extends ThemeExtension<FlbEditorialTheme> {
  const FlbEditorialTheme({
    required this.paperSurface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerHigh,
    required this.terracotta,
    required this.terracottaContainer,
    required this.onTerracotta,
    required this.ochreTertiary,
    required this.ambientShadow,
  });

  /// Base “paper” reading surface (#fcf9f2).
  final Color paperSurface;

  /// Highest interactive tier (#ffffff).
  final Color surfaceContainerLowest;

  /// Recessed / secondary (#ebe8e1).
  final Color surfaceContainerHigh;

  /// Primary terracotta (#9f3e07).
  final Color terracotta;

  /// Gradient end for CTAs (#c05621).
  final Color terracottaContainer;

  /// Text on terracotta fills.
  final Color onTerracotta;

  /// Sand / gold tertiary accent (#735c00).
  final Color ochreTertiary;

  /// Soft lift — tinted on-surface, never pure black.
  final Color ambientShadow;

  static const FlbEditorialTheme light = FlbEditorialTheme(
    paperSurface: Color(0xFFFCF9F2),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFEBE8E1),
    terracotta: Color(0xFF9F3E07),
    terracottaContainer: Color(0xFFC05621),
    onTerracotta: Color(0xFFFFF8F2),
    ochreTertiary: Color(0xFF735C00),
    ambientShadow: Color(0x281C1C18),
  );

  /// Studio / night reading — deeper paper, same terracotta brand.
  static const FlbEditorialTheme dark = FlbEditorialTheme(
    paperSurface: Color(0xFF1B1A16),
    surfaceContainerLowest: Color(0xFF25241F),
    surfaceContainerHigh: Color(0xFF2E2C26),
    terracotta: Color(0xFFE07A3A),
    terracottaContainer: Color(0xFFFF9B5C),
    onTerracotta: Color(0xFF1B0C00),
    ochreTertiary: Color(0xFFD4B870),
    ambientShadow: Color(0x40000000),
  );

  LinearGradient get terracottaCtaGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [terracotta, terracottaContainer],
      );

  @override
  FlbEditorialTheme copyWith({
    Color? paperSurface,
    Color? surfaceContainerLowest,
    Color? surfaceContainerHigh,
    Color? terracotta,
    Color? terracottaContainer,
    Color? onTerracotta,
    Color? ochreTertiary,
    Color? ambientShadow,
  }) {
    return FlbEditorialTheme(
      paperSurface: paperSurface ?? this.paperSurface,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      terracotta: terracotta ?? this.terracotta,
      terracottaContainer: terracottaContainer ?? this.terracottaContainer,
      onTerracotta: onTerracotta ?? this.onTerracotta,
      ochreTertiary: ochreTertiary ?? this.ochreTertiary,
      ambientShadow: ambientShadow ?? this.ambientShadow,
    );
  }

  @override
  FlbEditorialTheme lerp(ThemeExtension<FlbEditorialTheme>? other, double t) {
    if (other is! FlbEditorialTheme) return this;
    return FlbEditorialTheme(
      paperSurface: Color.lerp(paperSurface, other.paperSurface, t)!,
      surfaceContainerLowest:
          Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      terracotta: Color.lerp(terracotta, other.terracotta, t)!,
      terracottaContainer:
          Color.lerp(terracottaContainer, other.terracottaContainer, t)!,
      onTerracotta: Color.lerp(onTerracotta, other.onTerracotta, t)!,
      ochreTertiary: Color.lerp(ochreTertiary, other.ochreTertiary, t)!,
      ambientShadow: Color.lerp(ambientShadow, other.ambientShadow, t)!,
    );
  }
}

/// Lumina / speed-round “arcade” tokens from
/// `stitch_speed_round_remix/.../lumina_africa/DESIGN.md`.
@immutable
class StitchArcadeTheme extends ThemeExtension<StitchArcadeTheme> {
  const StitchArcadeTheme({
    required this.heroIndigo,
    required this.heroIndigoDeep,
    required this.parchment,
    required this.parchmentLow,
    required this.terracottaAccent,
  });

  final Color heroIndigo;
  final Color heroIndigoDeep;
  final Color parchment;
  final Color parchmentLow;
  final Color terracottaAccent;

  static const StitchArcadeTheme light = StitchArcadeTheme(
    heroIndigo: Color(0xFF333697),
    heroIndigoDeep: Color(0xFF4B4FB0),
    parchment: Color(0xFFFAFAF5),
    parchmentLow: Color(0xFFF4F4EF),
    terracottaAccent: Color(0xFFB85C38),
  );

  static const StitchArcadeTheme dark = StitchArcadeTheme(
    heroIndigo: Color(0xFF5C61D6),
    heroIndigoDeep: Color(0xFF7A7EE8),
    parchment: Color(0xFF121318),
    parchmentLow: Color(0xFF1A1C24),
    terracottaAccent: Color(0xFFE88B5A),
  );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [heroIndigo, heroIndigoDeep],
      );

  @override
  StitchArcadeTheme copyWith({
    Color? heroIndigo,
    Color? heroIndigoDeep,
    Color? parchment,
    Color? parchmentLow,
    Color? terracottaAccent,
  }) {
    return StitchArcadeTheme(
      heroIndigo: heroIndigo ?? this.heroIndigo,
      heroIndigoDeep: heroIndigoDeep ?? this.heroIndigoDeep,
      parchment: parchment ?? this.parchment,
      parchmentLow: parchmentLow ?? this.parchmentLow,
      terracottaAccent: terracottaAccent ?? this.terracottaAccent,
    );
  }

  @override
  StitchArcadeTheme lerp(ThemeExtension<StitchArcadeTheme>? other, double t) {
    if (other is! StitchArcadeTheme) return this;
    return StitchArcadeTheme(
      heroIndigo: Color.lerp(heroIndigo, other.heroIndigo, t)!,
      heroIndigoDeep: Color.lerp(heroIndigoDeep, other.heroIndigoDeep, t)!,
      parchment: Color.lerp(parchment, other.parchment, t)!,
      parchmentLow: Color.lerp(parchmentLow, other.parchmentLow, t)!,
      terracottaAccent:
          Color.lerp(terracottaAccent, other.terracottaAccent, t)!,
    );
  }
}

/// Private-chat cluster warm community tokens (Stitch private_chat tree).
@immutable
class StitchCommunityChatTheme extends ThemeExtension<StitchCommunityChatTheme> {
  const StitchCommunityChatTheme({
    required this.warmCanvas,
    required this.warmSurface,
    required this.accentCopper,
  });

  final Color warmCanvas;
  final Color warmSurface;
  final Color accentCopper;

  static const StitchCommunityChatTheme light = StitchCommunityChatTheme(
    warmCanvas: Color(0xFFFFF7F0),
    warmSurface: Color(0xFFFFE8D9),
    accentCopper: Color(0xFFC45D35),
  );

  static const StitchCommunityChatTheme dark = StitchCommunityChatTheme(
    warmCanvas: Color(0xFF1A1512),
    warmSurface: Color(0xFF2A221C),
    accentCopper: Color(0xFFE8A078),
  );

  @override
  StitchCommunityChatTheme copyWith({
    Color? warmCanvas,
    Color? warmSurface,
    Color? accentCopper,
  }) {
    return StitchCommunityChatTheme(
      warmCanvas: warmCanvas ?? this.warmCanvas,
      warmSurface: warmSurface ?? this.warmSurface,
      accentCopper: accentCopper ?? this.accentCopper,
    );
  }

  @override
  StitchCommunityChatTheme lerp(
    ThemeExtension<StitchCommunityChatTheme>? other,
    double t,
  ) {
    if (other is! StitchCommunityChatTheme) return this;
    return StitchCommunityChatTheme(
      warmCanvas: Color.lerp(warmCanvas, other.warmCanvas, t)!,
      warmSurface: Color.lerp(warmSurface, other.warmSurface, t)!,
      accentCopper: Color.lerp(accentCopper, other.accentCopper, t)!,
    );
  }
}

extension StitchThemeBuildContext on BuildContext {
  FlbEditorialTheme? get flbEditorial =>
      Theme.of(this).extension<FlbEditorialTheme>();

  StitchArcadeTheme? get stitchArcade =>
      Theme.of(this).extension<StitchArcadeTheme>();

  StitchCommunityChatTheme? get stitchCommunity =>
      Theme.of(this).extension<StitchCommunityChatTheme>();
}
