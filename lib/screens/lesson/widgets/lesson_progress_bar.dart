import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import '../models/lesson_content.dart';

/// Progress bar showing section completion status
class LessonProgressBar extends StatelessWidget {
  final List<LessonContent> sections;
  final int currentIndex;
  final double height;

  const LessonProgressBar({
    Key? key,
    required this.sections,
    required this.currentIndex,
    this.height = 6.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final progress = ((currentIndex + 1) / sections.length).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();
    return Semantics(
      label: 'Lesson progress. Section ${currentIndex + 1} of ${sections.length}. $percent percent complete.',
      value: '$percent%',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        child: Column(
          children: [
            // Progress bar
            PanAfricanProgressBar(
            progress: progress,
            color: PanAfricanColors.primary,
            height: height.h,
          ),
          SizedBox(height: 12.h),
          // Section indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(sections.length, (index) {
              final section = sections[index];
              final isCurrent = index == currentIndex;
              final isCompleted = section.isCompleted;
              final isPast = index < currentIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: isCurrent ? 24.w : 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  color: isCurrent
                      ? PanAfricanColors.primary
                      : isCompleted || isPast
                          ? PanAfricanColors.primary.withOpacity(0.5)
                          : PanAfricanColors.borderLight,
                ),
              );
            }),
          ),
        ],
      ),
    ),
    );
  }
}
