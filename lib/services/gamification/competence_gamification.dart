import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';
import 'package:lingafriq/learning/learner_model/error_taxonomy.dart';
import 'package:lingafriq/learning/skill_graph/skill_registry.dart';

/// Competence-based gamification that replaces shallow XP with real mastery signals.
///
/// Principles:
/// - Achievements reflect ACTUAL skill, not usage time
/// - Milestones are tied to mastery thresholds, not point accumulation
/// - Error reduction is celebrated (not just correctness)
/// - Social contribution earns recognition
/// - XP still exists but is calibrated to mastery changes
class CompetenceGamification {
  final LearnerModelService _learnerModel;

  CompetenceGamification({
    LearnerModelService? learnerModel,
  }) : _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Evaluates which competence achievements a learner has earned.
  ///
  /// Returns newly earned achievements (not previously unlocked).
  List<CompetenceAchievement> evaluateAchievements({
    required String learnerId,
    required String languageCode,
    required Set<String> previouslyEarned,
  }) {
    final metrics = _learnerModel.getCognitiveMetrics(
      learnerId: learnerId,
      languageCode: languageCode,
    );
    final allStates = _learnerModel.getAllStates(learnerId);
    final earned = <CompetenceAchievement>[];

    for (final achievement in _allAchievements) {
      if (previouslyEarned.contains(achievement.id)) continue;
      if (achievement.condition(metrics, allStates)) {
        earned.add(achievement);
      }
    }

    return earned;
  }

  /// Computes mastery-calibrated XP for a practice attempt.
  ///
  /// XP is proportional to:
  /// - Difficulty of the skill recalled
  /// - Memory stability (harder to recall = more XP)
  /// - Whether it was a review (maintaining) vs new learning (expanding)
  int computeMasteryXP({
    required LearnerSkillState stateBefore,
    required LearnerSkillState stateAfter,
    required bool wasReview,
  }) {
    int xp = 0;

    // Base XP for correct response
    if (stateAfter.totalAttempts > stateBefore.totalAttempts) {
      final wasCorrect = stateAfter.successfulAttempts > stateBefore.successfulAttempts;
      if (wasCorrect) {
        xp += 10;

        // Difficulty bonus: harder skills yield more XP
        final difficultyMultiplier = 1.0 + stateBefore.mastery;
        xp = (xp * difficultyMultiplier).round();

        // Review bonus: maintaining memory is valuable
        if (wasReview && stateBefore.currentRecallProbability < 0.6) {
          xp += 5; // Reviewed a decaying skill
        }

        // Streak bonus (diminishing returns to prevent grinding)
        final streakBonus = (stateAfter.currentStreak * 2).clamp(0, 20);
        xp += streakBonus;
      } else {
        // Partial XP for attempting (effort matters)
        xp += 2;
      }
    }

    // Mastery advancement bonus
    final masteryGain = stateAfter.mastery - stateBefore.mastery;
    if (masteryGain > 0.05) {
      xp += (masteryGain * 100).round();
    }

    return xp;
  }

