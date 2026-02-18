import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/error_taxonomy.dart';
import 'package:lingafriq/learning/core/hlr_forgetting_curve.dart';
import 'package:lingafriq/learning/scheduling/review_scheduler.dart';
import 'package:lingafriq/services/gamification/competence_gamification.dart';

/// Research-grade metrics provider for dashboards and A/B testing.
///
/// These metrics are NOT for users — they are for the team.
/// They enable:
/// 1. Reproducible learning experiments
/// 2. A/B testing learning algorithms
/// 3. Publishable retention/error metrics
/// 4. Curriculum flaw detection

/// Provides retention curve data points for visualization.
final retentionCurveProvider = Provider.family<
    List<RetentionCurvePoint>,
    (String learnerId, String languageCode)>((ref, params) {
  final service = LearnerModelService.instance;
  final allStates = service.getAllStates(params.$1);
  final now = DateTime.now();
  final points = <RetentionCurvePoint>[];

  for (final state in allStates.values) {
    // Generate predicted recall curve from now to +30 days
    for (int day = 0; day <= 30; day++) {
      final elapsed = now.difference(state.lastRecall).inHours / 24.0 + day;
      final recall = HlrForgettingCurve.recallProbability(
        elapsedDays: elapsed,
        halfLifeDays: state.halfLifeDays,
      );

      points.add(RetentionCurvePoint(
        skillId: state.skillId,
        daysFromNow: day,
        predictedRecall: recall,
        halfLifeDays: state.halfLifeDays,
        mastery: state.mastery,
      ));
    }
  }

  return points;
});

/// Provides error entropy trend over time.
final errorEntropyProvider = Provider.family<
    ErrorEntropySnapshot,
    (String learnerId, String languageCode)>((ref, params) {
  final service = LearnerModelService.instance;
  final metrics = service.getCognitiveMetrics(
    learnerId: params.$1,
    languageCode: params.$2,
  );

  final allStates = service.getAllStates(params.$1);

  // Per-skill error entropy
  final perSkillEntropy = <String, double>{};
  for (final entry in allStates.entries) {
    final entropy = ErrorTaxonomy.errorEntropy(entry.value.errorDistribution.rates);
    if (entropy > 0) perSkillEntropy[entry.key] = entropy;
  }

  return ErrorEntropySnapshot(
    overallEntropy: metrics.errorEntropy,
    perSkillEntropy: perSkillEntropy,
    topErrors: metrics.topErrors
        .map((e) => ErrorFrequency(
              errorTypeId: e.key,
              rate: e.value,
              errorName: ErrorType.byId(e.key)?.name ?? e.key,
            ))
        .toList(),
    isTargetable: metrics.hasTargetableErrors,
    timestamp: DateTime.now(),
  );
});

/// Provides learning velocity metrics.
final learningVelocityProvider = Provider.family<
    LearningVelocity,
    (String learnerId, String languageCode)>((ref, params) {
  final service = LearnerModelService.instance;
  final allStates = service.getAllStates(params.$1);
  final now = DateTime.now();

  // Calculate mastery gained in the last 7 days
  double masteryGainedLast7d = 0;
  int skillsPracticedLast7d = 0;
  int attemptsLast7d = 0;
  final sevenDaysAgo = now.subtract(const Duration(days: 7));

  for (final state in allStates.values) {
    if (state.lastPractice.isAfter(sevenDaysAgo)) {
      skillsPracticedLast7d++;
      masteryGainedLast7d += state.mastery;
      attemptsLast7d += state.totalAttempts;
    }
  }

  // Average mastery per day
  final masteryPerDay = masteryGainedLast7d / 7.0;

  // Skills to mastery estimate
  final unmasteredSkills = allStates.values.where((s) => !s.isMastered).length;
  final avgMasteryGap = allStates.values
      .where((s) => !s.isMastered)
      .fold(0.0, (sum, s) => sum + (0.95 - s.mastery));
  final daysToMasteryEstimate = masteryPerDay > 0
      ? (avgMasteryGap / masteryPerDay).round()
      : -1;

  return LearningVelocity(
    masteryGainedLast7Days: masteryGainedLast7d,
    skillsPracticedLast7Days: skillsPracticedLast7d,
    attemptsLast7Days: attemptsLast7d,
    averageMasteryPerDay: masteryPerDay,
    estimatedDaysToFullMastery: daysToMasteryEstimate,
    unmasteredSkillCount: unmasteredSkills,
  );
});

