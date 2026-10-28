import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/widgets/learning_path/learning_path_painter.dart';
import 'package:lingafriq/widgets/learning_path/path_checkpoint_card.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_node_widget.dart';
import 'package:lingafriq/widgets/learning_path/path_scene_art.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';
import 'package:lingafriq/widgets/learning_path/polie_path_mascot.dart';

/// One Candy Crush-style journey stop: clay road, sine node, side scenery,
/// and Polie standing beside the current lesson.
class PathJourneyNodeRow extends StatelessWidget {
  const PathJourneyNodeRow({
    super.key,
    required this.lesson,
    required this.lessonIndex,
    required this.state,
    required this.unitOrdinal,
    required this.languageKey,
    required this.reducedMotion,
    required this.lowEndStatic,
    required this.isRtl,
    required this.savedOffline,
    required this.totalLessons,
    required this.parallaxScroll,
    required this.showSideScenery,
    this.onTap,
    this.polieMood = PoliePathMood.pointUp,
  });

  final Lesson lesson;
  final int lessonIndex;
  final PathNodeVisualState state;
  final int unitOrdinal;
  final String languageKey;
  final bool reducedMotion;
  final bool lowEndStatic;
  final bool isRtl;
  final bool savedOffline;
  final int totalLessons;
  final double parallaxScroll;
  final bool showSideScenery;
  final VoidCallback? onTap;
  final PoliePathMood polieMood;

  @override
  Widget build(BuildContext context) {
    final isCheckpoint = PathLayout.isCheckpoint(lessonIndex);
    if (isCheckpoint) {
      return PathCheckpointCard(
        lessonTitle: lesson.name,
        nodeNumber: lessonIndex + 1,
        state: state,
        savedOffline: savedOffline,
        onTap: onTap,
      );
    }

    final dx = PathLayout.horizontalOffsetForIndex(lessonIndex);
    final prevDx = lessonIndex > 0
        ? PathLayout.horizontalOffsetForIndex(lessonIndex - 1)
        : dx;
    final rtlSign = isRtl ? -1.0 : 1.0;
    final traveled = state != PathNodeVisualState.locked;
    final place = PathLayout.placeThemeForUnit(unitOrdinal);
    final isCurrent = state == PathNodeVisualState.current;
    final sceneryEnd = PathLayout.sceneryOnEndSide(lessonIndex);

    return SizedBox(
      height: PathLayout.nodeRowExtent.h + (isCurrent ? 28.h : 8.h),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    pathPlaceWashColor(
                      place,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ).withValues(alpha: 0.35),
                    Colors.transparent,
                    pathPlaceWashColor(
                      place,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ).withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: PathRowConnector(
              fromLane: 0,
              toLane: 0,
              fromOffsetX: prevDx.w * rtlSign,
              toOffsetX: dx.w * rtlSign,
              traveled: traveled,
              clayRoad: true,
            ),
          ),
          if (showSideScenery && !lowEndStatic)
            Positioned(
              top: 4.h,
              left: sceneryEnd ? null : 4.w,
              right: sceneryEnd ? 4.w : null,
              child: Transform.translate(
                offset: Offset(
                  0,
                  -parallaxScroll * PathLayout.sceneryParallax * 0.15,
                ),
                child: SizedBox(
                  width: 72.w,
                  height: 72.h,
                  child: Opacity(
                    opacity: state == PathNodeVisualState.locked ? 0.45 : 0.95,
                    child: PathSceneArtSlot(
                      languageKey: languageKey,
                      unitIndex: unitOrdinal + lessonIndex,
                      dimmed: state == PathNodeVisualState.locked,
                      bundleLicensed: true,
                      reducedMotion: reducedMotion || lowEndStatic,
                      preferRive: !lowEndStatic,
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(dx.w * rtlSign, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCurrent && !sceneryEnd)
                    Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: _BesidePolie(
                        mood: polieMood,
                        reducedMotion: reducedMotion || lowEndStatic,
                      ),
                    ),
                  PathNodeWidget(
                    lesson: lesson,
                    state: state,
                    index: lessonIndex,
                    size: PathLayout.nodeSize,
                    studyLanguageKey: languageKey,
                    reducedMotion: reducedMotion || lowEndStatic,
                    totalLessons: totalLessons,
                    savedOffline: savedOffline,
                    isCheckpoint: false,
                    playNowFallback: 'Start',
                    onTap: onTap,
                  ),
                  if (isCurrent && sceneryEnd)
                    Padding(
                      padding: EdgeInsets.only(left: 6.w),
                      child: _BesidePolie(
                        mood: polieMood,
                        reducedMotion: reducedMotion || lowEndStatic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BesidePolie extends StatelessWidget {
  const _BesidePolie({
    required this.mood,
    required this.reducedMotion,
  });

  final PoliePathMood mood;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56.w,
      height: 68.h,
      child: PoliePathMascot(
        mood: mood,
        reducedMotion: reducedMotion,
        rivAssetPresent: true,
        compact: true,
        polieLabel: 'Polie',
      ),
    );
  }
}
