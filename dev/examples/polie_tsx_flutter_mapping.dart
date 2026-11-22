import 'package:flutter/material.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';

/// TSX -> Flutter mapping matrix used for parity checks.
/// This keeps implementation aligned with the provided Polie TSX design language.
class PolieTsxFlutterMapping {
  PolieTsxFlutterMapping._();

  static const Map<String, Color> colorTokens = {
    'polie-earth': PolieColors.primary,
    'polie-amber': PolieColors.goldEmber,
    'polie-gold': PolieColors.goldEmberLight,
    'polie-sage': PolieColors.electricTeal,
    'polie-clay': PolieColors.royalAmethyst,
    'polie-cream': PolieColors.surfaceLight,
    'polie-midnight': PolieColors.obsidian,
  };

  static const Map<String, double> spacingScale = {
    '4': 4,
    '8': 8,
    '12': 12,
    '16': 16,
    '24': 24,
    '32': 32,
  };

  static const Map<String, double> radiusScale = {
    'sm': 8,
    'md': 12,
    'lg': 20,
    'pill': 100,
  };

  static const List<String> coreInteractionStates = [
    'idle',
    'active',
    'disabled',
    'loading',
    'error',
  ];
}
