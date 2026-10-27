import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_difficulty.dart';
import 'package:lingafriq/games/gamekit/game_meta_layer.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/services/cultural_mastery_service.dart';

void main() {
  group('P8-911 mode selection', () {
    test('speaking game without flag stays practice', () {
      expect(
        gameKitPracticeNotScoredMode(
          isSpeakingGame: true,
          realScorerLive: false,
        ),
        isTrue,
      );
      expect(
        gameKitRealScorerLiveForGame(
          featureFlagOn: false,
          gameId: 'tone_trainer',
          isSpeakingGame: true,
        ),
        isFalse,
      );
    });

    test('flag on but adapter fail stays practice', () {
      expect(
        gameKitRealScorerLiveForGame(
          featureFlagOn: true,
          gameId: 'proverb_unlocker',
          isSpeakingGame: true,
        ),
        isFalse,
      );
    });

    test('flag on and adapter pass enables live scorer', () {
      expect(
        gameKitRealScorerLiveForGame(
          featureFlagOn: true,
          gameId: 'tone_trainer',
          isSpeakingGame: true,
        ),
        isTrue,
      );
      expect(
        gameKitPracticeNotScoredMode(
          isSpeakingGame: true,
          realScorerLive: true,
        ),
        isFalse,
      );
    });

    test('practice preview XP is zero', () {
      expect(
        previewGameSessionXp(
          correctCount: 8,
          totalTurns: 10,
          durationMs: 40_000,
          practiceNotScored: true,
        ),
        0,
      );
    });
  });

  group('meta layer skips rewards in practice', () {
    test('honest practice turn does not award badges', () async {
      final layer = GameMetaLayer(masteryService: CulturalMasteryService());
      final session = GameSession(
        sessionId: 's',
        userId: 'u',
        gameId: 'tone_trainer',
        language: 'yo',
        startTime: DateTime.now(),
      );
      final result = GameTurnResult(
        score: GameScore.honestPractice(message: 'practice'),
        feedback: GameFeedback.neutral(
          message: 'practice',
          animationEvent: AnimationEvent.listening,
        ),
        difficultyUpdate: GameDifficultyUpdate.maintain(),
        timestamp: DateTime.now(),
      );
      final update = await layer.updateAfterTurn(
        userId: 'u',
        language: 'yo',
        gameId: 'tone_trainer',
        result: result,
        practiceNotScored: true,
      );
      expect(update.badges, isEmpty);
      expect(update.countsForLeaderboard, isFalse);
    });
  });
}
