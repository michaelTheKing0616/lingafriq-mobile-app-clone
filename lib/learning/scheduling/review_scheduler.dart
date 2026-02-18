import '../core/hlr_forgetting_curve.dart';
import '../learner_model/learner_model_service.dart';
import '../learner_model/learner_skill_state.dart';
import '../learner_model/error_taxonomy.dart';

/// Spaced review scheduler driven by the learner model.
///
/// Uses Half-Life Regression to determine optimal review timing,
/// and Bayesian Knowledge Tracing to decide when to stop reviewing.
///
/// Review sessions:
/// - Are scheduled when recall probability drops below threshold
/// - Stop when predicted failure probability exceeds tolerance
/// - Prioritize skills by urgency (review debt)
/// - Balance new learning with maintenance reviews
class ReviewScheduler {
  final LearnerModelService _learnerModel;

  /// Recall probability below which a skill needs review.
  final double reviewThreshold;

  /// Predicted failure probability above which review stops.
  final double stopThreshold;

  /// Maximum items in a single review session.
  final int maxSessionItems;

  /// Ratio of review items to new items in a mixed session.
  final double reviewToNewRatio;

  ReviewScheduler({
    LearnerModelService? learnerModel,
    this.reviewThreshold = 0.7,
    this.stopThreshold = 0.6,
    this.maxSessionItems = 15,
    this.reviewToNewRatio = 0.7,
  }) : _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Generates a review session: ordered list of skills to practice.
  ///
  /// Combines review items (decaying skills) with new items (unlocked skills)
  /// in the optimal ratio for retention + progression.
  ReviewSession generateSession({
    required String learnerId,
    required String languageCode,
  }) {
    final allStates = _learnerModel.getAllStates(learnerId);
    final now = DateTime.now();

    // Separate skills into review-needed and stable
    final reviewItems = <ReviewItem>[];
    final stableItems = <String>[];

    for (final entry in allStates.entries) {
      final state = entry.value;
      final elapsed = now.difference(state.lastRecall).inHours / 24.0;
      final recall = HlrForgettingCurve.recallProbability(
        elapsedDays: elapsed,
        halfLifeDays: state.halfLifeDays,
      );

      if (recall < reviewThreshold && !state.isMastered) {
        final urgency = HlrForgettingCurve.reviewUrgency(
          elapsedDays: elapsed,
          halfLifeDays: state.halfLifeDays,
          recallThreshold: reviewThreshold,
        );

        reviewItems.add(ReviewItem(
          skillId: entry.key,
          currentRecall: recall,
          urgency: urgency,
          halfLifeDays: state.halfLifeDays,
          lastRecall: state.lastRecall,
          dominantError: state.dominantErrorType,
          mastery: state.mastery,
        ));
      } else {
        stableItems.add(entry.key);
      }
    }

    // Sort by urgency (most urgent first)
    reviewItems.sort((a, b) => b.urgency.compareTo(a.urgency));

    // Calculate session composition
    final reviewSlots = (maxSessionItems * reviewToNewRatio).round();
    final newSlots = maxSessionItems - reviewSlots;

    // Get new skill recommendations
    final newRecs = _learnerModel.getRecommendations(
      learnerId: learnerId,
      languageCode: languageCode,
      count: newSlots,
    ).where((r) => r.reason == RecommendationReason.newSkill).toList();

    // Build session
    final sessionItems = <ReviewSessionItem>[];

    // Interleave review and new items for better retention
    final reviewQueue = reviewItems.take(reviewSlots).toList();
    final newQueue = newRecs.map((r) => ReviewSessionItem(
      skillId: r.skillId,
      type: ReviewSessionItemType.newLearning,
      priority: r.priority,
    )).toList();

    int ri = 0, ni = 0;
    while (ri < reviewQueue.length || ni < newQueue.length) {
      // Pattern: 2 reviews, 1 new (roughly matching reviewToNewRatio)
      for (int i = 0; i < 2 && ri < reviewQueue.length; i++, ri++) {
        sessionItems.add(ReviewSessionItem(
          skillId: reviewQueue[ri].skillId,
          type: ReviewSessionItemType.review,
          priority: reviewQueue[ri].urgency,
          currentRecall: reviewQueue[ri].currentRecall,
        ));
      }
      if (ni < newQueue.length) {
        sessionItems.add(newQueue[ni]);
        ni++;
      }
    }

    return ReviewSession(
      learnerId: learnerId,
      languageCode: languageCode,
      items: sessionItems,
      totalReviewDue: reviewItems.length,
      estimatedMinutes: _estimateSessionDuration(sessionItems.length),
      generatedAt: now,
    );
  }

