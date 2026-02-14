import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Material 3 Segmented Button - For toggle groups
class SegmentedControlM3<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final ValueChanged<T>? onSelectionChanged;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;

  const SegmentedControlM3({
    super.key,
    required this.options,
    this.selected,
    this.onSelectionChanged,
    required this.labelBuilder,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: options.map((option) {
        return ButtonSegment<T>(
          value: option,
          label: Text(labelBuilder(option)),
          icon: iconBuilder != null ? Icon(iconBuilder!(option), size: 18.sp) : null,
        );
      }).toList(),
      selected: selected != null ? {selected as T} : <T>{},
      onSelectionChanged: (Set<T> newSelection) {
        if (newSelection.isNotEmpty && onSelectionChanged != null) {
          onSelectionChanged!(newSelection.first);
        }
      },
      style: SegmentedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
    );
  }
}

