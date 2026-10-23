import 'dart:math';

import 'memory_state.dart';

/// FSRS-6, fuzzing off so the same reviews always produce the same state.
///
/// Weights are the published defaults from py-fsrs (21 parameters).
/// A day scheduler has no minute-long learning steps, because some stores
/// only keep a whole-day interval.
class Fsrs6Scheduler {
  const Fsrs6Scheduler({
    this.learningSteps = const [
      Duration(minutes: 1),
      Duration(minutes: 10),
    ],
    this.relearningSteps = const [Duration(minutes: 10)],
    this.maximumInterval = 36500,
    this.desiredRetention = 0.9,
  });

  const Fsrs6Scheduler.days()
      : learningSteps = const [],
        relearningSteps = const [],
        maximumInterval = 36500,
        desiredRetention = 0.9;

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

  static const double stabilityMin = 0.001;
  static const double difficultyMin = 1;
  static const double difficultyMax = 10;

  double get _decay => -defaultParameters[20];

  double get _factor => pow(0.9, 1 / _decay).toDouble() - 1;

  double retrievability({
    required double elapsedDays,
    required double stability,
  }) {
    if (stability <= 0 || elapsedDays < 0) return 0;
    return pow(1 + _factor * elapsedDays / stability, _decay).toDouble();
  }

  /// Whole days until retention falls to [retention]. At 0.9 this equals stability.
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

  /// Stored ease rises when FSRS difficulty falls. The floor stays 1.3.
  static double difficultyFromEase(double ease) => (11 - ease).clamp(difficultyMin, difficultyMax);

  static double easeFromDifficulty(double difficulty) =>
      (11 - difficulty).clamp(1.3, double.infinity);

  MemoryState replay(MemoryState start, List<FsrsReview> reviews) {
    var current = start;
    for (final review in reviews) {
      current = this.review(current, review.rating, review.at);
    }
    return current;
  }

  double _initialStability(FsrsRating rating) {
    return max(defaultParameters[rating.value - 1], stabilityMin);
  }

  double _initialDifficulty(FsrsRating rating, {required bool clamp}) {
    final value = defaultParameters[4] -
        exp(defaultParameters[5] * (rating.value - 1)) +
        1;
    return clamp ? value.clamp(difficultyMin, difficultyMax) : value;
  }

  double _shortTermStability(double stability, FsrsRating rating) {
    var increase = exp(defaultParameters[17] * (rating.value - 3 + defaultParameters[18])) *
        pow(stability, -defaultParameters[19]);
    if (rating != FsrsRating.again) increase = max(increase, 1);
    return max(stability * increase, stabilityMin);
  }

  double _nextDifficulty(double difficulty, FsrsRating rating) {
    final target = _initialDifficulty(FsrsRating.easy, clamp: false);
    final delta = -(defaultParameters[6] * (rating.value - 3));
    final damped = difficulty + (10 - difficulty) * delta / 9;
    final next = defaultParameters[7] * target + (1 - defaultParameters[7]) * damped;
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
    final longTerm = defaultParameters[11] *
        pow(difficulty, -defaultParameters[12]) *
        (pow(stability + 1, defaultParameters[13]) - 1) *
        exp((1 - recall) * defaultParameters[14]);
    final shortTerm = stability / exp(defaultParameters[17] * defaultParameters[18]);
    return min(longTerm, shortTerm);
  }

  double _recallStability(
    double difficulty,
    double stability,
    double recall,
    FsrsRating rating,
  ) {
    final hardPenalty = rating == FsrsRating.hard ? defaultParameters[15] : 1.0;
    final easyBonus = rating == FsrsRating.easy ? defaultParameters[16] : 1.0;
    return stability *
        (1 +
            exp(defaultParameters[8]) *
                (11 - difficulty) *
                pow(stability, -defaultParameters[9]) *
                (exp((1 - recall) * defaultParameters[10]) - 1) *
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

/// Python's round-half-to-even, for the published interval.
int pythonRound(double value) {
  final lower = value.floor();
  final fraction = value - lower;
  if ((fraction - 0.5).abs() > 1e-9) {
    return fraction < 0.5 ? lower : lower + 1;
  }
  return lower.isEven ? lower : lower + 1;
}
