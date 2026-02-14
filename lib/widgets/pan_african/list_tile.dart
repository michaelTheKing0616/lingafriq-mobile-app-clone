import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Pan-African styled list tile with consistent design
/// 
/// Features:
/// - Consistent spacing and typography
/// - Leading/trailing icons or widgets
/// - Subtitle and description support
/// - Tap feedback
/// - Badge/tag support
class PanAfricanListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final Widget? leading;
  final Widget? trailing;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Color? leadingIconBackgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? badge;
  final Color? badgeColor;
  final bool showChevron;
  final bool isEnabled;
  final EdgeInsets? padding;
  final bool hasDivider;

  const PanAfricanListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.leading,
    this.trailing,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingIconBackgroundColor,
    this.onTap,
    this.onLongPress,
    this.badge,
    this.badgeColor,
    this.showChevron = false,
    this.isEnabled = true,
    this.padding,
    this.hasDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            onLongPress: isEnabled ? onLongPress : null,
            borderRadius: PanAfricanRadius.mdBR,
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: Padding(
                padding: padding ?? EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.md,
                  vertical: PanAfricanSpacing.sm,
                ),
                child: Row(
                  children: [
                    // Leading
                    if (leading != null)
                      Padding(
                        padding: EdgeInsets.only(right: PanAfricanSpacing.md),
                        child: leading!,
                      )
                    else if (leadingIcon != null)
                      Padding(
                        padding: EdgeInsets.only(right: PanAfricanSpacing.md),
                        child: _buildIconContainer(isDark),
                      ),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: PanAfricanTypography.bodyLarge(
                                    context,
                                    color: isDark
                                        ? PanAfricanColors.textPrimaryDark
                                        : PanAfricanColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              if (badge != null) _buildBadge(context),
                            ],
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              subtitle!,
                              style: PanAfricanTypography.bodySmall(
                                context,
                                color: isDark
                                    ? PanAfricanColors.textSecondaryDark
                                    : PanAfricanColors.textSecondaryLight,
                              ),
                            ),
                          ],
                          if (description != null) ...[
                            SizedBox(height: PanAfricanSpacing.xxs),
                            Text(
                              description!,
                              style: PanAfricanTypography.bodySmall(
                                context,
                                color: isDark
                                    ? PanAfricanColors.textTertiaryDark
                                    : PanAfricanColors.textTertiaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Trailing
                    if (trailing != null)
                      Padding(
                        padding: EdgeInsets.only(left: PanAfricanSpacing.sm),
                        child: trailing!,
                      )
                    else if (showChevron)
                      Padding(
                        padding: EdgeInsets.only(left: PanAfricanSpacing.sm),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark
                              ? PanAfricanColors.textTertiaryDark
                              : PanAfricanColors.textTertiaryLight,
                          size: 20.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasDivider)
          Padding(
            padding: EdgeInsets.only(
              left: leading != null || leadingIcon != null
                  ? PanAfricanSpacing.md + 40.w + PanAfricanSpacing.md
                  : PanAfricanSpacing.md,
            ),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
            ),
          ),
      ],
    );
  }

  Widget _buildIconContainer(bool isDark) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: leadingIconBackgroundColor ??
            (isDark
                ? PanAfricanColors.surfaceContainerDark
                : PanAfricanColors.surfaceContainerLight),
        borderRadius: PanAfricanRadius.smBR,
      ),
      child: Icon(
        leadingIcon,
        color: leadingIconColor ?? PanAfricanColors.primary,
        size: 20.sp,
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: PanAfricanSpacing.xs),
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.xs,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: badgeColor ?? PanAfricanColors.secondary,
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Text(
        badge!,
        style: PanAfricanTypography.labelSmall(
          context,
          color: PanAfricanColors.neutralDarkest,
        ).copyWith(fontSize: 10.sp),
      ),
    );
  }
}

/// Section header for grouped list tiles
class PanAfricanListSection extends StatelessWidget {
  final String title;
  final List<PanAfricanListTile> children;
  final EdgeInsets? padding;
  final bool showBackground;

  const PanAfricanListSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: PanAfricanSpacing.md,
            right: PanAfricanSpacing.md,
            bottom: PanAfricanSpacing.xs,
          ),
          child: Text(
            title.toUpperCase(),
            style: PanAfricanTypography.labelSmall(
              context,
              color: isDark
                  ? PanAfricanColors.textTertiaryDark
                  : PanAfricanColors.textTertiaryLight,
            ).copyWith(letterSpacing: 0.5),
          ),
        ),
        if (showBackground)
          Container(
            margin: padding ?? EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
              borderRadius: PanAfricanRadius.lgBR,
            ),
            child: Column(children: children),
          )
        else
          Column(children: children),
      ],
    );
  }
}
