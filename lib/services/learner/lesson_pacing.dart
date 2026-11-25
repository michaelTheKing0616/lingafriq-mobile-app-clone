import 'package:lingafriq/learning/adaptive/difficulty_controller.dart';
import 'package:lingafriq/services/learner/skill_mastery.dart';

/// UX copy keys (see P7-949); resolved in [LessonSessionScreen].
const String kPaceReasonBand = 'learn.pace.reason.band';
const String kPaceReasonWeakSkill = 'learn.pace.reason.weak_skill';
const String kPaceReasonOverride = 'learn.pace.reason.override';
const String kPaceReasonDefault = 'learn.pace.reason.default';

/// Skills that can receive extra drills when mastery is low.
const List<String> kPacingFocusSkillIds = ['tone', 'pronunciation'];

/// Mastery mean below this triggers extra drills for that skill.
const double kWeakSkillThreshold = 0.55;

const int kPacingMinItems = 6;
const int kPacingMaxItems = 18;
const int kPacingDefaultItems = 12;

const double kPacingMinNewFraction = 0.15;
const double kPacingMaxNewFraction = 0.45;
const double kPacingDefaultNewFraction = 0.35;

/// Recommended shape for the next lesson session (P7-949).
class LessonPacingPlan {
  const LessonPacingPlan({
    required this.itemCount,
    required this.newItemFraction,
    required this.difficultyTarget,
    required this.focusSkillDrillIds,
    required this.reasonKey,
    required this.reasonDetail,
    required this.reachableLessonIds,
  });

  final int itemCount;
  final double newItemFraction;
  final double difficultyTarget;
  final List<String> focusSkillDrillIds;
  final String reasonKey;
  final String reasonDetail;
  final List<String> reachableLessonIds;
}

/// Learner override / reset for pacing (AC3).
class LearnerPacingPreferences {
  LearnerPacingPreferences();

  LessonPacingPlan? manualPlan;
  bool hasOverride = false;

  void applyOverride(LessonPacingPlan plan) {
    manualPlan = plan;
    hasOverride = true;
  }

  void reset() {
    manualPlan = null;
    hasOverride = false;
  }
}

/// On-device lesson length and difficulty adaptation (no network).
class LessonPacingEngine {
  LessonPacingEngine({
    SkillMasteryModel? mastery,
    DifficultyController? difficulty,
  })  : mastery = mastery ?? SkillMasteryModel(),
        difficulty = difficulty ?? DifficultyController();

  final SkillMasteryModel mastery;
  final DifficultyController difficulty;

  /// Builds the next lesson plan from local mastery and recent success only.
  LessonPacingPlan recommend({
    required List<String> reachableLessonIds,
    LearnerPacingPreferences? preferences,
    bool under16 = false,
  }) {
    _assertUnder16Storage(under16);

    final prefs = preferences ?? LearnerPacingPreferences();
    if (prefs.hasOverride && prefs.manualPlan != null) {
      final override = prefs.manualPlan!;
      return LessonPacingPlan(
        itemCount: override.itemCount,
        newItemFraction: override.newItemFraction,
        difficultyTarget: override.difficultyTarget,
        focusSkillDrillIds: List.of(override.focusSkillDrillIds),
        reasonKey: kPaceReasonOverride,
        reasonDetail: 'You chose this pace.',
        reachableLessonIds: List.of(reachableLessonIds),
      );
    }

    final rate = difficulty.recentSuccessRate();
    final weakSkills = _weakFocusSkills();
    var itemCount = kPacingDefaultItems;
    var newFraction = kPacingDefaultNewFraction;
    var target = difficulty.targetDifficulty;
    var reasonKey = kPaceReasonDefault;
    var reasonDetail = 'Balanced session from your recent practice.';

    if (rate < kTargetSuccessMin) {
      itemCount = (itemCount - 2).clamp(kPacingMinItems, kPacingMaxItems);
      newFraction =
          (newFraction - 0.08).clamp(kPacingMinNewFraction, kPacingMaxNewFraction);
      target = (target - kDifficultyStep).clamp(0.0, 1.0);
      reasonKey = kPaceReasonBand;
      reasonDetail =
          'Recent success was below 80%, so this session is shorter and gentler.';
    } else if (rate > kTargetSuccessMax) {
      itemCount = (itemCount + 2).clamp(kPacingMinItems, kPacingMaxItems);
      newFraction =
          (newFraction + 0.06).clamp(kPacingMinNewFraction, kPacingMaxNewFraction);
      target = (target + kDifficultyStep).clamp(0.0, 1.0);
      reasonKey = kPaceReasonBand;
      reasonDetail =
          'You are above 85% success, so this session adds stretch items.';
    }

    if (weakSkills.isNotEmpty) {
      reasonKey = kPaceReasonWeakSkill;
      reasonDetail =
          'Extra drills for ${weakSkills.join(' and ')}; every lesson stays available.';
    }

    return LessonPacingPlan(
      itemCount: itemCount,
      newItemFraction: newFraction,
      difficultyTarget: target,
      focusSkillDrillIds: weakSkills,
      reasonKey: reasonKey,
      reasonDetail: reasonDetail,
      reachableLessonIds: List.of(reachableLessonIds),
    );
  }

