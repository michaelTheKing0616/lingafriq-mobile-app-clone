import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';
import 'package:lingafriq/learning/learner_model/error_taxonomy.dart';
import 'package:lingafriq/learning/scheduling/review_scheduler.dart';
import 'package:lingafriq/services/gamification/competence_gamification.dart';
import 'package:lingafriq/ai/modes/mode_prompts.dart';
import 'package:lingafriq/providers/learning_engine_providers.dart';

/// The bridge that connects the learning engine to existing UI providers.
///
/// This service:
/// 1. Translates GroqChatProvider interactions into learner model updates
/// 2. Feeds cognitive metrics into progress dashboards
/// 3. Connects game completions to skill outcomes
/// 4. Persists achievement unlocks and queues them for sync
/// 5. Provides real-time recommendations to any screen that asks
///
/// It is the SINGLE integration point between old and new systems.
class LearningEngineBridge {
  static LearningEngineBridge? _instance;
  static LearningEngineBridge get instance => _instance ??= LearningEngineBridge._();
  LearningEngineBridge._();

  final _learnerModel = LearnerModelService.instance;
  final _gamification = CompetenceGamification();
  final _scheduler = ReviewScheduler();

  // ─── Chat Integration ──────────────────────────────────────────────

  /// Called by GroqChatProvider after each message exchange.
  ///
  /// Maps the chat interaction into a learner model update.
  Future<LearningEngineUpdate> onChatInteraction({
    required String learnerId,
    required String languageCode,
    required String mode,
    required String userMessage,
    required String aiResponse,
    required double responseTimeSeconds,
    bool wasCorrect = true,
    List<String> detectedErrors = const [],
  }) async {
    // Derive skill ID from language + mode context
    final skillId = _deriveSkillId(languageCode, mode, userMessage);

    final stateBefore = _learnerModel.getState(
      learnerId: learnerId,
      skillId: skillId,
    );

    // Record the attempt
    final stateAfter = await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: wasCorrect,
      errorTypeIds: detectedErrors,
      responseTimeSeconds: responseTimeSeconds,
    );

    // Compute mastery-calibrated XP
    final xp = _gamification.computeMasteryXP(
      stateBefore: stateBefore,
      stateAfter: stateAfter,
      wasReview: stateBefore.totalAttempts > 0,
    );

    // Check for new achievements
    final newAchievements = _gamification.evaluateAchievements(
      learnerId: learnerId,
      languageCode: languageCode,
      previouslyEarned: await _getEarnedAchievementIds(learnerId),
    );

    // Persist new achievements
    if (newAchievements.isNotEmpty) {
      await _persistAchievements(learnerId, languageCode, newAchievements);
    }

    // Get next recommendation
    final recs = _learnerModel.getRecommendations(
      learnerId: learnerId,
      languageCode: languageCode,
      count: 1,
    );

