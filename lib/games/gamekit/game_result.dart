import 'game_feedback.dart';
import 'game_difficulty.dart';
import 'game_scoring.dart';
import '../../models/game/game_session_model.dart' as backend;

/// Complete result of a game turn
class GameTurnResult {
  final GameScore score;
  final GameFeedback feedback;
  final GameDifficultyUpdate difficultyUpdate;
  final DateTime timestamp;

  GameTurnResult({
    required this.score,
    required this.feedback,
    required this.difficultyUpdate,
    required this.timestamp,
  });

  /// Convert to backend GameTurn model
  backend.GameTurn toGameTurn({required String cardId}) {
    return backend.GameTurn(
      cardId: cardId,
      result: score.isCorrect ? backend.GameResult.correct : backend.GameResult.incorrect,
      durationMs: 0, // Should be set by caller
      confidence: score.accuracy,
      feedback: {
        'message': feedback.message,
        'animation_event': feedback.animationEvent.name,
        'accuracy': score.accuracy,
        'is_perfect': score.isPerfect,
        'is_fail': score.isFail,
      },
    );
  }
}

