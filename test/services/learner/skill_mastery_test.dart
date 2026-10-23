import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learner/mastery_event.dart';
import 'package:lingafriq/services/learner/skill_mastery.dart';

void main() {
  group('SkillMasteryModel', () {
    test('accuracy-only event changes the mean from the prior', () {
      final model = SkillMasteryModel();
      expect(model.estimate('low-tone').mean, 0.5);

      const event = MasteryEvent(skillId: 'low-tone', correct: true);
      model.update(event);

      final estimate = model.estimate('low-tone');
      expect(estimate.alpha, 2);
      expect(estimate.beta, 1);
      expect(estimate.mean, 2 / 3);
    });

    test('pronunciation moves the mean and null is not replaced with 0.5', () {
      final model = SkillMasteryModel();
      model.update(const MasteryEvent(skillId: 'low-tone', correct: true));
      expect(model.estimate('low-tone').mean, 2 / 3);

      model.update(
        const MasteryEvent(skillId: 'low-tone', pronunciationScore: 1),
      );
      final afterScore = model.estimate('low-tone');
      expect(afterScore.alpha, 3);
      expect(afterScore.beta, 1);
      expect(afterScore.mean, 0.75);

      model.update(
        const MasteryEvent(skillId: 'low-tone', pronunciationScore: null),
      );
      final afterNull = model.estimate('low-tone');
      expect(afterNull.alpha, 3);
      expect(afterNull.beta, 1);
      expect(afterNull.mean, 0.75);
    });

    test('out-of-range and non-finite scores do not move the estimate', () {
      final model = SkillMasteryModel();
      model.update(
        const MasteryEvent(skillId: 'vowel', pronunciationScore: 1.5),
      );
      model.update(
        const MasteryEvent(skillId: 'vowel', pronunciationScore: -0.1),
      );
      model.update(const MasteryEvent(skillId: 'vowel', toneScore: double.nan));
      model.update(
        const MasteryEvent(skillId: 'vowel', toneScore: double.infinity),
      );
      model.update(
        const MasteryEvent(skillId: 'vowel', pronunciationScore: null),
      );

      final estimate = model.estimate('vowel');
      expect(estimate.alpha, 1);
      expect(estimate.beta, 1);
      expect(estimate.mean, 0.5);
    });

    test('update uses only MasteryEvent signals', () {
      final model = SkillMasteryModel();
      const event = MasteryEvent(
        skillId: 'low-tone',
        correct: true,
        responseTimeSeconds: 45,
        hintUsed: true,
        pronunciationScore: 0.25,
        toneScore: 1,
        sessionLengthSeconds: 180,
        droppedOff: true,
      );

      model.update(event);

      expect(event.sessionLengthSeconds, 180);
      final estimate = model.estimate('low-tone');
      // Prior 1, 1. Correct +1 alpha. Hint +1 beta. Pronunciation 0.25.
      // Tone 1. Response above 30 adds 0.25 beta. Drop-off +1 beta.
      // Session length is not a weight. Mean is alpha / (alpha + beta).
      expect(estimate.alpha, 3.25);
      expect(estimate.beta, 4);
      expect(estimate.mean, 3.25 / 7.25);
      expect(model.estimate('other-skill').mean, 0.5);
    });

    test('time at or below 30 seconds and a null time do not change beta', () {
      final model = SkillMasteryModel();
      model.update(
        const MasteryEvent(skillId: 'pace', responseTimeSeconds: 30),
      );
      model.update(
        const MasteryEvent(skillId: 'pace', responseTimeSeconds: null),
      );
      expect(model.estimate('pace').alpha, 1);
      expect(model.estimate('pace').beta, 1);

      model.update(
        const MasteryEvent(skillId: 'pace', responseTimeSeconds: 30.1),
      );
      expect(model.estimate('pace').alpha, 1);
      expect(model.estimate('pace').beta, 1.25);
    });

    test('a missed answer, a hint, and a drop-off each add one failure', () {
      final model = SkillMasteryModel();
      model.update(const MasteryEvent(skillId: 'a', correct: false));
      model.update(const MasteryEvent(skillId: 'b', hintUsed: true));
      model.update(const MasteryEvent(skillId: 'c', droppedOff: true));
      model.update(const MasteryEvent(skillId: 'd', correct: null));

      expect(model.estimate('a').alpha, 1);
      expect(model.estimate('a').beta, 2);
      expect(model.estimate('b').beta, 2);
      expect(model.estimate('c').beta, 2);
      expect(model.estimate('d').alpha, 1);
      expect(model.estimate('d').beta, 1);
    });

    test('session length stays on the event and does not move mastery', () {
      const event = MasteryEvent(
        skillId: 'low-tone',
        sessionLengthSeconds: 99999,
      );
      final model = SkillMasteryModel();
      model.update(event);

      expect(event.sessionLengthSeconds, 99999);
      expect(model.estimate('low-tone').alpha, 1);
      expect(model.estimate('low-tone').beta, 1);
      final record = model.toRecord(under16: true);
      expect(record.toString().contains('99999'), isFalse);
    });

    test('under-16 record is skill estimates without a marketing profile', () {
      final model = SkillMasteryModel();
      model.update(
        const MasteryEvent(
          skillId: 'low-tone',
          correct: true,
          sessionLengthSeconds: 90,
        ),
      );
      model.update(const MasteryEvent(skillId: 'vowel', correct: false));

      final record = model.toRecord(under16: true);
      expect(record.keys, ['skills']);
      final skills = record['skills']! as List<Map<String, Object?>>;
      expect(skills, hasLength(2));
      expect(skills[0].keys, ['skillId', 'alpha', 'beta', 'mean']);
      expect(skills[0]['skillId'], 'low-tone');
      expect(skills[0]['alpha'], 2);
      expect(skills[0]['beta'], 1);
      expect(skills[0]['mean'], 2 / 3);
      expect(skills[1]['skillId'], 'vowel');

      _expectNoProfileKeys(record);
      expect(record.toString().toLowerCase().contains('advertising'), isFalse);
      expect(record.toString().toLowerCase().contains('marketing'), isFalse);

      final older = model.toRecord(under16: false);
      expect(older.keys, ['skills']);
      _expectNoProfileKeys(older);
    });

    test('reset returns every skill estimate to the starting prior', () {
      final model = SkillMasteryModel();
      model.update(const MasteryEvent(skillId: 'low-tone', correct: true));
      model.update(
        const MasteryEvent(skillId: 'vowel', correct: false, droppedOff: true),
      );
      expect(model.estimate('low-tone').mean, isNot(0.5));
      expect(model.estimate('vowel').mean, isNot(0.5));

      model.reset();

      expect(model.estimate('low-tone').alpha, 1);
      expect(model.estimate('low-tone').beta, 1);
      expect(model.estimate('low-tone').mean, 0.5);
      expect(model.estimate('vowel').alpha, 1);
      expect(model.estimate('vowel').beta, 1);
      expect(model.estimate('vowel').mean, 0.5);
      expect(model.estimate('never-seen').mean, 0.5);

      final record = model.toRecord(under16: true);
      final skills = record['skills']! as List<Map<String, Object?>>;
      expect(skills, hasLength(2));
      for (final skill in skills) {
        expect(skill['alpha'], 1);
        expect(skill['beta'], 1);
        expect(skill['mean'], 0.5);
      }
    });

    test('practice update source does not import a network client', () {
      final mastery = File(
        'lib/services/learner/skill_mastery.dart',
      ).readAsStringSync();
      final event = File(
        'lib/services/learner/mastery_event.dart',
      ).readAsStringSync();
      final source = '$mastery\n$event';
      expect(source.contains("import 'package:http"), isFalse);
      expect(source.contains('import "package:http'), isFalse);
      expect(source.contains("import 'package:dio"), isFalse);
      expect(source.contains('import "package:dio'), isFalse);
      expect(source.contains('dart:io'), isFalse);
      expect(source.contains('HttpClient'), isFalse);
      expect(source.contains('Socket'), isFalse);
    });
  });
}

void _expectNoProfileKeys(Object? node) {
  const banned = {
    'advertisingid',
    'adid',
    'marketing',
    'profile',
    'email',
    'name',
    'age',
  };
  if (node is Map) {
    for (final entry in node.entries) {
      expect(
        banned.contains('${entry.key}'.toLowerCase()),
        isFalse,
        reason: 'forbidden key ${entry.key}',
      );
      _expectNoProfileKeys(entry.value);
    }
    return;
  }
  if (node is List) {
    for (final item in node) {
      _expectNoProfileKeys(item);
    }
  }
}
