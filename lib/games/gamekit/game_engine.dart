import 'game_scoring.dart';
import 'game_difficulty.dart';
import 'game_feedback.dart';
import 'game_animation_bridge.dart';
import 'game_result.dart';
import 'game_session.dart';

/// Central game engine that orchestrates scoring, difficulty, feedback, and animation
/// This is the core of the GameKit framework - all games use this
class GameEngine {
  final GameScoringEngine scoring;
  final GameDifficultyEngine difficulty;
  final GameFeedbackEngine feedback;
  final GameAnimationBridge animation;

  GameEngine({
    required this.scoring,
    required this.difficulty,
    required this.feedback,
    required this.animation,
  });

  /// Resolve a game turn - this is called by all games
  /// Returns complete result with score, feedback, difficulty adjustment, and animation cues
  Future<GameTurnResult> resolve(GameTurnContext context) async {
    // Calculate score
    final score = await scoring.score(context);

    // Adjust difficulty based on performance
    final difficultyUpdate = difficulty.adjust(context, score);

    // Generate feedback
    final feedbackData = await feedback.generate(context, score);

    // Emit animation event
    animation.emit(feedbackData.animationEvent, score);

    return GameTurnResult(
      score: score,
      feedback: feedbackData,
      difficultyUpdate: difficultyUpdate,
      timestamp: DateTime.now(),
    );
  }

  /// Create a default engine instance
  factory GameEngine.defaultEngine(GameAnimationBridge animationBridge) {
    return GameEngine(
      scoring: DefaultGameScoringEngine(),
      difficulty: DefaultGameDifficultyEngine(),
      feedback: DefaultGameFeedbackEngine(),
      animation: animationBridge,
    );
  }
}

