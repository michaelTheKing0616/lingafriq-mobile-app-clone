import '../gamekit/game_feedback.dart';
import '../gamekit/game_turn_context.dart';
import '../gamekit/game_result.dart';
import '../gamekit/game_scoring.dart';
import 'proverb_unlocker_models.dart';

/// ProverbUnlocker feedback engine
class ProverbUnlockerFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(GameTurnContext context, GameScore score) async {
    final content = context.content as ProverbUnlockerContent;
    final details = score.details ?? {};

    if (score.isPerfect) {
      return GameFeedback.success(
        message: 'Excellent! You understand the wisdom of this proverb.',
        animationEvent: AnimationEvent.proud,
        metadata: {
          'proverb': content.proverb,
          'meaning': content.meaning,
          'context': content.context,
        },
      );
    }

    if (score.isFail) {
      final feedback = details['feedback'] as String?;
      return GameFeedback.failure(
        message: feedback ?? 'Not quite right. This proverb means: ${content.meaning}',
        animationEvent: AnimationEvent.encouraging,
        metadata: {
          'correct_answer': content.correctAnswer,
          'context': content.context,
        },
      );
    }

    if (score.isCorrect) {
      return GameFeedback.success(
        message: 'Good job! You\'re learning the wisdom of this culture.',
        animationEvent: AnimationEvent.happy,
      );
    }

    return GameFeedback.neutral(
      message: 'Almost there. Think about the deeper meaning.',
      animationEvent: AnimationEvent.thinking,
    );
  }
}

