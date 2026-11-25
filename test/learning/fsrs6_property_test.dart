import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';

import 'fsrs6_oracle.dart';

void main() {
  const scheduler = Fsrs6Scheduler();

  test('random reviews keep stability positive and retrievability in range', () {
    verifyFsrs6RandomReviews(scheduler);
  });

  test('a higher rating is not scheduled sooner', () {
    verifyFsrs6RatingOrder(scheduler);
  });
}
