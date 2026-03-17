import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared play-area frame to keep game layouts aligned with design rhythm.
class GamePlayFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const GamePlayFrame({
    super.key,
    required this.child,
    this.maxWidth = 520,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left.w,
            padding.top.h,
            padding.right.w,
            padding.bottom.h,
          ),
          child: child,
        ),
      ),
    );
  }
}
