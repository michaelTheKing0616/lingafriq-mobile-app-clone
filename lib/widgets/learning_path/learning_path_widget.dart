import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'learning_path_painter.dart';
import 'path_node_state.dart';
import 'path_node_widget.dart';

/// Scrollable learning path: vertical zig-zag, first lesson at the bottom (P7-951).
class LearningPathWidget extends StatelessWidget {
  final List<Lesson> lessons;
  final int? activeIndex;
  final ScrollController? scrollController;
  final double nodeSize;
  final double nodeSpacing;
  final double horizontalPadding;
  final PathPacingOverlay pacing;
  final bool reducedMotion;
  final String playNowLabel;
  final String reviewDueLabel;
  final String? studyLanguageKey;
  final Widget? learnerAvatar;
  final bool Function(int index, Lesson lesson)? sequentiallyUnlocked;

  const LearningPathWidget({
    super.key,
    required this.lessons,
    required this.activeIndex,
    this.scrollController,
    this.nodeSize = 64,
    this.nodeSpacing = 120,
    this.horizontalPadding = 80,
    this.pacing = const PathPacingOverlay(),
    this.reducedMotion = false,
    this.playNowLabel = 'Play now',
    this.reviewDueLabel = 'Review due',
    this.studyLanguageKey,
    this.learnerAvatar,
    this.sequentiallyUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final nodeRadius = nodeSize / 2;
    final leftX = horizontalPadding + nodeRadius;
    final rightX = screenWidth - horizontalPadding - nodeRadius;
    final centerX = screenWidth / 2;
    const bottomInset = 48.0;

    final positions = _calculateNodePositions(
      lessons.length,
      nodeSpacing,
      leftX,
      rightX,
      centerX,
      bottomInset,
    );

    final contentHeight =
        bottomInset + (lessons.length - 1) * nodeSpacing + bottomInset + nodeSize;

    return SingleChildScrollView(
      controller: scrollController,
      reverse: true,
      child: SizedBox(
        height: contentHeight.h,
        width: screenWidth,
        child: CustomPaint(
          painter: LearningPathPainter(
            nodePositions: positions,
            activeIndex: activeIndex ?? 0,
            primaryColor: PanAfricanColors.primary,
            inactiveColor: PanAfricanColors.neutralMedium.withOpacity(0.3),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: _buildNodes(
              context,
              lessons,
              positions,
            ),
          ),
        ),
      ),
    );
  }

  List<PathNodePosition> _calculateNodePositions(
    int nodeCount,
    double spacing,
    double leftX,
    double rightX,
    double centerX,
    double bottomInset,
  ) {
    final positions = <PathNodePosition>[];

    for (int i = 0; i < nodeCount; i++) {
      double x;
      if (i == 0) {
        x = centerX;
      } else {
        final isEven = i % 2 == 0;
        x = isEven ? rightX : leftX;
      }

      final y = pathNodeYFromBottom(
        index: i,
        lessonCount: nodeCount,
        nodeSpacing: spacing,
        bottomInset: bottomInset,
      );
      positions.add(PathNodePosition(x, y.h));
    }

    return positions;
  }

  List<Widget> _buildNodes(
    BuildContext context,
    List<Lesson> lessons,
    List<PathNodePosition> positions,
  ) {
    final nodes = <Widget>[];

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final seqUnlocked = sequentiallyUnlocked?.call(i, lesson) ??
          (i == 0 ||
              (lessons[i - 1].count > 0 &&
                  lessons[i - 1].completed >= lessons[i - 1].count));

      final progress = PathLessonProgress(
        lessonId: lesson.id.toString(),
        title: lesson.name,
        index: i,
        isCompleted: lesson.count > 0 && lesson.completed >= lesson.count,
        isPerfectScore:
            lesson.count > 0 && lesson.score >= lesson.count * 10,
      );

      final state = resolvePathNodeState(
        lesson: progress,
        activeIndex: activeIndex,
        pacing: pacing,
        sequentiallyUnlocked: seqUnlocked,
      );

      final pos = positions[i];
      final node = PathNodeWidget(
        lesson: lesson,
        state: state,
        index: i,
        size: nodeSize,
        studyLanguageKey: studyLanguageKey,
        reducedMotion: reducedMotion,
        reviewDueLabel: reviewDueLabel,
        playNowFallback: playNowLabel,
      );

      nodes.add(
        Positioned(
          left: pos.x - nodeSize.w / 2,
          top: pos.y - nodeSize.w / 2,
          child: node,
        ),
      );

      if (state == PathNodeVisualState.current) {
        nodes.add(
          Positioned(
            left: pos.x + nodeSize.w * 0.55,
            top: pos.y - 20.h,
            child: _PlayNowPill(
              title: lesson.name,
              playNowLabel: playNowLabel,
            ),
          ),
        );
        if (learnerAvatar != null) {
          nodes.add(
            Positioned(
              left: pos.x - nodeSize.w * 1.35,
              top: pos.y - nodeSize.w * 0.35,
              child: learnerAvatar!,
            ),
          );
        }
      }
    }

    return nodes;
  }
}

class _PlayNowPill extends StatelessWidget {
  const _PlayNowPill({
    required this.title,
    required this.playNowLabel,
  });

  final String title;
  final String playNowLabel;

  @override
  Widget build(BuildContext context) {
    final label = title.isNotEmpty ? title : playNowLabel;
    return Semantics(
      label: '$playNowLabel: $label',
      child: Container(
        constraints: BoxConstraints(maxWidth: 180.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: PanAfricanColors.primary,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: PanAfricanTypography.labelLarge(context).copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
