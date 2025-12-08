import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Material 3 Primary Button - Replaces old MaterialButton
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    this.enabled = true,
    this.isOutline = false,
    this.text,
    required this.onTap,
    this.verticalPadding = 16,
    this.width,
    this.child,
    this.color,
    this.textColor,
    this.icon,
  }) : super(key: key);

  final bool enabled;
  final bool isOutline;
  final String? text;
  final GestureTapCallback onTap;
  final double? width;
  final double verticalPadding;
  final Widget? child;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use Material 3 buttons
    if (isOutline) {
      return SizedBox(
        width: width ?? double.infinity,
        child: OutlinedButton(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            side: BorderSide(
              color: color ?? theme.colorScheme.primary,
              width: 2,
            ),
          ),
          child: child ??
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20.sp, color: textColor ?? theme.colorScheme.primary),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text ?? '',
                    style: TextStyle(
                      color: textColor ??
                          (!enabled
                              ? theme.colorScheme.onSurface.withOpacity(0.38)
                              : theme.colorScheme.primary),
                      fontSize: 18.sp,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        ),
      );
    } else {
      return SizedBox(
        width: width ?? double.infinity,
        child: FilledButton(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            backgroundColor: color ?? theme.colorScheme.primary,
            foregroundColor: textColor ?? theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
            disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 0,
          ),
          child: child ??
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20.sp),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text ?? '',
                    style: TextStyle(
                      fontSize: 18.sp,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        ),
      );
    }
  }
}
