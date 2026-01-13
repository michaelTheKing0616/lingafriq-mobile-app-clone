import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/design_system.dart';

/// Modern animated card with Material 3 design
class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;
  final int delayMs;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.elevation,
    this.delayMs = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 400.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: delayMs),
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          delay: Duration(milliseconds: delayMs),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}

