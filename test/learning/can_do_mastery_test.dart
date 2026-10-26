import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/skill_graph/can_do_mastery.dart';

void main() {
  group('evaluateUnitMastery', () {
    test('all can-dos met marks unit mastered', () {
      final result = evaluateUnitMastery(
        unitKey: 'yoruba-A1-u1',
        requiredCanDoIds: const ['a', 'b'],
        evidenceByCanDo: const {
          'a': CanDoEvidenceStatus.met,
          'b': CanDoEvidenceStatus.met,
        },
      );
      expect(result.status, 'mastered');
      expect(result.isMastered, isTrue);
      expect(result.missingCanDoIds, isEmpty);
      expect(result.unsureCanDoIds, isEmpty);
    });

    test('missing can-do keeps unit not mastered with list', () {
      final result = evaluateUnitMastery(
        unitKey: 'yoruba-A1-u1',
        requiredCanDoIds: const ['a', 'b', 'c'],
        evidenceByCanDo: const {
          'a': CanDoEvidenceStatus.met,
          'b': CanDoEvidenceStatus.notMet,
          'c': CanDoEvidenceStatus.met,
        },
      );
      expect(result.status, 'not_mastered');
      expect(result.missingCanDoIds, ['b']);
      expect(result.unsureCanDoIds, isEmpty);
    });

    test('unsure evidence is not enough evidence, not a pass', () {
      final result = evaluateUnitMastery(
        unitKey: 'yoruba-A1-u2',
        requiredCanDoIds: const ['a', 'b'],
        evidenceByCanDo: const {
          'a': CanDoEvidenceStatus.met,
          'b': CanDoEvidenceStatus.unsure,
        },
      );
      expect(result.status, 'not_enough_evidence');
      expect(result.isNotEnoughEvidence, isTrue);
      expect(result.isMastered, isFalse);
      expect(result.unsureCanDoIds, ['b']);
    });

    test('missing map entry counts as unsure', () {
      final result = evaluateUnitMastery(
        unitKey: 'u',
        requiredCanDoIds: const ['only'],
        evidenceByCanDo: const {},
      );
      expect(result.status, 'not_enough_evidence');
      expect(result.unsureCanDoIds, ['only']);
    });
  });

  group('evaluateUnitUnlock', () {
    const priorMastered = UnitMasteryEvaluation(
      unitKey: 'yoruba-A1-u1',
      status: 'mastered',
      missingCanDoIds: [],
      unsureCanDoIds: [],
    );

    const priorNotMastered = UnitMasteryEvaluation(
      unitKey: 'yoruba-A1-u1',
      status: 'not_mastered',
      missingCanDoIds: ['x'],
      unsureCanDoIds: [],
    );

    test('first unit is always unlocked', () {
      final u = evaluateUnitUnlock(
        unitKey: 'yoruba-A1-u1',
        rule: CurriculumUnlockRule.previousLessonCompleted,
        priorMastery: null,
        reviewPathChosen: false,
      );
      expect(u.unlocked, isTrue);
      expect(u.reason, 'first_unit');
    });

    test('legacy previous_lesson_completed unlocks only when prior can-dos mastered', () {
      final open = evaluateUnitUnlock(
        unitKey: 'yoruba-A1-u2',
        rule: CurriculumUnlockRule.previousLessonCompleted,
        priorMastery: priorMastered,
        reviewPathChosen: false,
      );
      expect(open.unlocked, isTrue);
      expect(open.reason, 'prior_mastered');

      final locked = evaluateUnitUnlock(
        unitKey: 'yoruba-A1-u2',
        rule: CurriculumUnlockRule.previousLessonCompleted,
        priorMastery: priorNotMastered,
        reviewPathChosen: false,
      );
      expect(locked.unlocked, isFalse);
      expect(locked.reason, 'locked_can_do');
    });

    test('review path unlocks under legacy rule without prior mastery', () {
      final u = evaluateUnitUnlock(
        unitKey: 'yoruba-A1-u2',
        rule: CurriculumUnlockRule.previousLessonCompleted,
        priorMastery: priorNotMastered,
        reviewPathChosen: true,
      );
      expect(u.unlocked, isTrue);
      expect(u.reason, 'review_path');
    });

    test('parseUnlockRule maps legacy string', () {
      expect(
        parseUnlockRule('previous_lesson_completed'),
        CurriculumUnlockRule.previousLessonCompleted,
      );
      expect(parseUnlockRule('can_do_evidence'), CurriculumUnlockRule.canDoEvidence);
    });
  });
}
