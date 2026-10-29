import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import '../models/lesson_content.dart';

/// Lesson progress indicator: a single row of equal-width segments, one per
/// section (Duolingo-style exercise bar). Using [Expanded] for every segment
/// guarantees the bar can never overflow horizontally, no matter how many
/// sections a lesson has or how small the phone is.
class LessonProgressBar extends StatelessWidget {
  final List<LessonContent> sections;
  final int currentIndex;
  final double height;

  const LessonProgressBar({
    super.key,
    required this.sections,
    required this.currentIndex,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final percent = (((currentIndex + 1) / sections.length) * 100)
        .clamp(0, 100)
        .toInt();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final segmentHeight = height.h;

    return Semantics(
      label:
          'Lesson progress. Section ${currentIndex + 1} of ${sections.length}. $percent percent complete.',
      value: '$percent%',
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.lg,
          vertical: PanAfricanSpacing.xs,
        ),
        child: Row(
          children: List.generate(sections.length, (index) {
            final section = sections[index];
            final isCurrent = index == currentIndex;
            final isPastOrDone = index < currentIndex || section.isCompleted;

            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == sections.length - 1 ? 0 : PanAfricanSpacing.xxs,
                ),
                child: AnimatedContainer(
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: segmentHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
                    // Current segment gets a subtle two-tone brand accent so
                    // learners can spot "where I am" at a glance; completed
                    // segments are solid; upcoming segments are outlined only.
                    gradient: isCurrent
                        ? const LinearGradient(
                            colors: [
                              PanAfricanColors.primary,
                              PanAfricanColors.secondary,
                            ],
                          )
                        : null,
                    color: isCurrent
                        ? null
                        : isPastOrDone
                        ? PanAfricanColors.primary
                        : Colors.transparent,
                    border: isCurrent || isPastOrDone
                        ? null
                        : Border.all(
                            color: PanAfricanColors.borderLight,
                            width: 1.5,
                          ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
