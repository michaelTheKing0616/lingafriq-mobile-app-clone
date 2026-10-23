import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/memory_state.dart';

void main() {
  const scheduler = Fsrs6Scheduler();

  test('random reviews keep stability positive and retrievability in range', () {
    var seed = 20261023;
    int next() {
      seed = (1664525 * seed + 1013904223) & 0x7fffffff;
      return seed;
    }

    for (var sequence = 0; sequence < 30; sequence++) {
      var memory = const MemoryState();
      var at = DateTime.utc(2026, 1, 1);
      for (var step = 0; step < 8; step++) {
        final rating = FsrsRating.values[next() % 4];
        at = at.add(Duration(days: 1 + next() % 5));
        memory = scheduler.review(memory, rating, at);
        expect(memory.stability!, greaterThan(0));
        expect(memory.difficulty!, inInclusiveRange(1, 10));
        final recall = scheduler.retrievability(
          elapsedDays: 0,
          stability: memory.stability!,
        );
        expect(recall, inInclusiveRange(0, 1));
        final later = scheduler.retrievability(
          elapsedDays: 30,
          stability: memory.stability!,
        );
        expect(later, inInclusiveRange(0, 1));
      }
    }
  });

  test('a higher rating is not scheduled sooner', () {
    final start = DateTime.utc(2026, 1, 1);
    var memory = const MemoryState();
    memory = scheduler.review(memory, FsrsRating.good, start);
    memory = scheduler.review(memory, FsrsRating.good, start.add(const Duration(days: 1)));
    final when = memory.lastReview!.add(const Duration(days: 2));
    DateTime? previous;
    for (final rating in FsrsRating.values) {
      final next = scheduler.review(memory, rating, when);
      expect(next.stability!, greaterThan(0));
      if (previous != null) {
        expect(next.due!.isBefore(previous), isFalse);
      }
      previous = next.due;
    }
  });
}
