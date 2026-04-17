import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Pan-African Design System Components
/// Reusable, culturally-inspired UI components

// ═══════════════════════════════════════════════════════════════════════════
// BUTTONS
// ═══════════════════════════════════════════════════════════════════════════

/// Primary Action Button with Pan-African styling - World-Class Design
class PanAfricanButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool hasGradient;
  final List<Color>? gradientColors;
  final double? width;
  final double? height;

  const PanAfricanButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.hasGradient = false,
    this.gradientColors,
    this.width,
    this.height,
  });

  @override
  State<PanAfricanButton> createState() => _PanAfricanButtonState();
}

class _PanAfricanButtonState extends State<PanAfricanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  // ignore: unused_field
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? PanAfricanColors.primary;
    final fgColor = widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary;

    Widget button;

    if (widget.isOutlined) {
      button = OutlinedButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        icon: widget.isLoading
            ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : widget.icon != null
                ? Icon(widget.icon, size: 20.sp)
                : SizedBox.shrink(),
        label: Text(
          widget.label,
          style: PanAfricanTypography.labelLarge(context),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: bgColor,
          side: BorderSide(color: bgColor, width: 2),
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg,
            vertical: widget.height ?? PanAfricanSpacing.md,
          ),
          minimumSize: widget.width != null
              ? Size(widget.width!, widget.height ?? PanAfricanSpacing.md * 2)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          ),
        ),
      );
    } else if (widget.hasGradient) {
      final subtleGradient = [
        bgColor,
        Color.lerp(bgColor, Theme.of(context).colorScheme.onPrimary, 0.08) ?? bgColor,
      ];
      button = Container(
        width: widget.width,
        height: widget.height ?? 48.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: subtleGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          boxShadow: PanAfricanShadows.sm,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.lg,
                vertical: PanAfricanSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                      ),
                    )
                  else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20.sp, color: fgColor),
                    SizedBox(width: PanAfricanSpacing.sm),
                  ],
                  Text(
                    widget.label,
                    style: PanAfricanTypography.labelLarge(context)
                        .copyWith(color: fgColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      button = ElevatedButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        icon: widget.isLoading
            ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : widget.icon != null
                ? Icon(widget.icon, size: 20.sp)
                : SizedBox.shrink(),
        label: Text(
          widget.label,
          style: PanAfricanTypography.labelLarge(context),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg,
            vertical: widget.height ?? PanAfricanSpacing.md,
          ),
          minimumSize: widget.width != null
              ? Size(widget.width!, widget.height ?? PanAfricanSpacing.md * 2)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          ),
          elevation: 2,
          shadowColor: bgColor.withOpacity(0.3),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: button,
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: Offset(0.95, 0.95), end: Offset(1, 1));
  }
}

/// Secondary Button with Gold accent
class PanAfricanSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PanAfricanSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PanAfricanButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: PanAfricanColors.secondary,
      foregroundColor: PanAfricanColors.neutralDarkest,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARDS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Card with gradient border option - World-Class Design
class PanAfricanCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool hasGradientBorder;
  final Color? gradientStart;
  final Color? gradientEnd;
  final bool hasHoverEffect;
  final bool hasGlow;
  final Color? glowColor;
  final double? elevation;
  final Color? backgroundColor;

  const PanAfricanCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.hasGradientBorder = false,
    this.gradientStart,
    this.gradientEnd,
    this.hasHoverEffect = false,
    this.hasGlow = false,
    this.glowColor,
    this.elevation,
    this.backgroundColor,
  });

  @override
  State<PanAfricanCard> createState() => _PanAfricanCardState();
}

