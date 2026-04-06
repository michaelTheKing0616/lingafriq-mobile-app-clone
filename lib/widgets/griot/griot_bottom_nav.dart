import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Glassmorphic bottom navigation bar.
///
/// Surface at 80% opacity + 24px blur + rounded top corners.
/// Takes a list of [GriotNavItem]s and a selected index.
///
/// ```dart
/// GriotBottomNav(
///   currentIndex: _tabIndex,
///   onTap: (i) => setState(() => _tabIndex = i),
///   items: [
///     GriotNavItem(icon: Icons.home_rounded, label: 'Home'),
///     GriotNavItem(icon: Icons.games_rounded, label: 'Games'),
///     GriotNavItem(icon: Icons.chat_rounded, label: 'Chat'),
///     GriotNavItem(icon: Icons.person_rounded, label: 'Profile'),
///   ],
/// )
/// ```
class GriotBottomNav extends StatelessWidget {
  const GriotBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GriotNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ModernGriotRadius.xl.r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: cs.surface.withAlpha(204),
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withAlpha(25),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60.h,
              child: Row(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = i == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected
                                  ? (item.activeIcon ?? item.icon)
                                  : item.icon,
                              size: 24.sp,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for a single navigation item in [GriotBottomNav].
class GriotNavItem {
  const GriotNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;
  final String label;

  /// Optional filled icon variant for the selected state.
  final IconData? activeIcon;
}
