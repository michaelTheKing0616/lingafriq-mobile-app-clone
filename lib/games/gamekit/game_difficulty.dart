import '../../learning/adaptive/difficulty_controller.dart';
import '../../learning/learner_model/learner_model_service.dart';
import 'game_turn_context.dart';
import 'game_scoring.dart';
import 'game_session.dart';

/// Rolling-window success band for GameKit (EP-§10.2-09/10, P8-905).
const int kGameKitDifficultyWindow = kSuccessWindowSize;
const int kGameKitDifficultyWarmupTurns = 5;
const int kGameKitMinDifficultyStep = 0;
const int kGameKitMaxDifficultyStep = 10;
const String kGameKitDifficultyStepKey = 'gamekit_difficulty_step';

/// Abstract difficulty engine - adjusts difficulty based on performance
abstract class GameDifficultyEngine {
  GameDifficultyUpdate adjust(GameTurnContext context, GameScore score);
}

/// Adaptive step engine: 80–85% success on the last 10 resolved turns.
class AdaptiveGameDifficultyEngine implements GameDifficultyEngine {
  AdaptiveGameDifficultyEngine({LearnerModelService? learnerModel})
      : _learnerModel = learnerModel ?? LearnerModelService.instance;

  final LearnerModelService _learnerModel;

  @override
  GameDifficultyUpdate adjust(GameTurnContext context, GameScore score) {
    final session = context.session;
    final resolvedBefore = session.turns.length;
    if (resolvedBefore < kGameKitDifficultyWarmupTurns) {
      return GameDifficultyUpdate.maintain(
        step: GameSessionDifficulty.currentStep(session),
      );
    }

    final rate = GameSessionDifficulty.rollingSuccessRate(
      session,
      includeCurrent: score,
    );

    final step = GameSessionDifficulty.currentStep(session);
    if (rate < kTargetSuccessMin) {
      final next = (step - 1).clamp(kGameKitMinDifficultyStep, kGameKitMaxDifficultyStep);
      return GameDifficultyUpdate.decrease(step: next);
    }
    if (rate > kTargetSuccessMax) {
      final next = (step + 1).clamp(kGameKitMinDifficultyStep, kGameKitMaxDifficultyStep);
      return GameDifficultyUpdate.increase(step: next);
    }
    return GameDifficultyUpdate.maintain(step: step);
  }

  /// Maps learner mastery to an initial discrete step when history is short.
  int initialStepForLearner({
    required String learnerId,
    required String gameId,
    String? skillId,
  }) {
    final sid = skillId ?? 'game:$gameId';
    final state = _learnerModel.getState(learnerId: learnerId, skillId: sid);
    if (state.totalAttempts < kGameKitDifficultyWindow) {
      return GameSessionDifficulty.stepFromMastery(state.mastery);
    }
    final accuracy = state.accuracy.clamp(0.0, 1.0);
    return GameSessionDifficulty.stepFromMastery(accuracy);
  }
}

/// Default difficulty engine — P8-905 adaptive policy.
class DefaultGameDifficultyEngine extends AdaptiveGameDifficultyEngine {
  DefaultGameDifficultyEngine({super.learnerModel});
}

/// Session helpers for discrete difficulty steps.
extension GameSessionDifficulty on GameSession {
  static int currentStep(GameSession session) {
    final raw = session.metadata[kGameKitDifficultyStepKey];
    if (raw is int) return raw.clamp(kGameKitMinDifficultyStep, kGameKitMaxDifficultyStep);
    if (raw is num) {
      return raw.round().clamp(kGameKitMinDifficultyStep, kGameKitMaxDifficultyStep);
    }
    return stepFromMastery(0.35);
  }

  static int stepFromMastery(double mastery) {
    final m = mastery.clamp(0.0, 1.0);
    return (m * kGameKitMaxDifficultyStep).round().clamp(
      kGameKitMinDifficultyStep,
      kGameKitMaxDifficultyStep,
    );
  }

  static double rollingSuccessRate(
    GameSession session, {
    GameScore? includeCurrent,
    int window = kGameKitDifficultyWindow,
  }) {
    final outcomes = <bool>[
      for (final t in session.turns) t.score.isCorrect,
      if (includeCurrent != null) includeCurrent.isCorrect,
    ];
    if (outcomes.isEmpty) {
      return (kTargetSuccessMin + kTargetSuccessMax) / 2;
    }
    final slice = outcomes.length <= window
        ? outcomes
        : outcomes.sublist(outcomes.length - window);
    final successes = slice.where((s) => s).length;
    return successes / slice.length;
  }

  GameSession withDifficultyBootstrap({
    required int initialStep,
  }) {
    return copyWith(
      metadata: {
        ...metadata,
        kGameKitDifficultyStepKey: initialStep.clamp(
          kGameKitMinDifficultyStep,
          kGameKitMaxDifficultyStep,
        ),
      },
    );
  }

  GameSession applyDifficultyUpdate(GameDifficultyUpdate update) {
    final nextStep = update.difficultyStep ?? currentStep(this);
    return copyWith(
      metadata: {
        ...metadata,
        kGameKitDifficultyStepKey: nextStep,
        if (update.action != 'maintain')
          'last_difficulty_action': update.action,
      },
    );
  }
}

/// Difficulty update result
class GameDifficultyUpdate {
  final String action; // 'increase', 'decrease', 'maintain'
  final double? newLevel; // Optional continuous level (legacy)
  final int? difficultyStep;
  final Map<String, dynamic>? metadata;

  GameDifficultyUpdate({
    required this.action,
    this.newLevel,
    this.difficultyStep,
    this.metadata,
  });

  factory GameDifficultyUpdate.increase({double? level, int? step}) {
    return GameDifficultyUpdate(
      action: 'increase',
      newLevel: level,
      difficultyStep: step,
    );
  }

  factory GameDifficultyUpdate.decrease({double? level, int? step}) {
    return GameDifficultyUpdate(
      action: 'decrease',
      newLevel: level,
      difficultyStep: step,
    );
  }

  factory GameDifficultyUpdate.maintain({int? step}) {
    return GameDifficultyUpdate(
      action: 'maintain',
      difficultyStep: step,
    );
  }
}

/// Predict success probability for simulations (test + perf harness).
double gameKitSuccessProbability({
  required int difficultyStep,
  required double learnerAbility,
}) {
  final itemDifficulty = difficultyStep / kGameKitMaxDifficultyStep;
  final gap = learnerAbility - itemDifficulty;
  // Harness-only linear model (simulations): each step ≈8.5 pts success.
  return (0.68 + gap * 0.85).clamp(0.05, 0.95);
}
