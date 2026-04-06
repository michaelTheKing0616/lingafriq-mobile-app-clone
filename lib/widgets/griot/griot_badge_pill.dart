import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Floating badge pill for XP, streak, level, or status indicators.
///
/// Supports an optional repeating bounce animation to draw attention.
///
/// ```dart
/// GriotBadgePill(
///   label: '+50 XP',
///   color: ModernGriotColors.primaryContainer,
///   textColor: ModernGriotColors.onPrimaryContainer,
///   bounce: true,
/// )
/// ```
class GriotBadgePill extends StatefulWidget {
  const GriotBadgePill({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
    this.bounce = false,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  /// When true, the pill bounces in a subtle loop animation.
  final bool bounce;

  @override
  State<GriotBadgePill> createState() => _GriotBadgePillState();
}

class _GriotBadgePillState extends State<GriotBadgePill>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _bounceAnim;

  @override
  void initState() {
    super.initState();
    if (widget.bounce) _initBounce();
  }

  @override
  void didUpdateWidget(GriotBadgePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bounce && _controller == null) {
      _initBounce();
    } else if (!widget.bounce && _controller != null) {
      _controller!.dispose();
      _controller = null;
      _bounceAnim = null;
    }
  }

  void _initBounce() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = widget.color ?? cs.primaryContainer;
    final fgColor = widget.textColor ?? cs.onPrimaryContainer;

    Widget pill = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: ModernGriotRadius.borderPill,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 14.sp, color: fgColor),
            SizedBox(width: 4.w),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: fgColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (_bounceAnim != null) {
      return AnimatedBuilder(
        animation: _bounceAnim!,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _bounceAnim!.value),
          child: child,
        ),
        child: pill,
      );
    }

    return pill;
  }
}

