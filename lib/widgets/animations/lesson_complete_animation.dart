import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// Full-screen celebration overlay shown after completing a lesson
class LessonCompleteAnimation extends StatefulWidget {
  final int xpGained;
  final int? comboBonus;
  final VoidCallback onContinue;
  final String? message;

  const LessonCompleteAnimation({
    Key? key,
    required this.xpGained,
    this.comboBonus,
    required this.onContinue,
    this.message,
  }) : super(key: key);

  @override
  State<LessonCompleteAnimation> createState() => _LessonCompleteAnimationState();
}

class _LessonCompleteAnimationState extends State<LessonCompleteAnimation>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _xpController;
  late AnimationController _buttonController;
  late Animation<double> _xpScaleAnimation;
  late Animation<double> _xpFadeAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _buttonSlideAnimation;

  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // XP animation
    _xpController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Button animation (delayed)
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // XP scale and fade
    _xpScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 30,
      ),
    ]).animate(_xpController);

    _xpFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _xpController,
      curve: Curves.easeIn,
    ));

    // Button fade and slide
    _buttonFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    ));

    _buttonSlideAnimation = Tween<double>(
      begin: 0.3,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    ));

    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.2,
        angle: _random.nextDouble() * 2 * pi,
        speed: 100 + _random.nextDouble() * 200,
        size: 4 + _random.nextDouble() * 8,
        color: _getRandomColor(),
        rotationSpeed: (_random.nextDouble() - 0.5) * 2 * pi,
      ));
    }

    // Start animations
    _confettiController.repeat();
    _xpController.forward();
    
    // Delay button appearance
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _buttonController.forward();
      }
    });
  }

  Color _getRandomColor() {
    final colors = [
      PanAfricanColors.secondary,
      PanAfricanColors.tertiary,
      PanAfricanColors.primaryLight,
      PanAfricanColors.kenteBlue,
      Colors.orange,
      Colors.red,
      Colors.yellow,
      Colors.green,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _xpController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Stack(
        children: [
          // Confetti particles
          CustomPaint(
            painter: ConfettiPainter(
              particles: _particles,
              animation: _confettiController,
            ),
            size: Size.infinite,
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                AnimatedBuilder(
                  animation: _xpController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _xpScaleAnimation.value,
                      child: Opacity(
                        opacity: _xpFadeAnimation.value,
                        child: Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: PanAfricanGradients.kenteVibrant,
                            boxShadow: [
                              BoxShadow(
                                color: PanAfricanColors.secondary.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 80.sp,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 32.h),
                // XP gained
                AnimatedBuilder(
                  animation: _xpController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _xpFadeAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'Lesson Complete!',
                            style: PanAfricanTypography.titleLarge(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PanAfricanSpacing.lg,
                              vertical: PanAfricanSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              gradient: PanAfricanGradients.celebration,
                              borderRadius: PanAfricanRadius.xlBR,
                              boxShadow: [
                                BoxShadow(
                                  color: PanAfricanColors.secondary.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 32.sp,
                                ),
                                SizedBox(width: PanAfricanSpacing.sm),
                                Text(
                                  '+${widget.xpGained}',
                                  style: TextStyle(
                                    fontSize: 36.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: PanAfricanSpacing.xxs),
                                Text(
                                  'XP',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.comboBonus != null && widget.comboBonus! > 0) ...[
                            SizedBox(height: 16.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: PanAfricanSpacing.md,
                                vertical: PanAfricanSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.9),
                                borderRadius: PanAfricanRadius.roundBR,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: PanAfricanSpacing.xs),
                                  Text(
                                    '${widget.comboBonus}x Combo Bonus!',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (widget.message != null) ...[
                            SizedBox(height: 16.h),
                            Text(
                              widget.message!,
                              style: PanAfricanTypography.bodyMedium(context).copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 48.h),
                // Continue button (delayed)
                AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _buttonFadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 50.h * _buttonSlideAnimation.value),
                        child: ElevatedButton(
                          onPressed: widget.onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PanAfricanColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 48.w,
                              vertical: 16.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final Animation<double> animation;

  ConfettiPainter({
    required this.particles,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;

    for (final particle in particles) {
      final y = particle.y + (particle.speed * progress) / size.height;
      final x = particle.x + sin(particle.angle) * progress * 0.3;
      final rotation = particle.rotationSpeed * progress;

      if (y > 1.1) continue; // Particle has fallen off screen

      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}
