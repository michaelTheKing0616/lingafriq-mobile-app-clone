import '../gamekit/game_feedback.dart';
import '../gamekit/game_turn_context.dart';
import '../gamekit/game_scoring.dart';

/// ToneForge-specific feedback engine
class ToneForgeFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(GameTurnContext context, GameScore score) async {
    final content = context.content;
    final details = score.details ?? {};

    if (score.isPerfect) {
      return GameFeedback.success(
        message: 'Excellent tonal control! Your pitch matches perfectly.',
        animationEvent: AnimationEvent.proud,
        metadata: {
          'mse': details['mse'],
          'cultural_context': content.culturalContext,
        },
      );
    }

    if (score.isFail) {
      final isWithinTolerance = details['is_within_tolerance'] as bool? ?? false;
      if (!isWithinTolerance) {
        return GameFeedback.failure(
          message: 'Listen closely to the pitch movement. Focus on matching the tone pattern.',
          animationEvent: AnimationEvent.encouraging,
          metadata: {
            'hint': 'Try to match the rise and fall of the pitch',
            'cultural_context': content.culturalContext,
          },
        );
      }

      return GameFeedback.failure(
        message: 'The pitch is close but needs refinement. Try again!',
        animationEvent: AnimationEvent.encouraging,
      );
    }

    if (score.isCorrect) {
      return GameFeedback.success(
        message: 'Good effort! Your pitch is getting closer.',
        animationEvent: AnimationEvent.happy,
      );
    }

    return GameFeedback.neutral(
      message: 'Almost there. Focus on matching the tone pattern more precisely.',
      animationEvent: AnimationEvent.thinking,
    );
  }
}

