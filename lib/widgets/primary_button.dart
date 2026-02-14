import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    this.enabled = true,
    this.isOutline = false,
    this.text,
    required this.onTap,
    this.elevation = 0,
    this.verticalPadding,
    this.width,
    this.child,
    this.color,
    this.textColor,
    this.icon,
    this.loading = false,
    this.height,
  });

  final bool enabled;
  final bool isOutline;
  final String? text;
  final GestureTapCallback onTap;
  final double elevation;
  final double? width;
  final double? verticalPadding;
  final Widget? child;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool loading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? PanAfricanColors.primary;
    final effectiveTextColor = textColor ?? (isOutline ? effectiveColor : Theme.of(context).colorScheme.onPrimary);
    final disabledColor = effectiveColor.withOpacity(0.4);
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52.h,
      child: MaterialButton(
        splashColor: isOutline ? effectiveColor.withOpacity(0.12) : Theme.of(context).colorScheme.onPrimary.withOpacity(0.12),
        highlightColor: effectiveColor.withOpacity(0.08),
        elevation: elevation,
        highlightElevation: elevation,
        disabledColor: isOutline ? Colors.transparent : disabledColor,
        color: isOutline ? Colors.transparent : (enabled ? effectiveColor : disabledColor),
        shape: RoundedRectangleBorder(
          borderRadius: PanAfricanRadius.mdBR,
          side: isOutline 
              ? BorderSide(
                  color: enabled ? effectiveColor : disabledColor, 
                  width: 1.5,
                ) 
              : BorderSide.none,
        ),
        onPressed: enabled && !loading
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        child: loading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(effectiveTextColor),
                ),
              )
            : child ??
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding ?? PanAfricanSpacing.sm,
                    horizontal: PanAfricanSpacing.md,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20.sp, color: effectiveTextColor),
                        SizedBox(width: PanAfricanSpacing.sm),
                      ],
                      Text(
                        text ?? '',
                        style: PanAfricanTypography.labelLarge(
                          context, 
                          color: enabled ? effectiveTextColor : effectiveTextColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
