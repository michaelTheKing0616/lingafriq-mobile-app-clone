import 'package:flutter/material.dart';
import 'package:lingafriq/utils/design_system.dart';
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
  }) : assert(title != null || titleWidget != null || !showBackButton,
          'Title or titleWidget must be provided if showBackButton is true'),
      super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? 
        (gradient != null ? Colors.transparent : 
         (isDark ? const Color(0xFF1F3527) : Colors.white));
    final fgColor = foregroundColor ?? 
        (gradient != null ? Colors.white : 
         (isDark ? Colors.white : Colors.black87));

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
      leading: _buildLeading(context, fgColor),
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: effectiveActions.isEmpty ? null : effectiveActions,
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
        icon: const Icon(Icons.arrow_back),
        color: iconColor,
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
      );
    } else if (showDrawerButton) {
      return IconButton(
        icon: const Icon(Icons.menu),
        color: iconColor,
        onPressed: () {
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ResponsiveSafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    )
                  else if (showDrawerButton)
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  if (title != null || titleWidget != null)
                    Expanded(
                      child: titleWidget ??
                          Text(
                            title!,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: const CircleBorder(),
                            ),
                          ),
                      ],
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

