import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_gamification_model.dart';
import '../models/badge_model.dart';
import 'api_provider.dart';
import 'backend_sync_provider.dart';
import 'user_provider.dart';
import 'base_provider.dart';
import 'gamification_services_provider.dart';
import '../services/gamification/events_service.dart';

final gamificationProvider =
    NotifierProvider<GamificationProvider, BaseProviderState>(() {
  return GamificationProvider();
});

/// Core gamification engine - beats Duolingo, Babbel, and all competitors
class GamificationProvider extends Notifier<BaseProviderState>
    with BaseProviderMixin {
  UserGamificationModel _gamification = UserGamificationModel();
  final List<Badge> _allBadges = BadgeDefinitions.getAllBadges();

  UserGamificationModel get gamification => _gamification;
  List<Badge> get allBadges => List.unmodifiable(_allBadges);
  List<Badge> get unlockedBadges => _allBadges
      .where((b) => _gamification.unlockedBadges.contains(b.id))
      .toList();

  @override
  BaseProviderState build() {
    _loadGamification();
    _syncWithBackend();
    return BaseProviderState();
  }

  /// Award XP and handle level ups, currency rewards
  /// Uses server-authoritative XP service to prevent cheating
  Future<int> awardXP(String source, {double multiplier = 1.0, String? sourceId}) async {
    final baseXP = XPSources.getXP(source);
    final xpGain = (baseXP * multiplier).round();
    
    // Map source to backend XP source type
    final backendSource = _mapSourceToBackendType(source);
    final uniqueSourceId = sourceId ?? '${source}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Award XP via backend service (server-authoritative)
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        final success = await ref.read(apiProvider.notifier).awardXP(
          userId: user.id.toString(),
          source: backendSource,
          sourceId: uniqueSourceId,
          amount: xpGain,
          difficultyMultiplier: multiplier,
        );
        
        if (!success) {
          debugPrint('Failed to award XP via backend for source: $source');
          // Fall back to local-only if backend fails (for offline support)
          // But don't sync to backend to prevent double-counting
        } else {
          // Update local state from backend response
          try {
            final userXP = await ref.read(apiProvider.notifier).getUserXP(user.id.toString());
            if (userXP != null && userXP is Map<String, dynamic>) {
              final totalXP = (userXP['totalXP'] as num?)?.toInt() ?? _gamification.xp;
              final backendLevel = (userXP['level'] as num?)?.toInt();
              final newLevel = backendLevel ?? LevelTitles.getLevelFromXP(totalXP);
              final newTitle = LevelTitles.getTitleForLevel(newLevel);
              
              _gamification = _gamification.copyWith(
                xp: totalXP,
                level: newLevel,
                levelTitle: newTitle,
              );
            }
          } catch (e) {
            debugPrint('Error updating local XP from backend: $e');
            // Continue with local calculation
          }
        }
      }
    } catch (e) {
      debugPrint('Error awarding XP via backend: $e');
      // Fall back to local-only for offline support
    }
    
    // Calculate currency rewards (5 ngwenya per XP)
    final ngwenyaGain = xpGain ~/ 5;
    final currentXP = _gamification.xp;
    final newXP = currentXP + xpGain;
    final newLevel = LevelTitles.getLevelFromXP(newXP);
    final newTitle = LevelTitles.getTitleForLevel(newLevel);

    _gamification = _gamification.copyWith(
      xp: newXP,
      level: newLevel,
      levelTitle: newTitle,
      ngwenya: _gamification.ngwenya + ngwenyaGain,
    );

    // Level up bonus
    if (newLevel > _gamification.level) {
      final levelUpBonus = 50 * (newLevel - _gamification.level);
      _gamification = _gamification.copyWith(
        cowries: _gamification.cowries + levelUpBonus,
      );
      debugPrint('Level up! New level: $newLevel - $newTitle');
      
      // Emit level up event
      await _emitEvent('level_up', {
        'old_level': _gamification.level,
        'new_level': newLevel,
        'bonus': levelUpBonus,
      });
    }

    // Emit XP gain event
    await _emitEvent('xp_gained', {
      'source': source,
      'amount': xpGain,
      'multiplier': multiplier,
      'total_xp': newXP,
    });

    await _saveGamification();
    await _checkBadges();
    await _syncToBackend();

    state = state.copyWith();
    return xpGain;
  }
  
  /// Map frontend XP source to backend source type
  String _mapSourceToBackendType(String source) {
    if (source.contains('quiz') || source.contains('lesson')) {
      return 'quiz';
    } else if (source.contains('story') || source.contains('chapter') || source.contains('quest')) {
      return 'story';
    } else if (source.contains('chat') || source.contains('polie')) {
      return 'chat';
    } else if (source.contains('event')) {
      return 'event';
    } else if (source.contains('tribe')) {
      return 'tribe';
    }
    // Default to quiz for unknown sources
    return 'quiz';
  }

  /// Emit event to backend
  Future<void> _emitEvent(String eventType, Map<String, dynamic> payload) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final eventsService = ref.read(eventsServiceProvider);
      await eventsService.ingestEvent(
        eventType: eventType,
        payload: payload,
        userId: user.id.toString(),
      );
    } catch (e) {
      debugPrint('Error emitting event: $e');
      // Don't throw - event emission failure shouldn't break XP flow
    }
  }

  /// Daily check-in with streak management
  Future<void> dailyCheckIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = _gamification.lastLogin;
    final lastLoginDate =
        lastLogin != null ? DateTime(lastLogin.year, lastLogin.month, lastLogin.day) : null;

    int newStreak = _gamification.dailyStreak;
    int newFreezeLeft = _gamification.freezeLeft;

    if (lastLoginDate == today) {
      // Already checked in today
      return;
    }

    if (lastLoginDate == today.subtract(const Duration(days: 1))) {
      // Consecutive day
      newStreak = _gamification.dailyStreak + 1;
    } else if (lastLoginDate == today.subtract(const Duration(days: 2)) &&
        _gamification.freezeLeft > 0) {
      // Use freeze (Ask the Ancestors)
      newStreak = _gamification.dailyStreak;
      newFreezeLeft = _gamification.freezeLeft - 1;
      debugPrint('Used streak freeze! Remaining: $newFreezeLeft');
    } else {
      // Streak broken
      if (_gamification.ubuntuStreakActive && _gamification.dailyStreak > 0) {
        // Ubuntu mode: donate lessons instead of breaking.
        final previousStreak = _gamification.dailyStreak;
        final donatedLessons = previousStreak.clamp(1, 30);
        final estimatedDonatedXp = donatedLessons * 30; // ~30 XP per lesson

        debugPrint(
          'Ubuntu streak: donating $donatedLessons lessons (~$estimatedDonatedXp XP) '
          'to help others instead of breaking a ${previousStreak}-day streak.',
        );

        // Fire-and-forget donation to backend; failure should not block UX.
        _donateUbuntuStreak(
          streakBefore: previousStreak,
          donatedLessons: donatedLessons,
          donatedXp: estimatedDonatedXp,
        );

        // Preserve streak instead of resetting.
        newStreak = previousStreak;
      } else {
        newStreak = 1;
      }
    }

    // Streak bonuses
    int streakBonus = 20;
    if (newStreak % 7 == 0) {
      streakBonus = 100; // Perfect week bonus
      await _checkPerfectWeekStreak(newStreak);
    }

    _gamification = _gamification.copyWith(
      dailyStreak: newStreak,
      freezeLeft: newFreezeLeft,
      lastLogin: now,
      cowries: _gamification.cowries + streakBonus,
    );

    // Award XP for daily check-in
    await awardXP('daily_checkin');

    await _saveGamification();
    await _checkBadges();
    await _syncToBackend();

    state = state.copyWith();
  }

  /// Ubuntu streak donation helper – informs backend that the learner chose
  /// to convert a broken streak into help for others.
  Future<void> _donateUbuntuStreak({
    required int streakBefore,
    required int donatedLessons,
    required int donatedXp,
  }) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final api = ref.read(apiProvider.notifier);
      await api.donateUbuntuStreak(
        streakBefore: streakBefore,
        donatedLessons: donatedLessons,
        donatedXp: donatedXp,
        language: null, // Optional: can be wired to current study language
      );

      // Emit a local gamification event for analytics / UI nudges.
      await _emitEvent('ubuntu_donation', {
        'streak_before': streakBefore,
        'donated_lessons': donatedLessons,
        'donated_xp': donatedXp,
      });
    } catch (e) {
      debugPrint('Error during Ubuntu streak donation: $e');
    }
  }

  /// Check perfect week streak
  Future<void> _checkPerfectWeekStreak(int streak) async {
    if (streak >= 7 && streak % 7 == 0) {
      _gamification = _gamification.copyWith(
        perfectWeekStreak: _gamification.perfectWeekStreak + 1,
      );
      await awardXP('perfect_week');
    }
  }

  /// Unlock a badge
  Future<bool> unlockBadge(String badgeId) async {
    if (_gamification.unlockedBadges.contains(badgeId)) {
      return false; // Already unlocked
    }

    final badge = BadgeDefinitions.getBadgeById(badgeId);
    if (badge == null) {
      debugPrint('Badge not found: $badgeId');
      return false;
    }

    final newBadges = List<String>.from(_gamification.unlockedBadges)..add(badgeId);

    _gamification = _gamification.copyWith(
      unlockedBadges: newBadges,
      ngwenya: _gamification.ngwenya + badge.cowriesReward,
      cowries: _gamification.cowries + badge.cowriesReward,
      ancestralBeads: _gamification.ancestralBeads + badge.beadsReward,
    );

    // Award XP for badge
    await awardXP('unlock_badge', multiplier: badge.xpReward / 50.0);

    await _saveGamification();
    await _syncToBackend();

    state = state.copyWith();
    debugPrint('Badge unlocked: ${badge.name}');
    return true;
  }

  /// Check and unlock badges based on current progress
  Future<void> _checkBadges() async {
    // Streak badges
    if (_gamification.dailyStreak >= 7 && !_gamification.unlockedBadges.contains('streak_7')) {
      await unlockBadge('streak_7');
    }
    if (_gamification.dailyStreak >= 30 && !_gamification.unlockedBadges.contains('streak_30')) {
      await unlockBadge('streak_30');
    }
    if (_gamification.dailyStreak >= 100 && !_gamification.unlockedBadges.contains('streak_100')) {
      await unlockBadge('streak_100');
    }

    // Perfect week badge
    if (_gamification.perfectWeekStreak >= 1 &&
        !_gamification.unlockedBadges.contains('perfect_week')) {
      // Add perfect week badge if needed
    }

    // Tonal mastery badge
    if (_gamification.tonalMasteryStreak >= 7 &&
        !_gamification.unlockedBadges.contains('tonal_master')) {
      await unlockBadge('tonal_master');
    }
  }

  /// Set user's tribe
  Future<void> setTribe(String tribe) async {
    if (!Tribes.isValidTribe(tribe)) {
      throw ArgumentError('Invalid tribe: $tribe');
    }

    _gamification = _gamification.copyWith(tribe: tribe);
    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
  }

  /// Activate a booster/item
  Future<bool> activateBooster(String boosterId, [int durationHours = 0]) async {
    // Check if user has the item (would need item inventory system)
    // For now, just track active boosters
    if (_gamification.activeBoosters.contains(boosterId)) {
      return false; // Already active
    }

    final newBoosters = List<String>.from(_gamification.activeBoosters)..add(boosterId);
    _gamification = _gamification.copyWith(activeBoosters: newBoosters);

    await _saveGamification();
    state = state.copyWith();
    return true;
  }

  /// Select tribe
  Future<void> selectTribe(String tribeId) async {
    _gamification = _gamification.copyWith(tribe: tribeId);
    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
  }

  /// Update quest progress
  Future<void> updateQuestProgress(String questId, int progress) async {
    final currentProgress = _gamification.questProgress[questId] ?? 0;
    final newProgress = currentProgress + progress;

    final updatedProgress = Map<String, int>.from(_gamification.questProgress)
      ..[questId] = newProgress;

    _gamification = _gamification.copyWith(questProgress: updatedProgress);

    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
  }

  /// Update tonal mastery streak
  Future<void> updateTonalMasteryStreak(bool perfect) async {
    if (perfect) {
      _gamification = _gamification.copyWith(
        tonalMasteryStreak: _gamification.tonalMasteryStreak + 1,
      );
      await _checkBadges();
    } else {
      _gamification = _gamification.copyWith(tonalMasteryStreak: 0);
    }

    await _saveGamification();
    state = state.copyWith();
  }

  /// Award currency directly
  Future<void> awardCurrency({
    int? cowries,
    int? ngwenya,
    int? ancestralBeads,
  }) async {
    _gamification = _gamification.copyWith(
      cowries: _gamification.cowries + (cowries ?? 0),
      ngwenya: _gamification.ngwenya + (ngwenya ?? 0),
      ancestralBeads: _gamification.ancestralBeads + (ancestralBeads ?? 0),
    );
    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
  }

  /// Enable Ubuntu streak (never break - help others if you do)
  Future<void> enableUbuntuStreak() async {
    _gamification = _gamification.copyWith(ubuntuStreakActive: true);
    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
  }

  /// Explicitly set the Ubuntu streak flag (used when turning it off).
  Future<void> setUbuntuStreakActive(bool active) async {
    _gamification = _gamification.copyWith(ubuntuStreakActive: active);
    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
  }

  /// Persistence
  Future<void> _saveGamification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _gamification.toJson();
      await prefs.setString('user_gamification', jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving gamification: $e');
    }
  }

  Future<void> _loadGamification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('user_gamification');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _gamification = UserGamificationModel.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading gamification: $e');
    }
  }

  /// Backend sync
  Future<void> _syncWithBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;
      
      final api = ref.read(apiProvider.notifier);
      final backendData = await api.getGamification(user.id.toString());
      if (backendData != null && backendData.isNotEmpty) {
        _gamification = UserGamificationModel.fromJson(backendData);
        await _saveGamification();
        state = state.copyWith();
      }
    } catch (e) {
      debugPrint('Error syncing gamification with backend: $e');
    }
  }

  Future<void> _syncToBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final syncProvider = ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.gamification,
        data: {
          'user_id': user.id.toString(),
          'gamification': _gamification.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error queuing gamification sync: $e');
    }
  }

}

