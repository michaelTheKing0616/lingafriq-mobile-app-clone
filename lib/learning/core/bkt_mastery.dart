import 'dart:math' show log;

/// Bayesian Knowledge Tracing (BKT) implementation for mastery estimation.
///
/// Based on Corbett & Anderson (1995): "Knowledge Tracing: Modeling the
/// Acquisition of Procedural Knowledge."
///
/// BKT models a learner's latent knowledge state as a binary variable
/// (known vs unknown) and updates the probability of knowing a skill
/// after each observed response (correct or incorrect).
///
/// Four parameters control the model:
/// - P(L0): initial probability of knowing the skill
/// - P(T):  probability of learning on each opportunity
/// - P(S):  probability of slipping (knows but answers wrong)
/// - P(G):  probability of guessing (doesn't know but answers right)
class BktMastery {
  BktMastery._();

  /// Default BKT parameters calibrated for language learning.
  ///
  /// These defaults are conservative — they assume learners start
  /// with low mastery and learn gradually. Per-skill tuning is recommended.
  static const BktParams defaultParams = BktParams(
    pL0: 0.10,
    pT: 0.10,
    pS: 0.10,
    pG: 0.25,
  );

  /// Mastery threshold — above this, a skill is considered "learned."
  static const double masteryThreshold = 0.95;

  /// Updates the mastery probability after observing a response.
  ///
  /// [currentMastery] — P(K) before the observation.
  /// [wasCorrect] — whether the learner responded correctly.
  /// [params] — BKT parameters for this skill.
  ///
  /// Returns the updated P(K) after incorporating the observation and
  /// accounting for the learning transition.
  static double updateMastery({
    required double currentMastery,
    required bool wasCorrect,
    BktParams params = defaultParams,
  }) {
    final pK = currentMastery.clamp(0.001, 0.999);

    // Step 1: Posterior update given observation
    final pKGivenObs = wasCorrect
        ? _posteriorGivenCorrect(pK, params)
        : _posteriorGivenIncorrect(pK, params);

    // Step 2: Learning transition — even after wrong answers, learning can occur
    final pKNew = pKGivenObs + (1.0 - pKGivenObs) * params.pT;

    return pKNew.clamp(0.0, 1.0);
  }

  /// Batch update: processes a sequence of observations.
  ///
  /// Returns the mastery trajectory (list of P(K) after each observation).
  static List<double> batchUpdate({
    required double initialMastery,
    required List<bool> responses,
    BktParams params = defaultParams,
  }) {
    final trajectory = <double>[];
    double mastery = initialMastery;

    for (final wasCorrect in responses) {
      mastery = updateMastery(
        currentMastery: mastery,
        wasCorrect: wasCorrect,
        params: params,
      );
      trajectory.add(mastery);
    }

    return trajectory;
  }

  /// Predicts the probability of a correct response given current mastery.
  ///
  /// P(correct) = P(K)(1 - P(S)) + (1 - P(K))P(G)
  static double predictCorrectProbability({
    required double mastery,
    BktParams params = defaultParams,
  }) {
    return mastery * (1.0 - params.pS) + (1.0 - mastery) * params.pG;
  }

  /// Estimates the number of additional practice opportunities needed
  /// to reach the mastery threshold, assuming all attempts are correct.
  static int opportunitiesToMastery({
    required double currentMastery,
    BktParams params = defaultParams,
    double threshold = masteryThreshold,
  }) {
    if (currentMastery >= threshold) return 0;

    double mastery = currentMastery;
    int count = 0;
    const maxIterations = 200;

    while (mastery < threshold && count < maxIterations) {
      mastery = updateMastery(
        currentMastery: mastery,
        wasCorrect: true,
        params: params,
      );
      count++;
    }

    return count;
  }

  /// Whether this skill has reached the mastery threshold.
  static bool isMastered(double mastery, {double threshold = masteryThreshold}) {
    return mastery >= threshold;
  }

