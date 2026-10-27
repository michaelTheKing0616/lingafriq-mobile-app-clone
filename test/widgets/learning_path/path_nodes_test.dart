import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';

void main() {
  group('resolvePathNodeState', () {
    test('locks future lessons', () {
      final lesson = PathLessonProgress(
        lessonId: 'l2',
        title: 'Greetings',
        index: 2,
        isCompleted: false,
      );
      expect(
        resolvePathNodeState(
          lesson: lesson,
          activeIndex: 1,
          pacing: const PathPacingOverlay(),
          sequentiallyUnlocked: false,
        ),
        PathNodeVisualState.locked,
      );
    });

    test('marks completed lesson done with tick semantics', () {
      final lesson = PathLessonProgress(
        lessonId: 'l0',
        title: 'Hello',
        index: 0,
        isCompleted: true,
      );
      expect(
        resolvePathNodeState(
          lesson: lesson,
          activeIndex: 1,
          pacing: const PathPacingOverlay(),
          sequentiallyUnlocked: true,
        ),
        PathNodeVisualState.done,
      );
    });

    test('review due from scheduler set not calendar', () {
      final lesson = PathLessonProgress(
        lessonId: 'l0',
        title: 'Hello',
        index: 0,
        isCompleted: true,
      );
      expect(
        resolvePathNodeState(
          lesson: lesson,
          activeIndex: 1,
          pacing: const PathPacingOverlay(reviewDueLessonIds: {'l0'}),
          sequentiallyUnlocked: true,
        ),
        PathNodeVisualState.reviewDue,
      );
    });

    test('pacing reachable opens node ahead of strict sequence', () {
      final lesson = PathLessonProgress(
        lessonId: 'l3',
        title: 'Market',
        index: 3,
        isCompleted: false,
      );
      expect(
        resolvePathNodeState(
          lesson: lesson,
          activeIndex: 0,
          pacing: const PathPacingOverlay(reachableLessonIds: {'l3'}),
          sequentiallyUnlocked: false,
        ),
        PathNodeVisualState.current,
      );
    });

    test('skipped pacing marks skipped state', () {
      final lesson = PathLessonProgress(
        lessonId: 'l1',
        title: 'Numbers',
        index: 1,
        isCompleted: false,
      );
      expect(
        resolvePathNodeState(
          lesson: lesson,
          activeIndex: 0,
          pacing: const PathPacingOverlay(skippedLessonIds: {'l1'}),
          sequentiallyUnlocked: true,
        ),
        PathNodeVisualState.skipped,
      );
    });
  });

  group('pathNodeYFromBottom', () {
    test('first lesson sits at bottom', () {
      const spacing = 100.0;
      const inset = 40.0;
      final y0 = pathNodeYFromBottom(
        index: 0,
        lessonCount: 3,
        nodeSpacing: spacing,
        bottomInset: inset,
      );
      final y2 = pathNodeYFromBottom(
        index: 2,
        lessonCount: 3,
        nodeSpacing: spacing,
        bottomInset: inset,
      );
      expect(y0, greaterThan(y2));
    });

    test('order increases bottom to top', () {
      const spacing = 80.0;
      const inset = 20.0;
      final ys = List.generate(
        4,
        (i) => pathNodeYFromBottom(
          index: i,
          lessonCount: 4,
          nodeSpacing: spacing,
          bottomInset: inset,
        ),
      );
      for (var i = 0; i < ys.length - 1; i++) {
        expect(ys[i], greaterThan(ys[i + 1]));
      }
    });
  });

  group('PathNodeRiveBinding', () {
    test('unlock trigger only with current state same frame', () {
      final binding = PathNodeRiveBinding.fromVisual(
        visual: PathNodeVisualState.current,
        nodeNumber: 2,
        lessonTitle: 'Market day',
        playNowLabel: 'Play now',
        reducedMotion: false,
        playUnlockThisFrame: true,
      );
      expect(binding.fireUnlock, isTrue);
      expect(binding.state, PathNodeRiveState.current);
      expect(binding.ctaText, 'Market day');
      expect(binding.label, '2');
    });

    test('cta uses lesson title not BEGIN default', () {
      final binding = PathNodeRiveBinding.fromVisual(
        visual: PathNodeVisualState.current,
        nodeNumber: 1,
        lessonTitle: 'Tone basics',
        playNowLabel: 'BEGIN',
        reducedMotion: true,
        playUnlockThisFrame: false,
      );
      expect(binding.ctaText, 'Tone basics');
      expect(binding.reducedMotion, isTrue);
      expect(binding.fireUnlock, isFalse);
    });
  });
}