class _PanAfricanCardState extends State<PanAfricanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  // ignore: unused_field
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        widget.backgroundColor ?? (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight);

    Widget card = Container(
      margin: widget.margin ?? EdgeInsets.zero,
      padding: widget.padding ?? EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: widget.hasGlow
            ? PanAfricanShadows.glowGreen(_glowAnimation.value)
            : (widget.elevation != null
                ? PanAfricanShadows.md
                : PanAfricanShadows.sm),
        border: widget.hasGradientBorder
            ? Border.all(
                width: 2,
                color: Colors.transparent,
              )
            : null,
      ),
      child: widget.child,
    );

    if (widget.hasGradientBorder) {
      card = Container(
        margin: widget.margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.gradientStart ?? PanAfricanColors.primary,
              widget.gradientEnd ?? PanAfricanColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        ),
        padding: EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg - 2),
          ),
          padding: widget.padding ?? EdgeInsets.all(PanAfricanSpacing.lg),
          child: widget.child,
        ),
      );
    }

    if (widget.onTap != null || widget.hasHoverEffect) {
      return GestureDetector(
        onTapDown: widget.hasHoverEffect
            ? (_) {
                setState(() => _isHovered = true);
                _controller.forward();
              }
            : null,
        onTapUp: widget.hasHoverEffect
            ? (_) {
                setState(() => _isHovered = false);
                _controller.reverse();
              }
            : null,
        onTapCancel: widget.hasHoverEffect
            ? () {
                setState(() => _isHovered = false);
                _controller.reverse();
              }
            : null,
        child: ScaleTransition(
          scale: widget.hasHoverEffect ? _scaleAnimation : AlwaysStoppedAnimation(1.0),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            child: card,
          ),
        ),
      );
    }

    return card
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: Offset(0.95, 0.95), end: Offset(1, 1));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODALS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Bottom Sheet with consistent styling
class PanAfricanBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets? padding;

  const PanAfricanBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? subtitle,
    required Widget child,
    List<Widget>? actions,
    EdgeInsets? padding,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: PanAfricanBottomSheet(
            title: title,
            subtitle: subtitle,
            actions: actions,
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight;
    final textPrimary =
        isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight;
    final textSecondary =
        isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanAfricanRadius.xl),
        ),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: PanAfricanSpacing.xl * 2,
              height: PanAfricanSpacing.xxs,
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
              ),
            ),
            if (title != null) ...[
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                title!,
                style: PanAfricanTypography.titleLarge(context).copyWith(
                  color: textPrimary,
                ),
              ),
            ],
            if (subtitle != null) ...[
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                subtitle!,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: PanAfricanSpacing.lg),
            child,
            if (actions != null && actions!.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.lg),
              Row(
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pan-African Dialog with consistent styling
class PanAfricanDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  const PanAfricanDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
    required List<Widget> actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return PanAfricanDialog(
          title: title,
          subtitle: subtitle,
          actions: actions,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight;
    final textPrimary =
        isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight;
    final textSecondary =
        isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      backgroundColor: surfaceColor,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: PanAfricanTypography.titleLarge(context).copyWith(
                color: textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                subtitle!,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: textSecondary,
                ),
              ),
            ],
            SizedBox(height: PanAfricanSpacing.md),
            child,
            SizedBox(height: PanAfricanSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NAVIGATION
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Tab Bar with pill indicator styling
class PanAfricanTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Tab> tabs;
  final bool isScrollable;

  const PanAfricanTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight;
    final textColor =
        isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.xs),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        labelColor: textColor,
        unselectedLabelColor: textColor.withOpacity(0.6),
        indicator: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: BorderRadius.circular(PanAfricanRadius.pill),
          boxShadow: PanAfricanShadows.sm,
        ),
        labelStyle: PanAfricanTypography.labelLarge(context),
        tabs: tabs,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(PanAfricanSpacing.xl * 2);
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African List Tile with consistent spacing and typography
class PanAfricanListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const PanAfricanListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight;
    final textSecondary =
        isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      child: Padding(
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.sm,
            ),
        child: Row(
          crossAxisAlignment:
              subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: PanAfricanSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      subtitle!,
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: PanAfricanSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AVATARS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Avatar with badge support
class PanAfricanAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double? size;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showBadge;
  final Color? badgeColor;
  final Widget? badge;

  const PanAfricanAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size,
    this.backgroundColor,
    this.borderColor,
    this.showBadge = false,
    this.badgeColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedSize = size ?? PanAfricanSpacing.xl * 2;
    final avatarBg = backgroundColor ??
        (isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight);
    final avatarBorder =
        borderColor ?? (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight);
    final badgeSize = PanAfricanSpacing.sm + PanAfricanSpacing.xxs;

    return Stack(
      children: [
        Container(
          width: resolvedSize,
          height: resolvedSize,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
            border: Border.all(color: avatarBorder, width: 1),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null && initials != null
              ? Center(
                  child: Text(
                    initials!,
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      color: isDark
                          ? PanAfricanColors.textPrimaryDark
                          : PanAfricanColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        if (showBadge || badge != null)
          Positioned(
            right: PanAfricanSpacing.xxs,
            bottom: PanAfricanSpacing.xxs,
            child: badge ??
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: badgeColor ?? PanAfricanColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      width: 2,
                    ),
                  ),
                ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATES
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Skeleton with shimmer animation
class PanAfricanSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final bool isCircle;
  final BorderRadius? borderRadius;

  const PanAfricanSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.isCircle = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? PanAfricanColors.surfaceContainerHighDark
        : PanAfricanColors.surfaceContainerHighLight;
    final highlightColor = isDark
        ? PanAfricanColors.surfaceContainerDark
        : PanAfricanColors.surfaceContainerLight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle
              ? null
              : borderRadius ?? BorderRadius.circular(PanAfricanRadius.sm),
        ),
      ),
    );
  }
}

