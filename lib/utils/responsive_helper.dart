import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive helper utilities for dynamic UI adaptation
class ResponsiveHelper {
  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 360;
    final isLarge = screenWidth > 600;
    
    // Base multipliers for different screen sizes
    final multiplier = isSmall ? 0.8 : (isLarge ? 1.2 : 1.0);
    
    return EdgeInsets.only(
      top: (top ?? vertical ?? all ?? 0) * multiplier,
      bottom: (bottom ?? vertical ?? all ?? 0) * multiplier,
      left: (left ?? horizontal ?? all ?? 0) * multiplier,
      right: (right ?? horizontal ?? all ?? 0) * multiplier,
    );
  }

  /// Get responsive font size
  static double getFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    final isLarge = screenWidth > 600;
    
    if (isSmall) return baseSize * 0.9;
    if (isLarge) return baseSize * 1.1;
    return baseSize;
  }

  /// Get responsive width percentage
  static double getWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  /// Get responsive height percentage
  static double getHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  /// Check if screen is small
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Check if screen is medium
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width <= 600;
  }

  /// Check if screen is large
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    final isLarge = screenWidth > 600;
    
    if (isSmall) return baseSize * 0.85;
    if (isLarge) return baseSize * 1.15;
    return baseSize;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).viewPadding;
  }

  /// Get bottom safe area height (for action buttons)
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).viewPadding.bottom;
  }

  /// Get top safe area height (for status bar)
  static double getTopSafeArea(BuildContext context) {
    return MediaQuery.of(context).viewPadding.top;
  }
}

/// Extension for easy responsive access
extension ResponsiveExtension on BuildContext {
  bool get isSmallScreen => ResponsiveHelper.isSmallScreen(this);
  bool get isMediumScreen => ResponsiveHelper.isMediumScreen(this);
  bool get isLargeScreen => ResponsiveHelper.isLargeScreen(this);
  
  double rw(double percentage) => ResponsiveHelper.getWidth(this, percentage);
  double rh(double percentage) => ResponsiveHelper.getHeight(this, percentage);
  double rf(double baseSize) => ResponsiveHelper.getFontSize(this, baseSize);
  double ri(double baseSize) => ResponsiveHelper.getIconSize(this, baseSize);
  
  EdgeInsets rp({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) => ResponsiveHelper.getPadding(this,
    all: all,
    horizontal: horizontal,
    vertical: vertical,
    top: top,
    bottom: bottom,
    left: left,
    right: right,
  );
  
  double get bottomSafeArea => ResponsiveHelper.getBottomSafeArea(this);
  double get topSafeArea => ResponsiveHelper.getTopSafeArea(this);
}

