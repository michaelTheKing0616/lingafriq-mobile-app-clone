import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Cultural insight / tip card with icon, headline, and body text.
///
/// Uses surfaceContainerLow background with xl radius. Designed for in-game
/// contextual tips like "Griot's Note", "Elder's Advice", cultural facts, etc.
///
/// ```dart
/// GriotInsightCard(
///   icon: Icons.auto_stories_rounded,
///   headline: "Griot's Note",
///   body: 'In Yoruba, greetings change by time of day...',
/// )
/// ```
class GriotInsightCard extends StatelessWidget {
  const GriotInsightCard({
    super.key,
    required this.headline,
    required this.body,
    this.icon,
    this.iconColor,
    this.action,
  });

  final String headline;
  final String body;
  final IconData? icon;
  final Color? iconColor;

  /// Optional trailing action widget (e.g. a dismiss button).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveIcon = icon ?? Icons.auto_stories_rounded;
    final effectiveIconColor = iconColor ?? cs.primary;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: effectiveIconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              effectiveIcon,
              size: 20.sp,
              color: effectiveIconColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            SizedBox(width: 8.w),
            action!,
          ],
        ],
      ),
    );
  }
}
