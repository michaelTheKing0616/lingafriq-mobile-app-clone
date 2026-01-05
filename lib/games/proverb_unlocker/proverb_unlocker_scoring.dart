import '../gamekit/game_scoring.dart';
import '../gamekit/game_turn_context.dart';
import 'proverb_unlocker_models.dart';
import '../../services/polie_game_client.dart';

/// ProverbUnlocker scoring engine
/// Uses Polie backend evaluation instead of random logic
class ProverbUnlockerScoringEngine implements GameScoringEngine {
  final PolieGameClient polieClient;

  ProverbUnlockerScoringEngine({required this.polieClient});

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final content = context.content as ProverbUnlockerContent;
    final input = context.input as ProverbUnlockerInput;
    final session = context.session;

    // Use Polie backend to evaluate - NO RANDOM LOGIC
    try {
      final evaluation = await polieClient.evaluateTurn(
        gameId: 'proverb_unlocker',
        contentId: content.contentId,
        language: session.language,
        userInput: {
          'selected_answer': input.selectedAnswer,
          'correct_answer': content.correctAnswer,
        },
        difficulty: session.level ?? 'A2',
        sessionMetrics: session.performanceProfile,
      );

      return GameScore(
        accuracy: evaluation.accuracy,
        isPerfect: evaluation.accuracy > 0.9,
        isFail: evaluation.accuracy < 0.4,
        details: {
          'correct': evaluation.correct,
          'feedback': evaluation.feedback,
          'selected': input.selectedAnswer,
          'correct_answer': content.correctAnswer,
        },
      );
    } catch (e) {
      // Fallback to simple string comparison if Polie fails
      final isCorrect = input.selectedAnswer == content.correctAnswer;
      return GameScore(
        accuracy: isCorrect ? 1.0 : 0.0,
        isPerfect: isCorrect,
        isFail: !isCorrect,
        details: {
          'correct': isCorrect,
          'selected': input.selectedAnswer,
          'correct_answer': content.correctAnswer,
        },
      );
    }
  }
}

