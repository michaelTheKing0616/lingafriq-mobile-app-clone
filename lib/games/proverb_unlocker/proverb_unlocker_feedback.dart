import '../gamekit/game_feedback.dart';
import '../gamekit/game_turn_context.dart';
import '../gamekit/game_scoring.dart';
import 'proverb_unlocker_models.dart';

/// Copy for a meaning choice. Strings stay the GameKit feedback lines.
String proverbChoiceFeedback({
  required bool correct,
  required String meaning,
}) {
  if (correct) {
    return 'Excellent! You understand the wisdom of this proverb.';
  }
  // The call keeps this the existing feedback line for the string inventory.
  return 'Not quite right. This proverb means: ${meaning.toString()}';
}

/// ProverbUnlocker feedback engine
class ProverbUnlockerFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(GameTurnContext context, GameScore score) async {
    final content = context.content as ProverbUnlockerContent;
    final details = score.details ?? {};

    if (score.isPerfect) {
      return GameFeedback.success(
        message: proverbChoiceFeedback(correct: true, meaning: content.meaning),
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
        message: feedback ??
            proverbChoiceFeedback(correct: false, meaning: content.meaning),
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
