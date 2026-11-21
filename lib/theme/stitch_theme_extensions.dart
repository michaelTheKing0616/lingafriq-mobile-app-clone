import 'package:flutter/material.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Stitch / FLB editorial tokens from
/// `Elite Features/.../f_l_b_heritage/DESIGN.md` (The Digital Curator).
@Deprecated('Use LingAfriqTokens. This file is a retired design system.')
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
    paperSurface: LingAfriqTokens.hexFFFCF9F2,
    surfaceContainerLowest: LingAfriqTokens.hexFFFFFFFF,
    surfaceContainerHigh: LingAfriqTokens.hexFFEBE8E1,
    terracotta: LingAfriqTokens.hexFF9F3E07,
    terracottaContainer: LingAfriqTokens.hexFFC05621,
    onTerracotta: LingAfriqTokens.hexFFFFF8F2,
    ochreTertiary: LingAfriqTokens.hexFF735C00,
    ambientShadow: LingAfriqTokens.hex281C1C18,
  );

  /// Studio / night reading — deeper paper, same terracotta brand.
  static const FlbEditorialTheme dark = FlbEditorialTheme(
    paperSurface: LingAfriqTokens.hexFF1B1A16,
    surfaceContainerLowest: LingAfriqTokens.hexFF25241F,
    surfaceContainerHigh: LingAfriqTokens.hexFF2E2C26,
    terracotta: LingAfriqTokens.hexFFE07A3A,
    terracottaContainer: LingAfriqTokens.hexFFFF9B5C,
    onTerracotta: LingAfriqTokens.hexFF1B0C00,
    ochreTertiary: LingAfriqTokens.hexFFD4B870,
    ambientShadow: LingAfriqTokens.hex40000000,
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
    heroIndigo: LingAfriqTokens.hexFF333697,
    heroIndigoDeep: LingAfriqTokens.hexFF4B4FB0,
    parchment: LingAfriqTokens.hexFFFAFAF5,
    parchmentLow: LingAfriqTokens.hexFFF4F4EF,
    terracottaAccent: LingAfriqTokens.hexFFB85C38,
  );

  static const StitchArcadeTheme dark = StitchArcadeTheme(
    heroIndigo: LingAfriqTokens.hexFF5C61D6,
    heroIndigoDeep: LingAfriqTokens.hexFF7A7EE8,
    parchment: LingAfriqTokens.hexFF121318,
    parchmentLow: LingAfriqTokens.hexFF1A1C24,
    terracottaAccent: LingAfriqTokens.hexFFE88B5A,
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
    warmCanvas: LingAfriqTokens.hexFFFFF7F0,
    warmSurface: LingAfriqTokens.hexFFFFE8D9,
    accentCopper: LingAfriqTokens.hexFFC45D35,
  );

  static const StitchCommunityChatTheme dark = StitchCommunityChatTheme(
    warmCanvas: LingAfriqTokens.hexFF1A1512,
    warmSurface: LingAfriqTokens.hexFF2A221C,
    accentCopper: LingAfriqTokens.hexFFE8A078,
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
