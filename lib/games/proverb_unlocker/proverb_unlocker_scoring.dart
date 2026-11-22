import '../gamekit/game_scoring.dart';
import '../gamekit/game_turn_context.dart';
import '../../services/polie_game_client.dart';
import 'proverb_unlocker_catalog.dart';
import 'proverb_unlocker_models.dart';

/// Scores a proverb turn by exact match.
///
/// A meaning choice matches [ProverbUnlockerContent.correctAnswer].
/// A non-empty fill map matches the seeded blank words.
/// Polie is not called. The client stays on the constructor for the factory.
class ProverbUnlockerScoringEngine implements GameScoringEngine {
  final PolieGameClient polieClient;

  ProverbUnlockerScoringEngine({required this.polieClient});

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final content = context.content as ProverbUnlockerContent;
    final input = context.input as ProverbUnlockerInput;
    final outcome = resolveProverbUnlockerOutcome(
      proverb: content.proverb,
      correctAnswer: content.correctAnswer,
      blankIndices: content.blankIndices,
      words: content.words,
      selectedAnswer: input.selectedAnswer,
      fills: input.fills,
    );

    return GameScore(
      accuracy: outcome.correct ? 1.0 : 0.0,
      isPerfect: outcome.correct,
      isFail: !outcome.correct,
      details: {
        'correct': outcome.correct,
        'selected': input.selectedAnswer,
        'correct_answer': content.correctAnswer,
        'proverb': content.proverb,
      },
    );
  }
}
