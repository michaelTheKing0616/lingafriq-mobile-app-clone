import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable button wrapper that scales down on press and springs back
/// Provides tactile feedback similar to Duolingo's button interactions
class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double pressScale;
  final bool enableHapticFeedback;

  const AnimatedPressButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.pressScale = 0.95,
    this.enableHapticFeedback = true,
  }) : super(key: key);

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isPressed) return;
    
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!_isPressed) return;
    
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
