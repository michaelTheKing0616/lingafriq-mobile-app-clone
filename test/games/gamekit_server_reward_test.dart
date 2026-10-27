import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/models/game/game_session_model.dart';

void main() {
  test('previewGameSessionXp matches two-correct session band', () {
    expect(
      previewGameSessionXp(correctCount: 2, totalTurns: 2, durationMs: 45_000),
      60,
    );
  });

  test('GameSessionRewardClaim parses server payload', () {
    final claim = GameSessionRewardClaim.fromJson({
      'session_id': 'sess_1',
      'xp_awarded': 45,
      'practice': false,
      'duplicate': false,
      'xp_total': 120,
    });
    expect(claim.sessionId, 'sess_1');
    expect(claim.xpAwarded, 45);
    expect(claim.xpTotal, 120);
  });

  test('practiceMode reads metadata', () {
    final session = GameSession(
      sessionId: 's',
      userId: 'u',
      gameType: 'tone_forge',
      language: 'yo',
      startTime: DateTime.now(),
      metadata: const {'mode': 'practice'},
    );
    expect(session.practiceMode, isTrue);
  });
}
