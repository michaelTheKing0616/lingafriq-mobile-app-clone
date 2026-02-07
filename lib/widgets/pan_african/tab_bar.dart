import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Pan-African styled tab bar with consistent design
/// 
/// Features:
/// - Pill-style indicator
/// - Smooth animations
/// - Icon support
/// - Badge support
class PanAfricanTabBar extends StatelessWidget {
  final List<PanAfricanTab> tabs;
  final TabController? controller;
  final int? initialIndex;
  final ValueChanged<int>? onTap;
  final bool isScrollable;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final EdgeInsets? padding;

  const PanAfricanTabBar({
    Key? key,
    required this.tabs,
    this.controller,
    this.initialIndex,
    this.onTap,
    this.isScrollable = false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        borderRadius: PanAfricanRadius.mdBR,
      ),
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        onTap: onTap,
        tabs: tabs.map((tab) => _buildTab(context, tab, isDark)).toList(),
        labelColor: labelColor ?? (isDark ? Colors.white : PanAfricanColors.textPrimaryLight),
        unselectedLabelColor: unselectedLabelColor ??
            (isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
        labelStyle: PanAfricanTypography.labelLarge(context),
        unselectedLabelStyle: PanAfricanTypography.labelMedium(context),
        indicator: BoxDecoration(
          color: indicatorColor ?? PanAfricanColors.primary,
          borderRadius: PanAfricanRadius.smBR,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.xs,
          vertical: PanAfricanSpacing.xxs,
        ),
        dividerColor: Colors.transparent,
        splashBorderRadius: PanAfricanRadius.smBR,
      ),
    );
  }

  Widget _buildTab(BuildContext context, PanAfricanTab tab, bool isDark) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (tab.icon != null) ...[
            Icon(tab.icon, size: 18.sp),
            SizedBox(width: PanAfricanSpacing.xs),
          ],
          Text(tab.label),
          if (tab.badge != null) ...[
            SizedBox(width: PanAfricanSpacing.xs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.xs,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: tab.badgeColor ?? PanAfricanColors.secondary,
                borderRadius: PanAfricanRadius.roundBR,
              ),
              child: Text(
                tab.badge!,
                style: PanAfricanTypography.labelSmall(
                  context,
                  color: PanAfricanColors.neutralDarkest,
                ).copyWith(fontSize: 10.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Represents a single tab in PanAfricanTabBar
class PanAfricanTab {
  final String label;
  final IconData? icon;
  final String? badge;
  final Color? badgeColor;

  const PanAfricanTab({
    required this.label,
    this.icon,
    this.badge,
    this.badgeColor,
  });
}

/// Segmented tab control for switching between 2-5 options
class PanAfricanSegmentedControl<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final Map<T, IconData>? icons;

  const PanAfricanSegmentedControl({
    Key? key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.icons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.xxs),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        borderRadius: PanAfricanRadius.mdBR,
      ),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = entry.key == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: PanAfricanSpacing.sm,
                  horizontal: PanAfricanSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PanAfricanColors.primary
                      : Colors.transparent,
                  borderRadius: PanAfricanRadius.smBR,
                  boxShadow: isSelected ? PanAfricanShadows.sm : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icons != null && icons![entry.key] != null) ...[
                      Icon(
                        icons![entry.key],
                        size: 16.sp,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
                      ),
                      SizedBox(width: PanAfricanSpacing.xxs),
                    ],
                    Text(
                      entry.value,
                      style: PanAfricanTypography.labelMedium(
                        context,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
                      ).copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
