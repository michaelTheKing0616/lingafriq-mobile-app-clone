import 'gamekit/game_difficulty.dart';
import 'gamekit/game_engine.dart';
import 'gamekit/game_scoring.dart';
import 'gamekit/game_feedback.dart';
import 'gamekit/game_animation_bridge.dart';
import 'gamekit/game_turn_context.dart';
import '../learning/game_integration/learning_game.dart';
import '../learning/learner_model/learner_model_service.dart';
import '../learning/learner_model/error_taxonomy.dart';

/// Difficulty engine that uses the learner model for adaptive difficulty.
///
/// Implements the same interface as [GameDifficultyEngine]. Uses
/// [LearnerModelService] to read learner state and compute difficulty from
/// mastery, error patterns, time pressure, and streak. Falls back to
/// [DefaultGameDifficultyEngine] behavior when no meaningful learner state exists.
class LearningGameDifficultyEngine implements GameDifficultyEngine {
  final String learnerId;
  final String skillId;

  LearningGameDifficultyEngine({
    required this.learnerId,
    required this.skillId,
  });

  @override
  GameDifficultyUpdate adjust(GameTurnContext context, GameScore score) {
    final session = context.session;
    final streak = session.streak;
    final recentAccuracy = session.accuracy;

    final state = LearnerModelService.instance.getState(
      learnerId: learnerId,
      skillId: skillId,
    );

    // Fallback to default behavior when no meaningful history
    final hasHistory = state.totalAttempts >= 2;
    if (!hasHistory) {
      if (score.isPerfect && streak >= 3 && recentAccuracy > 0.85) {
        return GameDifficultyUpdate.increase();
      }
      if (score.isFail && streak == 0 && recentAccuracy < 0.5) {
        return GameDifficultyUpdate.decrease();
      }
      return GameDifficultyUpdate.maintain();
    }

    // Learner-model–driven adjustment
    final mastery = state.mastery.clamp(0.0, 1.0);
    final accuracy = state.accuracy;
    final currentStreak = state.currentStreak;
    final errorEntropy = ErrorTaxonomy.errorEntropy(state.errorDistribution.rates);

    // Increase difficulty: high accuracy, good streak, solid mastery
    if (score.isPerfect && currentStreak >= 3 && accuracy > 0.85 && mastery > 0.4) {
      final newLevel = (mastery + 0.1).clamp(0.0, 1.0);
      return GameDifficultyUpdate.increase(level: newLevel);
    }

    // Decrease difficulty: failing, low accuracy, many attempts, or high error entropy
    if (score.isFail && (accuracy < 0.5 || currentStreak == 0)) {
      final newLevel = (mastery - 0.15).clamp(0.1, 1.0);
      return GameDifficultyUpdate.decrease(level: newLevel);
    }
    if (state.totalAttempts > 5 && accuracy < 0.4) {
      final newLevel = (mastery - 0.1).clamp(0.1, 1.0);
      return GameDifficultyUpdate.decrease(level: newLevel);
    }
    if (errorEntropy > 2.0 && score.isFail) {
      return GameDifficultyUpdate.decrease();
    }

    return GameDifficultyUpdate.maintain();
  }
}

/// Maps game results to learning model types and records sessions.
class GameResultMapper {
  GameResultMapper._();

  /// Maps a single turn result to a [SkillOutcome].
  static SkillOutcome mapToSkillOutcome({
    required double score,
    required double responseTimeSeconds,
    double expectedTimeSeconds = 5.0,
    List<String> errorTypeIds = const [],
  }) {
    final isCorrect = score >= 0.6;
    final partialCredit = score.clamp(0.0, 1.0);
    return SkillOutcome(
      isCorrect: isCorrect,
      partialCredit: partialCredit,
      errorTypeIds: errorTypeIds,
      responseTimeSeconds: responseTimeSeconds,
      expectedTimeSeconds: expectedTimeSeconds,
    );
  }

  /// Records a full game session by recording each outcome in the learner model.
  static Future<void> recordGameSession(GameSessionResult result) async {
    final learnerModel = LearnerModelService.instance;
    for (var i = 0; i < result.outcomes.length; i++) {
      final outcome = result.outcomes[i];
      final skillId = i < result.skillIds.length
          ? result.skillIds[i]
          : result.skillIds.isNotEmpty
              ? result.skillIds.first
              : '';
      if (skillId.isEmpty) continue;
      await learnerModel.recordAttempt(
        learnerId: result.learnerId,
        skillId: skillId,
        wasCorrect: outcome.isCorrect,
        errorTypeIds: outcome.errorTypeIds,
        responseTimeSeconds: outcome.responseTimeSeconds,
        expectedTimeSeconds: outcome.expectedTimeSeconds,
      );
    }
  }

  /// Records a single outcome for one learner/skill.
  static Future<void> recordSingleOutcome({
    required String learnerId,
    required String skillId,
    required SkillOutcome outcome,
  }) async {
    await LearnerModelService.instance.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: outcome.isCorrect,
      errorTypeIds: outcome.errorTypeIds,
      responseTimeSeconds: outcome.responseTimeSeconds,
      expectedTimeSeconds: outcome.expectedTimeSeconds,
    );
  }
}

/// Factory for a [GameEngine] configured with [LearningGameDifficultyEngine].
class AdaptiveLearningGameEngine {
  AdaptiveLearningGameEngine._();

  /// Creates a [GameEngine] that uses [LearningGameDifficultyEngine] for
  /// the given [learnerId] and first of [skillIds], with the provided
  /// [animationBridge]. Uses [DefaultGameScoringEngine] and
  /// [DefaultGameFeedbackEngine] for scoring and feedback.
  static GameEngine create({
    required String learnerId,
    required List<String> skillIds,
    required GameAnimationBridge animationBridge,
  }) {
    final skillId = skillIds.isNotEmpty ? skillIds.first : '';
    final difficulty = skillId.isNotEmpty
        ? LearningGameDifficultyEngine(learnerId: learnerId, skillId: skillId)
        : DefaultGameDifficultyEngine();
    return GameEngine(
      scoring: DefaultGameScoringEngine(),
      difficulty: difficulty,
      feedback: DefaultGameFeedbackEngine(),
      animation: animationBridge,
    );
  }
}
