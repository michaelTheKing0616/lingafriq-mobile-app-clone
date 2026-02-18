import 'dart:math';

/// Half-Life Regression (HLR) implementation for memory decay modeling.
///
/// Based on Settles & Meeder (2016): "A Trainable Spaced Repetition Model
/// for Language Learning." Models the probability that a learner will recall
/// a skill after a given time interval, and updates the memory stability
/// (half-life) after each practice attempt.
///
/// The half-life represents how many days until recall probability drops to 50%.
/// Longer half-lives indicate stronger, more stable memories.
class HlrForgettingCurve {
  HlrForgettingCurve._();

  /// Default parameters calibrated for language learning.
  static const double defaultAlpha = 0.2;
  static const double defaultBetaMin = 0.3;
  static const double defaultBetaMax = 0.6;
  static const double initialHalfLifeDays = 0.5;
  static const double minHalfLifeDays = 0.1;
  static const double maxHalfLifeDays = 365.0;

  /// Computes the probability of successful recall after [elapsedDays]
  /// given a memory with [halfLifeDays] stability.
  ///
  /// Formula: P(recall) = 2^(-Δt / H)
  ///
  /// Returns a value in [0, 1] where 1 means certain recall.
  static double recallProbability({
    required double elapsedDays,
    required double halfLifeDays,
  }) {
    if (elapsedDays <= 0) return 1.0;
    if (halfLifeDays <= 0) return 0.0;

    final probability = pow(2, -elapsedDays / halfLifeDays).toDouble();
    return probability.clamp(0.0, 1.0);
  }

  /// Updates the half-life after a practice attempt.
  ///
  /// Successful recall increases stability (longer half-life).
  /// Failed recall decreases stability, with the decrease proportional
  /// to error severity.
  ///
  /// Formula: H_new = H_old * e^(alpha * success - beta * error_severity)
  ///
  /// [wasSuccessful] — whether the learner recalled correctly.
  /// [errorSeverity] — severity of errors (0.0 = no error, 1.0 = severe).
  /// [alpha] — reward factor for successful recall (default 0.2).
  /// [beta] — penalty factor for errors (default derived from severity).
  /// [difficultyBonus] — extra stability boost for recalling difficult items.
  static double updateHalfLife({
    required double currentHalfLifeDays,
    required bool wasSuccessful,
    double errorSeverity = 0.0,
    double alpha = defaultAlpha,
    double? beta,
    double difficultyBonus = 0.0,
  }) {
    final effectiveBeta = beta ??
        _interpolateBeta(errorSeverity);

    final successTerm = wasSuccessful ? 1.0 : 0.0;
    final exponent = (alpha * successTerm) + difficultyBonus - (effectiveBeta * errorSeverity);

    final newHalfLife = currentHalfLifeDays * exp(exponent);

    return newHalfLife.clamp(minHalfLifeDays, maxHalfLifeDays);
  }

  /// Computes the optimal review time — when recall probability drops to [targetProbability].
  ///
  /// Solving P = 2^(-t/H) for t gives: t = -H * log2(P)
  static double optimalReviewDays({
    required double halfLifeDays,
    double targetProbability = 0.5,
  }) {
    if (targetProbability <= 0 || targetProbability >= 1) return halfLifeDays;

    return -halfLifeDays * (log(targetProbability) / log(2));
  }

  /// Estimates how many successful reviews are needed to reach [targetHalfLife].
  ///
  /// Assumes each review multiplies half-life by e^alpha.
  static int reviewsToTarget({
    required double currentHalfLife,
    required double targetHalfLife,
    double alpha = defaultAlpha,
  }) {
    if (currentHalfLife >= targetHalfLife) return 0;
    if (alpha <= 0) return -1;

    final ratio = targetHalfLife / currentHalfLife;
    return (log(ratio) / alpha).ceil();
  }

  /// Returns the urgency score for reviewing a skill.
  ///
  /// Higher values mean the skill is more urgently in need of review.
  /// Based on how far recall probability has dropped below the threshold.
  ///
  /// Returns 0.0 if skill doesn't need review, up to 1.0 for critical.
  static double reviewUrgency({
    required double elapsedDays,
    required double halfLifeDays,
    double recallThreshold = 0.7,
  }) {
    final currentRecall = recallProbability(
      elapsedDays: elapsedDays,
      halfLifeDays: halfLifeDays,
    );

    if (currentRecall >= recallThreshold) return 0.0;

    return ((recallThreshold - currentRecall) / recallThreshold).clamp(0.0, 1.0);
  }

  /// Interpolates beta between [defaultBetaMin] and [defaultBetaMax]
  /// based on error severity. More severe errors receive higher penalties.
  static double _interpolateBeta(double errorSeverity) {
    return defaultBetaMin + (defaultBetaMax - defaultBetaMin) * errorSeverity.clamp(0.0, 1.0);
  }
}
