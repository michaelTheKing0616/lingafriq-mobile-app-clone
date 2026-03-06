import 'package:flutter/material.dart';

class SnapUi {
  static Color scaffoldBg(bool isDark) => isDark ? Colors.black : const Color(0xFFF5F7FA);
  static Color cardBg(bool isDark) => isDark ? const Color(0xFF14181D) : Colors.white;
  static Color accent() => const Color(0xFFE05C2A);
  static Color storyRingA() => const Color(0xFFE05C2A);
  static Color storyRingB() => const Color(0xFFF59E0B);
  static Color storySeen() => const Color(0xFF6B7280);
}
