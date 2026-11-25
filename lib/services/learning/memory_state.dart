/// FSRS-6 memory for one item. Stability is the interval, in days, at 90 percent recall.
class MemoryState {
  const MemoryState({
    this.stability,
    this.difficulty,
    this.phase = FsrsPhase.learning,
    this.step = 0,
    this.lastReview,
    this.due,
  });

  final double? stability;
  final double? difficulty;
  final FsrsPhase phase;
  final int? step;
  final DateTime? lastReview;
  final DateTime? due;

  MemoryState copyWith({
    double? stability,
    double? difficulty,
    FsrsPhase? phase,
    int? step,
    bool clearStep = false,
    DateTime? lastReview,
    DateTime? due,
  }) {
    return MemoryState(
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      phase: phase ?? this.phase,
      step: clearStep ? null : (step ?? this.step),
      lastReview: lastReview ?? this.lastReview,
      due: due ?? this.due,
    );
  }
}

enum FsrsPhase { learning, review, relearning }

/// 1 again, 2 hard, 3 good, 4 easy.
enum FsrsRating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const FsrsRating(this.value);
  final int value;

  /// A 0–5 quality score. 0–2 fail, 3 is hard, 4 is good, 5 is easy.
  static FsrsRating fromQuality(int quality) {
    if (quality <= 2) return FsrsRating.again;
    if (quality == 3) return FsrsRating.hard;
    if (quality == 4) return FsrsRating.good;
    return FsrsRating.easy;
  }
}
