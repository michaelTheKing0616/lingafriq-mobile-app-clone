// Material 3 Migration Helper
// 
// This file provides helper functions and constants for Material 3 migration
// Use these utilities to ensure consistent Material 3 adoption

import 'package:flutter/material.dart';

class Material3Helper {
  /// Get Material 3 button style for primary actions
  static ButtonStyle filledButtonStyle(BuildContext context) {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }

  /// Get Material 3 button style for secondary actions
  static ButtonStyle outlinedButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }

  /// Get Material 3 button style for text actions
  static ButtonStyle textButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// Get Material 3 card style
  static CardTheme cardTheme(BuildContext context) {
    final theme = Theme.of(context);
    return CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: theme.colorScheme.surfaceContainerHighest,
    );
  }

  /// Check if Material 3 is enabled
  static bool isMaterial3Enabled(BuildContext context) {
    return Theme.of(context).useMaterial3;
  }

  /// Get Material 3 color scheme
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
}

/// Material 3 Button Variants
/// 
/// Use these instead of deprecated Material 2 buttons:
/// - RaisedButton → FilledButton
/// - FlatButton → TextButton  
/// - OutlineButton → OutlinedButton
/// - MaterialButton → FilledButton (for primary) or OutlinedButton (for secondary)

