import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';

void main() {
  tearDown(() {
    LearnerModelService.instance.resetPracticeEventStateForTests();
  });

  test('buildMasteryMapSkillRows marks untouched skill as not measured', () {
    final rows = buildMasteryMapSkillRows(
      learnerId: 'u1',
      records: const [],
      learnerModel: LearnerModelService.instance,
    );
    expect(rows, isEmpty);
  });

  test('tone skill with practice-only session stays not measured for scorer', () {
    final record = GameMasterySessionRecord(
      sessionId: 's1',
      gameId: 'tone_forge',
      learnerId: 'u1',
      language: 'yo',
      completedAt: DateTime.utc(2026, 1, 2),
      practiceNotScored: true,
      skillIdsTouched: const ['yo_tone'],
      skillDeltas: const [
        GameMasterySkillDelta(
          skillId: 'yo_tone',
          masteryBefore: 0.2,
          masteryAfter: 0.21,
        ),
      ],
      scorerBySkill: const {
        'yo_tone': ScorerSkillSnapshot(accuracyPercent: 88, fromPractice: true),
      },
    );
    final rows = buildMasteryMapSkillRows(
      learnerId: 'u1',
      records: [record],
      learnerModel: LearnerModelService.instance,
    );
    final tone = rows.singleWhere((r) => r.skillId == 'yo_tone');
    expect(tone.valueKind, MasteryMapSkillValueKind.notMeasured);
    expect(tone.gameIds, ['tone_forge']);
  });

  test('scorer unsure when confidence below gate', () {
    final session = GameSession(
      sessionId: 's2',
      userId: 'u1',
      gameId: 'talking_drum',
      language: 'yo',
      startTime: DateTime.utc(2026, 1, 1),
      metadata: {
        'learner_scorer_traces': [
          {
            'skillId': 'yo_tone',
            'confidence': 0.4,
            'accuracy': 0.4,
          },
        ],
      },
    );
    final snaps = scorerSnapshotsFromSession(session);
    expect(snaps['yo_tone']!.unsure, isTrue);
    expect(snaps['yo_tone']!.accuracyPercent, isNull);
  });

  test('sessionsForGameAndSkill filters archived records', () {
    final records = [
      GameMasterySessionRecord(
        sessionId: 'a',
        gameId: 'word_forge',
        learnerId: 'u1',
        language: 'yo',
        completedAt: DateTime.utc(2026, 1, 3),
        practiceNotScored: false,
        skillIdsTouched: const ['yo_grammar'],
        skillDeltas: const [],
      ),
      GameMasterySessionRecord(
        sessionId: 'b',
        gameId: 'tone_forge',
        learnerId: 'u1',
        language: 'yo',
        completedAt: DateTime.utc(2026, 1, 1),
        practiceNotScored: false,
        skillIdsTouched: const ['yo_grammar'],
        skillDeltas: const [],
      ),
    ];
    final filtered = sessionsForGameAndSkill(
      records: records,
      learnerId: 'u1',
      gameId: 'word_forge',
      skillId: 'yo_grammar',
    );
    expect(filtered.map((e) => e.sessionId), ['a']);
  });
}
