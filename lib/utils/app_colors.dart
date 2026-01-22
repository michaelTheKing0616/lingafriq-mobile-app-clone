import 'package:flutter/material.dart';

class AppColors {
  static const Color grey = Color(0xffB9C0D1);
  static const Color filledLight = Color(0xffE7E7E7);
  // static const Color filledDark = Color(0xff1A1A1A);
  static const Color filledDark = Color(0xff1A1A1A);
  static const Color primaryGreen = Color(0xff566A29);
  static const Color primaryOrange = Color(0xffEB8937);
  static const Color bottomBarOrange = Color(0xffC7463A);
  static const Color red = Color(0xffC4413A);
  static const Color accentGold = Color(0xffFFD700);
  
  // Additional colors for compatibility
  static const Color stitchPrimary = Color(0xFF1B7340); // Pan-African green
  static const Color success = Color(0xFF2ECC71);
  static const Color surfaceDark = Color(0xFF0D1810);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color stitchCardDark = Color(0xFF1F3527);
  static const Color stitchCardLight = Color(0xFFFFFFFF);
  static const Color stitchBorderDark = Color(0xFF2A4A35);
  static const Color stitchBorderLight = Color(0xFFE0E4E0);
  static const Color stitchTextDark = Color(0xFF0D1B12);
  static const Color stitchTextLight = Color(0xFFF4F6F5);
  static const Color accentOrange = Color(0xFFEB8937);

  /// Back-compat aliases (used by newer widgets/design system code)
  static const Color accentGreen = stitchPrimary;
  static const Color textPrimary = stitchTextDark;
  static const Color textSecondary = grey;
  
  // Additional color for games
  static const Color oceanBlue = Color(0xFF00A8E8);
}
