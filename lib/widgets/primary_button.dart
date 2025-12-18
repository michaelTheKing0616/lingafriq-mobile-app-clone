import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    this.enabled = true,
    this.isOutline = false,
    this.text,
    required this.onTap,
    this.elevation = 0,
    this.verticalPadding = 16,
    this.width,
    this.child,
    this.color,
    this.textColor,
  }) : super(key: key);

  final bool enabled;
  final bool isOutline;
  final String? text;
  final GestureTapCallback onTap;
  final double elevation;
  final double? width;
  final double verticalPadding;
  final Widget? child;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      splashColor: isOutline ? context.primaryColor.withOpacity(0.26) : null,
      highlightColor: context.primaryColor.withOpacity(0.12),
      elevation: elevation,
      highlightElevation: elevation,
      disabledColor: context.cardColor,
      minWidth: width ?? double.infinity,
      color: color ?? (isOutline ? Colors.transparent : context.primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: isOutline ? BorderSide(color: context.primaryColor, width: 2) : BorderSide.none,
      ),
      onPressed: enabled ? onTap : null,
      child: child ??
          Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Text(
              text ?? '',
              style: TextStyle(
                color: textColor ??
                    (!enabled
                        ? context.adaptive38
                        : isOutline
                            ? context.adaptive
                            : Colors.white),
                fontSize: 18.sp,
                letterSpacing: 0.8,
              ),
            ),
          ),
    );
  }
}
