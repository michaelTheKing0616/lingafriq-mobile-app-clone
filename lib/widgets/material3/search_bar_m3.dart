import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Material 3 Search Bar
class SearchBarM3 extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool enabled;
  final bool autofocus;

  const SearchBarM3({
    Key? key,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.controller,
    this.enabled = true,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SearchBar(
      hintText: hintText ?? 'Search...',
      controller: controller,
      enabled: enabled,
      autoFocus: autofocus,
      onChanged: onChanged,
      onTap: onTap,
      leading: Icon(
        Icons.search,
        color: theme.colorScheme.onSurfaceVariant,
        size: 24.sp,
      ),
      trailing: controller != null && controller!.text.isNotEmpty
          ? [
              IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 20.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  controller!.clear();
                  onChanged?.call('');
                },
              ),
            ]
          : null,
      padding: MaterialStateProperty.all(
        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
      ),
    );
  }
}

