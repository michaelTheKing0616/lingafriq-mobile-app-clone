import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Signature gradient CTA button for the Modern Griot design system.
///
/// Renders primary → primaryContainer gradient, full pill shape, and
/// onPrimary text. Includes a 0.95 scale-down animation on press.
///
/// ```dart
/// GriotGradientButton(
///   label: 'Start Lesson',
///   icon: Icons.play_arrow_rounded,
///   onPressed: () => _startLesson(),
/// )
/// ```
class GriotGradientButton extends StatefulWidget {
  const GriotGradientButton({
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

  @override
  State<GriotGradientButton> createState() => _GriotGradientButtonState();
}

class _GriotGradientButtonState extends State<GriotGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails _) {
    if (_enabled) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (_enabled) _controller.reverse();
  }

  void _handleTapCancel() {
    if (_enabled) _controller.reverse();
  }

  void _handleTap() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _enabled ? 1.0 : 0.5,
          child: Container(
            width: widget.width?.w,
            height: 52.h,
            decoration: BoxDecoration(
              gradient: ModernGriotGradients.signatureGradient,
              borderRadius: ModernGriotRadius.borderPill,
              boxShadow: ModernGriotShadows.fab,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24.r,
                      height: 24.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20.sp, color: cs.onPrimary),
                          SizedBox(width: 8.w),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

