import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class GameUiTokens {
  GameUiTokens._();

  static const double touchTarget = 44;
  static const double topBarHeight = 64;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static Color success(BuildContext context) => PanAfricanColors.success;
  static Color warning(BuildContext context) => PanAfricanColors.warning;
  static Color danger(BuildContext context) => PanAfricanColors.error;
  static Color score(BuildContext context) => PanAfricanColors.secondary;
  static Color timer(BuildContext context) => PanAfricanColors.primary;
}
