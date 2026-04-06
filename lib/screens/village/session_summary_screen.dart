import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../navigation/village_navigation.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class SessionSummaryScreen extends ConsumerStatefulWidget {
  const SessionSummaryScreen({super.key});

  @override
  ConsumerState<SessionSummaryScreen> createState() =>
      _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final AnimationController _heroFadeController;
  late final Animation<double> _heroFade;
  final _random = Random();

  static const _vocabCovered = [
    'Ọmọ — Child',
    'Ilé — House',
    'Omi — Water',
    'Àgbàlagbà — Elder',
    'Ẹ kú àárọ̀ — Good morning',
    'Ọjà — Market',
    'Bá mi sọ̀rọ̀ — Talk to me',
  ];

  static const _moments = [
    'Pronunciation challenge',
    'Group role-play',
    'Tonal drill win',
    'First Yoruba joke!',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _heroFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _heroFade = CurvedAnimation(
        parent: _heroFadeController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _heroFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              _buildCelebrationHero(cs),
              SizedBox(height: 24.h),
              _buildStatsBento(cs),
              SizedBox(height: 24.h),
              _buildVocabCovered(cs),
              SizedBox(height: 24.h),
              _buildSharedMoments(cs),
              SizedBox(height: 24.h),
              _buildAchievementBadge(cs),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                child: GriotGradientButton(
                  label: 'Finish & Exit',
                  icon: Icons.check_circle_rounded,
                  onPressed: () {
                    VillageNavigation.finishPracticeFlowToHub(context);
                  },
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationHero(ColorScheme cs) {
    return FadeTransition(
      opacity: _heroFade,
      child: SizedBox(
        height: 180.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(double.infinity, 180.h),
                  painter: _ConfettiPainter(
                    progress: _confettiController.value,
                    random: _random,
                    colors: [
                      cs.primary,
                      cs.primaryContainer,
                      cs.secondary,
                      cs.secondaryContainer,
                      ModernGriotColors.tertiaryContainer,
                    ],
                  ),
                );
              },
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64.r,
                  height: 64.r,
                  decoration: BoxDecoration(
                    gradient: ModernGriotGradients.signatureGradient,
                    shape: BoxShape.circle,
                    boxShadow: ModernGriotShadows.fab,
                  ),
                  child: Icon(Icons.celebration_rounded,
                      size: 32.sp, color: ModernGriotColors.onPrimary),
                ),
                SizedBox(height: 16.h),
                Text('Session Complete!',
                    style: ModernGriotTypography.headlineMedium(
                        context: context)),
                SizedBox(height: 4.h),
                Text('Great work on today\'s practice',
                    style: ModernGriotTypography.bodyMedium(
                        context: context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBento(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: GriotStatCard(
            icon: Icons.schedule_rounded,
            value: '18m',
            label: 'Duration',
            iconColor: cs.primary,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GriotStatCard(
            icon: Icons.translate_rounded,
            value: '7',
            label: 'Words Practiced',
            iconColor: cs.secondary,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GriotStatCard(
            icon: Icons.bolt_rounded,
            value: '+120',
            label: 'XP Earned',
            iconColor: ModernGriotColors.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildVocabCovered(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vocabulary Covered',
            style: ModernGriotTypography.titleMedium(context: context)),
        SizedBox(height: 12.h),
        GriotCard(
          surfaceLevel: 1,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.r),
          child: Column(
            children: _vocabCovered.map((word) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  children: [
                    Container(
                      width: 22.r,
                      height: 22.r,
                      decoration: BoxDecoration(
                        color: cs.secondary.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          size: 14.sp, color: cs.secondary),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(word,
                          style: ModernGriotTypography.bodyMedium(
                              context: context)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedMoments(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shared Moments',
            style: ModernGriotTypography.titleMedium(context: context)),
        SizedBox(height: 12.h),
        SizedBox(
          height: 110.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _moments.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (_, i) {
              return Container(
                width: 140.w,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: ModernGriotRadius.borderXl,
                  boxShadow: ModernGriotShadows.sm,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.photo_camera_rounded,
                          size: 28.sp,
                          color: cs.onSurfaceVariant.withAlpha(60)),
                    ),
                    Positioned(
                      left: 8.w,
                      bottom: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: cs.inverseSurface.withAlpha(180),
                          borderRadius: ModernGriotRadius.borderPill,
                        ),
                        child: Text(_moments[i],
                            style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: cs.onInverseSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ModernGriotColors.primaryContainer.withAlpha(40),
            ModernGriotColors.secondaryContainer.withAlpha(30),
          ],
        ),
        borderRadius: ModernGriotRadius.borderXl,
        border: Border.all(
            color: ModernGriotColors.primaryContainer.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              gradient: ModernGriotGradients.signatureGradient,
              borderRadius: ModernGriotRadius.borderLg,
              boxShadow: ModernGriotShadows.fab,
            ),
            child: Icon(Icons.workspace_premium_rounded,
                size: 28.sp, color: ModernGriotColors.onPrimary),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Silver Tongue',
                    style: ModernGriotTypography.titleMedium(
                        context: context)),
                SizedBox(height: 2.h),
                Text('Achievement unlocked! You completed 5 live sessions.',
                    style: ModernGriotTypography.bodySmall(
                        context: context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.random,
    required this.colors,
  });

  final double progress;
  final Random random;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final particleCount = 30;
    final rng = Random(42);

    for (int i = 0; i < particleCount; i++) {
      final x = rng.nextDouble() * size.width;
      final startY = -10.0;
      final endY = size.height + 20;
      final yOffset = rng.nextDouble() * 0.3;
      final currentY =
          startY + (endY - startY) * ((progress + yOffset).clamp(0.0, 1.0));
      final drift = sin(progress * pi * 3 + i) * 15;

      final paint = Paint()
        ..color = colors[i % colors.length]
            .withAlpha((200 * (1.0 - progress)).round())
        ..style = PaintingStyle.fill;

      final rectWidth = 4.0 + rng.nextDouble() * 4;
      final rectHeight = 6.0 + rng.nextDouble() * 6;

      canvas.save();
      canvas.translate(x + drift, currentY);
      canvas.rotate(progress * pi * 2 * (rng.nextBool() ? 1 : -1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: rectWidth, height: rectHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      progress != old.progress;
}
