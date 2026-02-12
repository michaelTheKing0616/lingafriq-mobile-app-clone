import '../gamekit/game_scoring.dart';
import '../gamekit/game_turn_context.dart';
import 'drum_rhythm_models.dart';
import '../../services/polie_game_client.dart' show PolieGameClient, PolieEvaluationResult, GameEvaluationException;

/// Drum Rhythm scoring engine - uses Polie backend evaluation
class DrumRhythmScoringEngine extends GameScoringEngine {
  final PolieGameClient polieClient;

  DrumRhythmScoringEngine({required this.polieClient});

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final content = context.content as DrumRhythmContent;
    final input = context.input as DrumRhythmInput;
    final session = context.session;

    // Use Polie backend to evaluate - NO RANDOM LOGIC
    try {
      final evaluation = await polieClient.evaluateTurn(
        gameId: 'drum_rhythm_shadowing',
        contentId: content.contentId,
        language: session.language,
        userInput: {
          'selected_word': input.selectedWord,
          'correct_word': content.correctWord,
          'pattern': content.pattern,
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
          'selected': input.selectedWord,
          'correct_word': content.correctWord,
        },
      );
    } on GameEvaluationException {
      rethrow;
    } catch (e) {
      // Fallback to simple string comparison for unexpected errors
      final isCorrect = input.selectedWord == content.correctWord;
      return GameScore(
        accuracy: isCorrect ? 1.0 : 0.0,
        isPerfect: isCorrect,
        isFail: !isCorrect,
        details: {
          'correct': isCorrect,
          'selected': input.selectedWord,
          'correct_word': content.correctWord,
        },
      );
    }
  }
}

