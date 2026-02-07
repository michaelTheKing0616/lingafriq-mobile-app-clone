import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Pan-African styled bottom sheet with consistent design
/// 
/// Features:
/// - Rounded top corners with drag handle
/// - Gradient header option
/// - Entrance animation
/// - Consistent spacing and typography
class PanAfricanBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showDragHandle;
  final bool hasGradientHeader;
  final VoidCallback? onClose;
  final double? maxHeight;
  final EdgeInsets? padding;

  const PanAfricanBottomSheet({
    Key? key,
    required this.child,
    this.title,
    this.subtitle,
    this.showDragHandle = true,
    this.hasGradientHeader = false,
    this.onClose,
    this.maxHeight,
    this.padding,
  }) : super(key: key);

  /// Shows a Pan-African styled bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    bool showDragHandle = true,
    bool hasGradientHeader = false,
    VoidCallback? onClose,
    double? maxHeight,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => PanAfricanBottomSheet(
        title: title,
        subtitle: subtitle,
        showDragHandle: showDragHandle,
        hasGradientHeader: hasGradientHeader,
        onClose: onClose,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanAfricanRadius.xl),
        ),
        boxShadow: PanAfricanShadows.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          if (showDragHandle)
            Container(
              margin: EdgeInsets.only(top: PanAfricanSpacing.sm),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.neutralLight.withOpacity(0.3)
                    : PanAfricanColors.neutralMedium.withOpacity(0.3),
                borderRadius: PanAfricanRadius.roundBR,
              ),
            ),
          
          // Header
          if (title != null || onClose != null)
            _buildHeader(context, isDark),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: padding ?? EdgeInsets.all(PanAfricanSpacing.lg),
              child: child,
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.1, end: 0, duration: 250.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.lg,
        vertical: PanAfricanSpacing.md,
      ),
      decoration: hasGradientHeader
          ? BoxDecoration(
              gradient: PanAfricanGradients.forest,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(PanAfricanRadius.xl),
              ),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: PanAfricanTypography.headlineSmall(
                      context,
                      color: hasGradientHeader
                          ? Colors.white
                          : (isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight),
                    ),
                  ),
                if (subtitle != null) ...[
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    subtitle!,
                    style: PanAfricanTypography.bodySmall(
                      context,
                      color: hasGradientHeader
                          ? Colors.white.withOpacity(0.8)
                          : (isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close_rounded,
                color: hasGradientHeader
                    ? Colors.white
                    : (isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
              ),
            ),
        ],
      ),
    );
  }
}
