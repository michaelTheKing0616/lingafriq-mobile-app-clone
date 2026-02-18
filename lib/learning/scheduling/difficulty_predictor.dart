import '../learner_model/learner_model_service.dart';
import '../learner_model/learner_skill_state.dart';
import '../learner_model/error_taxonomy.dart';
import '../skill_graph/skill_registry.dart';

/// Predicted difficulty for a single skill.
class PredictedDifficulty {
  final String skillId;
  /// Difficulty level in [0, 1]. Higher = harder.
  final double level;
  /// Confidence in the prediction [0, 1].
  final double confidence;
  /// Human-readable reason for the adjustment.
  final String adjustmentReason;

  const PredictedDifficulty({
    required this.skillId,
    required this.level,
    required this.confidence,
    required this.adjustmentReason,
  });

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'level': level,
        'confidence': confidence,
        'adjustmentReason': adjustmentReason,
      };
}

/// Recommended next challenge for the learner.
class ChallengeRecommendation {
  final String skillId;
  final String challengeType;
  final double difficulty;
  final double expectedSuccessRate;
  final String reasoning;

  const ChallengeRecommendation({
    required this.skillId,
    required this.challengeType,
    required this.difficulty,
    required this.expectedSuccessRate,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'challengeType': challengeType,
        'difficulty': difficulty,
        'expectedSuccessRate': expectedSuccessRate,
        'reasoning': reasoning,
      };
}

/// Standalone difficulty prediction using learner model signals.
///
/// Uses mastery, recent trend, error concentration, time since last practice,
/// and error entropy to predict difficulty and suggest the next challenge.
class DifficultyPredictor {
  DifficultyPredictor._();

  static LearnerModelService get _learnerModel => LearnerModelService.instance;

  /// Predicts difficulty for a single skill.
  ///
  /// Base: current mastery. Adjusts up if high accuracy + streak >= 3;
  /// adjusts down if low accuracy + many attempts. Factors time decay
  /// (longer since practice → lower predicted difficulty) and error
  /// concentration (high error entropy → lower difficulty).
  static PredictedDifficulty predictForSkill(String learnerId, String skillId) {
    final state = _learnerModel.getState(learnerId: learnerId, skillId: skillId);

    double level = state.mastery.clamp(0.1, 0.95);
    final reasons = <String>[];

    if (state.totalAttempts == 0) {
      return PredictedDifficulty(
        skillId: skillId,
        level: 0.2,
        confidence: 0.3,
        adjustmentReason: 'New skill; starting at low difficulty.',
      );
    }

    // Error concentration: high error entropy → lower difficulty
    final errorEntropy = ErrorTaxonomy.errorEntropy(state.errorDistribution.rates);
    if (errorEntropy > 2.0) {
      level = (level - 0.12).clamp(0.0, 1.0);
      reasons.add('High error entropy; lowering difficulty.');
    }

    final errorSeverity = ErrorTaxonomy.weightedSeverity(state.errorDistribution.rates);
    if (errorSeverity > 0.4) {
      level = (level - 0.15).clamp(0.0, 1.0);
      reasons.add('High error concentration; lowering difficulty.');
    } else if (errorSeverity < 0.15 && state.accuracy > 0.8) {
      level = (level + 0.08).clamp(0.0, 1.0);
      reasons.add('Strong performance; raising difficulty.');
    }

    // Adjust down if low accuracy + many attempts
    if (state.accuracy < 0.5 && state.totalAttempts > 3) {
      level = (level - 0.15).clamp(0.0, 1.0);
      reasons.add('Low accuracy with multiple attempts; reducing difficulty.');
    }

    // Adjust up if high accuracy + streak >= 3
    if (state.accuracy > 0.85 && state.currentStreak >= 3) {
      level = (level + 0.08).clamp(0.0, 1.0);
      reasons.add('High accuracy and streak; raising difficulty.');
    }

    if (state.timePressureScore < 0.4) {
      level = (level - 0.1).clamp(0.0, 1.0);
      reasons.add('Low time-pressure score; reducing difficulty.');
    } else if (state.timePressureScore > 0.75 && state.accuracy > 0.85) {
      level = (level + 0.05).clamp(0.0, 1.0);
      reasons.add('Good automaticity; slight increase.');
    }

    // Time decay: longer since practice → lower predicted difficulty
    final recall = state.currentRecallProbability;
    final hoursSincePractice = DateTime.now().difference(state.lastPractice).inHours / 24.0;
    if (recall < 0.6 || hoursSincePractice > 7) {
      level = (level - 0.1).clamp(0.0, 1.0);
      reasons.add('Memory decay or long gap since practice; easier content.');
    }

    final confidence = _confidenceFromAttempts(state.totalAttempts);
    return PredictedDifficulty(
      skillId: skillId,
      level: level.clamp(0.0, 1.0),
      confidence: confidence,
      adjustmentReason: reasons.isEmpty ? 'Stable; maintaining level.' : reasons.join(' '),
    );
  }

  /// Batch prediction for multiple skills in a session.
  static List<PredictedDifficulty> predictForSession(
    String learnerId,
    List<String> skillIds,
  ) {
    return skillIds
        .map((skillId) => predictForSkill(learnerId, skillId))
        .toList();
  }

  /// Suggests the next challenge (skill with best learning ROI) for the learner.
  static ChallengeRecommendation suggestNextChallenge(
    String learnerId,
    String languageCode,
  ) {
    final recommendations = _learnerModel.getRecommendations(
      learnerId: learnerId,
      languageCode: languageCode,
      count: 5,
    );

    if (recommendations.isEmpty) {
      return ChallengeRecommendation(
        skillId: '',
        challengeType: 'new_skill',
        difficulty: 0.2,
        expectedSuccessRate: 0.7,
        reasoning: 'No recommendations; consider starting a new skill.',
      );
    }

    final top = recommendations.first;
    final predicted = predictForSkill(learnerId, top.skillId);
    final state = top.state;

    String challengeType = 'practice';
    double expectedSuccessRate = 0.7;
    String reasoning = 'Recommended by learner model (best learning ROI).';

    if (top.reason == RecommendationReason.dueForReview) {
      challengeType = 'review';
      expectedSuccessRate = state != null ? state.currentRecallProbability.clamp(0.4, 0.9) : 0.65;
      reasoning = 'Skill due for review; memory decay detected.';
    } else if (top.reason == RecommendationReason.newSkill) {
      challengeType = 'new_skill';
      expectedSuccessRate = 0.6;
      reasoning = 'New skill unlocked; moderate difficulty.';
    } else if (top.reason == RecommendationReason.errorRemediation) {
      challengeType = 'remediation';
      expectedSuccessRate = state != null ? (0.5 + state.accuracy * 0.3) : 0.6;
      reasoning = 'Targeted practice for concentrated errors.';
    }

    return ChallengeRecommendation(
      skillId: top.skillId,
      challengeType: challengeType,
      difficulty: predicted.level,
      expectedSuccessRate: expectedSuccessRate.clamp(0.3, 0.95),
      reasoning: reasoning,
    );
  }

  static double _confidenceFromAttempts(int totalAttempts) {
    if (totalAttempts >= 20) return 0.9;
    if (totalAttempts >= 10) return 0.75;
    if (totalAttempts >= 5) return 0.55;
    if (totalAttempts >= 1) return 0.4;
    return 0.2;
  }
}
