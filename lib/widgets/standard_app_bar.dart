import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standardized Material 3 AppBar for consistent navigation across the app
/// Ensures all screens have proper back buttons, titles, and actions
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showDrawerButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final double? elevation;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  const StandardAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.showDrawerButton = false,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.elevation,
    this.onBackPressed,
    this.bottom,
    this.centerTitle = true,
  }) : assert(title != null || titleWidget != null || !showBackButton,
          'Title or titleWidget must be provided if showBackButton is true'),
      super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? 
        (gradient != null ? Colors.transparent : 
         (isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceLight));
    final fgColor = foregroundColor ?? 
        (gradient != null ? Colors.white : 
         (isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight));

    final effectiveActions = <Widget>[
      // World-class navigation: if both back + menu are requested, show back as leading
      // and menu as an action so users always have drawer access.
      if (showDrawerButton && showBackButton)
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            color: fgColor,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ...?actions,
    ];

    final appBar = AppBar(
      backgroundColor: gradient != null ? Colors.transparent : bgColor,
      foregroundColor: fgColor,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      leading: _buildLeading(context, fgColor),
      title: titleWidget ?? (title != null 
          ? Text(
              title!,
              style: PanAfricanTypography.titleLarge(context, color: fgColor),
            ) 
          : null),
      actions: effectiveActions.isEmpty ? null : [
        ...effectiveActions,
        SizedBox(width: PanAfricanSpacing.xs),
      ],
      bottom: bottom,
      flexibleSpace: gradient != null
          ? Container(
              decoration: BoxDecoration(
                gradient: gradient,
              ),
            )
          : null,
    );

    return appBar;
  }

  Widget? _buildLeading(BuildContext context, Color iconColor) {
    if (showBackButton) {
      return IconButton(
        icon: Icon(PanAfricanIcons.back, size: 24.sp),
        color: iconColor,
        padding: EdgeInsets.all(PanAfricanSpacing.sm),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
        tooltip: 'Back',
      );
    } else if (showDrawerButton) {
      return IconButton(
        icon: Icon(PanAfricanIcons.menu, size: 24.sp),
        color: iconColor,
        padding: EdgeInsets.all(PanAfricanSpacing.sm),
        onPressed: () {
          HapticFeedback.lightImpact();
          Scaffold.of(context).openDrawer();
        },
        tooltip: 'Menu',
      );
    }
    return null;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Gradient AppBar variant for screens with gradient headers
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showDrawerButton;
  final Gradient gradient;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.showDrawerButton = false,
    required this.gradient,
    this.onBackPressed,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StandardAppBar(
      title: title,
      titleWidget: titleWidget,
      actions: actions,
      showBackButton: showBackButton,
      showDrawerButton: showDrawerButton,
      gradient: gradient,
      foregroundColor: Colors.white,
      onBackPressed: onBackPressed,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Standardized header widget for screens with gradient backgrounds
/// Used in place of AppBar for full-screen gradient headers
class StandardGradientHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showDrawerButton;
  final Gradient gradient;
  final double height;
  final VoidCallback? onBackPressed;

  const StandardGradientHeader({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.showDrawerButton = false,
    required this.gradient,
    this.height = 200,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(PanAfricanRadius.xxl),
          bottomRight: Radius.circular(PanAfricanRadius.xxl),
        ),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: ResponsiveSafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: Icon(PanAfricanIcons.back, color: Colors.white, size: 24.sp),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (onBackPressed != null) {
                          onBackPressed!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.all(PanAfricanSpacing.sm),
                      ),
                    )
                  else if (showDrawerButton)
                    IconButton(
                      icon: Icon(PanAfricanIcons.menu, color: Colors.white, size: 24.sp),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Scaffold.of(context).openDrawer();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.all(PanAfricanSpacing.sm),
                      ),
                    )
                  else
                    SizedBox(width: 48.w),
                  if (title != null || titleWidget != null)
                    Expanded(
                      child: titleWidget ??
                          Text(
                            title!,
                            style: PanAfricanTypography.headlineSmall(context, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                    )
                  else
                    const Spacer(),
                  if ((actions != null && actions!.isNotEmpty) || (showDrawerButton && showBackButton))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...?actions,
                        if (showDrawerButton && showBackButton)
                          IconButton(
                            icon: Icon(PanAfricanIcons.menu, color: Colors.white, size: 24.sp),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Scaffold.of(context).openDrawer();
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              shape: const CircleBorder(),
                              padding: EdgeInsets.all(PanAfricanSpacing.sm),
                            ),
                          ),
                      ],
                    )
                  else
                    SizedBox(width: 48.w),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

