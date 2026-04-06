import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Secondary button: secondary background, onSecondary text, pill shape.
///
/// ```dart
/// GriotSecondaryButton(
///   label: 'Skip',
///   onPressed: () => _skip(),
/// )
/// ```
class GriotSecondaryButton extends StatelessWidget {
  const GriotSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: width?.w,
      height: 52.h,
      child: MaterialButton(
        elevation: 0,
        highlightElevation: 0,
        color: _enabled ? cs.secondary : cs.secondary.withAlpha(128),
        disabledColor: cs.secondary.withAlpha(128),
        splashColor: cs.onSecondary.withAlpha(30),
        highlightColor: cs.onSecondary.withAlpha(15),
        shape: RoundedRectangleBorder(
          borderRadius: ModernGriotRadius.borderPill,
        ),
        onPressed: _enabled
            ? () {
                HapticFeedback.mediumImpact();
                onPressed!();
              }
            : null,
        child: isLoading
            ? SizedBox(
                width: 24.r,
                height: 24.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(cs.onSecondary),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20.sp, color: cs.onSecondary),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: cs.onSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