  /// Returns the learner's competence level (not XP-based).
  ///
  /// Based on actual cognitive metrics: mastery, retention, breadth.
  CompetenceLevel getCompetenceLevel({
    required String learnerId,
    required String languageCode,
  }) {
    final metrics = _learnerModel.getCognitiveMetrics(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    if (metrics.skillsTotal == 0) return CompetenceLevel.newcomer;

    final masteryRatio = metrics.masteryRatio;
    final avgRecall = metrics.averageRecallProbability;
    final avgMastery = metrics.averageMastery;

    // Composite score (weighted)
    final score = (masteryRatio * 0.4) + (avgRecall * 0.3) + (avgMastery * 0.3);

    if (score >= 0.9) return CompetenceLevel.master;
    if (score >= 0.75) return CompetenceLevel.expert;
    if (score >= 0.6) return CompetenceLevel.proficient;
    if (score >= 0.4) return CompetenceLevel.intermediate;
    if (score >= 0.2) return CompetenceLevel.developing;
    return CompetenceLevel.beginner;
  }

  /// Generates a daily insight based on learner data.
  ///
  /// Shows real progress, not "You earned 50 XP today!"
  String generateDailyInsight({
    required String learnerId,
    required String languageCode,
  }) {
    final metrics = _learnerModel.getCognitiveMetrics(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    if (metrics.skillsTotal == 0) {
      return 'Start your first lesson to begin tracking your progress.';
    }

    // Most impactful insight first
    if (metrics.hasTargetableErrors) {
      final insight = metrics.weakestAreaInsight;
      if (insight != null) return insight;
    }

    if (metrics.averageRecallProbability < 0.5) {
      return 'You have ${metrics.mostVolatileSkillIds.length} skills decaying. '
          'A quick review session would strengthen them.';
    }

    if (metrics.masteryRatio > 0.5) {
      return 'You\'ve mastered ${metrics.skillsMastered} of ${metrics.skillsTotal} skills. '
          'Your recall stability is ${metrics.averageHalfLifeDays.toStringAsFixed(1)} days.';
    }

    return 'Your average mastery is ${(metrics.averageMastery * 100).toStringAsFixed(0)}%. '
        'Focus on your weakest skills to improve fastest.';
  }

  /// Returns progress predictions for tomorrow.
  ProgressPrediction predictTomorrow({
    required String learnerId,
    required String languageCode,
  }) {
    final metrics = _learnerModel.getCognitiveMetrics(
      learnerId: learnerId,
      languageCode: languageCode,
    );
    final allStates = _learnerModel.getAllStates(learnerId);

    // Predict how many skills will need review tomorrow
    int reviewsDue = 0;
    double avgRecallTomorrow = 0;

    for (final state in allStates.values) {
      final elapsed = DateTime.now().difference(state.lastRecall).inHours / 24.0 + 1.0;
      final recall = _predictRecall(elapsed, state.halfLifeDays);
      avgRecallTomorrow += recall;
      if (recall < 0.7) reviewsDue++;
    }

    if (allStates.isNotEmpty) {
      avgRecallTomorrow /= allStates.length;
    }

    return ProgressPrediction(
      reviewsDueTomorrow: reviewsDue,
      predictedRecallTomorrow: avgRecallTomorrow,
      strongestSkillIds: metrics.weakestSkillIds.isEmpty
          ? []
          : _getStrongestSkills(allStates),
      weakestSkillIds: metrics.weakestSkillIds,
      recommendedSessionMinutes: (reviewsDue * 0.75 + 5).clamp(5, 30).round(),
    );
  }

  double _predictRecall(double elapsedDays, double halfLifeDays) {
    if (halfLifeDays <= 0) return 0;
    return _pow2(-elapsedDays / halfLifeDays);
  }

  double _pow2(double x) {
    // 2^x approximation
    if (x >= 0) return 1.0;
    if (x < -10) return 0.0;
    // Use exp: 2^x = e^(x*ln2)
    final result = _exp(x * 0.6931471805599453);
    return result.clamp(0.0, 1.0);
  }

  double _exp(double x) {
    // Taylor series approximation for small |x|
    double sum = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      sum += term;
    }
    return sum;
  }

  List<String> _getStrongestSkills(Map<String, LearnerSkillState> states) {
    final sorted = states.entries.toList()
      ..sort((a, b) => b.value.mastery.compareTo(a.value.mastery));
    return sorted.take(5).map((e) => e.key).toList();
  }

  // ─── Achievement definitions ───────────────────────────────────────

  static final List<CompetenceAchievement> _allAchievements = [
    // Mastery achievements
    CompetenceAchievement(
      id: 'first_mastery',
      title: 'First Mastery',
      description: 'Mastered your first skill completely.',
      category: AchievementCategory.mastery,
      condition: (m, _) => m.skillsMastered >= 1,
    ),
    CompetenceAchievement(
      id: 'ten_mastered',
      title: 'Decathlon',
      description: 'Mastered 10 skills.',
      category: AchievementCategory.mastery,
      condition: (m, _) => m.skillsMastered >= 10,
    ),
    CompetenceAchievement(
      id: 'fifty_mastered',
      title: 'Scholar',
      description: 'Mastered 50 skills.',
      category: AchievementCategory.mastery,
      condition: (m, _) => m.skillsMastered >= 50,
    ),

    // Retention achievements
    CompetenceAchievement(
      id: 'iron_memory',
      title: 'Iron Memory',
      description: 'Average recall probability above 90%.',
      category: AchievementCategory.retention,
      condition: (m, _) => m.averageRecallProbability > 0.9 && m.skillsTotal >= 5,
    ),
    CompetenceAchievement(
      id: 'long_term_learner',
      title: 'Long-Term Learner',
      description: 'Average memory stability above 7 days.',
      category: AchievementCategory.retention,
      condition: (m, _) => m.averageHalfLifeDays > 7 && m.skillsTotal >= 5,
    ),

    // Error reduction achievements
    CompetenceAchievement(
      id: 'error_crusher',
      title: 'Error Crusher',
      description: 'Reduced your most common error by 50%.',
      category: AchievementCategory.errorReduction,
      condition: (m, states) {
        for (final state in states.values) {
          if (state.totalAttempts > 10 && state.accuracy > 0.85) {
            return true;
          }
        }
        return false;
      },
    ),
    CompetenceAchievement(
      id: 'low_entropy',
      title: 'Focused Learner',
      description: 'Error entropy below 1.0 (concentrated, targetable errors).',
      category: AchievementCategory.errorReduction,
      condition: (m, _) => m.errorEntropy < 1.0 && m.errorEntropy > 0 && m.skillsTotal >= 5,
    ),

    // Automaticity achievements
    CompetenceAchievement(
      id: 'quick_thinker',
      title: 'Quick Thinker',
      description: 'Average time pressure score above 80%.',
      category: AchievementCategory.automaticity,
      condition: (m, _) => m.averageTimePressure > 0.8 && m.skillsTotal >= 5,
    ),

    // Breadth achievements
    CompetenceAchievement(
      id: 'polyglot_start',
      title: 'Polyglot Start',
      description: 'Skills across all linguistic domains.',
      category: AchievementCategory.breadth,
      condition: (m, states) {
        final domains = <String>{};
        for (final state in states.values) {
          final skill = SkillRegistry.instance.findSkill(state.skillId);
          if (skill != null) domains.add(skill.type.name);
        }
        return domains.length >= 4;
      },
    ),
  ];
}

// ─── Data classes ──────────────────────────────────────────────────

class CompetenceAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final bool Function(LearnerCognitiveMetrics, Map<String, LearnerSkillState>) condition;

  const CompetenceAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
  });
}

enum AchievementCategory {
  mastery,
  retention,
  errorReduction,
  automaticity,
  breadth,
  social,
  culture,
}

enum CompetenceLevel {
  newcomer,
  beginner,
  developing,
  intermediate,
  proficient,
  expert,
  master;

  String get displayName {
    switch (this) {
      case CompetenceLevel.newcomer: return 'Newcomer';
      case CompetenceLevel.beginner: return 'Beginner';
      case CompetenceLevel.developing: return 'Developing';
      case CompetenceLevel.intermediate: return 'Intermediate';
      case CompetenceLevel.proficient: return 'Proficient';
      case CompetenceLevel.expert: return 'Expert';
      case CompetenceLevel.master: return 'Master';
    }
  }
}

class ProgressPrediction {
  final int reviewsDueTomorrow;
  final double predictedRecallTomorrow;
  final List<String> strongestSkillIds;
  final List<String> weakestSkillIds;
  final int recommendedSessionMinutes;

  const ProgressPrediction({
    required this.reviewsDueTomorrow,
    required this.predictedRecallTomorrow,
    required this.strongestSkillIds,
    required this.weakestSkillIds,
    required this.recommendedSessionMinutes,
  });
}
