/// Content quality label state machine (P5-009, CURRICULUM §5, ADR-001).
library;

/// Schema/storage values for `label` on curriculum items.
enum ContentQualityLabel {
  beta('beta'),
  expertReviewed('reviewed'),
  nativeVerified('native_verified');

  const ContentQualityLabel(this.storageValue);
  final String storageValue;

  static ContentQualityLabel? fromStorage(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final normalized = raw.trim();
    for (final value in ContentQualityLabel.values) {
      if (value.storageValue == normalized) {
        return value;
      }
    }
    return null;
  }

  String get displayName {
    switch (this) {
      case ContentQualityLabel.beta:
        return 'Beta';
      case ContentQualityLabel.expertReviewed:
        return 'Expert-reviewed';
      case ContentQualityLabel.nativeVerified:
        return 'Native-verified';
    }
  }
}

/// Stable failure codes aligned with the Studio label service.
abstract final class LabelStateCodes {
  static const insufficientNativeApprovals = 'InsufficientNativeApprovals';
  static const linguistApprovalRequired = 'LinguistApprovalRequired';
  static const machineChecksRequired = 'MachineChecksRequired';
  static const forbiddenPromoter = 'FORBIDDEN_PROMOTER';
  static const illegalLabelTransition = 'ILLEGAL_LABEL_TRANSITION';
}

class LabelStateFailure implements Exception {
  LabelStateFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class ReviewerApproval {
  const ReviewerApproval({
    required this.reviewerId,
    required this.role,
    required this.approved,
    this.reviewedAt,
  });

  final String reviewerId;
  final ReviewerRole role;
  final bool approved;
  final DateTime? reviewedAt;
}

enum ReviewerRole { native, linguist }

class MachineCheckSnapshot {
  const MachineCheckSnapshot({
    required this.machineChecksPassed,
    required this.samplingPassed,
  });

  final bool machineChecksPassed;
  final bool samplingPassed;
}

class LabelAuditEntry {
  const LabelAuditEntry({
    required this.actorId,
    required this.fromLabel,
    required this.toLabel,
    required this.itemVersion,
  });

  final String actorId;
  final ContentQualityLabel? fromLabel;
  final ContentQualityLabel toLabel;
  final int itemVersion;

  Map<String, Object?> toJson() => {
        'actor_id': actorId,
        'from': fromLabel?.storageValue,
        'to': toLabel.storageValue,
        'item_version': itemVersion,
      };
}

Set<String> distinctApprovedNativeIds(List<ReviewerApproval> reviewers) {
  final ids = <String>{};
  for (final row in reviewers) {
    if (!row.approved || row.role != ReviewerRole.native) {
      continue;
    }
    final id = row.reviewerId.trim();
    if (id.isNotEmpty) {
      ids.add(id);
    }
  }
  return ids;
}

ReviewerApproval? linguistApprovalRecord(List<ReviewerApproval> reviewers) {
  for (final row in reviewers) {
    if (!row.approved || row.role != ReviewerRole.linguist) {
      continue;
    }
    final id = row.reviewerId.trim();
    if (id.isNotEmpty && row.reviewedAt != null) {
      return row;
    }
  }
  return null;
}

bool hasHumanReview(List<ReviewerApproval> reviewers) {
  for (final row in reviewers) {
    if (row.approved && row.reviewerId.trim().isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// Validates promotion rules before persisting a label (AC1–AC3).
void assertLabelPromotionAllowed({
  required ContentQualityLabel target,
  required List<ReviewerApproval> reviewers,
  MachineCheckSnapshot? machine,
  required bool hasHumanCheck,
}) {
  switch (target) {
    case ContentQualityLabel.nativeVerified:
      final natives = distinctApprovedNativeIds(reviewers);
      if (natives.length < 2) {
        throw LabelStateFailure(
          LabelStateCodes.insufficientNativeApprovals,
          'native-verified requires approvals from at least two distinct native validators',
        );
      }
      return;
    case ContentQualityLabel.expertReviewed:
      if (linguistApprovalRecord(reviewers) == null) {
        throw LabelStateFailure(
          LabelStateCodes.linguistApprovalRequired,
          'expert-reviewed requires one linguist approval with reviewer id and date',
        );
      }
      return;
    case ContentQualityLabel.beta:
      if (hasHumanCheck) {
        return;
      }
      final snap = machine;
      if (snap == null ||
          !snap.machineChecksPassed ||
          !snap.samplingPassed) {
        throw LabelStateFailure(
          LabelStateCodes.machineChecksRequired,
          'beta publish without human review requires machine checks and sampling to pass',
        );
      }
      return;
  }
}

bool actorMayPromoteToLabel({
  required Set<String> permissions,
  required ContentQualityLabel target,
}) {
  switch (target) {
    case ContentQualityLabel.beta:
      return permissions.contains('content.publish');
    case ContentQualityLabel.expertReviewed:
      return permissions.contains('content.review.linguist');
    case ContentQualityLabel.nativeVerified:
      return permissions.contains('content.publish');
  }
}

void assertActorMayPromote({
  required Set<String> permissions,
  required ContentQualityLabel target,
}) {
  if (!actorMayPromoteToLabel(permissions: permissions, target: target)) {
    throw LabelStateFailure(
      LabelStateCodes.forbiddenPromoter,
      'actor lacks permission to promote to ${target.displayName}',
    );
  }
}

/// Monotonic label ladder: beta → expert-reviewed → native-verified.
bool isAllowedLabelTransition(
  ContentQualityLabel? from,
  ContentQualityLabel to,
) {
  if (from == to) {
    return true;
  }
  if (from == null) {
    return to == ContentQualityLabel.beta;
  }
  if (from == ContentQualityLabel.beta &&
      to == ContentQualityLabel.expertReviewed) {
    return true;
  }
  if (from == ContentQualityLabel.expertReviewed &&
      to == ContentQualityLabel.nativeVerified) {
    return true;
  }
  if (from == ContentQualityLabel.beta &&
      to == ContentQualityLabel.nativeVerified) {
    return false;
  }
  return false;
}

LabelAuditEntry planLabelChange({
  required String actorId,
  required ContentQualityLabel? fromLabel,
  required ContentQualityLabel toLabel,
  required int itemVersion,
  required List<ReviewerApproval> reviewers,
  required Set<String> permissions,
  MachineCheckSnapshot? machine,
}) {
  final actor = actorId.trim();
  if (actor.isEmpty) {
    throw LabelStateFailure(
      LabelStateCodes.forbiddenPromoter,
      'actor_id is required',
    );
  }
  if (itemVersion < 1) {
    throw ArgumentError.value(itemVersion, 'itemVersion', 'must be >= 1');
  }
  if (!isAllowedLabelTransition(fromLabel, toLabel)) {
    throw LabelStateFailure(
      LabelStateCodes.illegalLabelTransition,
      'illegal label transition ${fromLabel?.storageValue ?? 'null'} -> ${toLabel.storageValue}',
    );
  }
  assertActorMayPromote(permissions: permissions, target: toLabel);
  assertLabelPromotionAllowed(
    target: toLabel,
    reviewers: reviewers,
    machine: machine,
    hasHumanCheck: hasHumanReview(reviewers),
  );
  return LabelAuditEntry(
    actorId: actor,
    fromLabel: fromLabel,
    toLabel: toLabel,
    itemVersion: itemVersion,
  );
}