/// Pan-African Empty State
class PanAfricanEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool hasGlow;

  const PanAfricanEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? PanAfricanColors.primaryLight : PanAfricanColors.primary;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: PanAfricanCard(
          hasGlow: hasGlow,
          glowColor: iconColor,
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56.sp, color: iconColor),
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                title,
                style: PanAfricanTypography.titleLarge(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                description,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: isDark
                      ? PanAfricanColors.textSecondaryDark
                      : PanAfricanColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: PanAfricanSpacing.md),
                PanAfricanButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pan-African Error State
class PanAfricanErrorState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;

  const PanAfricanErrorState({
    super.key,
    required this.title,
    required this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return PanAfricanEmptyState(
      icon: PanAfricanIcons.error,
      title: title,
      description: description,
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}

/// Pan-African Loading State
class PanAfricanLoadingState extends StatelessWidget {
  final String message;

  const PanAfricanLoadingState({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? PanAfricanColors.secondary : PanAfricanColors.primary,
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            message,
            style: PanAfricanTypography.bodyMedium(context),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INTERACTIVE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Scale on tap widget - provides scale animation on tap
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INPUTS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Text Field
class PanAfricanTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? errorText;
  final String? helperText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PanAfricanTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.errorText,
    this.helperText,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: PanAfricanTypography.bodyLarge(context),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixTap,
              )
            : null,
        errorText: errorText,
        helperText: helperText,
        filled: true,
        fillColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          borderSide: BorderSide(
            color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          borderSide: BorderSide(
            color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          borderSide: BorderSide(
            color: PanAfricanColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          borderSide: BorderSide(
            color: PanAfricanColors.error,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHIPS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Filter Chip
class PanAfricanChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;
  final Color? backgroundColor;

  const PanAfricanChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16.sp),
            SizedBox(width: PanAfricanSpacing.xs),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected != null ? (_) => onSelected!() : null,
      selectedColor: backgroundColor ?? PanAfricanColors.primaryContainer,
      checkmarkColor: PanAfricanColors.primary,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? PanAfricanColors.surfaceContainerDark
          : PanAfricanColors.surfaceContainerLight,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BADGES
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Badge
class PanAfricanBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const PanAfricanBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? PanAfricanColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: badgeColor),
            SizedBox(width: PanAfricanSpacing.xxs),
          ],
          Text(
            label,
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROGRESS INDICATORS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Progress Bar
class PanAfricanProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final double? height;

  const PanAfricanProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = color ?? PanAfricanColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: height ?? 8.h,
        backgroundColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Divider with optional gradient
class PanAfricanDivider extends StatelessWidget {
  final bool hasGradient;
  final double? thickness;

  const PanAfricanDivider({
    super.key,
    this.hasGradient = false,
    this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (hasGradient) {
      return Container(
        height: thickness ?? 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              PanAfricanColors.primary,
              Colors.transparent,
            ],
          ),
        ),
      );
    }

    return Divider(
      thickness: thickness,
      color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ICONS
// ═══════════════════════════════════════════════════════════════════════════

/// Pan-African Icon Set
class PanAfricanIcons {
  PanAfricanIcons._();

  // Learning
  static const IconData book = Icons.menu_book;
  static const IconData lesson = Icons.school;
  static const IconData quiz = Icons.quiz;
  static const IconData story = Icons.auto_stories;
  static const IconData vocabulary = Icons.translate;

  // Gamification
  static const IconData badge = Icons.workspace_premium;
  static const IconData trophy = Icons.emoji_events;
  static const IconData star = Icons.star;
  static const IconData coin = Icons.monetization_on;

  // Social
  static const IconData community = Icons.people;
  static const IconData tribe = Icons.group;
  static const IconData chat = Icons.chat;
  static const IconData share = Icons.share;

  // Cultural
  static const IconData culture = Icons.public;
  static const IconData magazine = Icons.article;
  static const IconData music = Icons.music_note;
  static const IconData festival = Icons.celebration;

  // Navigation
  static const IconData home = Icons.home;
  static const IconData profile = Icons.person;
  static const IconData settings = Icons.settings;
  static const IconData dashboard = Icons.dashboard;

  // Actions
  static const IconData play = Icons.play_circle;
  static const IconData pause = Icons.pause_circle;
  static const IconData check = Icons.check_circle;
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData error = Icons.error_outline;
}
