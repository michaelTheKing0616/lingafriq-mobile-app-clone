/// Learner visibility when content is auto-hidden after flags (P5-013, CURRICULUM §5).
library;

/// Stable codes aligned with the content-flag autohide service.
abstract final class UnderReviewCodes {
  static const underReview = 'UNDER_REVIEW';
}

/// How an item appears in learner flows (never a silent omission).
enum ContentLearnerSurface {
  /// Item is playable in lessons.
  available,

  /// Item is withheld from lessons but the slot shows an explicit Under review state.
  underReviewVisible,
}

/// Curriculum §5: three distinct reporters, or one trusted reporter.
const int distinctReporterAutohideThreshold = 3;

bool isItemMarkedUnderReview(Map<String, dynamic>? itemJson) {
  if (itemJson == null) {
    return false;
  }
  final raw = itemJson['under_review'];
  if (raw is bool) {
    return raw;
  }
  if (raw is String) {
    return raw.trim().toLowerCase() == 'true';
  }
  return false;
}

int countDistinctReporters(Iterable<String> reporterIds) {
  final seen = <String>{};
  for (final id in reporterIds) {
    final trimmed = id.trim();
    if (trimmed.isNotEmpty) {
      seen.add(trimmed);
    }
  }
  return seen.length;
}

bool shouldAutoHideUnderReview({
  required Iterable<String> reporterIds,
  required Set<String> trustedReporterIds,
}) {
  if (countDistinctReporters(reporterIds) >= distinctReporterAutohideThreshold) {
    return true;
  }
  for (final id in reporterIds) {
    final trimmed = id.trim();
    if (trimmed.isNotEmpty && trustedReporterIds.contains(trimmed)) {
      return true;
    }
  }
  return false;
}

ContentLearnerSurface resolveLearnerSurface({required bool underReview}) {
  if (underReview) {
    return ContentLearnerSurface.underReviewVisible;
  }
  return ContentLearnerSurface.available;
}

/// Excludes under-review items from lesson assembly; they are surfaced separately.
List<T> lessonItemsExcludingUnderReview<T>(
  Iterable<T> items,
  bool Function(T item) isUnderReview,
) {
  return items.where((item) => !isUnderReview(item)).toList(growable: false);
}

/// Copy for the visible Under review placeholder (AC3).
String underReviewLearnerLabel({String locale = 'en'}) {
  if (locale == 'en') {
    return 'Under review';
  }
  return 'Under review';
}

bool learnerShouldSeeUnderReviewPlaceholder(ContentLearnerSurface surface) {
  return surface == ContentLearnerSurface.underReviewVisible;
}
