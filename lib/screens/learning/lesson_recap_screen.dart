import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class LessonRecapScreen extends StatefulWidget {
  const LessonRecapScreen({super.key});

  @override
  State<LessonRecapScreen> createState() => _LessonRecapScreenState();
}

class _LessonRecapScreenState extends State<LessonRecapScreen>
    with TickerProviderStateMixin {
  late AnimationController _trophyCtrl;
  late Animation<double> _trophyBounce;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _trophyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _trophyBounce = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _trophyCtrl, curve: Curves.easeInOut),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _trophyCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(progress: _particleCtrl.value),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              children: [
                SizedBox(height: 16.h),
                Center(child: _buildTrophy(cs)),
                SizedBox(height: 20.h),
                Center(
                  child: Text(
                    'Lesson Mastery!',
                    style: ModernGriotTypography.displaySmall(
                      color: cs.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Text(
                    'Greetings & Introductions complete',
                    style: ModernGriotTypography.bodyLarge(),
                  ),
                ),
                SizedBox(height: 32.h),
                _buildStatsBento(),
                SizedBox(height: 32.h),
                _buildTotemReward(cs),
                SizedBox(height: 32.h),
                GriotGradientButton(
                  label: 'Claim Rewards',
                  icon: Icons.card_giftcard_rounded,
                  onPressed: () => HapticFeedback.mediumImpact(),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: Text(
                      'Back to Path',
                      style: ModernGriotTypography.labelLarge(
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophy(ColorScheme cs) {
    return AnimatedBuilder(
      animation: Listenable.merge([_trophyBounce, _glowAnim]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _trophyBounce.value),
          child: Container(
            width: 100.r,
            height: 100.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFCD116).withAlpha(
                    (100 * _glowAnim.value).round(),
                  ),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFCD116), Color(0xFFFF9800)],
                ),
                shape: BoxShape.circle,
                boxShadow: ModernGriotShadows.lg,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 48.sp,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsBento() {
    return Row(
      children: [
        Expanded(
          child: GriotStatCard(
            icon: Icons.bolt_rounded,
            value: '+85',
            label: 'XP Earned',
            iconColor: ModernGriotColors.primaryContainer,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GriotStatCard(
            icon: Icons.timer_rounded,
            value: '4:32',
            label: 'Focus Time',
            iconColor: ModernGriotColors.secondary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GriotStatCard(
            icon: Icons.check_circle_rounded,
            value: '92%',
            label: 'Accuracy',
            iconColor: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildTotemReward(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 18.sp, color: ModernGriotColors.primaryContainer),
              SizedBox(width: 8.w),
              Text(
                'New Totem Discovered',
                style: ModernGriotTypography.titleMedium(
                  color: ModernGriotColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 140.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ModernGriotColors.primary.withAlpha(15),
                      ModernGriotColors.primaryContainer.withAlpha(20),
                    ],
                  ),
                  borderRadius: ModernGriotRadius.borderXl,
                  border: Border.all(
                    color: ModernGriotColors.primaryContainer.withAlpha(
                      (60 * _glowAnim.value).round(),
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ModernGriotColors.primaryContainer.withAlpha(
                        (30 * _glowAnim.value).round(),
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 48.sp,
                      color: ModernGriotColors.primary.withAlpha(180),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Greetings Totem',
                      style: ModernGriotTypography.titleSmall(
                        color: ModernGriotColors.primary,
                      ),
                    ),
                    Text(
                      'Symbol of first words spoken',
                      style: ModernGriotTypography.bodySmall(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    const particleCount = 30;
    const colors = [
      Color(0xFFFCD116),
      Color(0xFFFF7A35),
      Color(0xFF9E3D00),
      Color(0xFF526124),
      Color(0xFFD6ED79),
    ];

    for (int i = 0; i < particleCount; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final y = (baseY + progress * size.height * speed) % size.height;
      final particleSize = 3.0 + rng.nextDouble() * 4.0;
      final alpha = (0.15 + rng.nextDouble() * 0.25);

      paint.color = colors[i % colors.length].withAlpha((alpha * 255).round());

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), particleSize / 2, paint);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * pi * 2 + i);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: particleSize,
              height: particleSize * 0.6),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
