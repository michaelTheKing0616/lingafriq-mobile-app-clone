import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/adaptive/difficulty_controller.dart';
import 'package:lingafriq/services/learner/lesson_pacing.dart';
import 'package:lingafriq/services/learner/mastery_event.dart';
import 'package:lingafriq/services/learner/skill_mastery.dart';

void main() {
  group('LessonPacingEngine', () {
    test('low success rate shortens session and eases difficulty', () {
      final difficulty = DifficultyController(initialTarget: 0.6);
      for (var i = 0; i < 10; i++) {
        difficulty.recordOutcome(
          SessionAttemptOutcome(
            candidateId: 'a',
            success: false,
            difficultyAtPresentation: 0.6,
          ),
        );
      }
      final engine = LessonPacingEngine(difficulty: difficulty);
      final plan = engine.recommend(
        reachableLessonIds: const ['u1', 'u2', 'u3'],
      );
      expect(plan.itemCount, lessThan(kPacingDefaultItems));
      expect(plan.newItemFraction, lessThan(kPacingDefaultNewFraction));
      expect(plan.difficultyTarget, lessThan(0.6));
      expect(plan.reasonKey, kPaceReasonBand);
    });

    test('weak tone skill adds drills without shrinking reachable lessons', () {
      final mastery = SkillMasteryModel();
      for (var i = 0; i < 6; i++) {
        mastery.update(
          const MasteryEvent(skillId: 'tone', correct: false),
        );
      }
      final engine = LessonPacingEngine(mastery: mastery);
      final plan = engine.recommend(
        reachableLessonIds: const ['lesson-a', 'lesson-b'],
      );
      expect(plan.focusSkillDrillIds, contains('tone'));
      expect(plan.reachableLessonIds, ['lesson-a', 'lesson-b']);
      expect(plan.reasonKey, kPaceReasonWeakSkill);
    });

    test('override and reset change plan', () {
      final engine = LessonPacingEngine();
      final prefs = LearnerPacingPreferences();
      final base = engine.recommend(
        reachableLessonIds: const ['x'],
        preferences: prefs,
      );
      prefs.applyOverride(
        LessonPacingPlan(
          itemCount: kPacingMinItems,
          newItemFraction: kPacingMinNewFraction,
          difficultyTarget: 0.2,
          focusSkillDrillIds: const [],
          reasonKey: kPaceReasonOverride,
          reasonDetail: 'test',
          reachableLessonIds: const ['x'],
        ),
      );
      final overridden = engine.recommend(
        reachableLessonIds: const ['x'],
        preferences: prefs,
      );
      expect(overridden.itemCount, kPacingMinItems);
      expect(overridden.reasonKey, kPaceReasonOverride);

      prefs.reset();
      final restored = engine.recommend(
        reachableLessonIds: const ['x'],
        preferences: prefs,
      );
      expect(restored.itemCount, base.itemCount);
      expect(prefs.hasOverride, isFalse);
    });

    test('under-16 uses same adaptation and skill-only mastery record', () {
      final engine = LessonPacingEngine();
      final plan = engine.recommend(
        reachableLessonIds: const ['u1'],
        under16: true,
      );
      expect(plan.itemCount, greaterThanOrEqualTo(kPacingMinItems));
      expect(engine.mastery.toRecord(under16: true).keys, ['skills']);
    });
  });
}
