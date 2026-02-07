import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/pan_african_design_system.dart';

/// A beautiful achievement celebration modal with confetti effect
/// Shows when user unlocks badges, completes milestones, or achieves special goals
class AchievementCelebrationModal extends StatefulWidget {
  final String title;
  final String description;
  final String iconEmoji;
  final int xpReward;
  final int currencyReward;
  final String currencyName;
  final VoidCallback onDismiss;
  final Color? accentColor;

  const AchievementCelebrationModal({
    Key? key,
    required this.title,
    required this.description,
    required this.iconEmoji,
    this.xpReward = 0,
    this.currencyReward = 0,
    this.currencyName = 'Cowries',
    required this.onDismiss,
    this.accentColor,
  }) : super(key: key);

  /// Show the modal as an overlay
  static void show({
    required BuildContext context,
    required String title,
    required String description,
    required String iconEmoji,
    int xpReward = 0,
    int currencyReward = 0,
    String currencyName = 'Cowries',
    Color? accentColor,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Achievement',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AchievementCelebrationModal(
          title: title,
          description: description,
          iconEmoji: iconEmoji,
          xpReward: xpReward,
          currencyReward: currencyReward,
          currencyName: currencyName,
          accentColor: accentColor,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AchievementCelebrationModal> createState() =>
      _AchievementCelebrationModalState();
}

class _AchievementCelebrationModalState
    extends State<AchievementCelebrationModal>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<_ConfettiParticle> _confetti = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      _confetti.add(_ConfettiParticle(
        color: _getConfettiColor(),
        startX: _random.nextDouble(),
        startY: _random.nextDouble() * 0.3 - 0.3,
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * pi * 2,
        velocity: _random.nextDouble() * 0.5 + 0.3,
      ));
    }

    _confettiController.forward();

    // Pulse animation for icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Color _getConfettiColor() {
    final colors = [
      PanAfricanColors.secondary,
      PanAfricanColors.tertiary,
      PanAfricanColors.primary,
      Colors.red,
      Colors.blue,
      Colors.purple,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.accentColor ?? PanAfricanColors.secondary;

    return Stack(
      children: [
        // Confetti overlay
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return CustomPaint(
              painter: _ConfettiPainter(
                confetti: _confetti,
                progress: _confettiController.value,
              ),
              size: MediaQuery.of(context).size,
            );
          },
        ),

        // Main content
        Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Container(
              constraints: BoxConstraints(maxWidth: 350.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1A2530),
                          const Color(0xFF0D1B2A),
                        ]
                      : [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: accentColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top decoration
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.2),
                          accentColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icon with pulse animation
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      accentColor,
                                      accentColor.withOpacity(0.7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.iconEmoji,
                                  style: TextStyle(fontSize: 48.sp),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      children: [
                        // Title
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),

                        // Description
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Rewards
                        if (widget.xpReward > 0 || widget.currencyReward > 0) ...[
                          SizedBox(height: 20.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accentColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.xpReward > 0) ...[
                                  Icon(
                                    Icons.star_rounded,
                                    color: PanAfricanColors.secondary,
                                    size: 24.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '+${widget.xpReward} XP',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: PanAfricanColors.secondary,
                                    ),
                                  ),
                                ],
                                if (widget.xpReward > 0 && widget.currencyReward > 0)
                                  SizedBox(width: 20.w),
                                if (widget.currencyReward > 0) ...[
                                  Text(
                                    '🐚',
                                    style: TextStyle(fontSize: 20.sp),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '+${widget.currencyReward}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: PanAfricanColors.tertiary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 24.h),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: widget.onDismiss,
                            style: FilledButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Awesome!',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double size;
  final double rotation;
  final double velocity;

  _ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.size,
    required this.rotation,
    required this.velocity,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in confetti) {
      final paint = Paint()..color = particle.color.withOpacity(1 - progress);

      final x = particle.startX * size.width;
      final y =
          (particle.startY + particle.velocity * progress * 2) * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * pi * 4);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Show badge unlock celebration
void showBadgeUnlockCelebration(
  BuildContext context, {
  required String badgeName,
  required String badgeDescription,
  required String badgeEmoji,
  int xpReward = 50,
  int currencyReward = 25,
}) {
  AchievementCelebrationModal.show(
    context: context,
    title: 'Badge Unlocked!',
    description: '$badgeName\n\n$badgeDescription',
    iconEmoji: badgeEmoji,
    xpReward: xpReward,
    currencyReward: currencyReward,
    accentColor: PanAfricanColors.secondary,
  );
}

/// Show level up celebration
void showLevelUpCelebration(
  BuildContext context, {
  required int newLevel,
  required String levelTitle,
  int bonusXP = 100,
  int bonusCurrency = 50,
}) {
  AchievementCelebrationModal.show(
    context: context,
    title: 'Level Up!',
    description: 'Congratulations! You\'ve reached Level $newLevel\n"$levelTitle"',
    iconEmoji: '🌟',
    xpReward: bonusXP,
    currencyReward: bonusCurrency,
    accentColor: PanAfricanColors.primary,
  );
}

/// Show streak milestone celebration
void showStreakMilestoneCelebration(
  BuildContext context, {
  required int streakDays,
  int bonusXP = 100,
  int bonusCurrency = 50,
}) {
  AchievementCelebrationModal.show(
    context: context,
    title: '$streakDays Day Streak!',
    description: 'Incredible dedication! You\'ve been learning for $streakDays days straight!',
    iconEmoji: '🔥',
    xpReward: bonusXP,
    currencyReward: bonusCurrency,
    accentColor: PanAfricanColors.tertiary,
  );
}