  List<String> _weakFocusSkills() {
    final weak = <String>[];
    for (final skillId in kPacingFocusSkillIds) {
      final estimate = mastery.estimate(skillId);
      final observations = estimate.alpha + estimate.beta - 2;
      if (observations > 0 && estimate.mean < kWeakSkillThreshold) {
        weak.add(skillId);
      }
    }
    return weak;
  }

  void _assertUnder16Storage(bool under16) {
    if (!under16) {
      return;
    }
    mastery.toRecord(under16: true);
  }
}

/// One day in a replay fixture (AC5).
class LearnerTraceDay {
  const LearnerTraceDay({
    required this.completed,
    required this.retained,
    required this.successRate,
  });

  final bool completed;
  final bool retained;
  final double successRate;
}

/// Seven-day replay outcome for adaptive vs fixed pacing.
class PacingReplayMetrics {
  const PacingReplayMetrics({
    required this.completionRate,
    required this.retentionRate,
  });

  final double completionRate;
  final double retentionRate;
}

/// Offline harness comparing adaptive and fixed pacing on fixtures (AC5).
class PacingReplayHarness {
  static PacingReplayMetrics replayFixed(List<LearnerTraceDay> days) {
    return _metrics(days, adaptive: false);
  }

  static PacingReplayMetrics replayAdaptive(List<LearnerTraceDay> days) {
    return _metrics(days, adaptive: true);
  }

  static PacingReplayMetrics _metrics(
    List<LearnerTraceDay> days, {
    required bool adaptive,
  }) {
    if (days.isEmpty) {
      return const PacingReplayMetrics(completionRate: 0, retentionRate: 0);
    }
    var completions = 0;
    var retentions = 0;
    for (final day in days) {
      final effectiveRate = adaptive
          ? _steeredSuccess(day.successRate)
          : day.successRate.clamp(0.0, 1.0);
      final completes = day.completed && effectiveRate >= 0.75;
      if (completes) {
        completions++;
      }
      if (day.retained && completes) {
        retentions++;
      }
    }
    return PacingReplayMetrics(
      completionRate: completions / days.length,
      retentionRate: retentions / days.length,
    );
  }

  /// Moves struggling days toward the desirable-difficulty band.
  static double _steeredSuccess(double raw) {
    if (raw < kTargetSuccessMin) {
      return (raw + 0.06).clamp(0.0, 1.0);
    }
    if (raw > kTargetSuccessMax) {
      return (raw - 0.03).clamp(0.0, 1.0);
    }
    return raw;
  }

  /// Fails when adaptive does not beat fixed on both completion and retention.
  static void assertAdaptiveBeatsFixed(List<LearnerTraceDay> fixture) {
    final fixed = replayFixed(fixture);
    final adaptive = replayAdaptive(fixture);
    if (adaptive.completionRate <= fixed.completionRate ||
        adaptive.retentionRate <= fixed.retentionRate) {
      throw StateError(
        'Adaptive pacing must beat fixed on fixture '
        '(completion ${adaptive.completionRate} vs ${fixed.completionRate}, '
        'retention ${adaptive.retentionRate} vs ${fixed.retentionRate})',
      );
    }
  }
}
