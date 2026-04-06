import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class GameMasteryResultsScreen extends ConsumerStatefulWidget {
  const GameMasteryResultsScreen({
    super.key,
    required this.masteryPercent,
    required this.xpEarned,
    required this.streakCount,
    required this.coinsEarned,
    required this.levelProgress,
    required this.currentLevel,
    required this.onNextChallenge,
    this.onReviewMistakes,
  });

  final int masteryPercent;
  final int xpEarned;
  final int streakCount;
  final int coinsEarned;
  final double levelProgress;
  final int currentLevel;
  final VoidCallback onNextChallenge;
  final VoidCallback? onReviewMistakes;

  @override
  ConsumerState<GameMasteryResultsScreen> createState() =>
      _GameMasteryResultsScreenState();
}

class _GameMasteryResultsScreenState
    extends ConsumerState<GameMasteryResultsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _starController;
  late final Animation<double> _starBounce;
  late final AnimationController _particleController;
  final List<_Particle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _starBounce = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    for (var i = 0; i < 24; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 4 + 2,
        speed: _rng.nextDouble() * 0.4 + 0.1,
        phase: _rng.nextDouble() * 2 * pi,
        color: [
          ModernGriotColors.primaryContainer,
          ModernGriotColors.primary,
          ModernGriotColors.onPrimary,
          ModernGriotColors.secondaryContainer,
        ][_rng.nextInt(4)],
      ));
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ModernGriotColors.primaryContainer.withAlpha(40),
                    cs.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 24.h),
                  _CelebrationHero(bounceAnim: _starBounce),
                  SizedBox(height: 24.h),
                  GriotMasteryRing(
                    value: widget.masteryPercent / 100,
                    size: 180,
                    strokeWidth: 14,
                    label: 'Mastery',
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    children: [
                      Expanded(
                        child: GriotStatCard(
                          icon: Icons.star_rounded,
                          iconColor: ModernGriotColors.primaryContainer,
                          value: '+${widget.xpEarned}',
                          label: 'XP Earned',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GriotStatCard(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFE65100),
                          value: '${widget.streakCount}',
                          label: 'Streak',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GriotStatCard(
                          icon: Icons.paid_rounded,
                          iconColor: const Color(0xFFFFC107),
                          value: '+${widget.coinsEarned}',
                          label: 'Coins',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),
                  _LevelProgressSection(
                    progress: widget.levelProgress,
                    level: widget.currentLevel,
                  ),
                  SizedBox(height: 36.h),
                  GriotGradientButton(
                    label: 'Next Challenge',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: widget.onNextChallenge,
                  ),
                  SizedBox(height: 10.h),
                  GriotSecondaryButton(
                    label: 'Review Mistakes',
                    icon: Icons.replay_rounded,
                    onPressed: widget.onReviewMistakes,
                  ),
                  SizedBox(height: safePadding.bottom + 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationHero extends StatelessWidget {
  const _CelebrationHero({required this.bounceAnim});
  final Animation<double> bounceAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bounceAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, bounceAnim.value),
        child: child,
      ),
      child: Container(
        width: 80.r,
        height: 80.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              ModernGriotColors.primaryContainer.withAlpha(180),
              ModernGriotColors.primaryContainer.withAlpha(40),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.star_rounded,
            size: 44.sp,
            color: ModernGriotColors.primaryContainer,
          ),
        ),
      ),
    );
  }
}

class _LevelProgressSection extends StatelessWidget {
  const _LevelProgressSection({required this.progress, required this.level});
  final double progress;
  final int level;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: ModernGriotTypography.titleMedium(context: context, color: cs.onSurface),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: ModernGriotTypography.labelLarge(context: context, color: cs.primary),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          GriotProgressBar(value: progress, showGlowTip: true),
        ],
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.color,
  });
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;
  final Color color;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final dx = p.x * size.width + sin(t * 2 * pi) * 20;
      final dy = (p.y - t * 0.3) % 1.0 * size.height;
      final opacity = (1.0 - (t - 0.5).abs() * 2).clamp(0.15, 0.6);

      canvas.drawCircle(
        Offset(dx, dy),
        p.size,
        Paint()..color = p.color.withAlpha((opacity * 255).round()),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
