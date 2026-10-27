/// Path node visual states for the F-007 lesson map (P7-951).
enum PathNodeVisualState {
  locked,
  current,
  done,
  reviewDue,
  skipped,
}

/// Copy keys (resolved in UI / ARB elsewhere).
const String kPathPlayNowKey = 'learn.f_007.play_now';
const String kPathReviewDueKey = 'learn.f_007.review_due';

/// Minimum tap target per AC7 (logical dp before ScreenUtil).
const double kPathNodeMinTapTargetDp = 48;

/// Rive `nodeState` enum names from path_node.contract.json (v3).
enum PathNodeRiveState { done, current, locked, reviewDue }

/// Inputs for resolving a single lesson node on the path.
class PathLessonProgress {
  const PathLessonProgress({
    required this.lessonId,
    required this.title,
    required this.index,
    required this.isCompleted,
    this.isPerfectScore = false,
  });

  final String lessonId;
  final String title;
  final int index;
  final bool isCompleted;
  final bool isPerfectScore;
}

/// Pacing / FSRS overlays (P7-949 + scheduler, not calendar dates).
class PathPacingOverlay {
  const PathPacingOverlay({
    this.reachableLessonIds = const {},
    this.skippedLessonIds = const {},
    this.reviewDueLessonIds = const {},
  });

  final Set<String> reachableLessonIds;
  final Set<String> skippedLessonIds;
  final Set<String> reviewDueLessonIds;
}

/// Resolves [PathNodeVisualState] for one lesson row.
PathNodeVisualState resolvePathNodeState({
  required PathLessonProgress lesson,
  required int? activeIndex,
  required PathPacingOverlay pacing,
  required bool sequentiallyUnlocked,
}) {
  final id = lesson.lessonId;

  if (pacing.skippedLessonIds.contains(id)) {
    return PathNodeVisualState.skipped;
  }

  if (lesson.isCompleted) {
    if (pacing.reviewDueLessonIds.contains(id)) {
      return PathNodeVisualState.reviewDue;
    }
    return PathNodeVisualState.done;
  }

  final pacingReachable = pacing.reachableLessonIds.contains(id);

  if (activeIndex == lesson.index) {
    return PathNodeVisualState.current;
  }

  if (!sequentiallyUnlocked && !pacingReachable) {
    return PathNodeVisualState.locked;
  }

  if (sequentiallyUnlocked || pacingReachable) {
    if (activeIndex != null && lesson.index < activeIndex) {
      return PathNodeVisualState.done;
    }
    return PathNodeVisualState.current;
  }

  return PathNodeVisualState.locked;
}

/// Vertical layout: first lesson at the bottom, later lessons above (AC1).
double pathNodeYFromBottom({
  required int index,
  required int lessonCount,
  required double nodeSpacing,
  required double bottomInset,
}) {
  assert(index >= 0 && index < lessonCount);
  final fromBottom = bottomInset + index * nodeSpacing;
  final totalHeight = bottomInset + (lessonCount - 1) * nodeSpacing + bottomInset;
  return totalHeight - fromBottom;
}

/// Maps visual state to Rive contract + strings (AC8).
class PathNodeRiveBinding {
  PathNodeRiveBinding({
    required this.state,
    required this.label,
    required this.ctaText,
    required this.reducedMotion,
    this.fireUnlock = false,
  });

  final PathNodeRiveState state;
  final String label;
  final String ctaText;
  final bool reducedMotion;
  final bool fireUnlock;

  factory PathNodeRiveBinding.fromVisual({
    required PathNodeVisualState visual,
    required int nodeNumber,
    required String lessonTitle,
    required String playNowLabel,
    required bool reducedMotion,
    required bool playUnlockThisFrame,
  }) {
    final label = '$nodeNumber';
    final cta = lessonTitle.isNotEmpty ? lessonTitle : playNowLabel;
    final riveState = switch (visual) {
      PathNodeVisualState.done => PathNodeRiveState.done,
      PathNodeVisualState.current => PathNodeRiveState.current,
      PathNodeVisualState.reviewDue => PathNodeRiveState.reviewDue,
      PathNodeVisualState.skipped => PathNodeRiveState.done,
      PathNodeVisualState.locked => PathNodeRiveState.locked,
    };
    final unlock = playUnlockThisFrame && visual == PathNodeVisualState.current;
    return PathNodeRiveBinding(
      state: riveState,
      label: label,
      ctaText: cta,
      reducedMotion: reducedMotion,
      fireUnlock: unlock,
    );
  }
}

String pathNodeSemanticsLabel({
  required int nodeNumber,
  required String title,
  required PathNodeVisualState state,
  required String reviewDueLabel,
}) {
  final stateText = switch (state) {
    PathNodeVisualState.locked => 'Locked',
    PathNodeVisualState.current => 'Current lesson',
    PathNodeVisualState.done => 'Completed',
    PathNodeVisualState.reviewDue => reviewDueLabel,
    PathNodeVisualState.skipped => 'Skipped ahead',
  };
  return 'Lesson $nodeNumber: $title. $stateText.';
}
