import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Pan-African styled dialog with consistent design
/// 
/// Features:
/// - Rounded corners
/// - Optional icon header
/// - Gradient accent option
/// - Entrance animation
/// - Consistent button styling
class PanAfricanDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool isDestructive;
  final bool hasGradientHeader;

  const PanAfricanDialog({
    Key? key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.isDestructive = false,
    this.hasGradientHeader = false,
  }) : super(key: key);

  /// Shows a Pan-African styled dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    Color? iconColor,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool isDestructive = false,
    bool hasGradientHeader = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Theme.of(context).colorScheme.scrim.withOpacity(0.5),
      builder: (context) => PanAfricanDialog(
        title: title,
        message: message,
        content: content,
        icon: icon,
        iconColor: iconColor,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        isDestructive: isDestructive,
        hasGradientHeader: hasGradientHeader,
      ),
    );
  }

  /// Shows a confirmation dialog
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      title: title,
      message: message,
      icon: isDestructive ? Icons.warning_rounded : Icons.help_outline_rounded,
      iconColor: isDestructive ? PanAfricanColors.error : PanAfricanColors.primary,
      primaryButtonText: confirmText,
      secondaryButtonText: cancelText,
      isDestructive: isDestructive,
      onPrimaryPressed: () => Navigator.of(context).pop(true),
      onSecondaryPressed: () => Navigator.of(context).pop(false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(maxWidth: 340.w),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.xlBR,
          boxShadow: PanAfricanShadows.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            if (hasGradientHeader)
              _buildGradientHeader(context)
            else if (icon != null)
              _buildIconHeader(context, isDark),
            
            // Content
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasGradientHeader && icon == null)
                    Text(
                      title,
                      style: PanAfricanTypography.headlineSmall(
                        context,
                        color: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (message != null) ...[
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      message!,
                      style: PanAfricanTypography.bodyMedium(
                        context,
                        color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (content != null) ...[
                    SizedBox(height: PanAfricanSpacing.md),
                    content!,
                  ],
                  
                  // Buttons
                  if (primaryButtonText != null || secondaryButtonText != null) ...[
                    SizedBox(height: PanAfricanSpacing.lg),
                    _buildButtons(context, isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ).animate()
          .fadeIn(duration: 150.ms)
          .scale(begin: Offset(0.9, 0.9), end: Offset(1, 1), duration: 200.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.forest,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanAfricanRadius.xl),
        ),
      ),
      child: Column(
        children: [
          if (icon != null)
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 32.sp),
            ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            title,
            style: PanAfricanTypography.headlineSmall(context, color: Theme.of(context).colorScheme.onPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIconHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(top: PanAfricanSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: (iconColor ?? PanAfricanColors.primary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? PanAfricanColors.primary,
              size: 32.sp,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            title,
            style: PanAfricanTypography.headlineSmall(
              context,
              color: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        if (secondaryButtonText != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
                side: BorderSide(
                  color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                ),
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
              ),
              child: Text(secondaryButtonText!),
            ),
          ),
        if (secondaryButtonText != null && primaryButtonText != null)
          SizedBox(width: PanAfricanSpacing.sm),
        if (primaryButtonText != null)
          Expanded(
            child: ElevatedButton(
              onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? PanAfricanColors.error : PanAfricanColors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                elevation: 0,
              ),
              child: Text(primaryButtonText!),
            ),
          ),
      ],
    );
  }
}
