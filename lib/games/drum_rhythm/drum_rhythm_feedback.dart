import '../gamekit/game_feedback.dart';
import '../gamekit/game_turn_context.dart';
import '../gamekit/game_result.dart';
import '../gamekit/game_scoring.dart';
import 'drum_rhythm_models.dart';

/// Drum Rhythm feedback engine
class DrumRhythmFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(GameTurnContext context, GameScore score) async {
    final content = context.content as DrumRhythmContent;
    final details = score.details ?? {};

    if (score.isPerfect) {
      return GameFeedback.success(
        message: 'Perfect! You matched the rhythm beautifully.',
        animationEvent: AnimationEvent.proud,
        metadata: {
          'pattern': content.pattern,
          'context': content.context,
        },
      );
    }

    if (score.isFail) {
      final feedback = details['feedback'] as String?;
      return GameFeedback.failure(
        message: feedback ?? 'Listen carefully to the rhythm pattern. Try again!',
        animationEvent: AnimationEvent.encouraging,
        metadata: {
          'correct_word': content.correctWord,
          'pattern': content.pattern,
        },
      );
    }

    if (score.isCorrect) {
      return GameFeedback.success(
        message: 'Good! You\'re getting the rhythm.',
        animationEvent: AnimationEvent.happy,
      );
    }

    return GameFeedback.neutral(
      message: 'Almost there. Focus on matching the rhythm pattern.',
      animationEvent: AnimationEvent.thinking,
    );
  }
}

