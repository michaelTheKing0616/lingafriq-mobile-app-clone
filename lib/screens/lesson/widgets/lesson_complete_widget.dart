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

  Widget _buildStatsSheet(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
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
            style: PanAfricanTypography.headlineSmall(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24.h),

          // Stats grid
          Semantics(
            label: 'Lesson complete. XP earned: $totalXP. Accuracy: ${accuracy.toStringAsFixed(0)} percent. Time: ${_formatTime(timeTaken)}.',
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
                  color: PanAfricanColors.success,
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
                  color: PanAfricanColors.secondary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.local_fire_department,
                  label: 'Best Combo',
                  value: '$bestCombo',
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          if (comboBonus > 0) ...[
            SizedBox(height: 16.h),
            PanAfricanCard(
              padding: EdgeInsets.all(16.w),
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Combo Bonus: +$comboBonus XP',
                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                        color: Colors.orange,
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
                      icon: Icon(Icons.share_rounded, semanticLabel: 'Share'),
                      label: Text('Share'),
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
                    icon: Icons.arrow_forward_rounded,
                    backgroundColor: PanAfricanColors.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
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
            style: PanAfricanTypography.titleLarge(context).copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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
