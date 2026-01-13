import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Material 3 Text Button - Modern replacement for FlatButton
class TextButtonM3 extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? foregroundColor;
  final double? fontSize;
  final bool enabled;

  const TextButtonM3({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.foregroundColor,
    this.fontSize,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? theme.colorScheme.primary,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: (fontSize ?? 16.sp) + 2),
            SizedBox(width: 8.w),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

