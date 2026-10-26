import 'dart:math';

import 'package:lingafriq/services/learning/memory_state.dart';

/// Canonical on-device FSRS-6 scheduler (P5-019). Fuzzing is off so replays match.
class Fsrs6Scheduler {
  const Fsrs6Scheduler({
    this.learningSteps = const [
      Duration(minutes: 1),
      Duration(minutes: 10),
    ],
    this.relearningSteps = const [Duration(minutes: 10)],
    this.maximumInterval = 36500,
    this.desiredRetention = 0.9,
    this.parameters = defaultParameters,
  });

  const Fsrs6Scheduler.days({
    this.parameters = defaultParameters,
  })  : learningSteps = const [],
        relearningSteps = const [],
        maximumInterval = 36500,
        desiredRetention = 0.9;

  factory Fsrs6Scheduler.forLearner(LearnerFsrsParameters profile) {
    return Fsrs6Scheduler(
      parameters: profile.effectiveWeights,
      learningSteps: const [
        Duration(minutes: 1),
        Duration(minutes: 10),
      ],
      relearningSteps: const [Duration(minutes: 10)],
    );
  }

  static const List<double> defaultParameters = [
    0.212,
    1.2931,
    2.3065,
    8.2956,
    6.4133,
    0.8334,
    3.0194,
    0.001,
    1.8722,
    0.1666,
    0.796,
    1.4835,
    0.0614,
    0.2629,
    1.6483,
    0.6014,
    1.8729,
    0.5425,
    0.0912,
    0.0658,
    0.1542,
  ];

  final List<Duration> learningSteps;
  final List<Duration> relearningSteps;
  final int maximumInterval;
  final double desiredRetention;
  final List<double> parameters;

  static const double stabilityMin = 0.001;
  static const double difficultyMin = 1;
  static const double difficultyMax = 10;

  double get _decay => -parameters[20];

  double get _factor => pow(0.9, 1 / _decay).toDouble() - 1;

  double retrievability({
    required double elapsedDays,
    required double stability,
  }) {
    if (stability <= 0 || elapsedDays < 0) return 0;
    return pow(1 + _factor * elapsedDays / stability, _decay).toDouble();
  }

  int intervalDays(double stability, {double? retention}) {
    final target = retention ?? desiredRetention;
    final raw = (stability / _factor) * (pow(target, 1 / _decay) - 1);
    return pythonRound(raw).clamp(1, maximumInterval);
  }

  MemoryState review(MemoryState memory, FsrsRating rating, DateTime at) {
    final daysSince = memory.lastReview == null
        ? null
        : at.difference(memory.lastReview!).inDays;
    var stability = memory.stability;
    var difficulty = memory.difficulty;
    var phase = memory.phase;
    var step = memory.step;

    if (phase == FsrsPhase.learning && (stability == null || difficulty == null)) {
      stability = _initialStability(rating);
      difficulty = _initialDifficulty(rating, clamp: true);
    } else if (daysSince != null && daysSince < 1) {
      stability = _shortTermStability(stability!, rating);
      difficulty = _nextDifficulty(difficulty!, rating);
    } else {
      final recall = memory.lastReview == null || stability == null
          ? 0.0
          : retrievability(elapsedDays: daysSince!.toDouble(), stability: stability);
      stability = _nextStability(difficulty!, stability!, recall, rating);
      difficulty = _nextDifficulty(difficulty, rating);
    }

    final Duration next;
    if (phase == FsrsPhase.learning) {
      final graduated = learningSteps.isEmpty ||
          ((step ?? 0) >= learningSteps.length && rating != FsrsRating.again);
      if (graduated) {
        phase = FsrsPhase.review;
        step = null;
        next = Duration(days: intervalDays(stability));
      } else {
        final moved = _stepInterval(
          steps: learningSteps,
          relearning: false,
          step: step ?? 0,
          rating: rating,
          stability: stability,
        );
        step = moved.step;
        phase = moved.phase;
        next = moved.interval;
      }
    } else if (phase == FsrsPhase.review) {
      if (rating == FsrsRating.again && relearningSteps.isNotEmpty) {
        phase = FsrsPhase.relearning;
        step = 0;
        next = relearningSteps[0];
      } else {
        next = Duration(days: intervalDays(stability));
      }
    } else {
      final graduated = relearningSteps.isEmpty ||
          ((step ?? 0) >= relearningSteps.length && rating != FsrsRating.again);
      if (graduated) {
        phase = FsrsPhase.review;
        step = null;
        next = Duration(days: intervalDays(stability));
      } else {
        final moved = _stepInterval(
          steps: relearningSteps,
          relearning: true,
          step: step ?? 0,
          rating: rating,
          stability: stability,
        );
        step = moved.step;
        phase = moved.phase;
        next = moved.interval;
      }
    }

    return MemoryState(
      stability: stability,
      difficulty: difficulty,
      phase: phase,
      step: step,
      lastReview: at,
      due: at.add(next),
    );
  }