    return LearningEngineUpdate(
      skillId: skillId,
      masteryDelta: stateAfter.mastery - stateBefore.mastery,
      newMastery: stateAfter.mastery,
      xpEarned: xp,
      newAchievements: newAchievements.map((a) => a.title).toList(),
      nextRecommendedSkillId: recs.isNotEmpty ? recs.first.skillId : null,
      reviewsDue: _scheduler.getDueReviews(
        learnerId: learnerId,
        languageCode: languageCode,
      ).length,
      dailyInsight: _gamification.generateDailyInsight(
        learnerId: learnerId,
        languageCode: languageCode,
      ),
    );
  }

  // ─── Game Integration ──────────────────────────────────────────────

  /// Called by BaseGameScreen after each game turn/completion.
  Future<LearningEngineUpdate> onGameCompletion({
    required String learnerId,
    required String languageCode,
    required String gameType,
    required List<GameTurnResult> turns,
  }) async {
    double totalMasteryDelta = 0;
    int totalXp = 0;

    for (final turn in turns) {
      final skillId = turn.skillId ?? _deriveSkillId(languageCode, gameType, turn.cardId);

      final before = _learnerModel.getState(
        learnerId: learnerId,
        skillId: skillId,
      );

      final after = await _learnerModel.recordAttempt(
        learnerId: learnerId,
        skillId: skillId,
        wasCorrect: turn.isCorrect,
        errorTypeIds: turn.errorTypeIds,
        responseTimeSeconds: turn.durationMs / 1000.0,
      );

      totalMasteryDelta += after.mastery - before.mastery;
      totalXp += _gamification.computeMasteryXP(
        stateBefore: before,
        stateAfter: after,
        wasReview: before.totalAttempts > 0,
      );
    }

    final newAchievements = _gamification.evaluateAchievements(
      learnerId: learnerId,
      languageCode: languageCode,
      previouslyEarned: await _getEarnedAchievementIds(learnerId),
    );

    if (newAchievements.isNotEmpty) {
      await _persistAchievements(learnerId, languageCode, newAchievements);
    }

    return LearningEngineUpdate(
      skillId: turns.isNotEmpty ? (turns.first.skillId ?? '') : '',
      masteryDelta: totalMasteryDelta,
      newMastery: 0,
      xpEarned: totalXp,
      newAchievements: newAchievements.map((a) => a.title).toList(),
      reviewsDue: _scheduler.getDueReviews(
        learnerId: learnerId,
        languageCode: languageCode,
      ).length,
      dailyInsight: _gamification.generateDailyInsight(
        learnerId: learnerId,
        languageCode: languageCode,
      ),
    );
  }

  // ─── Progress Dashboard Data ───────────────────────────────────────

  /// Returns cognitive metrics formatted for the progress dashboard.
  ProgressDashboardData getProgressDashboard({
    required String learnerId,
    required String languageCode,
  }) {
    final metrics = _learnerModel.getCognitiveMetrics(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    final level = _gamification.getCompetenceLevel(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    final prediction = _gamification.predictTomorrow(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    final reviewDue = _scheduler.getDueReviews(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    return ProgressDashboardData(
      competenceLevel: level.displayName,
      averageMastery: metrics.averageMastery,
      averageRecall: metrics.averageRecallProbability,
      skillsMastered: metrics.skillsMastered,
      skillsTotal: metrics.skillsTotal,
      averageHalfLife: metrics.averageHalfLifeDays,
      weakestSkills: metrics.weakestSkillIds,
      reviewsDue: reviewDue.length,
      nextReviewTime: _scheduler.nextSessionTime(
        learnerId: learnerId,
        languageCode: languageCode,
      ),
      prediction: prediction,
      dailyInsight: _gamification.generateDailyInsight(
        learnerId: learnerId,
        languageCode: languageCode,
      ),
    );
  }

  // ─── Media Import Integration ──────────────────────────────────────

  /// Registers media learning results in the learner model.
  Future<int> onMediaImported({
    required String learnerId,
    required String languageCode,
    required List<String> newSkillIds,
  }) async {
    int registered = 0;
    for (final skillId in newSkillIds) {
      _learnerModel.getState(learnerId: learnerId, skillId: skillId);
      registered++;
    }
    return registered;
  }

  // ─── Home Dashboard Data ───────────────────────────────────────────

  /// Returns the most impactful action for the home screen.
  String getHomeScreenAction({
    required String learnerId,
    required String languageCode,
  }) {
    final reviewDue = _scheduler.getDueReviews(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    if (reviewDue.length >= 3) {
      return 'You have ${reviewDue.length} skills decaying. Quick review?';
    }

    final metrics = _learnerModel.getCognitiveMetrics(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    if (metrics.hasTargetableErrors) {
      final insight = metrics.weakestAreaInsight;
      if (insight != null) return insight;
    }

    if (metrics.skillsTotal == 0) {
      return 'Start your first lesson to begin learning!';
    }

    return 'Continue building your ${languageCode} skills.';
  }

  // ─── Private helpers ───────────────────────────────────────────────

  String _deriveSkillId(String language, String mode, String context) {
    final normalizedContext = context.toLowerCase().trim();
    final hash = normalizedContext.hashCode.abs() % 10000;
    return '${language}_${mode}_$hash';
  }

  Future<Set<String>> _getEarnedAchievementIds(String learnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('earned_achievements_$learnerId') ?? [];
    return data.toSet();
  }

  Future<void> _persistAchievements(
    String learnerId,
    String languageCode,
    List<CompetenceAchievement> achievements,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Save to earned list
    final earned = prefs.getStringList('earned_achievements_$learnerId') ?? [];
    for (final a in achievements) {
      earned.add(a.id);
    }
    await prefs.setStringList('earned_achievements_$learnerId', earned);

    // Queue for sync
    final pending = prefs.getStringList('pending_achievements') ?? [];
    for (final a in achievements) {
      pending.add(jsonEncode({
        'achievementId': a.id,
        'languageCode': languageCode,
        'title': a.title,
        'description': a.description,
        'category': a.category.name,
      }));
    }
    await prefs.setStringList('pending_achievements', pending);
  }
}

// ─── Data classes ──────────────────────────────────────────────────

class LearningEngineUpdate {
  final String skillId;
  final double masteryDelta;
  final double newMastery;
  final int xpEarned;
  final List<String> newAchievements;
  final String? nextRecommendedSkillId;
  final int reviewsDue;
  final String dailyInsight;

  const LearningEngineUpdate({
    required this.skillId,
    required this.masteryDelta,
    required this.newMastery,
    required this.xpEarned,
    this.newAchievements = const [],
    this.nextRecommendedSkillId,
    this.reviewsDue = 0,
    this.dailyInsight = '',
  });
}

class GameTurnResult {
  final String cardId;
  final String? skillId;
  final bool isCorrect;
  final int durationMs;
  final List<String> errorTypeIds;

  const GameTurnResult({
    required this.cardId,
    this.skillId,
    required this.isCorrect,
    required this.durationMs,
    this.errorTypeIds = const [],
  });
}

class ProgressDashboardData {
  final String competenceLevel;
  final double averageMastery;
  final double averageRecall;
  final int skillsMastered;
  final int skillsTotal;
  final double averageHalfLife;
  final List<String> weakestSkills;
  final int reviewsDue;
  final DateTime nextReviewTime;
  final ProgressPrediction prediction;
  final String dailyInsight;

  const ProgressDashboardData({
    required this.competenceLevel,
    required this.averageMastery,
    required this.averageRecall,
    required this.skillsMastered,
    required this.skillsTotal,
    required this.averageHalfLife,
    required this.weakestSkills,
    required this.reviewsDue,
    required this.nextReviewTime,
    required this.prediction,
    required this.dailyInsight,
  });

  double get masteryPercentage => (averageMastery * 100);
  double get recallPercentage => (averageRecall * 100);
}
