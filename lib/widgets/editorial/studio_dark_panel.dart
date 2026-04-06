import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dark inverse-surface panel for studio and processing modes.
///
/// Uses the theme's [ColorScheme.inverseSurface] as background with
/// [ColorScheme.onInverseSurface] text color, creating a high-contrast
/// dark panel suitable for audio studios, processing dashboards,
/// and recording interfaces.
class StudioDarkPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const StudioDarkPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = borderRadius ?? 16.r;

    return Container(
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.onInverseSurface),
        child: IconTheme.merge(
          data: IconThemeData(color: colors.onInverseSurface),
          child: child,
        ),
      ),
    );
  }
}
