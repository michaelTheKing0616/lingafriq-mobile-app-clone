import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/widgets/learning_path/learning_path_painter.dart';
import 'package:lingafriq/widgets/learning_path/path_checkpoint_card.dart';
import 'package:lingafriq/widgets/learning_path/path_motion.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_node_widget.dart';
import 'package:lingafriq/widgets/learning_path/path_scene_art.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';
import 'package:lingafriq/widgets/learning_path/polie_path_mascot.dart';

/// One Candy Crush-style journey stop: clay road, sine node, side scenery,
/// and Polie standing beside the current lesson only.
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
    this.playTrailDraw = false,
    this.playDoneFill = false,
    this.playPolieHop = false,
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

  /// Completion choreography: dotted trail draws toward this row (400 ms).
  final bool playTrailDraw;

  /// Completion choreography: gold fill on a newly done node (300 ms).
  final bool playDoneFill;

  /// Completion choreography: Polie hops onto current (500 ms arc).
  final bool playPolieHop;

  @override
  Widget build(BuildContext context) {
    final isCheckpoint = PathLayout.isCheckpoint(lessonIndex);
    final isCurrent = state == PathNodeVisualState.current;
    if (isCheckpoint) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          PathCheckpointCard(
            lessonTitle: lesson.name,
            nodeNumber: lessonIndex + 1,
            state: state,
            unitOrdinal: unitOrdinal,
            savedOffline: savedOffline,
            onTap: onTap,
          ),
          if (isCurrent)
            PositionedDirectional(
              end: 10.w,
              bottom: -6.h,
              child: _BesidePolie(
                mood: polieMood,
                reducedMotion: reducedMotion || lowEndStatic,
                playHop: playPolieHop,
              ),
            ),
        ],
      );
    }

    final dx = PathLayout.horizontalOffsetForIndex(lessonIndex);
    final prevDx = lessonIndex > 0
        ? PathLayout.horizontalOffsetForIndex(lessonIndex - 1)
        : dx;
    final rtlSign = isRtl ? -1.0 : 1.0;
    final traveled = state != PathNodeVisualState.locked;
    final place = PathLayout.placeThemeForUnit(unitOrdinal);
    final sceneryEnd = PathLayout.sceneryOnEndSide(lessonIndex);

    final row = SizedBox(
      height: PathLayout.nodeRowExtent.h + (isCurrent ? 36.h : 8.h),
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
                    ).withValues(alpha: 0.45),
                    Colors.transparent,
                    pathPlaceWashColor(
                      place,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ).withValues(alpha: 0.45),
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
              traveled: traveled && !playTrailDraw,
              clayRoad: true,
              drawProgress: playTrailDraw ? null : (traveled ? 1.0 : 0.0),
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
                  -parallaxScroll * PathLayout.sceneryParallax,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent && !sceneryEnd)
                        Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: _BesidePolie(
                            mood: polieMood,
                            reducedMotion: reducedMotion || lowEndStatic,
                            playHop: playPolieHop,
                          ),
                        ),
                      Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          if (isCurrent)
                            Positioned(
                              bottom: -2.h,
                              child: PathCurrentPedestal(
                                size: PathLayout.nodeSize.w,
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
                            playNowFallback: 'Begin',
                            playDoneFill: playDoneFill,
                            onTap: onTap,
                          ),
                        ],
                      ),
                      if (isCurrent && sceneryEnd)
                        Padding(
                          padding: EdgeInsets.only(left: 6.w),
                          child: _BesidePolie(
                            mood: polieMood,
                            reducedMotion: reducedMotion || lowEndStatic,
                            playHop: playPolieHop,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!playTrailDraw) return row;
    return PathTrailDrawOverlay(
      play: true,
      reducedMotion: reducedMotion || lowEndStatic,
      child: row,
    );
  }
}

class _BesidePolie extends StatelessWidget {
  const _BesidePolie({
    required this.mood,
    required this.reducedMotion,
    this.playHop = false,
  });

  final PoliePathMood mood;
  final bool reducedMotion;
  final bool playHop;

  @override
  Widget build(BuildContext context) {
    final mascot = SizedBox(
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
    if (reducedMotion && !playHop) return mascot;
    return TweenAnimationBuilder<double>(
      key: ValueKey('polie-hop-$playHop'),
      tween: Tween(begin: playHop || !reducedMotion ? 0.0 : 1.0, end: 1),
      duration: PathMotion.resolve(
        PathMotion.polieHop,
        reducedMotion: reducedMotion,
      ),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final arc = (1 - t) * 28.h;
        final lift = (4 * t * (1 - t)) * 18.h;
        return Transform.translate(
          offset: Offset(arc * 0.35, arc - lift),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: mascot,
    );
  }
}
