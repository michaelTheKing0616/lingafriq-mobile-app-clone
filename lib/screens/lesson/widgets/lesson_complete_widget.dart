import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/animations/lesson_complete_animation.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Lesson completion celebration widget
class LessonCompleteWidget extends StatelessWidget {
  final int totalXP;
  final int comboBonus;
  final double accuracy;
  final int timeTaken;
  final int bestCombo;
  final VoidCallback onContinue;
  final VoidCallback? onShare;

  const LessonCompleteWidget({
    super.key,
    required this.totalXP,
    this.comboBonus = 0,
    required this.accuracy,
    required this.timeTaken,
    this.bestCombo = 0,
    required this.onContinue,
    this.onShare,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    // Celebration confetti + elastic pops are pure flourish — skip them for
    // learners who've asked their OS to reduce motion, and go straight to
    // the full, readable summary instead of gating it behind a tap.
    if (MediaQuery.disableAnimationsOf(context)) {
      return _buildReducedMotionComplete(context);
    }

    return LessonCompleteAnimation(
      xpGained: totalXP,
      comboBonus: comboBonus > 0 ? comboBonus : null,
      message: LingAfriqUxVoice.lessonCompleteMessage(accuracy),
      onContinue: () {
        // Show detailed stats before continuing
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildStatsSheet(context),
        );
      },
    );
  }

  /// Static (non-animated) completion view shown when reduced motion is on.
  Widget _buildReducedMotionComplete(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipOval(
                child: Container(
                  width: 88.w,
                  height: 88.w,
                  color: PanAfricanColors.primary,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Same brand motif already used behind PanAfricanHeader
                      // (see _AfricanPatternPainter in pan_african_app_bar.dart)
                      // -- a small, reused touch of LingAfriq's visual
                      // identity rather than a generic checkmark-in-a-circle.
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CelebrationMotifPainter(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 56.sp,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Lesson Complete!',
              textAlign: TextAlign.center,
              style: PanAfricanTypography.headlineSmall(
                context,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              LingAfriqUxVoice.lessonCompleteMessage(accuracy),
              textAlign: TextAlign.center,
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            _buildStatsAndActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSheet(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            // Same reused brand motif as the checkmark badge above and
            // PanAfricanHeader elsewhere -- a small, consistent touch of
            // LingAfriq's visual identity on the completion sheet, kept
            // faint enough not to compete with the stat cards on top.
            Positioned.fill(
              child: CustomPaint(
                painter: _CelebrationMotifPainter(
                  color: PanAfricanColors.primary.withValues(alpha: 0.035),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: PanAfricanColors.borderLight,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Title
                  Text(
                    'Lesson Complete!',
                    style: PanAfricanTypography.headlineSmall(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24.h),

                  _buildStatsAndActions(context),

                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stat cards, combo-bonus banner and Share/Continue actions — shared by
  /// both the animated bottom sheet and the reduced-motion static view.
  Widget _buildStatsAndActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats grid
        Semantics(
          label:
              'Lesson complete. XP earned: $totalXP. Accuracy: ${accuracy.toStringAsFixed(0)} percent. Time: ${_formatTime(timeTaken)}.',
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.star_rounded,
                  label: 'XP Earned',
                  value: '+$totalXP',
                  color: PanAfricanColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.percent_rounded,
                  label: 'Accuracy',
                  value: '${accuracy.toStringAsFixed(0)}%',
                  // Brand primary green reads as "success" and clears AA;
                  // the flat "success" token is too light on a light card.
                  color: PanAfricanColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.timer_rounded,
                label: 'Time',
                value: _formatTime(timeTaken),
                // Flat gold "secondary" fails AA on a light card; its
                // on-container token keeps the warm gold family readable.
                color: PanAfricanColors.onSecondaryContainer,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.local_fire_department,
                label: 'Best Combo',
                value: '$bestCombo',
                // tertiaryDark only clears the 3:1 "large text" floor
                // (~3.96:1) here; onTertiaryContainer clears normal-text
                // AA (~12.6:1) while staying in the warm orange family.
                color: PanAfricanColors.onTertiaryContainer,
              ),
            ),
          ],
        ),

        if (comboBonus > 0) ...[
          SizedBox(height: 16.h),
          PanAfricanCard(
            padding: EdgeInsets.all(16.w),
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Combo Bonus: +$comboBonus XP',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      // tertiaryDark only clears the 3:1 "large text"
                      // floor (~3.96:1) here, which is too risky for
                      // 14sp body text. onTertiaryContainer clears
                      // normal-text AA (~12.6:1) in the same warm family.
                      color: PanAfricanColors.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 24.h),

        // Action buttons
        Row(
          children: [
            if (onShare != null) ...[
              Expanded(
                child: Semantics(
                  label: 'Share your result',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(
                      Icons.share_rounded,
                      semanticLabel: 'Share',
                    ),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              flex: 2,
              child: Semantics(
                label: 'Continue to next lesson',
                button: true,
                child: PanAfricanButton(
                  onPressed: onContinue,
                  label: 'Continue',
                  // Mirror the arrow for RTL locales (Arabic, Darija).
                  icon: Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  backgroundColor: PanAfricanColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return PanAfricanCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: PanAfricanTypography.titleLarge(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: PanAfricanTypography.labelSmall(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Subtle diamond-lattice texture reused from the motif already used behind
/// `PanAfricanHeader` (see `_AfricanPatternPainter` in
/// `pan_african_app_bar.dart`) -- ties the lesson-complete celebration back
/// to LingAfriq's existing visual identity instead of a generic template
/// celebration. The algorithm is copied verbatim (rather than imported,
/// since the original is private to that file) so the motif stays visually
/// identical everywhere it already appears in the app.
class _CelebrationMotifPainter extends CustomPainter {
  final Color color;

  _CelebrationMotifPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 40.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final path = Path()
          ..moveTo(x, y + spacing / 2)
          ..lineTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
