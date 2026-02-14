import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Animated answer tile - replaces static Card + ListTile
/// This is what makes the UI feel premium
class GameAnswerTile extends StatefulWidget {
  final String text;
  final bool isCorrect;
  final bool isSelected;
  final bool showResult;
  final VoidCallback? onTap;
  final IconData? icon;

  const GameAnswerTile({
    super.key,
    required this.text,
    this.isCorrect = false,
    this.isSelected = false,
    this.showResult = false,
    this.onTap,
    this.icon,
  });

  @override
  State<GameAnswerTile> createState() => _GameAnswerTileState();
}

class _GameAnswerTileState extends State<GameAnswerTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Determine colors based on state
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? trailingIcon;
    Color? iconColor;

    if (widget.showResult) {
      if (widget.isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.2);
        borderColor = Colors.green;
        textColor = Colors.green.shade900;
        trailingIcon = Icons.check_circle;
        iconColor = Colors.green;
      } else if (widget.isSelected && !widget.isCorrect) {
        backgroundColor = Colors.red.withOpacity(0.2);
        borderColor = Colors.red;
        textColor = Colors.red.shade900;
        trailingIcon = Icons.cancel;
        iconColor = Colors.red;
      } else {
        backgroundColor = Colors.grey.withOpacity(0.1);
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
      }
    } else if (widget.isSelected) {
      backgroundColor = Colors.blue.withOpacity(0.2);
      borderColor = Colors.blue;
      textColor = Colors.blue.shade900;
    } else {
      backgroundColor = Theme.of(context).colorScheme.surface;
      borderColor = Colors.grey.shade300;
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        Vibrate.feedback(FeedbackType.selection);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: _isPressed ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: borderColor, size: 24.sp),
              SizedBox(width: 3.w),
            ],
            Expanded(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: 2.w),
              Icon(trailingIcon, color: iconColor, size: 28.sp),
            ],
          ],
        ),
      )
          .animate(target: widget.isSelected ? 1 : 0)
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.02, 1.02),
            duration: 200.ms,
          )
          .shimmer(
            delay: 100.ms,
            duration: 500.ms,
            color: widget.isCorrect ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
          ),
    );
  }
}

