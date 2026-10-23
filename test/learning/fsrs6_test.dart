import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
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
}
