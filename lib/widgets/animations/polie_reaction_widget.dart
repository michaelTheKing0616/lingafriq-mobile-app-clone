import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Character reaction states for Polie
enum PolieReactionState {
  idle,
  happy,
  sad,
  excited,
  sleeping,
}

/// Animated character widget (Polie) that reacts to user actions
/// Size: ~80x80 dp, can be overlaid on any screen
class PolieReactionWidget extends StatefulWidget {
  final PolieReactionState state;
  final double size;
  final VoidCallback? onTap;

  const PolieReactionWidget({
    Key? key,
    this.state = PolieReactionState.idle,
    this.size = 80,
    this.onTap,
  }) : super(key: key);

  @override
  State<PolieReactionWidget> createState() => _PolieReactionWidgetState();
}

class _PolieReactionWidgetState extends State<PolieReactionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  PolieReactionState _currentState = PolieReactionState.idle;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 50,
      ),
    ]).animate(_controller);

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -10.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (_currentState == PolieReactionState.idle) {
      _startIdleAnimation();
    }
  }

  @override
  void didUpdateWidget(PolieReactionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      setState(() {
        _currentState = widget.state;
      });
      _triggerReaction();
    }
  }

  void _startIdleAnimation() {
    if (_currentState == PolieReactionState.idle) {
      _controller.repeat(reverse: true);
    }
  }

  void _triggerReaction() {
    _controller.stop();
    _controller.reset();
    _controller.forward().then((_) {
      if (_currentState == PolieReactionState.idle) {
        _startIdleAnimation();
      } else {
        _controller.reverse();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = widget.size.w;

    final content = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getBackgroundColor(isDark),
                  boxShadow: [
                    BoxShadow(
                      color: _getBackgroundColor(isDark).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _buildFace(isDark, size),
              ),
            ),
          );
        },
      ),
    );
    return content
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), curve: Curves.elasticOut);
  }

  Color _getBackgroundColor(bool isDark) {
    switch (_currentState) {
      case PolieReactionState.happy:
        return PanAfricanColors.success;
      case PolieReactionState.sad:
        return PanAfricanColors.error;
      case PolieReactionState.excited:
        return PanAfricanColors.secondary;
      case PolieReactionState.sleeping:
        return PanAfricanColors.neutralMedium;
      case PolieReactionState.idle:
      default:
        return PanAfricanColors.primary;
    }
  }

  Widget _buildFace(bool isDark, double size) {
    switch (_currentState) {
      case PolieReactionState.happy:
        return _buildHappyFace(size);
      case PolieReactionState.sad:
        return _buildSadFace(size);
      case PolieReactionState.excited:
        return _buildExcitedFace(size);
      case PolieReactionState.sleeping:
        return _buildSleepingFace(size);
      case PolieReactionState.idle:
      default:
        return _buildIdleFace(size);
    }
  }

  Widget _buildHappyFace(double size) {
    return CustomPaint(
      painter: _HappyFacePainter(),
      size: Size(size, size),
    );
  }

  Widget _buildSadFace(double size) {
    return CustomPaint(
      painter: _SadFacePainter(),
      size: Size(size, size),
    );
  }

  Widget _buildExcitedFace(double size) {
    return CustomPaint(
      painter: _ExcitedFacePainter(),
      size: Size(size, size),
    );
  }

  Widget _buildSleepingFace(double size) {
    return CustomPaint(
      painter: _SleepingFacePainter(),
      size: Size(size, size),
    );
  }

  Widget _buildIdleFace(double size) {
    return CustomPaint(
      painter: _IdleFacePainter(),
      size: Size(size, size),
    );
  }
}

class _HappyFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Eyes
    final eyeRadius = radius * 0.15;
    final eyeY = center.dy - radius * 0.2;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, eyeY),
      eyeRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, eyeY),
      eyeRadius,
      paint,
    );

    // Smile (arc)
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;

    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.15),
      width: radius * 0.8,
      height: radius * 0.6,
    );

    canvas.drawArc(
      smileRect,
      0,
      -3.14,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(_HappyFacePainter oldDelegate) => false;
}

class _SadFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Eyes
    final eyeRadius = radius * 0.15;
    final eyeY = center.dy - radius * 0.2;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, eyeY),
      eyeRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, eyeY),
      eyeRadius,
      paint,
    );

    // Frown (arc)
    final frownPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;

    final frownRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.3),
      width: radius * 0.8,
      height: radius * 0.6,
    );

    canvas.drawArc(
      frownRect,
      0,
      3.14,
      false,
      frownPaint,
    );
  }

  @override
  bool shouldRepaint(_SadFacePainter oldDelegate) => false;
}

class _ExcitedFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Wide eyes
    final eyeRadius = radius * 0.18;
    final eyeY = center.dy - radius * 0.2;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, eyeY),
      eyeRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, eyeY),
      eyeRadius,
      paint,
    );

    // Big smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12
      ..strokeCap = StrokeCap.round;

    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.1),
      width: radius * 0.9,
      height: radius * 0.7,
    );

    canvas.drawArc(
      smileRect,
      0,
      -3.14,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(_ExcitedFacePainter oldDelegate) => false;
}

class _SleepingFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Closed eyes (horizontal lines)
    final eyeY = center.dy - radius * 0.2;
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - radius * 0.35, eyeY),
      Offset(center.dx - radius * 0.15, eyeY),
      eyePaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.15, eyeY),
      Offset(center.dx + radius * 0.35, eyeY),
      eyePaint,
    );

    // Zzz (sleeping indicator)
    final zzzPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round;

    final zzzY = center.dy + radius * 0.3;
    canvas.drawLine(
      Offset(center.dx - radius * 0.2, zzzY),
      Offset(center.dx - radius * 0.1, zzzY - radius * 0.1),
      zzzPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.1, zzzY - radius * 0.1),
      Offset(center.dx, zzzY),
      zzzPaint,
    );
    canvas.drawLine(
      Offset(center.dx, zzzY),
      Offset(center.dx + radius * 0.1, zzzY - radius * 0.1),
      zzzPaint,
    );
  }

  @override
  bool shouldRepaint(_SleepingFacePainter oldDelegate) => false;
}

class _IdleFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Neutral eyes
    final eyeRadius = radius * 0.12;
    final eyeY = center.dy - radius * 0.2;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, eyeY),
      eyeRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, eyeY),
      eyeRadius,
      paint,
    );

    // Neutral mouth (small line)
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - radius * 0.2, center.dy + radius * 0.2),
      Offset(center.dx + radius * 0.2, center.dy + radius * 0.2),
      mouthPaint,
    );
  }

  @override
  bool shouldRepaint(_IdleFacePainter oldDelegate) => false;
}
