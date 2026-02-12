import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that shakes left-right when triggered
/// Used for incorrect answer feedback
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeDistance;
  final int oscillations;
  final VoidCallback? onComplete;

  const ShakeAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.shakeDistance = 10.0,
    this.oscillations = 3,
    this.onComplete,
  }) : super(key: key);

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Create shake animation using sine wave
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isShaking = false;
        });
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger the shake animation
  void shake() {
    if (_isShaking) {
      _controller.reset();
    }
    setState(() {
      _isShaking = true;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        if (!_isShaking) {
          return widget.child;
        }

        // Calculate shake offset using sine wave
        // Creates smooth oscillation: left-right-left-right pattern
        final progress = _shakeAnimation.value;
        final oscillationCount = widget.oscillations * 2; // Each oscillation has 2 movements
        final angle = progress * oscillationCount * pi;
        final offset = sin(angle) * widget.shakeDistance * (1 - progress);

        return Transform.translate(
          offset: Offset(offset, 0),
          child: widget.child,
        );
      },
    );
  }
}

/// A controller for managing shake animations
class ShakeController extends ChangeNotifier {
  VoidCallback? _shakeCallback;

  void _attach(VoidCallback shakeCallback) {
    _shakeCallback = shakeCallback;
  }

  void _detach() {
    _shakeCallback = null;
  }

  /// Trigger shake animation
  void shake() {
    _shakeCallback?.call();
  }
}

/// ShakeAnimation widget with external controller
class ControlledShakeAnimation extends StatefulWidget {
  final Widget child;
  final ShakeController controller;
  final Duration duration;
  final double shakeDistance;
  final int oscillations;
  final VoidCallback? onComplete;

  const ControlledShakeAnimation({
    Key? key,
    required this.child,
    required this.controller,
    this.duration = const Duration(milliseconds: 400),
    this.shakeDistance = 10.0,
    this.oscillations = 3,
    this.onComplete,
  }) : super(key: key);

  @override
  State<ControlledShakeAnimation> createState() => _ControlledShakeAnimationState();
}

class _ControlledShakeAnimationState extends State<ControlledShakeAnimation> {
  final GlobalKey<_ShakeAnimationState> _shakeKey = GlobalKey<_ShakeAnimationState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _shakeKey.currentState;
      if (state != null) {
        widget.controller._attach(state.shake);
      }
    });
  }

  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShakeAnimation(
      key: _shakeKey,
      duration: widget.duration,
      shakeDistance: widget.shakeDistance,
      oscillations: widget.oscillations,
      onComplete: widget.onComplete,
      child: widget.child,
    );
  }
}
