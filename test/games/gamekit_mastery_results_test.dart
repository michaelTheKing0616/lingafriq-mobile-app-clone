import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';

void main() {
  test('flat mastery is no change, not improved', () {
    const delta = GameMasterySkillDelta(
      skillId: 'yo_vocab',
      masteryBefore: 0.42,
      masteryAfter: 0.42,
    );
    expect(delta.changeKind, GameMasteryChangeKind.noChange);
    expect(delta.improved, isFalse);
  });

  test('skillDeltasFromGameSession reads learner snapshots', () {
    final session = GameSession(
      sessionId: 's1',
      userId: 'u1',
      gameId: 'tone_trainer',
      language: 'yo',
      startTime: DateTime.utc(2026, 1, 1),
      metadata: {
        'skill_mastery_snapshots': {
          'yo_tone': {'before': 0.2, 'after': 0.25},
          'yo_vocab': {'before': 0.5, 'after': 0.5},
        },
      },
    );
    final deltas = skillDeltasFromGameSession(session);
    expect(deltas.length, 2);
    final vocab = deltas.firstWhere((d) => d.skillId == 'yo_vocab');
    expect(vocab.changeKind, GameMasteryChangeKind.noChange);
    final tone = deltas.firstWhere((d) => d.skillId == 'yo_tone');
    expect(tone.changeKind, GameMasteryChangeKind.improved);
  });
}
