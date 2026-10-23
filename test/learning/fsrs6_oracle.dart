import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/memory_state.dart';

void verifyFsrs6(dynamic scheduler) {
  verifyFsrs6PublishedVectors(scheduler);
  verifyFsrs6Replay(scheduler);
  verifyFsrs6RandomReviews(scheduler);
  verifyFsrs6RatingOrder(scheduler);
  verifyFsrs6Branches(scheduler);
  verifyFsrs6Edges(scheduler);
}

void verifyFsrs6PublishedVectors(dynamic scheduler) {
  final t0 = DateTime.utc(2026, 1, 1);
  final first = scheduler.review(const MemoryState(), FsrsRating.good, t0);
  expect(first.stability, closeTo(2.3065, 1e-6));
  expect(first.difficulty, closeTo(2.118103970459016, 1e-6));
  expect(first.phase, FsrsPhase.learning);
  expect(first.due!.difference(t0), const Duration(minutes: 10));
  expect(
    scheduler.retrievability(elapsedDays: 0.0, stability: first.stability),
    closeTo(1, 1e-6),
  );

  final t1 = t0.add(const Duration(days: 1));
  expect(
    scheduler.retrievability(elapsedDays: 1.0, stability: first.stability),
    closeTo(0.9468474993825461, 1e-6),
  );
  final second = scheduler.review(first, FsrsRating.good, t1);
  expect(second.stability, closeTo(7.31530074407728, 1e-6));
  expect(second.difficulty, closeTo(2.111214235785395, 1e-6));
  expect(second.phase, FsrsPhase.review);
  expect(second.due, DateTime.utc(2026, 1, 9));

  expect(
    scheduler.retrievability(
      elapsedDays: second.due!.difference(second.lastReview!).inDays.toDouble(),
      stability: second.stability,
    ),
    closeTo(0.9029981645406641, 1e-6),
  );
  final third = scheduler.review(second, FsrsRating.again, second.due!);
  expect(third.stability, closeTo(1.2389417584956706, 1e-6));
  expect(third.difficulty, closeTo(7.392238132342694, 1e-6));
  expect(third.phase, FsrsPhase.relearning);
}

void verifyFsrs6Replay(dynamic scheduler) {
  final t0 = DateTime.utc(2026, 1, 1);
  final ratings = [FsrsRating.good, FsrsRating.good, FsrsRating.hard, FsrsRating.easy];
  final times = [
    t0,
    t0.add(const Duration(days: 1)),
    t0.add(const Duration(days: 4)),
    t0.add(const Duration(days: 20)),
  ];
  dynamic whole = const MemoryState();
  for (var index = 0; index < ratings.length; index++) {
    whole = scheduler.review(whole, ratings[index], times[index]);
  }
  dynamic left = const MemoryState();
  for (var index = 0; index < 2; index++) {
    left = scheduler.review(left, ratings[index], times[index]);
  }
  dynamic split = left;
  for (var index = 2; index < ratings.length; index++) {
    split = scheduler.review(split, ratings[index], times[index]);
  }
  expect(split.stability, closeTo(whole.stability, 1e-12));
  expect(split.difficulty, closeTo(whole.difficulty, 1e-12));
  expect(split.due, whole.due);
}

void verifyFsrs6RandomReviews(dynamic scheduler) {
  var seed = 20261023;
  int next() {
    seed = (1664525 * seed + 1013904223) & 0x7fffffff;
    return seed;
  }

  for (var sequence = 0; sequence < 30; sequence++) {
    dynamic memory = const MemoryState();
    var at = DateTime.utc(2026, 1, 1);
    for (var step = 0; step < 8; step++) {
      final rating = FsrsRating.values[next() % 4];
      at = at.add(Duration(days: 1 + next() % 5));
      memory = scheduler.review(memory, rating, at);
      expect(memory.stability, greaterThan(0));
      expect(memory.difficulty, inInclusiveRange(1, 10));
      final recall = scheduler.retrievability(elapsedDays: 0.0, stability: memory.stability);
      expect(recall, inInclusiveRange(0, 1));
      final later = scheduler.retrievability(elapsedDays: 30.0, stability: memory.stability);
      expect(later, inInclusiveRange(0, 1));
    }
  }
}

void verifyFsrs6RatingOrder(dynamic scheduler) {
  final start = DateTime.utc(2026, 1, 1);
  dynamic memory = const MemoryState();
  memory = scheduler.review(memory, FsrsRating.good, start);
  memory = scheduler.review(memory, FsrsRating.good, start.add(const Duration(days: 1)));
  final when = memory.lastReview!.add(const Duration(days: 2));
  DateTime? previous;
  for (final rating in FsrsRating.values) {
    final next = scheduler.review(memory, rating, when);
    expect(next.stability, greaterThan(0));
    if (previous != null) {
      expect(next.due!.isBefore(previous), isFalse);
    }
    previous = next.due;
  }
}

