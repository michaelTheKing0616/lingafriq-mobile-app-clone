import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Pill-shaped chip with uppercase label, configurable selected state.
///
/// Unselected: surfaceVariant background, onSurfaceVariant text.
/// Selected:   primary background, onPrimary text.
///
/// ```dart
/// GriotChip(
///   label: 'Yoruba',
///   selected: _selectedLang == 'yo',
///   onTap: () => _select('yo'),
/// )
/// ```
class GriotChip extends StatelessWidget {
  const GriotChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor = selected ? cs.primary : cs.surfaceContainerHighest;
    final fgColor = selected ? cs.onPrimary : cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: ModernGriotRadius.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16.sp, color: fgColor),
              SizedBox(width: 6.w),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: fgColor,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
