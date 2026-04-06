import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Glassmorphic overlay panel: surface at 80% opacity + 24px backdrop blur.
///
/// Used for floating overlays, bottom nav, modals, and any surface that
/// needs translucent depth. Respects light/dark mode via [ColorScheme].
///
/// ```dart
/// GriotGlassPanel(
///   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
///   child: BottomNavContent(),
/// )
/// ```
class GriotGlassPanel extends StatelessWidget {
  const GriotGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blurSigma = 24.0,
    this.opacity = 0.80,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Backdrop blur sigma. Defaults to 24.
  final double blurSigma;

  /// Surface opacity. Defaults to 0.80 (80%).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveRadius =
        borderRadius ?? ModernGriotRadius.borderXl;
    final alphaValue = (opacity * 255).round();

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          padding: padding ?? EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: cs.surface.withAlpha(alphaValue),
            borderRadius: effectiveRadius,
            border: Border.all(
              color: cs.outlineVariant.withAlpha(25),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
