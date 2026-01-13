import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../utils/pan_african_design_system.dart';
import '../screens/tabs_view/tabs_view.dart';

/// A beautiful, Material 3 compliant app bar with Pan-African styling
/// 
/// Features:
/// - Gradient background option
/// - Integrated drawer menu button
/// - XP/Level display option
/// - Beautiful animations
class PanAfricanAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showMenuButton;
  final bool showBackButton;
  final bool useGradient;
  final bool centerTitle;
  final VoidCallback? onBackPressed;
  final double? elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;
  final bool automaticallyImplyLeading;

  const PanAfricanAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showMenuButton = false,
    this.showBackButton = true,
    this.useGradient = false,
    this.centerTitle = false,
    this.onBackPressed,
    this.elevation,
    this.backgroundColor,
    this.bottom,
    this.flexibleSpace,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0) + (subtitle != null ? 24.h : 0),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldKey = ref.watch(scaffoldKeyProvider);
    
    // Determine text/icon color based on background
    final foregroundColor = useGradient || isDark ? Colors.white : PanAfricanColors.textPrimaryLight;
    
    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      if (showMenuButton) {
        leadingWidget = _MenuButton(scaffoldKey: scaffoldKey, color: foregroundColor);
      } else if (showBackButton && Navigator.of(context).canPop()) {
        leadingWidget = _BackButton(
          color: foregroundColor,
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        );
      }
    }

    final titleWidget = Column(
      crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: PanAfricanTypography.titleLarge(context, color: foregroundColor),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: PanAfricanTypography.bodySmall(context, color: foregroundColor.withOpacity(0.8)),
          ),
      ],
    );

    return AppBar(
      systemOverlayStyle: isDark || useGradient
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      backgroundColor: useGradient ? Colors.transparent : (backgroundColor ?? Theme.of(context).colorScheme.surface),
      elevation: elevation ?? (useGradient ? 0 : 1),
      scrolledUnderElevation: useGradient ? 0 : 2,
      surfaceTintColor: Colors.transparent,
      leading: leadingWidget,
      title: titleWidget,
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
      flexibleSpace: useGradient
          ? Container(
              decoration: BoxDecoration(
                gradient: context.panHeaderGradient,
              ),
              child: flexibleSpace,
            )
          : flexibleSpace,
      iconTheme: IconThemeData(color: foregroundColor),
      actionsIconTheme: IconThemeData(color: foregroundColor),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Color color;

  const _MenuButton({required this.scaffoldKey, required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.menu_rounded, color: color),
      onPressed: () => scaffoldKey.currentState?.openDrawer(),
      tooltip: 'Menu',
    );
  }
}

class _BackButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const _BackButton({required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: color),
      onPressed: onPressed,
      tooltip: 'Back',
    );
  }
}

/// A gradient header widget for screens that need a large header area
class PanAfricanHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double? height;
  final bool showPattern;
  final Widget? bottomWidget;

  const PanAfricanHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.height,
    this.showPattern = true,
    this.bottomWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + PanAfricanSpacing.md,
        left: PanAfricanSpacing.lg,
        right: PanAfricanSpacing.lg,
        bottom: PanAfricanSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: context.panHeaderGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(PanAfricanRadius.xxl),
        ),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Stack(
        children: [
          // Background pattern
          if (showPattern)
            Positioned.fill(
              child: CustomPaint(
                painter: _AfricanPatternPainter(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: PanAfricanTypography.headlineLarge(
                            context,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: PanAfricanSpacing.xs),
                          Text(
                            subtitle!,
                            style: PanAfricanTypography.bodyMedium(
                              context,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (bottomWidget != null) ...[
                SizedBox(height: PanAfricanSpacing.md),
                bottomWidget!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AfricanPatternPainter extends CustomPainter {
  final Color color;

  _AfricanPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spacing = 40.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        // Draw diamond pattern
        final path = Path()
          ..moveTo(x, y + spacing / 2)
          ..lineTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

