import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'pan_african_design_system.dart';
import 'polie_design_tokens.dart';

/// LingAfriq UI Consistency System
/// 
/// Provides standardized UI components and patterns for consistent,
/// world-class design across all screens.
/// 
/// Usage:
/// - Use [LingAfriqScaffold] for consistent screen structure
/// - Use [LingAfriqAppBar] for consistent app bars
/// - Use [LingAfriqCard] for consistent cards
/// - Use [LingAfriqButton] for consistent buttons
/// - Use [LingAfriqTextField] for consistent inputs
/// - Use [UISpacing] widget helpers for consistent spacing

// ═══════════════════════════════════════════════════════════════════════════
// STANDARDIZED SCREEN SCAFFOLD
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent screen scaffold with proper safe areas and backgrounds
class LingAfriqScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool useGradientBackground;
  final bool useDarkBackground;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  const LingAfriqScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.useGradientBackground = false,
    this.useDarkBackground = false,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget content = body;
    
    // Apply gradient background if requested
    if (useGradientBackground || useDarkBackground) {
      content = Container(
        decoration: BoxDecoration(
          gradient: useDarkBackground
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PolieColors.primary,
                    PolieColors.primaryDark,
                    PolieColors.obsidian,
                  ],
                )
              : isDark
                  ? PanAfricanGradients.darkSurface
                  : PanAfricanGradients.forest,
        ),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? 
          (useGradientBackground || useDarkBackground 
              ? Colors.transparent 
              : isDark 
                  ? PanAfricanColors.surfaceDark 
                  : PanAfricanColors.surfaceLight),
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STANDARDIZED APP BAR
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent app bar with proper back button, title styling, and actions
class LingAfriqAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final bool transparent;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const LingAfriqAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.centerTitle = true,
    this.transparent = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();
    
    final effectiveForegroundColor = foregroundColor ?? 
        (transparent || isDark ? Colors.white : PanAfricanColors.textPrimary);
    
    return AppBar(
      backgroundColor: transparent 
          ? Colors.transparent 
          : backgroundColor ?? (isDark 
              ? PanAfricanColors.surfaceContainerDark 
              : PanAfricanColors.surfaceLight),
      foregroundColor: effectiveForegroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leading ?? (showBackButton && canPop
          ? LingAfriqBackButton(
              onPressed: onBackPressed,
              color: effectiveForegroundColor,
            )
          : null),
      title: titleWidget ?? (title != null
          ? Text(
              title!,
              style: PanAfricanTypography.titleLarge(context, color: effectiveForegroundColor),
            )
          : null),
      actions: actions != null
          ? [
              ...actions!,
              SizedBox(width: PanAfricanSpacing.sm),
            ]
          : null,
      bottom: bottom,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STANDARDIZED BACK BUTTON
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent back button with haptic feedback
class LingAfriqBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final EdgeInsetsGeometry? padding;

  const LingAfriqBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        PanAfricanIcons.back,
        color: color,
        size: size ?? 24.sp,
      ),
      padding: padding ?? EdgeInsets.all(PanAfricanSpacing.sm),
      onPressed: () {
        HapticFeedback.lightImpact();
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      tooltip: 'Back',
    );
  }
}

/// Consistent close button with haptic feedback
class LingAfriqCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  const LingAfriqCloseButton({
    super.key,
    this.onPressed,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        PanAfricanIcons.close,
        color: color,
        size: size ?? 24.sp,
      ),
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      onPressed: () {
        HapticFeedback.lightImpact();
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      tooltip: 'Close',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STANDARDIZED CARDS
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent card with proper styling
class LingAfriqCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadow;
  final Border? border;
  final VoidCallback? onTap;
  final bool elevated;

  const LingAfriqCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.shadow,
    this.border,
    this.onTap,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
        borderRadius: borderRadius ?? PanAfricanRadius.mdBR,
        boxShadow: shadow ?? (elevated ? PanAfricanShadows.sm : null),
        border: border ?? Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? PanAfricanRadius.mdBR,
        child: Padding(
          padding: padding ?? EdgeInsets.all(PanAfricanSpacing.md),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: cardWidget,
      );
    }
    
    return cardWidget;
  }
}

/// Glass-style card for dark/AI contexts
class LingAfriqGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? glowColor;
  final bool hasGlow;
  final VoidCallback? onTap;

  const LingAfriqGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.glowColor,
    this.hasGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: PolieColors.surfaceGlass,
        borderRadius: borderRadius ?? PanAfricanRadius.lgBR,
        boxShadow: hasGlow 
            ? PolieElevation.level2(context, glowColor: glowColor)
            : PolieElevation.level1(context),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? PanAfricanRadius.lgBR,
        child: Padding(
          padding: padding ?? EdgeInsets.all(PanAfricanSpacing.md),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: cardWidget,
      );
    }
    
    return cardWidget;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STANDARDIZED BUTTONS
// ═══════════════════════════════════════════════════════════════════════════

