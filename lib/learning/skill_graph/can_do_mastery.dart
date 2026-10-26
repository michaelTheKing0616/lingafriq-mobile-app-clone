/// Unit mastery and unlock from can-do evidence (EP-§6.2-19, EP-§6.2-20).
///
/// Replaces the legacy `previous_lesson_completed` gate with demonstrated
/// can-dos on the prerequisite unit, or an explicit review path.
library;

/// User-visible copy for mastery and unlock states.
class CanDoMasteryCopy {
  static const notEnoughEvidence =
      'Not enough evidence yet. Complete more practice before this counts as mastered.';
  static const lockedCanDo =
      'Finish the can-do goals in the previous unit to unlock this one.';
  static const unlockedReview = 'Review path — you can open this unit now.';
}

/// Per can-do evidence state after grading (aligned with [CanDoResult.status]).
enum CanDoEvidenceStatus { met, notMet, unsure }

/// Curriculum unlock rule from legacy JSON or v2 policy.
enum CurriculumUnlockRule {
  /// Legacy: treated as prerequisite unit mastered via can-do evidence.
  previousLessonCompleted,
  /// Prerequisite unit must have all can-dos demonstrated.
  canDoEvidence,
  /// Learner may open the unit without prerequisite mastery (explicit opt-in).
  reviewPath,
}

/// Outcome of evaluating whether a unit is mastered.
class UnitMasteryEvaluation {
  const UnitMasteryEvaluation({
    required this.unitKey,
    required this.status,
    required this.missingCanDoIds,
    required this.unsureCanDoIds,
  });

  final String unitKey;

  /// `mastered`, `not_mastered`, or `not_enough_evidence`.
  final String status;

  /// Can-dos scored not-met or never demonstrated when status is `not_mastered`.
  final List<String> missingCanDoIds;

  /// Can-dos with thin or missing scorer evidence when status is `not_enough_evidence`.
  final List<String> unsureCanDoIds;

  bool get isMastered => status == 'mastered';
  bool get isNotEnoughEvidence => status == 'not_enough_evidence';
}

/// Outcome of whether a unit is unlocked for the learner.
class UnitUnlockEvaluation {
  const UnitUnlockEvaluation({
    required this.unitKey,
    required this.unlocked,
    required this.reason,
  });

  final String unitKey;
  final bool unlocked;

  /// `first_unit`, `prior_mastered`, `review_path`, or `locked_can_do`.
  final String reason;
}

/// Evaluates unit mastery from required can-dos and demonstrated evidence.
///
/// A can-do counts as demonstrated only when [evidenceByCanDo] maps it to
/// [CanDoEvidenceStatus.met]. Any [CanDoEvidenceStatus.unsure] yields
/// `not_enough_evidence` for the unit (never a pass). Otherwise missing
/// can-dos yield `not_mastered` with [UnitMasteryEvaluation.missingCanDoIds].
UnitMasteryEvaluation evaluateUnitMastery({
  required String unitKey,
  required List<String> requiredCanDoIds,
  required Map<String, CanDoEvidenceStatus> evidenceByCanDo,
}) {
  final unsure = <String>[];
  final missing = <String>[];

  for (final canDoId in requiredCanDoIds) {
    final evidence = evidenceByCanDo[canDoId];
    switch (evidence) {
      case CanDoEvidenceStatus.met:
        break;
      case CanDoEvidenceStatus.notMet:
        missing.add(canDoId);
        break;
      case CanDoEvidenceStatus.unsure:
      case null:
        unsure.add(canDoId);
        break;
    }
  }

  if (unsure.isNotEmpty) {
    return UnitMasteryEvaluation(
      unitKey: unitKey,
      status: 'not_enough_evidence',
      missingCanDoIds: List<String>.unmodifiable(missing),
      unsureCanDoIds: List<String>.unmodifiable(unsure),
    );
  }

  if (missing.isNotEmpty) {
    return UnitMasteryEvaluation(
      unitKey: unitKey,
      status: 'not_mastered',
      missingCanDoIds: List<String>.unmodifiable(missing),
      unsureCanDoIds: const <String>[],
    );
  }

  return UnitMasteryEvaluation(
    unitKey: unitKey,
    status: 'mastered',
    missingCanDoIds: const <String>[],
    unsureCanDoIds: const <String>[],
  );
}

/// Parses legacy curriculum `unlock_rule` strings into [CurriculumUnlockRule].
CurriculumUnlockRule parseUnlockRule(String? raw) {
  switch (raw) {
    case 'previous_lesson_completed':
      return CurriculumUnlockRule.previousLessonCompleted;
    case 'can_do_evidence':
      return CurriculumUnlockRule.canDoEvidence;
    case 'review_path':
      return CurriculumUnlockRule.reviewPath;
    default:
      return CurriculumUnlockRule.canDoEvidence;
  }
}

/// Whether [unitKey] is unlocked given prerequisite mastery and policy.
///
/// [priorMastery] is the evaluation for the immediately previous unit in the
/// path, or null when this is the first unit. Legacy
/// [CurriculumUnlockRule.previousLessonCompleted] no longer unlocks on lesson
/// completion alone; it requires the same can-do mastery as [canDoEvidence],
/// unless [reviewPathChosen] is true and the rule allows a review path.
UnitUnlockEvaluation evaluateUnitUnlock({
  required String unitKey,
  required CurriculumUnlockRule rule,
  required UnitMasteryEvaluation? priorMastery,
  required bool reviewPathChosen,
}) {
  if (priorMastery == null) {
    return UnitUnlockEvaluation(
      unitKey: unitKey,
      unlocked: true,
      reason: 'first_unit',
    );
  }

  if (reviewPathChosen &&
      (rule == CurriculumUnlockRule.reviewPath ||
          rule == CurriculumUnlockRule.previousLessonCompleted)) {
    return UnitUnlockEvaluation(
      unitKey: unitKey,
      unlocked: true,
      reason: 'review_path',
    );
  }

  final needsCanDoGate = rule == CurriculumUnlockRule.canDoEvidence ||
      rule == CurriculumUnlockRule.previousLessonCompleted;

  if (needsCanDoGate) {
    if (priorMastery.isNotEnoughEvidence || !priorMastery.isMastered) {
      return UnitUnlockEvaluation(
        unitKey: unitKey,
        unlocked: false,
        reason: 'locked_can_do',
      );
    }
    return UnitUnlockEvaluation(
      unitKey: unitKey,
      unlocked: true,
      reason: 'prior_mastered',
    );
  }

  if (rule == CurriculumUnlockRule.reviewPath) {
    return UnitUnlockEvaluation(
      unitKey: unitKey,
      unlocked: reviewPathChosen,
      reason: reviewPathChosen ? 'review_path' : 'locked_can_do',
    );
  }

  return UnitUnlockEvaluation(
    unitKey: unitKey,
    unlocked: false,
    reason: 'locked_can_do',
  );
}
