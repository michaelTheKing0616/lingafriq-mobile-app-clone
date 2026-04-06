import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Stat display card: icon + large value + label.
///
/// Uses surfaceContainerLow background with xl radius. Intended for game
/// results, profile stats, dashboard metrics, etc.
///
/// ```dart
/// GriotStatCard(
///   icon: Icons.local_fire_department_rounded,
///   value: '12',
///   label: 'Day Streak',
/// )
/// ```
class GriotStatCard extends StatelessWidget {
  const GriotStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? cs.primary;

    Widget card = Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: effectiveIconColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20.sp, color: effectiveIconColor),
            ),
            SizedBox(height: 8.h),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