/// Primary button with consistent styling
class LingAfriqPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final BorderRadius? borderRadius;

  const LingAfriqPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? PanAfricanColors.primary;
    final fgColor = foregroundColor ?? Colors.white;
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? 52.h,
      child: ElevatedButton(
        onPressed: loading ? null : () {
          HapticFeedback.mediumImpact();
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withOpacity(0.5),
          elevation: 0,
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg,
            vertical: PanAfricanSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? PanAfricanRadius.mdBR,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(fgColor),
                ),
              )
            : Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20.sp),
                    SizedBox(width: PanAfricanSpacing.sm),
                  ],
                  Text(
                    label,
                    style: PanAfricanTypography.labelLarge(context, color: fgColor),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary/outlined button with consistent styling
class LingAfriqSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final Color? borderColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const LingAfriqSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.borderColor,
    this.foregroundColor,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bColor = borderColor ?? PanAfricanColors.primary;
    final fgColor = foregroundColor ?? bColor;
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? 52.h,
      child: OutlinedButton(
        onPressed: loading ? null : () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
          side: BorderSide(color: bColor, width: 1.5),
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg,
            vertical: PanAfricanSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: PanAfricanRadius.mdBR,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(fgColor),
                ),
              )
            : Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20.sp),
                    SizedBox(width: PanAfricanSpacing.sm),
                  ],
                  Text(
                    label,
                    style: PanAfricanTypography.labelLarge(context, color: fgColor),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text/tertiary button with consistent styling
class LingAfriqTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? foregroundColor;

  const LingAfriqTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = foregroundColor ?? PanAfricanColors.primary;
    
    return TextButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed?.call();
      },
      style: TextButton.styleFrom(
        foregroundColor: fgColor,
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18.sp),
            SizedBox(width: PanAfricanSpacing.xs),
          ],
          Text(
            label,
            style: PanAfricanTypography.labelLarge(context, color: fgColor),
          ),
        ],
      ),
    );
  }
}

