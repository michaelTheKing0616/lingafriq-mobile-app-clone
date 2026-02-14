import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern animated icon button with Material 3 ripple effect
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size,
    this.tooltip,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.9).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPressed
                ? (widget.color ?? Theme.of(context).primaryColor)
                    .withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            color: widget.color ?? Theme.of(context).primaryColor,
            size: widget.size ?? 24,
          ),
        )
            .animate()
            .fadeIn(duration: 200.ms)
            .scale(delay: 100.ms, duration: 200.ms),
      ),
    );
  }
}

