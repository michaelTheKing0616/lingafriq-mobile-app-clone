import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/pan_african_design_system.dart';

/// Beautiful Pan-African styled card
class PanAfricanCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final bool elevated;
  final bool selected;
  final Color? borderColor;
  final double? borderRadius;

  const PanAfricanCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.elevated = true,
    this.selected = false,
    this.borderColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final effectiveBorderRadius = borderRadius ?? PanAfricanRadius.lg;
    
    final decoration = BoxDecoration(
      color: gradient == null
          ? (backgroundColor ?? context.panCard)
          : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      border: Border.all(
        color: selected
            ? context.panPrimary
            : (borderColor ?? context.panBorder),
        width: selected ? 2 : 1,
      ),
      boxShadow: elevated ? PanAfricanShadows.sm : null,
    );

    final cardWidget = Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.all(PanAfricanSpacing.md),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}

/// Primary action button with Pan-African styling
class PanAfricanButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final bool isSmall;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const PanAfricanButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? context.panPrimary;
    final fgColor = foregroundColor ?? Colors.white;
    
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: bgColor,
            side: BorderSide(color: bgColor, width: 2),
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? PanAfricanSpacing.md : PanAfricanSpacing.lg,
              vertical: isSmall ? PanAfricanSpacing.sm : PanAfricanSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: PanAfricanRadius.roundBR,
            ),
          )
        : FilledButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? PanAfricanSpacing.md : PanAfricanSpacing.lg,
              vertical: isSmall ? PanAfricanSpacing.sm : PanAfricanSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: PanAfricanRadius.roundBR,
            ),
            elevation: 0,
          );

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(isOutlined ? bgColor : fgColor),
            ),
          )
        else if (icon != null)
          Icon(icon, size: isSmall ? 18.sp : 22.sp),
        if ((icon != null || isLoading) && label.isNotEmpty)
          SizedBox(width: PanAfricanSpacing.xs),
        if (label.isNotEmpty)
          Text(
            label,
            style: isSmall
                ? PanAfricanTypography.labelMedium(context, color: isOutlined ? bgColor : fgColor)
                : PanAfricanTypography.labelLarge(context, color: isOutlined ? bgColor : fgColor),
          ),
      ],
    );

    if (width != null) {
      child = SizedBox(
        width: width,
        child: child,
      );
    }

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}

/// Secondary/accent button
class PanAfricanSecondaryButton extends PanAfricanButton {
  const PanAfricanSecondaryButton({
    Key? key,
    required super.label,
    super.onPressed,
    super.icon,
    super.isLoading,
    super.isSmall,
    super.width,
  }) : super(
          key: key,
          backgroundColor: PanAfricanColors.secondary,
          foregroundColor: PanAfricanColors.neutralDarkest,
        );
}

/// Icon button with container
class PanAfricanIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final String? tooltip;

  const PanAfricanIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 44.w;
    final bgColor = backgroundColor ?? context.panPrimary.withOpacity(0.1);
    final fgColor = iconColor ?? context.panPrimary;

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: PanAfricanRadius.roundBR,
          child: Container(
            width: effectiveSize,
            height: effectiveSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: PanAfricanRadius.roundBR,
            ),
            child: Icon(icon, color: fgColor, size: effectiveSize * 0.5),
          ),
        ),
      ),
    );
  }
}

/// Progress indicator with Pan-African styling
class PanAfricanProgress extends StatelessWidget {
  final double value;
  final double? height;
  final Color? backgroundColor;
  final Color? valueColor;
  final bool showPercentage;

  const PanAfricanProgress({
    Key? key,
    required this.value,
    this.height,
    this.backgroundColor,
    this.valueColor,
    this.showPercentage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 8.h;
    final bgColor = backgroundColor ?? context.panBorder;
    final fgColor = valueColor ?? context.panPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPercentage)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(value * 100).toInt()}%',
                style: PanAfricanTypography.labelSmall(context),
              ),
            ],
          ),
        if (showPercentage) SizedBox(height: PanAfricanSpacing.xxs),
        ClipRRect(
          borderRadius: PanAfricanRadius.roundBR,
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: effectiveHeight,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation(fgColor),
          ),
        ),
      ],
    );
  }
}

/// Chip/Tag with Pan-African styling
class PanAfricanChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool selected;

  const PanAfricanChip({
    Key? key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? context.panPrimary
        : (backgroundColor ?? context.panPrimary.withOpacity(0.1));
    final fgColor = selected
        ? Colors.white
        : (textColor ?? context.panPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: PanAfricanRadius.roundBR,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.sm,
            vertical: PanAfricanSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: PanAfricanRadius.roundBR,
            border: Border.all(
              color: selected ? context.panPrimary : context.panBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fgColor, size: 16.sp),
                SizedBox(width: PanAfricanSpacing.xxs),
              ],
              Text(
                label,
                style: PanAfricanTypography.labelMedium(context, color: fgColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget
class PanAfricanEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const PanAfricanEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: context.panPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40.sp,
                color: context.panPrimary.withOpacity(0.5),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              title,
              style: PanAfricanTypography.titleLarge(context),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                subtitle!,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: context.panTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: PanAfricanSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Section header widget
class PanAfricanSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const PanAfricanSectionHeader({
    Key? key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: PanAfricanTypography.titleMedium(context),
          ),
          if (actionLabel != null || actionIcon != null)
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(
                actionIcon ?? Icons.chevron_right_rounded,
                size: 18.sp,
              ),
              label: Text(actionLabel ?? ''),
              style: TextButton.styleFrom(
                foregroundColor: context.panPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.xs,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Divider with optional label
class PanAfricanDivider extends StatelessWidget {
  final String? label;
  final double? height;
  final Color? color;

  const PanAfricanDivider({
    Key? key,
    this.label,
    this.height,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Divider(
        height: height ?? PanAfricanSpacing.lg,
        color: color ?? context.panBorder,
      );
    }

    return Row(
      children: [
        Expanded(child: Divider(color: color ?? context.panBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
          child: Text(
            label!,
            style: PanAfricanTypography.labelSmall(context),
          ),
        ),
        Expanded(child: Divider(color: color ?? context.panBorder)),
      ],
    );
  }
}

/// Badge with count
class PanAfricanBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;

  const PanAfricanBadge({
    Key? key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final effectiveSize = size ?? 20.w;
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: BoxConstraints(
        minWidth: effectiveSize,
        minHeight: effectiveSize,
      ),
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xxs),
      decoration: BoxDecoration(
        color: backgroundColor ?? PanAfricanColors.error,
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Center(
        child: Text(
          displayCount,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: effectiveSize * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