/// Provides skill graph heatmap data.
final skillGraphHeatmapProvider = Provider.family<
    List<SkillHeatmapEntry>,
    (String learnerId, String languageCode)>((ref, params) {
  final service = LearnerModelService.instance;
  final allStates = service.getAllStates(params.$1);
  final entries = <SkillHeatmapEntry>[];

  for (final entry in allStates.entries) {
    final state = entry.value;
    entries.add(SkillHeatmapEntry(
      skillId: entry.key,
      mastery: state.mastery,
      halfLifeDays: state.halfLifeDays,
      currentRecall: state.currentRecallProbability,
      errorEntropy: ErrorTaxonomy.errorEntropy(state.errorDistribution.rates),
      isDueForReview: state.isDueForReview,
      totalAttempts: state.totalAttempts,
      accuracy: state.accuracy,
    ));
  }

  entries.sort((a, b) => a.mastery.compareTo(b.mastery));
  return entries;
});

/// Provides competence level and daily insight.
final competenceDashboardProvider = Provider.family<
    CompetenceDashboard,
    (String learnerId, String languageCode)>((ref, params) {
  final gamification = CompetenceGamification();

  final level = gamification.getCompetenceLevel(
    learnerId: params.$1,
    languageCode: params.$2,
  );

  final insight = gamification.generateDailyInsight(
    learnerId: params.$1,
    languageCode: params.$2,
  );

  final prediction = gamification.predictTomorrow(
    learnerId: params.$1,
    languageCode: params.$2,
  );

  final metrics = LearnerModelService.instance.getCognitiveMetrics(
    learnerId: params.$1,
    languageCode: params.$2,
  );

  return CompetenceDashboard(
    level: level,
    dailyInsight: insight,
    prediction: prediction,
    metrics: metrics,
  );
});

/// Provides review schedule data.
final reviewScheduleProvider = Provider.family<
    ReviewSession,
    (String learnerId, String languageCode)>((ref, params) {
  final scheduler = ReviewScheduler();
  return scheduler.generateSession(
    learnerId: params.$1,
    languageCode: params.$2,
  );
});

// ─── Data classes ──────────────────────────────────────────────────

class RetentionCurvePoint {
  final String skillId;
  final int daysFromNow;
  final double predictedRecall;
  final double halfLifeDays;
  final double mastery;

  const RetentionCurvePoint({
    required this.skillId,
    required this.daysFromNow,
    required this.predictedRecall,
    required this.halfLifeDays,
    required this.mastery,
  });
}

class ErrorEntropySnapshot {
  final double overallEntropy;
  final Map<String, double> perSkillEntropy;
  final List<ErrorFrequency> topErrors;
  final bool isTargetable;
  final DateTime timestamp;

  const ErrorEntropySnapshot({
    required this.overallEntropy,
    required this.perSkillEntropy,
    required this.topErrors,
    required this.isTargetable,
    required this.timestamp,
  });
}

class ErrorFrequency {
  final String errorTypeId;
  final double rate;
  final String errorName;

  const ErrorFrequency({
    required this.errorTypeId,
    required this.rate,
    required this.errorName,
  });
}

class LearningVelocity {
  final double masteryGainedLast7Days;
  final int skillsPracticedLast7Days;
  final int attemptsLast7Days;
  final double averageMasteryPerDay;
  final int estimatedDaysToFullMastery;
  final int unmasteredSkillCount;

  const LearningVelocity({
    required this.masteryGainedLast7Days,
    required this.skillsPracticedLast7Days,
    required this.attemptsLast7Days,
    required this.averageMasteryPerDay,
    required this.estimatedDaysToFullMastery,
    required this.unmasteredSkillCount,
  });
}

class SkillHeatmapEntry {
  final String skillId;
  final double mastery;
  final double halfLifeDays;
  final double currentRecall;
  final double errorEntropy;
  final bool isDueForReview;
  final int totalAttempts;
  final double accuracy;

  const SkillHeatmapEntry({
    required this.skillId,
    required this.mastery,
    required this.halfLifeDays,
    required this.currentRecall,
    required this.errorEntropy,
    required this.isDueForReview,
    required this.totalAttempts,
    required this.accuracy,
  });
}

class CompetenceDashboard {
  final CompetenceLevel level;
  final String dailyInsight;
  final ProgressPrediction prediction;
  final LearnerCognitiveMetrics metrics;

  const CompetenceDashboard({
    required this.level,
    required this.dailyInsight,
    required this.prediction,
    required this.metrics,
  });
}