  static double difficultyFromEase(double ease) =>
      (11 - ease).clamp(difficultyMin, difficultyMax);

  static double easeFromDifficulty(double difficulty) =>
      (11 - difficulty).clamp(1.3, double.infinity);

  MemoryState replay(MemoryState start, List<FsrsReview> reviews) {
    var current = start;
    for (final review in reviews) {
      current = this.review(current, review.rating, review.at);
    }
    return current;
  }

  /// Maps a legacy SM-2 card snapshot into FSRS memory (ADR-005 migration).
  static MemoryState migrateLegacySm2({
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime lastReview,
  }) {
    final stability = intervalDays.toDouble().clamp(stabilityMin, 36500.0);
    final difficulty = difficultyFromEase(easeFactor);
    final phase = repetitions >= 1 ? FsrsPhase.review : FsrsPhase.learning;
    return MemoryState(
      stability: stability,
      difficulty: difficulty,
      phase: phase,
      lastReview: lastReview,
      due: lastReview.add(Duration(days: max(1, intervalDays))),
    );
  }

  /// Maps half-life regression stability into FSRS memory.
  static MemoryState migrateLegacyHalfLife({
    required double halfLifeDays,
    required DateTime lastRecall,
  }) {
    return MemoryState(
      stability: halfLifeDays.clamp(stabilityMin, 36500.0),
      difficulty: 5,
      phase: FsrsPhase.review,
      lastReview: lastRecall,
    );
  }

  double _initialStability(FsrsRating rating) {
    return max(parameters[rating.value - 1], stabilityMin);
  }

  double _initialDifficulty(FsrsRating rating, {required bool clamp}) {
    final value = parameters[4] - exp(parameters[5] * (rating.value - 1)) + 1;
    return clamp ? value.clamp(difficultyMin, difficultyMax) : value;
  }

  double _shortTermStability(double stability, FsrsRating rating) {
    var increase = exp(parameters[17] * (rating.value - 3 + parameters[18])) *
        pow(stability, -parameters[19]);
    if (rating != FsrsRating.again) increase = max(increase, 1);
    return max(stability * increase, stabilityMin);
  }

  double _nextDifficulty(double difficulty, FsrsRating rating) {
    final target = _initialDifficulty(FsrsRating.easy, clamp: false);
    final delta = -(parameters[6] * (rating.value - 3));
    final damped = difficulty + (10 - difficulty) * delta / 9;
    final next = parameters[7] * target + (1 - parameters[7]) * damped;
    return next.clamp(difficultyMin, difficultyMax);
  }

  double _nextStability(
    double difficulty,
    double stability,
    double recall,
    FsrsRating rating,
  ) {
    final next = rating == FsrsRating.again
        ? _forgetStability(difficulty, stability, recall)
        : _recallStability(difficulty, stability, recall, rating);
    return max(next, stabilityMin);
  }

  double _forgetStability(double difficulty, double stability, double recall) {
    final longTerm = parameters[11] *
        pow(difficulty, -parameters[12]) *
        (pow(stability + 1, parameters[13]) - 1) *
        exp((1 - recall) * parameters[14]);
    final shortTerm = stability / exp(parameters[17] * parameters[18]);
    return min(longTerm, shortTerm);
  }

  double _recallStability(
    double difficulty,
    double stability,
    double recall,
    FsrsRating rating,
  ) {
    final hardPenalty = rating == FsrsRating.hard ? parameters[15] : 1.0;
    final easyBonus = rating == FsrsRating.easy ? parameters[16] : 1.0;
    return stability *
        (1 +
            exp(parameters[8]) *
                (11 - difficulty) *
                pow(stability, -parameters[9]) *
                (exp((1 - recall) * parameters[10]) - 1) *
                hardPenalty *
                easyBonus);
  }

