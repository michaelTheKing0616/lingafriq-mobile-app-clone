import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_gamification_model.dart';
import '../models/badge_model.dart';
import 'api_provider.dart';
import 'user_provider.dart';
import 'base_provider.dart';
import 'gamification_services_provider.dart';
import '../services/rive_gamification_service.dart';
import '../utils/api.dart';
import '../config/api_contract.dart';
import 'dio_provider.dart' show client;
import '../utils/structured_logger.dart';
import '../widgets/gamification/streak_milestone_overlay.dart';
import '../models/game_streak.dart';
import 'notification_provider.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';

final gamificationProvider =
    NotifierProvider<GamificationProvider, BaseProviderState>(() {
  return GamificationProvider();
});

class CircleQuestMemberLabel {
  const CircleQuestMemberLabel({
    required this.slot,
    required this.isViewer,
    this.userId,
  });
  final String slot;
  final bool isViewer;
  final String? userId;
}

class CircleQuestSnapshot {
  const CircleQuestSnapshot({
    required this.empty,
    required this.goalXp,
    required this.progressXp,
    required this.members,
    this.complete = false,
  });

  final bool empty;
  final int goalXp;
  final int progressXp;
  final List<CircleQuestMemberLabel> members;
  final bool complete;

  factory CircleQuestSnapshot.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'] as List<dynamic>? ?? [];
    return CircleQuestSnapshot(
      empty: json['empty'] == true,
      goalXp: (json['goalXp'] as num?)?.toInt() ?? 0,
      progressXp: (json['progressXp'] as num?)?.toInt() ?? 0,
      complete: json['complete'] == true,
      members: membersRaw
          .map((e) => CircleQuestMemberLabel(
                slot: (e as Map)['slot']?.toString() ?? 'Learner',
                isViewer: (e as Map)['isViewer'] == true,
                userId: (e as Map)['userId']?.toString(),
              ))
          .toList(),
    );
  }
}

class FamilyPhraseSnapshot {
  const FamilyPhraseSnapshot({
    required this.empty,
    this.phrase = '',
    this.gloss = '',
  });

  final bool empty;
  final String phrase;
  final String gloss;

  factory FamilyPhraseSnapshot.fromJson(Map<String, dynamic> json) {
    return FamilyPhraseSnapshot(
      empty: json['empty'] == true,
      phrase: json['phrase']?.toString() ?? '',
      gloss: json['gloss']?.toString() ?? '',
    );
  }
}

class HeritageTreeSnapshot {
  const HeritageTreeSnapshot({
    required this.canDoCount,
    required this.stage,
    required this.members,
  });

  final int canDoCount;
  final String stage;
  final List<CircleQuestMemberLabel> members;

  factory HeritageTreeSnapshot.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'] as List<dynamic>? ?? [];
    return HeritageTreeSnapshot(
      canDoCount: (json['canDoCount'] as num?)?.toInt() ?? 0,
      stage: json['stage']?.toString() ?? 'seed',
      members: membersRaw
          .map((e) => CircleQuestMemberLabel(
                slot: (e as Map)['slot']?.toString() ?? 'Learner',
                isViewer: (e as Map)['isViewer'] == true,
              ))
          .toList(),
    );
  }
}

