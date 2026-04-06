import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// A card following the Modern Griot tonal-layering system.
///
/// Uses [surfaceLevel] (0–4) to pick from the M3 surface-container hierarchy,
/// giving depth through color instead of elevation shadows. No visible borders.
/// Minimum xl (24) border radius per design rules.
///
/// ```dart
/// GriotCard(
///   surfaceLevel: 2,
///   onTap: () => _openDetails(),
///   child: Text('Lesson 1'),
/// )
/// ```
class GriotCard extends StatelessWidget {
  const GriotCard({
    super.key,
    required this.child,
    this.padding,
    this.surfaceLevel = 2,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Tonal surface level: 0 = lowest, 1 = low, 2 = container, 3 = high, 4 = highest.
  final int surfaceLevel;
  final VoidCallback? onTap;

  /// Defaults to [ModernGriotRadius.xl] (24).
  final double? borderRadius;

  Color _surfaceColor(ColorScheme cs) {
    switch (surfaceLevel) {
      case 0:
        return cs.surfaceContainerLowest;
      case 1:
        return cs.surfaceContainerLow;
      case 3:
        return cs.surfaceContainerHigh;
      case 4:
        return cs.surfaceContainerHighest;
      default:
        return cs.surfaceContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(
      (borderRadius ?? ModernGriotRadius.xl).r,
    );

    Widget content = Container(
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _surfaceColor(cs),
        borderRadius: radius,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap!();
          },
          borderRadius: radius,
          splashColor: cs.primary.withAlpha(20),
          highlightColor: cs.primary.withAlpha(10),
          child: content,
        ),
      );
    }

    return content;
  }
}
