import '../../l10n/l10n_of.dart';
import '../gamekit/game_feedback.dart';
import '../gamekit/game_turn_context.dart';
import '../gamekit/game_scoring.dart';
import 'tone_forge_scoring.dart';

/// Feedback sentence for one scorer result.
///
/// A percent is included only when [toneForgeShownPercent] has one.
String toneForgeFeedbackMessage(GameScore score) {
  final int? percent = toneForgeShownPercent(score);
  if (percent == null) return l10nEn().revRvPlayUnsure;
  return l10nEn().revRvPlayScoreReturned(percent);
}

/// Tone Forge feedback. The message follows the real scorer result.
class ToneForgeFeedbackEngine implements GameFeedbackEngine {
  const ToneForgeFeedbackEngine();

  @override
  Future<GameFeedback> generate(
    GameTurnContext context,
    GameScore score,
  ) async {
    final int? percent = toneForgeShownPercent(score);
    return GameFeedback.neutral(
      message: toneForgeFeedbackMessage(score),
      animationEvent: percent == null
          ? AnimationEvent.thinking
          : AnimationEvent.happy,
    );
  }
}