  /// Returns all skills due for review, ordered by urgency.
  List<ReviewItem> getDueReviews({
    required String learnerId,
    required String languageCode,
  }) {
    final allStates = _learnerModel.getAllStates(learnerId);
    final now = DateTime.now();
    final items = <ReviewItem>[];

    for (final entry in allStates.entries) {
      final state = entry.value;
      final elapsed = now.difference(state.lastRecall).inHours / 24.0;
      final recall = HlrForgettingCurve.recallProbability(
        elapsedDays: elapsed,
        halfLifeDays: state.halfLifeDays,
      );

      if (recall < reviewThreshold) {
        items.add(ReviewItem(
          skillId: entry.key,
          currentRecall: recall,
          urgency: HlrForgettingCurve.reviewUrgency(
            elapsedDays: elapsed,
            halfLifeDays: state.halfLifeDays,
          ),
          halfLifeDays: state.halfLifeDays,
          lastRecall: state.lastRecall,
          dominantError: state.dominantErrorType,
          mastery: state.mastery,
        ));
      }
    }

    items.sort((a, b) => b.urgency.compareTo(a.urgency));
    return items;
  }

  /// Determines whether a review session should stop.
  ///
  /// Stops when the predicted failure rate exceeds the tolerance threshold,
  /// indicating fatigue or diminishing returns.
  bool shouldStopSession({
    required List<bool> recentResults,
    int windowSize = 5,
  }) {
    if (recentResults.length < windowSize) return false;

    final recent = recentResults.sublist(recentResults.length - windowSize);
    final failureRate = recent.where((r) => !r).length / windowSize;

    return failureRate >= stopThreshold;
  }

  /// Computes the optimal time for the next review session.
  DateTime nextSessionTime({
    required String learnerId,
    required String languageCode,
  }) {
    final allStates = _learnerModel.getAllStates(learnerId);
    if (allStates.isEmpty) return DateTime.now();

    // Find the skill that will hit review threshold soonest
    DateTime? earliestDue;

    for (final state in allStates.values) {
      final optimalDays = HlrForgettingCurve.optimalReviewDays(
        halfLifeDays: state.halfLifeDays,
        targetProbability: reviewThreshold,
      );
      final due = state.lastRecall.add(Duration(
        hours: (optimalDays * 24).round(),
      ));

      if (earliestDue == null || due.isBefore(earliestDue)) {
        earliestDue = due;
      }
    }

    return earliestDue ?? DateTime.now();
  }

  /// Predicts how many skills will be due for review at a future time.
  int predictReviewLoad({
    required String learnerId,
    required int daysFromNow,
  }) {
    final allStates = _learnerModel.getAllStates(learnerId);
    int count = 0;

    for (final state in allStates.values) {
      final currentElapsed = DateTime.now().difference(state.lastRecall).inHours / 24.0;
      final futureElapsed = currentElapsed + daysFromNow;
      final futureRecall = HlrForgettingCurve.recallProbability(
        elapsedDays: futureElapsed,
        halfLifeDays: state.halfLifeDays,
      );

      if (futureRecall < reviewThreshold) count++;
    }

    return count;
  }

  double _estimateSessionDuration(int itemCount) {
    // ~30 seconds per review item, ~60 seconds per new item
    return itemCount * 0.75;
  }
}

/// A skill due for review.
class ReviewItem {
  final String skillId;
  final double currentRecall;
  final double urgency;
  final double halfLifeDays;
  final DateTime lastRecall;
  final String? dominantError;
  final double mastery;

  const ReviewItem({
    required this.skillId,
    required this.currentRecall,
    required this.urgency,
    required this.halfLifeDays,
    required this.lastRecall,
    this.dominantError,
    required this.mastery,
  });

  /// Days since last review.
  int get daysSinceReview =>
      DateTime.now().difference(lastRecall).inDays;

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'currentRecall': currentRecall,
        'urgency': urgency,
        'halfLifeDays': halfLifeDays,
        'lastRecall': lastRecall.toIso8601String(),
        'dominantError': dominantError,
        'mastery': mastery,
      };
}

/// A complete review session plan.
class ReviewSession {
  final String learnerId;
  final String languageCode;
  final List<ReviewSessionItem> items;
  final int totalReviewDue;
  final double estimatedMinutes;
  final DateTime generatedAt;

  const ReviewSession({
    required this.learnerId,
    required this.languageCode,
    required this.items,
    required this.totalReviewDue,
    required this.estimatedMinutes,
    required this.generatedAt,
  });

  int get itemCount => items.length;
  int get reviewCount => items.where((i) => i.type == ReviewSessionItemType.review).length;
  int get newCount => items.where((i) => i.type == ReviewSessionItemType.newLearning).length;
}

/// A single item in a review session.
class ReviewSessionItem {
  final String skillId;
  final ReviewSessionItemType type;
  final double priority;
  final double? currentRecall;

  const ReviewSessionItem({
    required this.skillId,
    required this.type,
    required this.priority,
    this.currentRecall,
  });
}

enum ReviewSessionItemType { review, newLearning }
