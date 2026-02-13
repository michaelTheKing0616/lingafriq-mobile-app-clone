// Enhanced Material 3 Card
// Card with animations, haptic feedback, and proper elevation

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/haptic_feedback_helper.dart';
class EnhancedCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool animate;
  final int animationDelay;
  final BorderRadius? borderRadius;

  const EnhancedCard({
    Key? key,
    required this.child,
    this.color,
    this.elevation,
    this.margin,
    this.padding,
    this.onTap,
    this.animate = true,
    this.animationDelay = 0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget card = Card(
      color: color ?? (isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface),
      elevation: elevation ?? (isDark ? 2 : 4),
      margin: margin ?? const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticHelper.lightImpact();
                onTap!();
              }
            : null,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (animate) {
      return card.animate(delay: animationDelay.ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
    }

    return card;
  }
}

