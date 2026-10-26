import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/content/under_review.dart';

void main() {
  group('P5-013 autohide policy', () {
    test('AC1 hides after three distinct reporters', () {
      final hide = shouldAutoHideUnderReview(
        reporterIds: ['a', 'b', 'c'],
        trustedReporterIds: {},
      );
      expect(hide, isTrue);
    });

    test('AC4 counts duplicate flags from one user once', () {
      expect(
        shouldAutoHideUnderReview(
          reporterIds: ['u1', 'u1', 'u1'],
          trustedReporterIds: {},
        ),
        isFalse,
      );
      expect(
        shouldAutoHideUnderReview(
          reporterIds: ['u1', 'u1', 'u2', 'u3'],
          trustedReporterIds: {},
        ),
        isTrue,
      );
    });

    test('AC2 trusted user hides on first flag', () {
      expect(
        shouldAutoHideUnderReview(
          reporterIds: ['trusted-1'],
          trustedReporterIds: {'trusted-1'},
        ),
        isTrue,
      );
    });
  });

  group('learner visibility', () {
    test('AC3 excludes under review from lessons but keeps visible surface', () {
      final items = ['a', 'b', 'c'];
      final under = {'b'};
      final lesson = lessonItemsExcludingUnderReview(
        items,
        (id) => under.contains(id),
      );
      expect(lesson, ['a', 'c']);
      expect(
        resolveLearnerSurface(underReview: true),
        ContentLearnerSurface.underReviewVisible,
      );
      expect(learnerShouldSeeUnderReviewPlaceholder(
        ContentLearnerSurface.underReviewVisible,
      ), isTrue);
      expect(underReviewLearnerLabel(), 'Under review');
    });

    test('parses under_review from item JSON', () {
      expect(isItemMarkedUnderReview({'under_review': true}), isTrue);
      expect(isItemMarkedUnderReview({'under_review': false}), isFalse);
      expect(isItemMarkedUnderReview(null), isFalse);
    });
  });
}
