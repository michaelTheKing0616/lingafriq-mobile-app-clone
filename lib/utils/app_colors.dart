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
  
  // Additional color constants for design system
  static const Color stitchPrimary = primaryGreen;
  static const Color success = Color(0xFF22C55E);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = primaryOrange;
  static const Color surfaceDark = filledDark;
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color stitchCardDark = Color(0xFF2A2A2A);
  static const Color stitchCardLight = Color(0xFFFFFFFF);
  static const Color stitchBorderDark = Color(0xFF404040);
  static const Color stitchBorderLight = Color(0xFFE0E0E0);
  static const Color stitchTextDark = Color(0xFFFFFFFF);
  static const Color stitchTextLight = Color(0xFF1A1A1A);

  /// Back-compat aliases used throughout the app UI.
  static const Color textPrimary = stitchTextLight;
  static const Color textSecondary = grey;

  /// Accent used by some game UIs.
  static const Color oceanBlue = Color(0xFF00A8E8);
}