void verifyFsrs6Branches(dynamic scheduler) {
  final t0 = DateTime.utc(2026, 1, 1);
  _expectReview(
    scheduler.review(const MemoryState(), FsrsRating.again, t0),
    stability: 0.212,
    difficulty: 6.4133,
    phase: FsrsPhase.learning,
    step: 0,
    due: const Duration(minutes: 1),
    from: t0,
  );
  _expectReview(
    scheduler.review(const MemoryState(), FsrsRating.hard, t0),
    stability: 1.2931,
    difficulty: 5.112170705601055,
    phase: FsrsPhase.learning,
    step: 0,
    due: const Duration(microseconds: 330000000),
    from: t0,
  );
  _expectReview(
    scheduler.review(const MemoryState(), FsrsRating.easy, t0),
    stability: 8.2956,
    difficulty: 1,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 8),
    from: t0,
  );

  final good = scheduler.review(const MemoryState(), FsrsRating.good, t0);
  final sameAt = t0.add(const Duration(hours: 1));
  _expectReview(
    scheduler.review(good, FsrsRating.again, sameAt),
    stability: 0.7750839828558983,
    difficulty: 7.394502741279718,
    phase: FsrsPhase.learning,
    step: 0,
    due: const Duration(minutes: 1),
    from: sameAt,
  );
  _expectReview(
    scheduler.review(good, FsrsRating.hard, sameAt),
    stability: 2.3065,
    difficulty: 4.752858488532556,
    phase: FsrsPhase.learning,
    step: 1,
    due: const Duration(minutes: 10),
    from: sameAt,
  );
  _expectReview(
    scheduler.review(good, FsrsRating.good, sameAt),
    stability: 2.3065,
    difficulty: 2.1112142357853942,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 2),
    from: sameAt,
  );
  _expectReview(
    scheduler.review(good, FsrsRating.easy, sameAt),
    stability: 3.9460540679694778,
    difficulty: 1,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 4),
    from: sameAt,
  );

  final reviewed = scheduler.review(good, FsrsRating.good, t0.add(const Duration(days: 1)));
  final atDue = reviewed.due as DateTime;
  _expectReview(
    scheduler.review(reviewed, FsrsRating.hard, atDue),
    stability: 21.967765454179595,
    difficulty: 4.7482847615945705,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 22),
    from: atDue,
  );
  _expectReview(
    scheduler.review(reviewed, FsrsRating.good, atDue),
    stability: 31.679226101746572,
    difficulty: 2.1043313908464474,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 32),
    from: atDue,
  );
  _expectReview(
    scheduler.review(reviewed, FsrsRating.easy, atDue),
    stability: 52.9464965464561,
    difficulty: 1,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 53),
    from: atDue,
  );

  final forgotten = scheduler.review(reviewed, FsrsRating.again, atDue);
  final relearnAt = forgotten.due as DateTime;
  _expectReview(
    scheduler.review(forgotten, FsrsRating.again, relearnAt),
    stability: 0.43371633912658636,
    difficulty: 9.128074776178583,
    phase: FsrsPhase.relearning,
    step: 0,
    due: const Duration(minutes: 10),
    from: relearnAt,
  );
  _expectReview(
    scheduler.review(forgotten, FsrsRating.hard, relearnAt),
    stability: 1.2389417584956706,
    difficulty: 8.254074519842886,
    phase: FsrsPhase.relearning,
    step: 0,
    due: const Duration(minutes: 15),
    from: relearnAt,
  );
  _expectReview(
    scheduler.review(forgotten, FsrsRating.good, relearnAt),
    stability: 1.2835574040491404,
    difficulty: 7.38007426350719,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 1),
    from: relearnAt,
  );
  _expectReview(
    scheduler.review(forgotten, FsrsRating.easy, relearnAt),
    stability: 2.2081066854835103,
    difficulty: 6.5060740071714935,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 2),
    from: relearnAt,
  );
}

void verifyFsrs6OneStep(dynamic scheduler) {
  final t0 = DateTime.utc(2026, 1, 1);
  _expectReview(
    scheduler.review(const MemoryState(), FsrsRating.hard, t0),
    stability: 1.2931,
    difficulty: 5.112170705601055,
    phase: FsrsPhase.learning,
    step: 0,
    due: const Duration(microseconds: 450000000),
    from: t0,
  );
}

void verifyFsrs6Days(dynamic scheduler) {
  final t0 = DateTime.utc(2026, 1, 1);
  final good = scheduler.review(const MemoryState(), FsrsRating.good, t0);
  _expectReview(
    good,
    stability: 2.3065,
    difficulty: 2.118103970459016,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 2),
    from: t0,
  );
  final againAt = good.due as DateTime;
  _expectReview(
    scheduler.review(good, FsrsRating.again, againAt),
    stability: 0.6075801062519337,
    difficulty: 7.394502741279718,
    phase: FsrsPhase.review,
    step: null,
    due: const Duration(days: 1),
    from: againAt,
  );
}

void verifyFsrs6Edges(dynamic scheduler) {
  expect(scheduler.retrievability(elapsedDays: 1.0, stability: 0.0), 0.0);
  expect(scheduler.retrievability(elapsedDays: -1.0, stability: 2.0), 0.0);
  expect(scheduler.intervalDays(2.3065), 2);
  expect(scheduler.intervalDays(8.2956), 8);
}

void verifyFsrs6Rounding(int Function(double value) round) {
  expect(round(2.5), 2);
  expect(round(3.5), 4);
  expect(round(2.4), 2);
  expect(round(2.6), 3);
}

void verifyFsrs6Ease(
  double Function(double ease) difficultyFromEase,
  double Function(double difficulty) easeFromDifficulty,
) {
  expect(difficultyFromEase(2.5), closeTo(8.5, 1e-9));
  expect(difficultyFromEase(11), closeTo(1, 1e-9));
  expect(easeFromDifficulty(5), closeTo(6, 1e-9));
  expect(easeFromDifficulty(10), closeTo(1.3, 1e-9));
}

void _expectReview(
  dynamic memory, {
  required double stability,
  required double difficulty,
  required FsrsPhase phase,
  required int? step,
  required Duration due,
  required DateTime from,
}) {
  final state = memory as MemoryState;
  expect(state.stability, closeTo(stability, 1e-6));
  expect(state.difficulty, closeTo(difficulty, 1e-6));
  expect(state.phase, phase);
  expect(state.step, step);
  expect(state.due!.difference(from), due);
}
