import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/pan_african_design_system.dart';

/// A clean, modern empty state widget for list/grid screens.
/// Follows the Duolingo/Linear pattern: centered icon, title, subtitle, optional action.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double? iconSize;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDark ? PanAfricanColors.neutralLight : PanAfricanColors.neutralMedium;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.xl,
          vertical: PanAfricanSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize ?? 36.sp,
                color: iconColor,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              title,
              style: PanAfricanTypography.titleLarge(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              subtitle,
              style: PanAfricanTypography.bodyMedium(
                context,
                color: isDark
                    ? PanAfricanColors.textSecondaryDark
                    : PanAfricanColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: PanAfricanSpacing.lg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.xl,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: PanAfricanRadius.mdBR,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