  _StepMove _stepInterval({
    required List<Duration> steps,
    required bool relearning,
    required int step,
    required FsrsRating rating,
    required double stability,
  }) {
    final phase = relearning ? FsrsPhase.relearning : FsrsPhase.learning;
    switch (rating) {
      case FsrsRating.again:
        return _StepMove(phase: phase, step: 0, interval: steps[0]);
      case FsrsRating.hard:
        if (step == 0 && steps.length == 1) {
          return _StepMove(phase: phase, step: step, interval: _scale(steps[0], 1.5));
        }
        if (step == 0 && steps.length >= 2) {
          return _StepMove(
            phase: phase,
            step: step,
            interval: _scale(steps[0] + steps[1], 0.5),
          );
        }
        return _StepMove(phase: phase, step: step, interval: steps[step]);
      case FsrsRating.good:
        if (step + 1 == steps.length) {
          return _StepMove(
            phase: FsrsPhase.review,
            step: null,
            interval: Duration(days: intervalDays(stability)),
          );
        }
        return _StepMove(
          phase: phase,
          step: step + 1,
          interval: steps[step + 1],
        );
      case FsrsRating.easy:
        return _StepMove(
          phase: FsrsPhase.review,
          step: null,
          interval: Duration(days: intervalDays(stability)),
        );
    }
  }
}

/// Per-learner FSRS weights. Optimised after [optimizationReviewThreshold] reviews.
class LearnerFsrsParameters {
  const LearnerFsrsParameters({
    this.weights = Fsrs6Scheduler.defaultParameters,
    this.reviewCount = 0,
  });

  static const int optimizationReviewThreshold = 1000;

  final List<double> weights;
  final int reviewCount;

  List<double> get effectiveWeights =>
      reviewCount >= optimizationReviewThreshold ? weights : Fsrs6Scheduler.defaultParameters;

  bool get isOptimised => reviewCount >= optimizationReviewThreshold;

  LearnerFsrsParameters withRecordedReview() {
    return LearnerFsrsParameters(weights: weights, reviewCount: reviewCount + 1);
  }

  /// Deterministic weight tune from a review log (used at the 1k-review gate).
  LearnerFsrsParameters optimizeFromLog(List<FsrsReviewLogEntry> log) {
    if (log.length < optimizationReviewThreshold) {
      return LearnerFsrsParameters(reviewCount: log.length);
    }
    final againCount =
        log.where((entry) => entry.rating == FsrsRating.again).length;
    final againRate = againCount / log.length;
    final tuned = List<double>.from(Fsrs6Scheduler.defaultParameters);
    tuned[11] = (tuned[11] * (1 + (againRate - 0.2) * 0.05)).clamp(0.05, 5.0);
    return LearnerFsrsParameters(weights: tuned, reviewCount: log.length);
  }

  Map<String, dynamic> toJson() => {
        'weights': weights,
        'reviewCount': reviewCount,
      };

  factory LearnerFsrsParameters.fromJson(Map<String, dynamic> json) {
    final raw = json['weights'] as List<dynamic>?;
    return LearnerFsrsParameters(
      weights: raw == null
          ? Fsrs6Scheduler.defaultParameters
          : raw.map((v) => (v as num).toDouble()).toList(growable: false),
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }
}

class FsrsReviewLogEntry {
  const FsrsReviewLogEntry({required this.rating, required this.at});
  final FsrsRating rating;
  final DateTime at;
}

Duration _scale(Duration value, double factor) {
  return Duration(microseconds: (value.inMicroseconds * factor).round());
}

class FsrsReview {
  const FsrsReview(this.rating, this.at);
  final FsrsRating rating;
  final DateTime at;
}

class _StepMove {
  const _StepMove({required this.phase, required this.step, required this.interval});
  final FsrsPhase phase;
  final int? step;
  final Duration interval;
}

int pythonRound(double value) {
  final lower = value.floor();
  final fraction = value - lower;
  if ((fraction - 0.5).abs() > 1e-9) {
    return fraction < 0.5 ? lower : lower + 1;
  }
  return lower.isEven ? lower : lower + 1;
}
