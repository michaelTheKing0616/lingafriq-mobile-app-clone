import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/models/achievement_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'base_provider.dart';

final achievementsProvider = NotifierProvider<AchievementsProvider, BaseProviderState>(() {
  return AchievementsProvider();
});

class AchievementsProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  final List<Achievement> _achievements = [];
  int _totalXP = 0;
  int _level = 1;

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  int get totalXP => _totalXP;
  int get level => _level;
  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;
  List<Achievement> get unlockedAchievements => _achievements.where((a) => a.isUnlocked).toList();

  @override
  BaseProviderState build() {
    _loadAchievements();
    _loadXP();
    _initializeAchievements();
    _syncWithBackend();
    return BaseProviderState();
  }

  Future<void> _syncWithBackend() async {
    try {
      final backendAchievements = await ref.read(apiProvider.notifier).getAchievements();
      if (backendAchievements.isNotEmpty) {
        // Update local achievements with backend data
        for (final backendAchievement in backendAchievements) {
          final id = backendAchievement['id'] as String;
          final index = _achievements.indexWhere((a) => a.id == id);
          if (index >= 0 && (backendAchievement['isUnlocked'] as bool? ?? false)) {
            _achievements[index] = Achievement.fromMap(backendAchievement);
          }
        }
        await _saveAchievements();
        state = state.copyWith();
      }
    } catch (e) {
      debugPrint('Error syncing achievements with backend: $e');
      // Silently fail - local state is primary
    }
  }

  void _initializeAchievements() {
    if (_achievements.isEmpty) {
      _achievements.addAll([
        // Streak Achievements
        Achievement(
          id: 'streak_7',
          name: 'Week Warrior',
          description: 'Maintain a 7-day learning streak',
          type: AchievementType.streak,
          rarity: AchievementRarity.uncommon,
          icon: '🔥',
          xpReward: 100,
        ),
        Achievement(
          id: 'streak_30',
          name: 'Monthly Master',
          description: 'Maintain a 30-day learning streak',
          type: AchievementType.streak,
          rarity: AchievementRarity.rare,
          icon: '⭐',
          xpReward: 500,
        ),
        Achievement(
          id: 'streak_100',
          name: 'Century Champion',
          description: 'Maintain a 100-day learning streak',
          type: AchievementType.streak,
          rarity: AchievementRarity.legendary,
          icon: '👑',
          xpReward: 2000,
        ),
        // Learning Milestones
        Achievement(
          id: 'words_100',
          name: 'Word Explorer',
          description: 'Learn 100 words',
          type: AchievementType.milestone,
          rarity: AchievementRarity.common,
          icon: '📚',
          xpReward: 50,
        ),
        Achievement(
          id: 'words_1000',
          name: 'Vocabulary Virtuoso',
          description: 'Learn 1,000 words',
          type: AchievementType.milestone,
          rarity: AchievementRarity.rare,
          icon: '📖',
          xpReward: 500,
        ),
        Achievement(
          id: 'lessons_50',
          name: 'Lesson Learner',
          description: 'Complete 50 lessons',
          type: AchievementType.milestone,
          rarity: AchievementRarity.uncommon,
          icon: '🎓',
          xpReward: 200,
        ),
        Achievement(
          id: 'quizzes_100',
          name: 'Quiz Master',
          description: 'Complete 100 quizzes',
          type: AchievementType.milestone,
          rarity: AchievementRarity.rare,
          icon: '🎯',
          xpReward: 300,
        ),
        // Time-based
        Achievement(
          id: 'time_10h',
          name: 'Dedicated Learner',
          description: 'Spend 10 hours learning',
          type: AchievementType.milestone,
          rarity: AchievementRarity.uncommon,
          icon: '⏰',
          xpReward: 150,
        ),
        Achievement(
          id: 'time_100h',
          name: 'Time Titan',
          description: 'Spend 100 hours learning',
          type: AchievementType.milestone,
          rarity: AchievementRarity.epic,
          icon: '⏳',
          xpReward: 1000,
        ),
        // Language-specific
        Achievement(
          id: 'language_master',
          name: 'Polyglot',
          description: 'Learn 5 different languages',
          type: AchievementType.badge,
          rarity: AchievementRarity.epic,
          icon: '🌍',
          xpReward: 800,
        ),
      ]);
      _saveAchievements();
    }
  }

  void checkAndUnlockAchievements({
    int? streak,
    int? wordsLearned,
    int? lessonsCompleted,
    int? quizzesCompleted,
    double? hoursSpent,
    int? languagesLearned,
  }) {
    bool anyUnlocked = false;

    for (var achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'streak_7':
          shouldUnlock = streak != null && streak >= 7;
          break;
        case 'streak_30':
          shouldUnlock = streak != null && streak >= 30;
          break;
        case 'streak_100':
          shouldUnlock = streak != null && streak >= 100;
          break;
        case 'words_100':
          shouldUnlock = wordsLearned != null && wordsLearned >= 100;
          break;
        case 'words_1000':
          shouldUnlock = wordsLearned != null && wordsLearned >= 1000;
          break;
        case 'lessons_50':
          shouldUnlock = lessonsCompleted != null && lessonsCompleted >= 50;
          break;
        case 'quizzes_100':
          shouldUnlock = quizzesCompleted != null && quizzesCompleted >= 100;
          break;
        case 'time_10h':
          shouldUnlock = hoursSpent != null && hoursSpent >= 10;
          break;
        case 'time_100h':
          shouldUnlock = hoursSpent != null && hoursSpent >= 100;
          break;
        case 'language_master':
          shouldUnlock = languagesLearned != null && languagesLearned >= 5;
          break;
      }

      if (shouldUnlock) {
        final index = _achievements.indexWhere((a) => a.id == achievement.id);
        if (index >= 0) {
          _achievements[index] = Achievement(
            id: achievement.id,
            name: achievement.name,
            description: achievement.description,
            type: achievement.type,
            rarity: achievement.rarity,
            icon: achievement.icon,
            xpReward: achievement.xpReward,
            unlockedAt: DateTime.now(),
            isUnlocked: true,
            metadata: achievement.metadata,
          );
          _totalXP += achievement.xpReward;
          _updateLevel();
          anyUnlocked = true;
        }
      }
    }

    if (anyUnlocked) {
      _saveAchievements();
      _saveXP();
      state = state.copyWith();
    }
  }

  void _updateLevel() {
    // Level up formula: level = sqrt(XP / 100)
    final xpRatio = _totalXP / 100;
    _level = sqrt(xpRatio).floor() + 1;
  }

  Future<void> _saveAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = _achievements.map((a) => a.toJson()).toList();
      await prefs.setStringList('achievements', achievementsJson);
    } catch (e) {
      debugPrint('Error saving achievements: $e');
    }
  }

  Future<void> _loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getStringList('achievements') ?? [];
      if (achievementsJson.isNotEmpty) {
        _achievements.clear();
        _achievements.addAll(achievementsJson.map((json) => Achievement.fromJson(json)));
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> _saveXP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_xp', _totalXP);
      await prefs.setInt('user_level', _level);
    } catch (e) {
      debugPrint('Error saving XP: $e');
    }
  }

  Future<void> _loadXP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalXP = prefs.getInt('total_xp') ?? 0;
      _level = prefs.getInt('user_level') ?? 1;
    } catch (e) {
      debugPrint('Error loading XP: $e');
    }
  }
}

