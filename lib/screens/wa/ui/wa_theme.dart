import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class WaUi {
  static Color scaffoldBg(bool isDark) =>
      isDark ? const Color(0xFF0F151A) : const Color(0xFFF3FBF5);
  static Color cardBg(bool isDark) =>
      isDark ? const Color(0xFF1B2A33) : Colors.white;
  static Color ringSeen(bool isDark) =>
      isDark ? PanAfricanColors.neutralDark : PanAfricanColors.neutralMedium;
  static Color ringUnseenA() => const Color(0xFF16A34A);
  static Color ringUnseenB() => const Color(0xFF059669);
  static Color primary() => const Color(0xFF16A34A);
}
