import 'package:flutter/material.dart';
import 'package:lingafriq/design/legacy_shim.dart';
import 'package:lingafriq/design/tokens.g.dart';

@Deprecated('Use LingAfriqTokens. This file is a retired design system.')
class AppColors {
  static Color readGrey() => LegacyDesignShim.read('app_colors.grey', grey);

  static const Color grey = LingAfriqTokens.hexFFB9C0D1;
  static const Color filledLight = LingAfriqTokens.hexFFE7E7E7;
  // static const Color filledDark = LingAfriqTokens.hexFF1A1A1A;
  static const Color filledDark = LingAfriqTokens.hexFF1A1A1A;
  static const Color primaryGreen = LingAfriqTokens.hexFF566A29;
  static const Color primaryOrange = LingAfriqTokens.hexFFEB8937;
  static const Color bottomBarOrange = LingAfriqTokens.hexFFC7463A;
  static const Color red = LingAfriqTokens.hexFFC4413A;
  static const Color accentGold = LingAfriqTokens.hexFFFFD700;
  
  // Additional colors for compatibility
  static const Color stitchPrimary = LingAfriqTokens.hexFF1B7340; // Pan-African green
  static const Color success = LingAfriqTokens.hexFF2ECC71;
  static const Color surfaceDark = LingAfriqTokens.hexFF0D1810;
  static const Color surfaceLight = LingAfriqTokens.hexFFFAFAFA;
  static const Color stitchCardDark = LingAfriqTokens.hexFF1F3527;
  static const Color stitchCardLight = LingAfriqTokens.hexFFFFFFFF;
  static const Color stitchBorderDark = LingAfriqTokens.hexFF2A4A35;
  static const Color stitchBorderLight = LingAfriqTokens.hexFFE0E4E0;
  static const Color stitchTextDark = LingAfriqTokens.hexFF0D1B12;
  static const Color stitchTextLight = LingAfriqTokens.hexFFF4F6F5;
  static const Color accentOrange = LingAfriqTokens.hexFFEB8937;

  /// Back-compat aliases (used by newer widgets/design system code)
  static const Color accentGreen = stitchPrimary;
  static const Color textPrimary = stitchTextDark;
  static const Color textSecondary = grey;
  
  // Additional color for games
  static const Color oceanBlue = LingAfriqTokens.hexFF00A8E8;
}
