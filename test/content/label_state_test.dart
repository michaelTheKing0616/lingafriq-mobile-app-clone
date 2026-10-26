import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/content/label_state.dart';

ReviewerApproval native(String id) => ReviewerApproval(
      reviewerId: id,
      role: ReviewerRole.native,
      approved: true,
    );

ReviewerApproval linguist(String id, DateTime when) => ReviewerApproval(
      reviewerId: id,
      role: ReviewerRole.linguist,
      approved: true,
      reviewedAt: when,
    );

void main() {
  group('transitions', () {
    test('allows null to beta', () {
      expect(
        isAllowedLabelTransition(null, ContentQualityLabel.beta),
        isTrue,
      );
    });

    test('rejects beta to native_verified skip', () {
      expect(
        isAllowedLabelTransition(
          ContentQualityLabel.beta,
          ContentQualityLabel.nativeVerified,
        ),
        isFalse,
      );
    });

    test('allows beta to expert-reviewed to native-verified', () {
      expect(
        isAllowedLabelTransition(
          ContentQualityLabel.beta,
          ContentQualityLabel.expertReviewed,
        ),
        isTrue,
      );
      expect(
        isAllowedLabelTransition(
          ContentQualityLabel.expertReviewed,
          ContentQualityLabel.nativeVerified,
        ),
        isTrue,
      );
    });
  });

  group('two-native rule', () {
    test('requires two distinct natives for native-verified', () {
      expect(
        () => assertLabelPromotionAllowed(
          target: ContentQualityLabel.nativeVerified,
          reviewers: [native('n1')],
          hasHumanCheck: true,
        ),
        throwsA(
          predicate(
            (e) =>
                e is LabelStateFailure &&
                e.code == LabelStateCodes.insufficientNativeApprovals,
          ),
        ),
      );

      assertLabelPromotionAllowed(
        target: ContentQualityLabel.nativeVerified,
        reviewers: [native('n1'), native('n2')],
        hasHumanCheck: true,
      );
    });

    test('duplicate native reviewer_id counts once', () {
      expect(
        distinctApprovedNativeIds([native('n1'), native('n1')]).length,
        1,
      );
    });
  });

  group('linguist rule', () {
    test('expert-reviewed requires linguist id and date', () {
      expect(
        () => assertLabelPromotionAllowed(
          target: ContentQualityLabel.expertReviewed,
          reviewers: [
            ReviewerApproval(
              reviewerId: 'l1',
              role: ReviewerRole.linguist,
              approved: true,
            ),
          ],
          hasHumanCheck: true,
        ),
        throwsA(
          predicate(
            (e) =>
                e is LabelStateFailure &&
                e.code == LabelStateCodes.linguistApprovalRequired,
          ),
        ),
      );

      assertLabelPromotionAllowed(
        target: ContentQualityLabel.expertReviewed,
        reviewers: [linguist('l1', DateTime.utc(2026, 1, 2))],
        hasHumanCheck: true,
      );
    });
  });

  group('beta without human review', () {
    test('requires machine checks and sampling', () {
      expect(
        () => assertLabelPromotionAllowed(
          target: ContentQualityLabel.beta,
          reviewers: const [],
          hasHumanCheck: false,
          machine: const MachineCheckSnapshot(
            machineChecksPassed: true,
            samplingPassed: false,
          ),
        ),
        throwsA(
          predicate(
            (e) =>
                e is LabelStateFailure &&
                e.code == LabelStateCodes.machineChecksRequired,
          ),
        ),
      );

      assertLabelPromotionAllowed(
        target: ContentQualityLabel.beta,
        reviewers: const [],
        hasHumanCheck: false,
        machine: const MachineCheckSnapshot(
          machineChecksPassed: true,
          samplingPassed: true,
        ),
      );
    });
  });

  group('audit trail', () {
    test('planLabelChange records actor from to and version', () {
      final entry = planLabelChange(
        actorId: 'lead-1',
        fromLabel: ContentQualityLabel.beta,
        toLabel: ContentQualityLabel.expertReviewed,
        itemVersion: 4,
        reviewers: [linguist('ling-9', DateTime.utc(2026, 3, 1))],
        permissions: {'content.review.linguist'},
      );
      expect(entry.actorId, 'lead-1');
      expect(entry.fromLabel, ContentQualityLabel.beta);
      expect(entry.toLabel, ContentQualityLabel.expertReviewed);
      expect(entry.itemVersion, 4);
      expect(entry.toJson()['item_version'], 4);
    });
  });

  group('non-validator cannot promote', () {
    test('writer cannot set expert-reviewed', () {
      expect(
        () => planLabelChange(
          actorId: 'writer-1',
          fromLabel: ContentQualityLabel.beta,
          toLabel: ContentQualityLabel.expertReviewed,
          itemVersion: 1,
          reviewers: [linguist('l1', DateTime.utc(2026, 1, 1))],
          permissions: {'content.draft.write'},
        ),
        throwsA(
          predicate(
            (e) =>
                e is LabelStateFailure &&
                e.code == LabelStateCodes.forbiddenPromoter,
          ),
        ),
      );
    });
  });
}
