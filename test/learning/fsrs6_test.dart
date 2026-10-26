import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/scheduling/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/memory_state.dart';

import 'fsrs6_oracle.dart';

void main() {
  const scheduler = Fsrs6Scheduler();

  test('published FSRS-6 vectors match within 1e-6', () {
    verifyFsrs6PublishedVectors(scheduler);
  });

  test('the same reviews in two batches end on the same state', () {
    verifyFsrs6Replay(scheduler);
    final t0 = DateTime.utc(2026, 1, 1);
    final reviews = [
      FsrsReview(FsrsRating.good, t0),
      FsrsReview(FsrsRating.good, t0.add(const Duration(days: 1))),
      FsrsReview(FsrsRating.hard, t0.add(const Duration(days: 4))),
      FsrsReview(FsrsRating.easy, t0.add(const Duration(days: 20))),
    ];
    final whole = scheduler.replay(const MemoryState(), reviews);
    final left = scheduler.replay(const MemoryState(), reviews.sublist(0, 2));
    final split = scheduler.replay(left, reviews.sublist(2));
    expect(split.stability, closeTo(whole.stability!, 1e-12));
    expect(split.difficulty, closeTo(whole.difficulty!, 1e-12));
    expect(split.due, whole.due);
  });

  test('each rating and phase follows the FSRS-6 schedule', () {
    verifyFsrs6Branches(scheduler);
    verifyFsrs6Edges(scheduler);
    verifyFsrs6Rounding(pythonRound);
  });

  test('one learning step scales a hard rating by 1.5', () {
    verifyFsrs6OneStep(const Fsrs6Scheduler(learningSteps: [Duration(minutes: 5)]));
  });

  test('stored ease moves opposite FSRS difficulty', () {
    verifyFsrs6Ease(Fsrs6Scheduler.difficultyFromEase, Fsrs6Scheduler.easeFromDifficulty);
  });

  test('a day scheduler graduates on the first review', () {
    verifyFsrs6Days(const Fsrs6Scheduler.days());
  });

  test('per-learner weights stay default until 1000 reviews', () {
    const profile = LearnerFsrsParameters(reviewCount: 999);
    expect(profile.isOptimised, isFalse);
    expect(profile.effectiveWeights, Fsrs6Scheduler.defaultParameters);
    const tuned = LearnerFsrsParameters(
      reviewCount: LearnerFsrsParameters.optimizationReviewThreshold,
      weights: [1.0],
    );
    expect(tuned.isOptimised, isTrue);
    expect(tuned.effectiveWeights, isNot(Fsrs6Scheduler.defaultParameters));
  });

  test('optimising from a 1000-review log is deterministic', () {
    final log = List.generate(
      1000,
      (i) => FsrsReviewLogEntry(
        rating: i % 7 == 0 ? FsrsRating.again : FsrsRating.good,
        at: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
      ),
    );
    final a = const LearnerFsrsParameters().optimizeFromLog(log);
    final b = const LearnerFsrsParameters().optimizeFromLog(log);
    expect(a.weights, b.weights);
    expect(a.reviewCount, 1000);
    expect(a.weights[11], isNot(closeTo(Fsrs6Scheduler.defaultParameters[11], 1e-9)));
    expect(Fsrs6Scheduler.forLearner(a).parameters, a.weights);
  });

  test('legacy SM-2 and half-life migrations replay deterministically', () {
    const scheduler = Fsrs6Scheduler.days();
    final sm2 = Fsrs6Scheduler.migrateLegacySm2(
      easeFactor: 2.5,
      intervalDays: 6,
      repetitions: 2,
      lastReview: DateTime.utc(2026, 1, 1),
    );
    final hlr = Fsrs6Scheduler.migrateLegacyHalfLife(
      halfLifeDays: 3.5,
      lastRecall: DateTime.utc(2026, 1, 1),
    );
    final at = DateTime.utc(2026, 1, 8);
    final left = scheduler.review(sm2, FsrsRating.good, at);
    final right = scheduler.review(sm2, FsrsRating.good, at);
    expect(left.stability, right.stability);
    expect(scheduler.review(hlr, FsrsRating.hard, at).due, isNotNull);
  });
}
