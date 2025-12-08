/// Material 3 Migration Helper
/// Utility functions for Material 3 styling and components

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Material3Helper {
  /// Get Material 3 filled button style
  static ButtonStyle filledButtonStyle(BuildContext context) {
    return FilledButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 0,
    );
  }

  /// Get Material 3 outlined button style
  static ButtonStyle outlinedButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      side: BorderSide(
        width: 1.5,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  /// Get Material 3 text button style
  static ButtonStyle textButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  /// Get Material 3 card theme with enhanced elevation
  static CardTheme cardTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardTheme(
      elevation: isDark ? 2 : 4,
      shadowColor: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      margin: EdgeInsets.all(8.w),
      clipBehavior: Clip.antiAlias,
    );
  }

  /// Get enhanced card with Material 3 styling
  static Widget enhancedCard({
    required Widget child,
    Color? color,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return Card(
      color: color,
      elevation: elevation ?? 4,
      margin: margin ?? EdgeInsets.all(8.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: padding ?? EdgeInsets.all(16.w),
          child: child,
        ),
      ),
    );
  }

  /// Get Material 3 color scheme
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Get Material 3 surface color with elevation
  static Color surfaceColor(BuildContext context, int elevation) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      switch (elevation) {
        case 1:
          return colorScheme.surfaceContainerHighest;
        case 2:
          return colorScheme.surfaceContainerHigh;
        case 3:
          return colorScheme.surfaceContainer;
        case 4:
          return colorScheme.surfaceContainerLow;
        case 5:
          return colorScheme.surfaceContainerLowest;
        default:
          return colorScheme.surface;
      }
    } else {
      // Light mode uses elevation shadows
      return colorScheme.surface;
    }
  }

  /// Get Material 3 button with haptic feedback
  static Widget hapticButton({
    required Widget child,
    required VoidCallback? onPressed,
    String actionType = 'button_press',
    ButtonStyle? style,
  }) {
    return Builder(
      builder: (context) {
        return FilledButton(
          onPressed: onPressed != null
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed();
                }
              : null,
          style: style ?? filledButtonStyle(context),
          child: child,
        );
      },
    );
  }

  /// Get Material 3 icon button with haptic feedback
  static Widget hapticIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    String actionType = 'button_press',
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed != null
          ? () {
              HapticFeedback.lightImpact();
              onPressed();
            }
          : null,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        padding: EdgeInsets.all(12.w),
      ),
    );
  }
}

