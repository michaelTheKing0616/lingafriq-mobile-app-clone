import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Best-in-class LingAfriq UI helpers: SnackBars, empty states, and feedback.
/// Use these app-wide for consistent branding and UX.

// ═══════════════════════════════════════════════════════════════════════════
// SNACKBARS / TOAST
// ═══════════════════════════════════════════════════════════════════════════

void showLingAfriqSuccess(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
  if (!context.mounted) return;
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14.sp)),
      backgroundColor: PanAfricanColors.success,
      behavior: SnackBarBehavior.floating,
      action: (onAction != null && actionLabel != null)
          ? SnackBarAction(label: actionLabel, textColor: Theme.of(context).colorScheme.onPrimary, onPressed: onAction)
          : null,
    ),
  );
}

void showLingAfriqError(BuildContext context, String message, {VoidCallback? onRetry}) {
  if (!context.mounted) return;
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14.sp)),
      backgroundColor: PanAfricanColors.error,
      behavior: SnackBarBehavior.floating,
      action: onRetry != null
          ? SnackBarAction(label: 'Try again', textColor: Theme.of(context).colorScheme.onPrimary, onPressed: onRetry)
          : null,
    ),
  );
}

void showLingAfriqInfo(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14.sp)),
      backgroundColor: PanAfricanColors.info,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class LingAfriqEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LingAfriqEmptyState({
    Key? key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : PanAfricanColors.textSecondary;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72.sp, color: textColor.withValues(alpha: 0.6)),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.titleMedium(context).copyWith(color: textColor),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: PanAfricanTypography.bodyMedium(context).copyWith(color: textColor.withValues(alpha: 0.8)),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: PanAfricanSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add, size: 20.sp),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg, vertical: PanAfricanSpacing.md),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RETRY BLOCK (error state with retry button)
// ═══════════════════════════════════════════════════════════════════════════

class LingAfriqRetryBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LingAfriqRetryBlock({Key? key, required this.message, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LingAfriqEmptyState(
      icon: Icons.cloud_off,
      title: message,
      subtitle: 'Check your connection and try again.',
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}
