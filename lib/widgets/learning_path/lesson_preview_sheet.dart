import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

const String kPathPreviewSheetKey = 'learn.f_007.preview';

/// Lesson goal, time, XP, and start/review actions (P7-952 AC3).
class LessonPreviewSheet extends StatelessWidget {
  const LessonPreviewSheet({
    super.key,
    required this.lesson,
    required this.goal,
    required this.estimatedMinutes,
    required this.xpReward,
    required this.isReview,
    required this.onPrimaryAction,
    this.lessonNumber,
    this.totalLessons,
  });

  final Lesson lesson;
  final String goal;
  final int estimatedMinutes;
  final int xpReward;
  final bool isReview;
  final VoidCallback onPrimaryAction;
  final int? lessonNumber;
  final int? totalLessons;

  static Future<void> show(
    BuildContext context, {
    required Lesson lesson,
    required String goal,
    required int estimatedMinutes,
    required int xpReward,
    required bool isReview,
    required VoidCallback onPrimaryAction,
    int? lessonNumber,
    int? totalLessons,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => LessonPreviewSheet(
        lesson: lesson,
        goal: goal,
        estimatedMinutes: estimatedMinutes,
        xpReward: xpReward,
        isReview: isReview,
        lessonNumber: lessonNumber,
        totalLessons: totalLessons,
        onPrimaryAction: () {
          Navigator.of(ctx).pop();
          onPrimaryAction();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryLabel = isReview ? 'Review' : 'Start';
    final progressLabel = (lessonNumber != null &&
            totalLessons != null &&
            totalLessons! > 0)
        ? 'Lesson $lessonNumber of $totalLessons'
        : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (progressLabel != null) ...[
            Text(
              progressLabel,
              style: ModernGriotTypography.labelLarge(context: context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
          ],
          Text(
            lesson.name.isNotEmpty ? lesson.name : 'Lesson',
            style: ModernGriotTypography.titleLarge(context: context),
          ),
          SizedBox(height: 12.h),
          Text(
            goal,
            style: ModernGriotTypography.bodyLarge(context: context),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _MetricChip(
                icon: Icons.schedule_outlined,
                label: '$estimatedMinutes min',
              ),
              SizedBox(width: 12.w),
              _MetricChip(
                icon: Icons.bolt_outlined,
                label: '$xpReward XP',
              ),
            ],
          ),
          SizedBox(height: 24.h),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PathBrandColors.gold,
              foregroundColor: const Color(0xFF3A1500),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              minimumSize: Size.fromHeight(48.h),
            ),
            onPressed: onPrimaryAction,
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: cs.onSurfaceVariant),
          SizedBox(width: 6.w),
          Text(label, style: ModernGriotTypography.labelLarge(context: context)),
        ],
      ),
    );
  }
}

/// Preview copy helpers shared with tests.
int estimatePathLessonMinutes(Lesson lesson) {
  final activities = lesson.count > 0 ? lesson.count : 1;
  return (activities * 3).clamp(3, 45);
}

int estimatePathLessonXp(Lesson lesson) {
  final activities = lesson.count > 0 ? lesson.count : 1;
  return activities * 10;
}

String pathLessonGoal(Lesson lesson) {
  if (lesson.congrats.isNotEmpty) {
    return lesson.congrats;
  }
  if (lesson.name.isNotEmpty) {
    return lesson.name;
  }
  return 'Complete this section';
}

bool pathLessonIsReview(PathNodeVisualState state) {
  return state == PathNodeVisualState.reviewDue ||
      state == PathNodeVisualState.done;
}