/// Core gamification engine - beats Duolingo, Babbel, and all competitors
class GamificationProvider extends Notifier<BaseProviderState>
    with BaseProviderMixin {
  UserGamificationModel _gamification = UserGamificationModel();
  String? _serverBalanceError;
  String? get serverBalanceError => _serverBalanceError;
  final List<Badge> _allBadges = BadgeDefinitions.getAllBadges();

  CircleQuestSnapshot? _circleQuest;
  FamilyPhraseSnapshot? _familyPhrase;
  HeritageTreeSnapshot? _heritageTree;
  StreakCadence _streakCadence = StreakCadence.daily;
  List<String> _practiceDaysThisWeek = [];
  DateTime? _streakBrokenAt;

  CircleQuestSnapshot? get circleQuest => _circleQuest;
  StreakCadence get streakCadence => _streakCadence;
  FamilyPhraseSnapshot? get familyPhrase => _familyPhrase;
  HeritageTreeSnapshot? get heritageTree => _heritageTree;

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

  /// Award XP and handle level ups, currency rewards.
  /// Uses server-authoritative XP service to prevent cheating.
  ///
  /// Flow:
  /// 1. Try backend award → on success, use backend-reported totals (authoritative).
  /// 2. If backend fails → apply optimistic local XP but mark as *pending* so
  ///    the next sync does NOT blindly overwrite backend state and cause a
  ///    double-count.
  Future<int> awardXP(String source, {double multiplier = 1.0, String? sourceId}) async {
    final baseXP = XPSources.getXP(source);
    final xpGain = (baseXP * multiplier).round();

    // Map source to backend XP source type
    final backendSource = _mapSourceToBackendType(source);
    final uniqueSourceId = sourceId ?? '${source}_${DateTime.now().millisecondsSinceEpoch}';

    bool backendAwarded = false;

    // 1. Award XP via backend service (server-authoritative)
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        final success = await ref.read(apiProvider.notifier).awardXP(
          userId: user.id.toString(),
          source: backendSource,
          sourceId: uniqueSourceId,
          amount: 0,
          difficultyMultiplier: multiplier,
        );

        if (success) {
          backendAwarded = true;
          _serverBalanceError = null;
          // Update local state from backend response (authoritative totals)
          try {
            final userXP = await ref.read(apiProvider.notifier).getUserXP(user.id.toString());
            if (userXP != null) {
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
            logger.error('Error updating local XP from backend', tag: 'gamification', error: e);
            // Continue — local state was already partially updated
          }
        } else {
          logger.warn('Failed to award XP via backend', tag: 'gamification', context: {'source': source});
        }
      }
    } catch (e) {
      logger.error('Error awarding XP via backend', tag: 'gamification', error: e, context: {'source': source});
    }

    if (backendAwarded) {
      await _saveGamification();
      state = state.copyWith();
      return xpGain;
    }

    // Offline fallback: no local balance mint; queue retry via outbox sync path.
    final currentXP = _gamification.xp;
    final newXP = currentXP + xpGain;
    final newLevel = LevelTitles.getLevelFromXP(newXP);
    final newTitle = LevelTitles.getTitleForLevel(newLevel);

    _gamification = _gamification.copyWith(
      xp: newXP,
      level: newLevel,
      levelTitle: newTitle,
    );

    // Level up bonus
    if (newLevel > _gamification.level) {
      final levelUpBonus = 50 * (newLevel - _gamification.level);
      _gamification = _gamification.copyWith(
        cowries: _gamification.cowries + levelUpBonus,
      );
      logger.info('Level up!', tag: 'gamification', context: {'newLevel': newLevel, 'newTitle': newTitle});

      // React with Rive
      try {
        ref.read(riveGamificationServiceProvider).reactToLevelUp(newLevel: newLevel);
      } catch (e) {
        logger.warn('Rive service not available', tag: 'gamification', error: e);
      }

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

    // 3. CRITICAL: Only sync optimistic state to backend when the backend
    //    award succeeded. If it failed, queue a *pending XP event* instead
    //    so the next sync retries the award rather than overwriting backend
    //    totals with a stale/inflated local value.
    if (backendAwarded) {
      await _syncToBackend();
    } else {
      // Queue the failed XP award as a retriable event — NOT a full state sync
      await _queuePendingXPEvent(backendSource, uniqueSourceId, xpGain, multiplier);
    }

    state = state.copyWith();
    return xpGain;
  }

  /// Queue a failed XP award as a retriable sync task so it can be
  /// re-attempted on next connectivity window without double-counting.
  Future<void> _queuePendingXPEvent(
    String source, String sourceId, int amount, double multiplier,
  ) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      await PersistedOutboxService.instance.enqueue(
          type: 'gamification_sync',
          data: {
          'user_id': user.id.toString(),
          'pending_xp_award': true,
          'source': source,
          'source_id': sourceId,
          'amount': amount,
          'multiplier': multiplier,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      logger.error('Error queuing pending XP event', tag: 'gamification', error: e);
    }
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
      logger.error('Error emitting event', tag: 'gamification', error: e, context: {'eventType': eventType});
      // Don't throw - event emission failure shouldn't break XP flow
    }
  }

  Future<void> setStreakCadence(StreakCadence cadence) async {
    _streakCadence = cadence;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('streak_cadence', cadence.name);
    } catch (e) {
      logger.error('Error saving streak cadence', tag: 'gamification', error: e);
    }
    state = state.copyWith();
  }

  /// Daily check-in with streak management
  Future<void> dailyCheckIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = _gamification.lastLogin;
    final lastLoginDate =
        lastLogin != null ? DateTime(lastLogin.year, lastLogin.month, lastLogin.day) : null;

    if (lastLoginDate == today) {
      return;
    }

    final ethicalState = EthicalStreakState(
      cadence: _streakCadence,
      currentStreak: _gamification.dailyStreak,
      freezeTokens: _gamification.freezeLeft,
      lastPracticeAt: lastLogin,
      practiceDaysThisWeek: _practiceDaysThisWeek,
      brokenAt: _streakBrokenAt,
    );
    final practice = EthicalStreakPolicy.recordPractice(ethicalState, now);
    _practiceDaysThisWeek = practice.state.practiceDaysThisWeek;
    _streakBrokenAt = practice.state.brokenAt;

    int newStreak = practice.state.currentStreak;
    int newFreezeLeft = practice.state.freezeTokens;

    if (practice.streakBroken && _gamification.ubuntuStreakActive) {
      logger.info('Ubuntu streak: Donating lessons to help others', tag: 'gamification');
      await _donateLessonsToCommunity();
    }
    if (practice.freezeSpent) {
      logger.info('Used streak freeze', tag: 'gamification', context: {'remaining': newFreezeLeft});
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

    // React with Rive
    try {
      ref.read(riveGamificationServiceProvider).reactToDailyCheckIn(streak: newStreak);
    } catch (e) {
      logger.warn('Rive service not available', tag: 'gamification', error: e);
    }

    // Trigger streak milestone celebration for milestone streaks
    const streakMilestones = {7, 14, 30, 60, 100, 365};
    if (streakMilestones.contains(newStreak)) {
      try {
        ref.read(streakMilestoneOverlayProvider.notifier).showMilestone(streakCount: newStreak);
      } catch (e) {
        logger.warn('Streak milestone overlay not available', tag: 'gamification', error: e);
      }
    }

    await _saveGamification();
    await _checkBadges();
    await _syncToBackend();

    state = state.copyWith();
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
      logger.warn('Badge not found', tag: 'gamification', context: {'badgeId': badgeId});
      return false;
    }

    final newBadges = List<String>.from(_gamification.unlockedBadges)..add(badgeId);

    final cowriesBonus = badge.cowriesReward + badge.beadsReward;
    _gamification = _gamification.copyWith(
      unlockedBadges: newBadges,
      cowries: _gamification.cowries + cowriesBonus,
    );

    // Award XP for badge
    await awardXP('unlock_badge', multiplier: badge.xpReward / 50.0);

    await _saveGamification();
    await _syncToBackend();

    // React with Rive
    try {
      ref.read(riveGamificationServiceProvider).reactToBadgeUnlock();
    } catch (e) {
      logger.warn('Rive service not available', tag: 'gamification', error: e);
    }

    // Show badge unlock celebration notification
    try {
      ref.read(notificationProvider.notifier).showAchievementAlert(
        'Badge Unlocked! 🏆',
        'You earned "${badge.name}"!',
      );
    } catch (e) {
      logger.warn('Failed to show badge unlock celebration', tag: 'gamification', error: e);
    }

    state = state.copyWith();
    logger.info('Badge unlocked', tag: 'gamification', context: {'badgeName': badge.name, 'badgeId': badgeId});
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

  /// P10-909 — load circle quest + phrase for a group.
  Future<void> refreshCircleQuest(String groupId) async {
    try {
      final dio = ref.read(client);
      final questRes = await dio.get(
        ApiContract.url('/api/gamification/advanced/quests/circle?groupId=$groupId'),
      );
      final phraseRes = await dio.get(
        ApiContract.url('/api/gamification/advanced/quests/family-phrase?groupId=$groupId'),
      );
      if (questRes.data is Map<String, dynamic>) {
        _circleQuest = CircleQuestSnapshot.fromJson(questRes.data as Map<String, dynamic>);
      }
      if (phraseRes.data is Map<String, dynamic>) {
        _familyPhrase = FamilyPhraseSnapshot.fromJson(phraseRes.data as Map<String, dynamic>);
      }
      state = state.copyWith();
    } catch (e) {
      logger.error('refreshCircleQuest failed', tag: 'gamification', error: e);
    }
  }

  Future<void> refreshHeritageTree(String groupId) async {
    try {
      final dio = ref.read(client);
      final res = await dio.get(
        ApiContract.url('/api/gamification/advanced/quests/heritage-tree?groupId=$groupId'),
      );
      if (res.data is Map<String, dynamic>) {
        _heritageTree = HeritageTreeSnapshot.fromJson(res.data as Map<String, dynamic>);
        state = state.copyWith();
      }
    } catch (e) {
      logger.error('refreshHeritageTree failed', tag: 'gamification', error: e);
    }
  }

  Future<void> confirmFamilyPhraseTeachBack({
    required String groupId,
    required String learnerId,
  }) async {
    try {
      final api = ref.read(apiProvider.notifier);
      await api.post(
        ApiContract.url('/api/gamification/advanced/quests/family-phrase/confirm'),
        data: {
          'groupId': groupId,
          'learnerId': learnerId,
        },
      );
      await refreshCircleQuest(groupId);
    } catch (e) {
      logger.error('confirmFamilyPhraseTeachBack failed', tag: 'gamification', error: e);
    }
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
    @Deprecated('Cowries only (P10-902)') int? ngwenya,
    @Deprecated('Cowries only (P10-902)') int? ancestralBeads,
  }) async {
    final legacySpend = (ngwenya ?? 0) + (ancestralBeads ?? 0);
    if (legacySpend < 0) {
      await spendCurrency(cowries: -legacySpend);
      return;
    }
    if (legacySpend > 0) {
      logger.warn('Legacy currency earn blocked; server ledger only', tag: 'gamification');
      return;
    }
    if ((cowries ?? 0) > 0) {
      try {
        final evidenceId = 'cowries_${DateTime.now().millisecondsSinceEpoch}';
        final res = await client.post(
          '/api/rewards/learning-event',
          data: {
            'evidence_id': evidenceId,
            'rule_id': 'streak_bonus_cowries',
          },
        );
        if (res.statusCode == 200) {
          _serverBalanceError = null;
          await _syncWithBackend();
          return;
        }
      } catch (e) {
        logger.error('Cowries award failed', tag: 'gamification', error: e);
      }
      _serverBalanceError = 'balance_unavailable';
      state = state.copyWith();
      return;
    }
  }

  /// Spend currency (deduct from current balance)
  Future<bool> spendCurrency({
    required int cowries,
  }) async {
    if (_gamification.cowries < cowries) return false;

    _gamification = _gamification.copyWith(
      cowries: _gamification.cowries - cowries,
    );
    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
    return true;
  }

  /// Enable Ubuntu streak (never break - help others if you do)
  Future<void> enableUbuntuStreak() async {
    _gamification = _gamification.copyWith(ubuntuStreakActive: true);
    await _saveGamification();
    state = state.copyWith();
  }

  /// Toggle Ubuntu streak on/off (used by the Ubuntu card switch).
  Future<void> setUbuntuStreakActive(bool isActive) async {
    _gamification = _gamification.copyWith(ubuntuStreakActive: isActive);
    await _saveGamification();
    state = state.copyWith();
  }

  /// Persistence
  Future<void> _saveGamification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _gamification.toJson();
      await prefs.setString('user_gamification', jsonEncode(json));
      await prefs.setString('streak_cadence', _streakCadence.name);
      await prefs.setStringList('streak_practice_week_days', _practiceDaysThisWeek);
      if (_streakBrokenAt != null) {
        await prefs.setString('streak_broken_at', _streakBrokenAt!.toIso8601String());
      } else {
        await prefs.remove('streak_broken_at');
      }
    } catch (e) {
      logger.error('Error saving gamification', tag: 'gamification', error: e);
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
      final cadenceName = prefs.getString('streak_cadence');
      if (cadenceName == StreakCadence.weekly.name) {
        _streakCadence = StreakCadence.weekly;
      }
      _practiceDaysThisWeek = prefs.getStringList('streak_practice_week_days') ?? [];
      final brokenRaw = prefs.getString('streak_broken_at');
      if (brokenRaw != null) {
        _streakBrokenAt = DateTime.tryParse(brokenRaw);
      }
    } catch (e) {
      logger.error('Error loading gamification', tag: 'gamification', error: e);
    }
  }

  /// Public refresh: reload gamification from backend (e.g. after gifting cowries).
  Future<void> refreshGamification() async => _syncWithBackend();

  /// Backend sync
  Future<void> _syncWithBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;
      
      final api = ref.read(apiProvider.notifier);
      final balanceRes = await client.get('/api/rewards/balance');
      if (balanceRes.statusCode == 200 && balanceRes.data is Map) {
        final data = (balanceRes.data as Map)['data'] as Map?;
        final backendData = await api.getGamification(user.id.toString());
        if (backendData != null && backendData.isNotEmpty) {
          final merged = Map<String, dynamic>.from(backendData);
          if (data != null) {
            merged['xp'] = data['xp'];
            merged['cowries'] = data['cowries'];
          }
          _gamification = UserGamificationModel.fromJson(merged);
          _serverBalanceError = null;
          await _saveGamification();
          state = state.copyWith();
          return;
        }
      }
      _serverBalanceError = 'balance_unavailable';
      state = state.copyWith();
    } catch (e) {
      _serverBalanceError = 'balance_unavailable';
      logger.error('Error syncing gamification with backend', tag: 'gamification', error: e);
      state = state.copyWith();
    }
  }

  Future<void> _syncToBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      await PersistedOutboxService.instance.enqueue(
          type: 'gamification_sync',
          data: {
          'user_id': user.id.toString(),
          'gamification': _gamification.toSyncPayload(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      logger.error('Error queuing gamification sync', tag: 'gamification', error: e);
    }
  }

  /// Donate lessons to community when Ubuntu streak would break
  Future<void> _donateLessonsToCommunity() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final api = ref.read(apiProvider.notifier);
      final response = await api.post(
        Api.ubuntuDonate,
        data: {
          'streakBefore': _gamification.dailyStreak,
          'donatedLessons': 1, // Donate 1 lesson per broken streak
          'language': user.learningLanguage ?? 'yoruba',
        },
      );

      if (response != null && response.statusCode == 200) {
        logger.info('Successfully donated lesson to community via Ubuntu streak', tag: 'gamification');
        // Award small XP bonus for donation
        await awardXP('ubuntu_donation', multiplier: 0.5);
      } else {
        logger.warn('Failed to donate lesson', tag: 'gamification', context: {'statusCode': response?.statusCode});
      }
    } catch (e) {
      logger.error('Error donating lesson to community', tag: 'gamification', error: e);
      // Don't throw - this is a nice-to-have feature, don't break the streak logic
    }
  }

}

