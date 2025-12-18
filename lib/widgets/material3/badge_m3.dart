import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Material 3 Badge - For notifications, counts, etc.
class BadgeM3 extends StatelessWidget {
  final Widget child;
  final String? label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isVisible;
  final BadgePosition position;

  const BadgeM3({
    Key? key,
    required this.child,
    this.label,
    this.backgroundColor,
    this.textColor,
    this.isVisible = true,
    this.position = BadgePosition.topEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!isVisible || label == null) {
      return child;
    }
    
    return Badge(
      label: Text(
        label!,
        style: TextStyle(
          color: textColor ?? theme.colorScheme.onErrorContainer,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor ?? theme.colorScheme.errorContainer,
      alignment: _getAlignment(position),
      child: child,
    );
  }

  Alignment _getAlignment(BadgePosition position) {
    switch (position) {
      case BadgePosition.topStart:
        return Alignment.topLeft;
      case BadgePosition.topEnd:
        return Alignment.topRight;
      case BadgePosition.bottomStart:
        return Alignment.bottomLeft;
      case BadgePosition.bottomEnd:
        return Alignment.bottomRight;
    }
  }
}

enum BadgePosition {
  topStart,
  topEnd,
  bottomStart,
  bottomEnd,
}

