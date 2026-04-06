import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Text-only tertiary button: no background, bold primary-colored text.
///
/// Includes a subtle translate-down animation (2px) on press for tactile feel.
///
/// ```dart
/// GriotTertiaryButton(
///   label: 'Learn more',
///   onPressed: () => _showDetails(),
/// )
/// ```
class GriotTertiaryButton extends StatefulWidget {
  const GriotTertiaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<GriotTertiaryButton> createState() => _GriotTertiaryButtonState();
}

class _GriotTertiaryButtonState extends State<GriotTertiaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _handleDown(TapDownDetails _) {
    if (_enabled) setState(() => _pressed = true);
  }

  void _handleUp(TapUpDetails _) {
    if (_enabled) setState(() => _pressed = false);
  }

  void _handleCancel() {
    if (_enabled) setState(() => _pressed = false);
  }

  void _handleTap() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: _handleDown,
      onTapUp: _handleUp,
      onTapCancel: _handleCancel,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? 2.0 : 0.0, 0),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _enabled ? 1.0 : 0.5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18.sp, color: cs.primary),
                SizedBox(width: 6.w),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
