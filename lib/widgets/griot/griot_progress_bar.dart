import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Gradient progress bar using the signature primary → primaryContainer
/// gradient, with rounded ends and optional glowing tip.
///
/// ```dart
/// GriotProgressBar(
///   value: 0.65,
///   height: 8,
///   showGlowTip: true,
/// )
/// ```
class GriotProgressBar extends StatelessWidget {
  const GriotProgressBar({
    super.key,
    required this.value,
    this.height,
    this.showGlowTip = false,
    this.backgroundColor,
    this.animate = true,
  });

  /// Progress value from 0.0 to 1.0.
  final double value;

  /// Bar height in logical pixels. Defaults to 8.
  final double? height;

  /// Shows a glowing dot at the tip of the progress.
  final bool showGlowTip;

  /// Track background. Defaults to surfaceContainerHighest.
  final Color? backgroundColor;

  /// Whether to animate value changes.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final barHeight = (height ?? 8).h;
    final clampedValue = value.clamp(0.0, 1.0);

    return SizedBox(
      height: showGlowTip ? barHeight + 8.h : barHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * clampedValue;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Track
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: backgroundColor ?? cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(barHeight / 2),
                ),
              ),
              // Fill
              AnimatedContainer(
                duration:
                    animate ? const Duration(milliseconds: 400) : Duration.zero,
                curve: Curves.easeInOut,
                width: fillWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: ModernGriotGradients.signatureGradient,
                  borderRadius: BorderRadius.circular(barHeight / 2),
                ),
              ),
              // Glow tip
              if (showGlowTip && clampedValue > 0.02)
                AnimatedPositioned(
                  duration: animate
                      ? const Duration(milliseconds: 400)
                      : Duration.zero,
                  curve: Curves.easeInOut,
                  left: fillWidth - (barHeight / 2 + 4.r),
                  top: -(4.h),
                  child: Container(
                    width: barHeight + 8.r,
                    height: barHeight + 8.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withAlpha(77),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
