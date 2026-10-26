import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/adaptive/difficulty_controller.dart';

AdaptiveSessionCandidate _item(
  String id,
  SessionPracticeType type, {
  double difficulty = 0.5,
  String voice = 'v1',
}) {
  return AdaptiveSessionCandidate(
    id: id,
    type: type,
    difficulty: difficulty,
    voiceId: voice,
  );
}

List<AdaptiveSessionCandidate> _fullPool() {
  final voices = ['voice_a', 'voice_b'];
  final items = <AdaptiveSessionCandidate>[];
  var i = 0;
  for (final type in SessionPracticeType.values) {
    for (final voice in voices) {
      items.add(_item(
        '${type.name}_$voice',
        type,
        difficulty: 0.3 + (i % 5) * 0.1,
        voice: voice,
      ));
      i++;
    }
  }
  return items;
}

void main() {
  group('DifficultyController', () {
    test('planSession mixes all practice types', () {
      final controller = DifficultyController();
      final plan = controller.planSession(_fullPool(), length: 10);
      final types = plan.map((c) => c.type).toSet();
      expect(types, equals(SessionPracticeType.values.toSet()));
    });

    test('alternates voices when multiple are available', () {
      final controller = DifficultyController();
      final pool = [
        _item('a1', SessionPracticeType.listen, voice: 'va'),
        _item('a2', SessionPracticeType.listen, voice: 'vb'),
        _item('b1', SessionPracticeType.say, voice: 'va'),
        _item('b2', SessionPracticeType.say, voice: 'vb'),
        _item('c1', SessionPracticeType.choose, voice: 'va'),
        _item('c2', SessionPracticeType.choose, voice: 'vb'),
        _item('d1', SessionPracticeType.build, voice: 'va'),
        _item('d2', SessionPracticeType.build, voice: 'vb'),
        _item('e1', SessionPracticeType.translate, voice: 'va'),
        _item('e2', SessionPracticeType.translate, voice: 'vb'),
      ];
      final plan = controller.planSession(pool, length: 6);
      final voices = plan.map((c) => c.voiceId).toList();
      expect(voices.toSet().length, greaterThanOrEqualTo(2));
      for (var i = 1; i < voices.length; i++) {
        if (plan[i].type == plan[i - 1].type) {
          expect(voices[i], isNot(voices[i - 1]));
        }
      }
    });

    test('low success rate lowers target difficulty on next pick', () {
      final controller = DifficultyController(initialTarget: 0.6);
      for (var i = 0; i < kSuccessWindowSize; i++) {
        controller.recordOutcome(SessionAttemptOutcome(
          candidateId: 'x$i',
          success: false,
          difficultyAtPresentation: 0.6,
        ));
      }
      expect(controller.recentSuccessRate(), lessThan(kTargetSuccessMin));
      expect(controller.targetDifficulty, lessThan(0.6));

      final pool = [
        _item('easy', SessionPracticeType.listen, difficulty: 0.2),
        _item('hard', SessionPracticeType.listen, difficulty: 0.9),
      ];
      final next = controller.pickNext(pool);
      expect(next!.id, 'easy');
    });

    test('high success rate raises target difficulty on next pick', () {
      final controller = DifficultyController(initialTarget: 0.4);
      for (var i = 0; i < kSuccessWindowSize; i++) {
        controller.recordOutcome(SessionAttemptOutcome(
          candidateId: 'x$i',
          success: true,
          difficultyAtPresentation: 0.4,
        ));
      }
      expect(controller.recentSuccessRate(), greaterThan(kTargetSuccessMax));
      expect(controller.targetDifficulty, greaterThan(0.4));

      final pool = [
        _item('easy', SessionPracticeType.choose, difficulty: 0.2),
        _item('hard', SessionPracticeType.choose, difficulty: 0.85),
      ];
      final next = controller.pickNext(pool);
      expect(next!.id, 'hard');
    });

    test('session simulation steers toward success band', () {
      final controller = DifficultyController(initialTarget: 0.5);
      final pool = List.generate(
        30,
        (i) => _item(
          'item$i',
          SessionPracticeType.values[i % SessionPracticeType.values.length],
          difficulty: (i % 10) / 10,
          voice: i.isEven ? 'va' : 'vb',
        ),
      );

      var successes = 0;
      var attempts = 0;
      for (var round = 0; round < 40; round++) {
        final next = controller.pickNext(pool);
        expect(next, isNotNull);
        final presented = next!.difficulty;
        final success = presented <= controller.targetDifficulty + 0.15;
        controller.recordOutcome(SessionAttemptOutcome(
          candidateId: next.id,
          success: success,
          difficultyAtPresentation: presented,
        ));
        if (success) successes++;
        attempts++;
      }
      final rate = successes / attempts;
      expect(rate, greaterThan(0.5));
      expect(controller.targetDifficulty, inInclusiveRange(0.0, 1.0));
    });
  });
}
