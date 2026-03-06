import 'package:flutter/material.dart';

class XUi {
  static Color scaffoldBg(bool isDark) => isDark ? const Color(0xFF000000) : Colors.white;
  static Color cardBg(bool isDark) => isDark ? const Color(0xFF16181C) : Colors.white;
  static Color divider(bool isDark) =>
      isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4);
  static Color accent() => const Color(0xFFE05C2A);
  static Color secondaryText(bool isDark) =>
      isDark ? const Color(0xFF71767B) : const Color(0xFF536471);
}
