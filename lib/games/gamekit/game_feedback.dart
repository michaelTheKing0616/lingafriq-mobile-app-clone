import 'game_turn_context.dart';
import 'game_result.dart';
import 'game_scoring.dart';

/// Abstract feedback engine - generates user-facing feedback
abstract class GameFeedbackEngine {
  Future<GameFeedback> generate(GameTurnContext context, GameScore score);
}

/// Default feedback engine
class DefaultGameFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(GameTurnContext context, GameScore score) async {
    if (score.isPerfect) {
      return GameFeedback.success(
        message: 'Excellent! Perfect score!',
        animationEvent: AnimationEvent.proud,
      );
    }

    if (score.isFail) {
      return GameFeedback.failure(
        message: 'Not quite right. Try again!',
        animationEvent: AnimationEvent.encouraging,
      );
    }

    if (score.isCorrect) {
      return GameFeedback.success(
        message: 'Good job!',
        animationEvent: AnimationEvent.happy,
      );
    }

    return GameFeedback.neutral(
      message: 'Almost there. Keep trying!',
      animationEvent: AnimationEvent.thinking,
    );
  }
}

/// Feedback data
class GameFeedback {
  final String message;
  final AnimationEvent animationEvent;
  final Map<String, dynamic>? metadata;

  GameFeedback({
    required this.message,
    required this.animationEvent,
    this.metadata,
  });

  factory GameFeedback.success({
    required String message,
    required AnimationEvent animationEvent,
    Map<String, dynamic>? metadata,
  }) {
    return GameFeedback(
      message: message,
      animationEvent: animationEvent,
      metadata: metadata,
    );
  }

  factory GameFeedback.failure({
    required String message,
    required AnimationEvent animationEvent,
    Map<String, dynamic>? metadata,
  }) {
    return GameFeedback(
      message: message,
      animationEvent: animationEvent,
      metadata: metadata,
    );
  }

  factory GameFeedback.neutral({
    required String message,
    required AnimationEvent animationEvent,
    Map<String, dynamic>? metadata,
  }) {
    return GameFeedback(
      message: message,
      animationEvent: animationEvent,
      metadata: metadata,
    );
  }
}

/// Animation events that trigger Rive state changes
enum AnimationEvent {
  idle,
  thinking,
  listening,
  speaking,
  happy,
  proud,
  disappointed,
  encouraging,
  confused,
}