/// Icon button with consistent styling
class LingAfriqIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double? size;
  final String? tooltip;

  const LingAfriqIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return IconButton(
      icon: Icon(
        icon,
        color: color ?? (isDark ? Colors.white : PanAfricanColors.textPrimary),
        size: size ?? 24.sp,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed?.call();
      },
      tooltip: tooltip,
      style: backgroundColor != null
          ? IconButton.styleFrom(
              backgroundColor: backgroundColor,
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STANDARDIZED TEXT FIELDS
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent text field with proper styling
class LingAfriqTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? Function(String?)? validator;

  const LingAfriqTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.autofocus = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: PanAfricanTypography.labelMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          minLines: minLines,
          validator: validator,
          style: PanAfricanTypography.bodyLarge(context),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: PanAfricanTypography.bodyLarge(context, 
              color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight,
            ),
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark 
                ? PanAfricanColors.surfaceContainerDark 
                : PanAfricanColors.surfaceContainerLight,
            contentPadding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: PanAfricanRadius.mdBR,
              borderSide: BorderSide(
                color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: PanAfricanRadius.mdBR,
              borderSide: BorderSide(
                color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: PanAfricanRadius.mdBR,
              borderSide: BorderSide(
                color: PanAfricanColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: PanAfricanRadius.mdBR,
              borderSide: BorderSide(
                color: PanAfricanColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: PanAfricanRadius.mdBR,
              borderSide: BorderSide(
                color: PanAfricanColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: PanAfricanRadius.mdBR,
              borderSide: BorderSide(
                color: (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight)
                    .withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SPACING HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent vertical spacing widget
class UISpacingVertical extends StatelessWidget {
  final double? height;
  final UISpacingSize size;

  const UISpacingVertical({super.key, this.height, this.size = UISpacingSize.md});
  
  const UISpacingVertical.xxxs({super.key}) : height = null, size = UISpacingSize.xxxs;
  const UISpacingVertical.xxs({super.key}) : height = null, size = UISpacingSize.xxs;
  const UISpacingVertical.xs({super.key}) : height = null, size = UISpacingSize.xs;
  const UISpacingVertical.sm({super.key}) : height = null, size = UISpacingSize.sm;
  const UISpacingVertical.md({super.key}) : height = null, size = UISpacingSize.md;
  const UISpacingVertical.lg({super.key}) : height = null, size = UISpacingSize.lg;
  const UISpacingVertical.xl({super.key}) : height = null, size = UISpacingSize.xl;
  const UISpacingVertical.xxl({super.key}) : height = null, size = UISpacingSize.xxl;
  const UISpacingVertical.xxxl({super.key}) : height = null, size = UISpacingSize.xxxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height ?? size.value);
  }
}

/// Consistent horizontal spacing widget
class UISpacingHorizontal extends StatelessWidget {
  final double? width;
  final UISpacingSize size;

  const UISpacingHorizontal({super.key, this.width, this.size = UISpacingSize.md});
  
  const UISpacingHorizontal.xxxs({super.key}) : width = null, size = UISpacingSize.xxxs;
  const UISpacingHorizontal.xxs({super.key}) : width = null, size = UISpacingSize.xxs;
  const UISpacingHorizontal.xs({super.key}) : width = null, size = UISpacingSize.xs;
  const UISpacingHorizontal.sm({super.key}) : width = null, size = UISpacingSize.sm;
  const UISpacingHorizontal.md({super.key}) : width = null, size = UISpacingSize.md;
  const UISpacingHorizontal.lg({super.key}) : width = null, size = UISpacingSize.lg;
  const UISpacingHorizontal.xl({super.key}) : width = null, size = UISpacingSize.xl;
  const UISpacingHorizontal.xxl({super.key}) : width = null, size = UISpacingSize.xxl;
  const UISpacingHorizontal.xxxl({super.key}) : width = null, size = UISpacingSize.xxxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width ?? size.value);
  }
}

enum UISpacingSize {
  xxxs,
  xxs,
  xs,
  sm,
  md,
  lg,
  xl,
  xxl,
  xxxl;

  double get value {
    switch (this) {
      case UISpacingSize.xxxs: return PanAfricanSpacing.xxxs;
      case UISpacingSize.xxs: return PanAfricanSpacing.xxs;
      case UISpacingSize.xs: return PanAfricanSpacing.xs;
      case UISpacingSize.sm: return PanAfricanSpacing.sm;
      case UISpacingSize.md: return PanAfricanSpacing.md;
      case UISpacingSize.lg: return PanAfricanSpacing.lg;
      case UISpacingSize.xl: return PanAfricanSpacing.xl;
      case UISpacingSize.xxl: return PanAfricanSpacing.xxl;
      case UISpacingSize.xxxl: return PanAfricanSpacing.xxxl;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STANDARD SCREEN PADDING
// ═══════════════════════════════════════════════════════════════════════════

/// Standard screen padding using adaptive layout
class ScreenPadding extends StatelessWidget {
  final Widget child;
  final bool horizontal;
  final bool vertical;
  final bool top;
  final bool bottom;

  const ScreenPadding({
    super.key,
    required this.child,
    this.horizontal = true,
    this.vertical = false,
    this.top = false,
    this.bottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = horizontal ? AdaptiveLayout.sideMargin(context) : 0.0;
    final v = vertical ? PanAfricanSpacing.md : 0.0;
    final t = top ? PanAfricanSpacing.md : 0.0;
    final b = bottom ? PanAfricanSpacing.md : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: h,
        right: h,
        top: vertical ? v : t,
        bottom: vertical ? v : b,
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onActionTap,
    this.actionLabel,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: AdaptiveLayout.sideMargin(context),
        vertical: PanAfricanSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.titleMedium(context),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    subtitle!,
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!
          else if (onActionTap != null && actionLabel != null)
            LingAfriqTextButton(
              label: actionLabel!,
              onPressed: onActionTap,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent divider
class LingAfriqDivider extends StatelessWidget {
  final double? height;
  final double? indent;
  final double? endIndent;
  final Color? color;

  const LingAfriqDivider({
    super.key,
    this.height,
    this.indent,
    this.endIndent,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Divider(
      height: height ?? PanAfricanSpacing.md,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: color ?? (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent empty state widget
class LingAfriqEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LingAfriqEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64.sp,
              color: PanAfricanColors.neutralMedium,
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              title,
              style: PanAfricanTypography.titleMedium(context),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                subtitle!,
                style: PanAfricanTypography.bodyMedium(context, 
                  color: PanAfricanColors.neutralMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: PanAfricanSpacing.lg),
              LingAfriqPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent loading indicator
class LingAfriqLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? message;

  const LingAfriqLoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40.w,
            height: size ?? 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                color ?? PanAfricanColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              message!,
              style: PanAfricanTypography.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AVATAR
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent avatar widget
class LingAfriqAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;

  const LingAfriqAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? PanAfricanColors.primary;
    final fgColor = foregroundColor ?? Colors.white;
    final initials = _getInitials(name);

    Widget avatar = Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: fgColor,
                  fontSize: (size * 0.4).sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: avatar,
      );
    }

    return avatar;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BADGE
// ═══════════════════════════════════════════════════════════════════════════

/// Consistent badge/chip widget
class LingAfriqBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool small;

  const LingAfriqBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? PanAfricanColors.primaryContainer;
    final fgColor = foregroundColor ?? PanAfricanColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? PanAfricanSpacing.xs : PanAfricanSpacing.sm,
        vertical: small ? PanAfricanSpacing.xxs : PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12.sp : 14.sp, color: fgColor),
            SizedBox(width: PanAfricanSpacing.xxs),
          ],
          Text(
            label,
            style: (small 
                ? PanAfricanTypography.labelSmall(context) 
                : PanAfricanTypography.labelMedium(context))
                .copyWith(color: fgColor),
          ),
        ],
      ),
    );
  }
}
