import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/pan_african_design_system.dart';

/// A clean, standardized error state widget with optional retry.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorState({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: PanAfricanColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 32.sp,
                color: PanAfricanColors.error,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              message,
              style: PanAfricanTypography.bodyLarge(
                context,
                color: isDark
                    ? PanAfricanColors.textSecondaryDark
                    : PanAfricanColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: PanAfricanSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry!();
                },
                icon: Icon(Icons.refresh_rounded, size: 18.sp),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PanAfricanColors.primary,
                  side: BorderSide(
                      color: PanAfricanColors.primary.withOpacity(0.3)),
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.lg,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: PanAfricanRadius.mdBR,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
