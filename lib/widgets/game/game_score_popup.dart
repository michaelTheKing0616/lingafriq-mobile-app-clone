import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Animated floating score popup (e.g. "+5 XP", "+10").
///
/// Slides upward and fades out over ~1.2 seconds, then calls [onComplete].
/// Designed to be placed in a [Stack] at the position where the score
/// event occurred.
class GameScorePopup extends StatefulWidget {
  /// The text to display (e.g. "+5 XP").
  final String text;

  /// Color of the popup text. Defaults to the primary color.
  final Color? color;

  /// Called after the animation finishes and the widget should be removed.
  final VoidCallback? onComplete;

  const GameScorePopup({
    super.key,
    required this.text,
    this.color,
    this.onComplete,
  });

  @override
  State<GameScorePopup> createState() => _GameScorePopupState();
}

class _GameScorePopupState extends State<GameScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: const Offset(0, -1.2),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 60,
      ),
    ]).animate(_controller);

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? PanAfricanColors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.15),
          borderRadius: PanAfricanRadius.roundBR,
          border: Border.all(
            color: effectiveColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          widget.text,
          style: PanAfricanTypography.titleMedium(context).copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }
}
