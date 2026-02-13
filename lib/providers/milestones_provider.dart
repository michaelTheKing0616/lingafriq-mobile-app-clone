import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_milestone_model.dart';
import '../services/sound_effects_service.dart';
import 'gamification_provider.dart';
import '../utils/structured_logger.dart';

/// Provider for progress milestones tracking
final milestonesProvider = NotifierProvider<MilestonesNotifier, UserMilestones>(() {
  return MilestonesNotifier();
});

class MilestonesNotifier extends Notifier<UserMilestones> {
  static const String _storageKey = 'user_milestones';

  @override
  UserMilestones build() {
    _loadMilestones();
    return UserMilestones();
  }

  Future<void> _loadMilestones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        state = UserMilestones.fromJson(jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (e) {
      logger.error('Error loading milestones', tag: 'milestones', error: e);
    }
  }

  Future<void> _saveMilestones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      logger.error('Error saving milestones', tag: 'milestones', error: e);
    }
  }

  /// Check and unlock a milestone if conditions are met
  Future<bool> checkAndUnlock(MilestoneType type) async {
    if (state.hasAchieved(type)) return false;

    final milestone = MilestoneDefinitions.getMilestone(type);
    if (milestone == null) return false;

    // Unlock the milestone
    final newAchieved = Set<MilestoneType>.from(state.achieved)..add(type);
    final newDates = Map<MilestoneType, DateTime>.from(state.achievedDates);
    newDates[type] = DateTime.now();

    state = state.copyWith(
      achieved: newAchieved,
      lastAchieved: DateTime.now(),
      achievedDates: newDates,
    );

    await _saveMilestones();

    // Award rewards
    await ref.read(gamificationProvider.notifier).awardXP(
      'milestone_${type.name}',
      multiplier: 1.5,
      sourceId: 'milestone_${type.name}',
    );

    await ref.read(gamificationProvider.notifier).awardCurrency(
      cowries: milestone.cowriesReward,
    );

    // Play celebration
    ref.read(soundEffectsProvider).playBadgeUnlock();

    // Show XP overlay - Note: showXPGain requires WidgetRef, not available in Notifier context
    // XP gain will be shown automatically by gamification system

    return true;
  }

  /// Check multiple milestones based on current stats
  Future<void> checkProgressMilestones({
    int? wordsLearned,
    int? totalXP,
    int? streakDays,
    int? lessonsCompleted,
    int? quizzesCompleted,
    int? perfectQuizzes,
    int? gamesPlayed,
    int? badgesEarned,
    int? level,
    int? polieMessages,
    int? voiceContributions,
  }) async {
    // Word milestones
    if (wordsLearned != null) {
      if (wordsLearned >= 1) await checkAndUnlock(MilestoneType.firstWord);
      if (wordsLearned >= 10) await checkAndUnlock(MilestoneType.tenWords);
      if (wordsLearned >= 50) await checkAndUnlock(MilestoneType.fiftyWords);
      if (wordsLearned >= 100) await checkAndUnlock(MilestoneType.hundredWords);
      if (wordsLearned >= 500) await checkAndUnlock(MilestoneType.fiveHundredWords);
      if (wordsLearned >= 1000) await checkAndUnlock(MilestoneType.thousandWords);
    }

    // XP milestones
    if (totalXP != null) {
      if (totalXP >= 1) await checkAndUnlock(MilestoneType.firstXP);
      if (totalXP >= 100) await checkAndUnlock(MilestoneType.hundredXP);
      if (totalXP >= 500) await checkAndUnlock(MilestoneType.fiveHundredXP);
      if (totalXP >= 1000) await checkAndUnlock(MilestoneType.thousandXP);
      if (totalXP >= 5000) await checkAndUnlock(MilestoneType.fiveThousandXP);
      if (totalXP >= 10000) await checkAndUnlock(MilestoneType.tenThousandXP);
    }

    // Streak milestones
    if (streakDays != null) {
      if (streakDays >= 1) await checkAndUnlock(MilestoneType.firstStreak);
      if (streakDays >= 7) await checkAndUnlock(MilestoneType.weekStreak);
      if (streakDays >= 30) await checkAndUnlock(MilestoneType.monthStreak);
      if (streakDays >= 90) await checkAndUnlock(MilestoneType.quarterStreak);
      if (streakDays >= 365) await checkAndUnlock(MilestoneType.yearStreak);
    }

    // Lesson milestones
    if (lessonsCompleted != null) {
      if (lessonsCompleted >= 1) await checkAndUnlock(MilestoneType.firstLesson);
      if (lessonsCompleted >= 10) await checkAndUnlock(MilestoneType.tenLessons);
      if (lessonsCompleted >= 50) await checkAndUnlock(MilestoneType.fiftyLessons);
      if (lessonsCompleted >= 100) await checkAndUnlock(MilestoneType.hundredLessons);
    }

    // Quiz milestones
    if (quizzesCompleted != null && quizzesCompleted >= 1) {
      await checkAndUnlock(MilestoneType.firstQuiz);
    }
    if (perfectQuizzes != null) {
      if (perfectQuizzes >= 1) await checkAndUnlock(MilestoneType.firstPerfectQuiz);
      if (perfectQuizzes >= 10) await checkAndUnlock(MilestoneType.tenPerfectQuizzes);
    }

    // Game milestones
    if (gamesPlayed != null) {
      if (gamesPlayed >= 1) await checkAndUnlock(MilestoneType.firstGame);
      if (gamesPlayed >= 10) await checkAndUnlock(MilestoneType.tenGames);
      if (gamesPlayed >= 50) await checkAndUnlock(MilestoneType.fiftyGames);
    }

    // Badge milestones
    if (badgesEarned != null) {
      if (badgesEarned >= 1) await checkAndUnlock(MilestoneType.firstBadge);
      if (badgesEarned >= 10) await checkAndUnlock(MilestoneType.tenBadges);
      if (badgesEarned >= 25) await checkAndUnlock(MilestoneType.twentyFiveBadges);
    }

    // Level milestones
    if (level != null) {
      if (level >= 5) await checkAndUnlock(MilestoneType.levelFive);
      if (level >= 10) await checkAndUnlock(MilestoneType.levelTen);
      if (level >= 25) await checkAndUnlock(MilestoneType.levelTwentyFive);
      if (level >= 50) await checkAndUnlock(MilestoneType.levelFifty);
      if (level >= 100) await checkAndUnlock(MilestoneType.levelHundred);
    }

    // Polie chat milestones
    if (polieMessages != null) {
      if (polieMessages >= 1) await checkAndUnlock(MilestoneType.firstPolieChat);
      if (polieMessages >= 100) await checkAndUnlock(MilestoneType.hundredPolieMessages);
    }

    // Voice contribution milestones
    if (voiceContributions != null) {
      if (voiceContributions >= 1) await checkAndUnlock(MilestoneType.firstVoiceContrib);
      if (voiceContributions >= 10) await checkAndUnlock(MilestoneType.tenVoiceContribs);
    }
  }

  /// Get list of achieved milestones
  List<Milestone> getAchievedMilestones() {
    return state.achieved
        .map((type) => MilestoneDefinitions.getMilestone(type))
        .whereType<Milestone>()
        .toList();
  }

  /// Get list of unachieved visible milestones
  List<Milestone> getUnachievedMilestones() {
    return MilestoneDefinitions.getVisibleMilestones()
        .where((m) => !state.hasAchieved(m.type))
        .toList();
  }

  /// Get progress percentage
  double get progressPercentage {
    final total = MilestoneDefinitions.getAllMilestones().length;
    return total > 0 ? state.totalAchieved / total : 0.0;
  }
}

