import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/game/game_session_model.dart';

void main() {
  group('Game Logic Tests', () {
    test('GameSession accuracy calculation', () {
      final session = GameSession(
        sessionId: 'test_session',
        userId: 'test_user',
        gameType: 'wordMatch',
        language: 'Yoruba',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
        turns: [
          GameTurn(
            cardId: 'card1',
            result: GameResult.correct,
            durationMs: 2000,
            confidence: 1.0,
          ),
          GameTurn(
            cardId: 'card2',
            result: GameResult.correct,
            durationMs: 1500,
            confidence: 1.0,
          ),
          GameTurn(
            cardId: 'card3',
            result: GameResult.incorrect,
            durationMs: 3000,
            confidence: 0.0,
          ),
        ],
      );

      expect(session.accuracy, closeTo(0.666, 0.001)); // 2/3 correct
      expect(session.correctCount, 2);
      expect(session.totalTurns, 3);
    });

    test('GameResult enum values', () {
      expect(GameResult.correct.name, 'correct');
      expect(GameResult.incorrect.name, 'incorrect');
      expect(GameResult.partial.name, 'partial');
    });

    test('GameSession duration calculation', () {
      final start = DateTime.now().subtract(const Duration(minutes: 10));
      final end = DateTime.now();
      final session = GameSession(
        sessionId: 'test',
        userId: 'user',
        gameType: 'test',
        language: 'Yoruba',
        startTime: start,
        endTime: end,
      );

      expect(session.durationMs, closeTo(600000, 1000)); // ~10 minutes
    });
  });
}

