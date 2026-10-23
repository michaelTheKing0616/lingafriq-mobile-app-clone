import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/memory_state.dart';

void main() {
  const scheduler = Fsrs6Scheduler();
  final t0 = DateTime.utc(2026, 1, 1);

  test('published FSRS-6 vectors match within 1e-6', () {
    final first = scheduler.review(const MemoryState(), FsrsRating.good, t0);
    expect(first.stability, closeTo(2.3065, 1e-6));
    expect(first.difficulty, closeTo(2.118103970459016, 1e-6));
    expect(first.phase, FsrsPhase.learning);
    expect(first.due!.difference(t0), const Duration(minutes: 10));
    expect(
      scheduler.retrievability(elapsedDays: 0, stability: first.stability!),
      closeTo(1, 1e-6),
    );

    final t1 = t0.add(const Duration(days: 1));
    expect(
      scheduler.retrievability(elapsedDays: 1, stability: first.stability!),
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
        stability: second.stability!,
      ),
      closeTo(0.9029981645406641, 1e-6),
    );
    final third = scheduler.review(second, FsrsRating.again, second.due!);
    expect(third.stability, closeTo(1.2389417584956706, 1e-6));
    expect(third.difficulty, closeTo(7.392238132342694, 1e-6));
    expect(third.phase, FsrsPhase.relearning);
  });

  test('the same reviews in two batches end on the same state', () {
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
}