  /// Computes the information gain from the next observation.
  ///
  /// Higher information gain means testing this skill will be more
  /// informative about the learner's true state. Useful for adaptive
  /// item selection.
  static double informationGain({
    required double mastery,
    BktParams params = defaultParams,
  }) {
    final pCorrect = predictCorrectProbability(mastery: mastery, params: params);

    // Entropy before observation
    final entropyBefore = _binaryEntropy(mastery);

    // Expected entropy after observation
    final masteryIfCorrect = updateMastery(
      currentMastery: mastery,
      wasCorrect: true,
      params: params,
    );
    final masteryIfIncorrect = updateMastery(
      currentMastery: mastery,
      wasCorrect: false,
      params: params,
    );

    final entropyAfter = pCorrect * _binaryEntropy(masteryIfCorrect) +
        (1.0 - pCorrect) * _binaryEntropy(masteryIfIncorrect);

    return (entropyBefore - entropyAfter).clamp(0.0, 1.0);
  }

  /// Posterior P(K | correct response).
  ///
  /// P(K|correct) = P(K)(1-S) / [P(K)(1-S) + (1-P(K))G]
  static double _posteriorGivenCorrect(double pK, BktParams params) {
    final numerator = pK * (1.0 - params.pS);
    final denominator = numerator + (1.0 - pK) * params.pG;

    if (denominator == 0) return pK;
    return numerator / denominator;
  }

  /// Posterior P(K | incorrect response).
  ///
  /// P(K|incorrect) = P(K) * S / [P(K) * S + (1-P(K))(1-G)]
  static double _posteriorGivenIncorrect(double pK, BktParams params) {
    final numerator = pK * params.pS;
    final denominator = numerator + (1.0 - pK) * (1.0 - params.pG);

    if (denominator == 0) return pK;
    return numerator / denominator;
  }

  /// Binary entropy H(p) = -p*log2(p) - (1-p)*log2(1-p).
  static double _binaryEntropy(double p) {
    if (p <= 0.0 || p >= 1.0) return 0.0;

    return -(p * _log2(p) + (1.0 - p) * _log2(1.0 - p));
  }

  static double _log2(double x) {
    if (x <= 0) return 0;
    return log(x) / ln2;
  }
}

/// Parameters for a BKT skill model.
///
/// These can be tuned per-skill or per-skill-type for better accuracy.
class BktParams {
  /// P(L0): Initial probability that the learner knows the skill.
  final double pL0;

  /// P(T): Probability of transitioning from unknown to known on each attempt.
  final double pT;

  /// P(S): Probability of slipping (answering wrong despite knowing).
  final double pS;

  /// P(G): Probability of guessing correctly despite not knowing.
  final double pG;

  const BktParams({
    required this.pL0,
    required this.pT,
    required this.pS,
    required this.pG,
  })  : assert(pL0 >= 0 && pL0 <= 1, 'pL0 must be in [0, 1]'),
        assert(pT >= 0 && pT <= 1, 'pT must be in [0, 1]'),
        assert(pS >= 0 && pS <= 1, 'pS must be in [0, 1]'),
        assert(pG >= 0 && pG <= 1, 'pG must be in [0, 1]');

  /// Creates params from JSON.
  factory BktParams.fromJson(Map<String, dynamic> json) {
    return BktParams(
      pL0: (json['pL0'] as num).toDouble(),
      pT: (json['pT'] as num).toDouble(),
      pS: (json['pS'] as num).toDouble(),
      pG: (json['pG'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pL0': pL0,
    'pT': pT,
    'pS': pS,
    'pG': pG,
  };

  BktParams copyWith({double? pL0, double? pT, double? pS, double? pG}) {
    return BktParams(
      pL0: pL0 ?? this.pL0,
      pT: pT ?? this.pT,
      pS: pS ?? this.pS,
      pG: pG ?? this.pG,
    );
  }
}

/// ln(2) constant for log2 calculations.
const double ln2 = 0.6931471805599453;
