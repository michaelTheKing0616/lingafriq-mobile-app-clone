import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_gamification_model.dart';
import '../models/badge_model.dart';
import 'api_provider.dart';
import 'user_provider.dart';
import 'gamification_snapshots.dart';
import 'gamification_state.dart';
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
import '../games/gamekit/game_result.dart';
import '../models/game/game_session_model.dart';
import 'game_provider.dart';

export 'gamification_snapshots.dart';

// P8-907: GameKit core sessions never gate on hearts/energy (GameKitRewardPolicy).

final gamificationProvider =
    NotifierProvider<GamificationProvider, GamificationState>(() {
  return GamificationProvider();
});

/// Core gamification engine - beats Duolingo, Babbel, and all competitors
class GamificationProvider extends Notifier<GamificationState> {
  final List<Badge> _allBadges = BadgeDefinitions.getAllBadges();

  String? get serverBalanceError => state.serverBalanceError;
  CircleQuestSnapshot? get circleQuest => state.circleQuest;
  List<CowriesShopItem> get shopCatalog => List.unmodifiable(state.shopCatalog);
  bool get shopCatalogLoading => state.shopCatalogLoading;
  StreakCadence get streakCadence => state.streakCadence;
  FamilyPhraseSnapshot? get familyPhrase => state.familyPhrase;
  HeritageTreeSnapshot? get heritageTree => state.heritageTree;

  UserGamificationModel get gamification => state.gamification;
  List<Badge> get allBadges => List.unmodifiable(_allBadges);
  List<Badge> get unlockedBadges => _allBadges
      .where((b) => state.gamification.unlockedBadges.contains(b.id))
      .toList();

  @override
  GamificationState build() {
    _loadGamification();
    _syncWithBackend();
    return GamificationState();
  }

  /// Award XP and handle level ups, currency rewards.
  /// Uses server-authoritative XP service to prevent cheating.
  ///
  /// Flow:
  /// 1. Try backend award → on success, use backend-reported totals (authoritative).
  /// 2. If backend fails → apply optimistic local XP but mark as *pending* so
  ///    the next sync does NOT blindly overwrite backend state and cause a
  ///    double-count.
  /// P8-909 — server recomputes XP from synced turn log; client never posts amounts.
  Future<int> claimVerifiedGameSessionReward(GameSession session) async {
    try {
      final dio = ref.read(client);
      final claim = await claimGameSessionRewardVerified(dio: dio, session: session);
      if (claim == null) {
        logger.warn('Game reward claim rejected', tag: 'gamification', context: {
          'sessionId': session.sessionId,
        });
        return 0;
      }
      if (claim.practice) {
        return 0;
      }
      final total = claim.xpTotal;
      if (total != null) {
        final newLevel = LevelTitles.getLevelFromXP(total);
        state = state.copyWith(gamification: state.gamification.copyWith(
          xp: total,
          level: newLevel,
          levelTitle: LevelTitles.getTitleForLevel(newLevel),
        ));
        await _saveGamification();
        state = state.copyWith();
      }
      return claim.xpAwarded;
    } catch (e) {
      logger.error('Game reward claim failed', tag: 'gamification', error: e);
      return 0;
    }
  }

  Future<int> awardXP(String source, {double multiplier = 1.0, String? sourceId}) async {
    if (source == 'game_complete') {
      final active = ref.read(gameProvider.notifier).currentSession;
      if (active != null) {
        return claimVerifiedGameSessionReward(active);
      }
    }

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
          state = state.copyWith(serverBalanceError: null);
          // Update local state from backend response (authoritative totals)
          try {
            final userXP = await ref.read(apiProvider.notifier).getUserXP(user.id.toString());
            if (userXP != null) {
              final totalXP = (userXP['totalXP'] as num?)?.toInt() ?? state.gamification.xp;
              final backendLevel = (userXP['level'] as num?)?.toInt();
              final newLevel = backendLevel ?? LevelTitles.getLevelFromXP(totalXP);
              final newTitle = LevelTitles.getTitleForLevel(newLevel);

              state = state.copyWith(gamification: state.gamification.copyWith(
                xp: totalXP,
                level: newLevel,
                levelTitle: newTitle,
              ));
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
    final currentXP = state.gamification.xp;
    final newXP = currentXP + xpGain;
    final newLevel = LevelTitles.getLevelFromXP(newXP);
    final newTitle = LevelTitles.getTitleForLevel(newLevel);

    state = state.copyWith(gamification: state.gamification.copyWith(
      xp: newXP,
      level: newLevel,
      levelTitle: newTitle,
    ));

    // Level up bonus
    if (newLevel > state.gamification.level) {
      final levelUpBonus = 50 * (newLevel - state.gamification.level);
      state = state.copyWith(gamification: state.gamification.copyWith(
        cowries: state.gamification.cowries + levelUpBonus,
      ));
      logger.info('Level up!', tag: 'gamification', context: {'newLevel': newLevel, 'newTitle': newTitle});

      // React with Rive
      try {
        ref.read(riveGamificationServiceProvider).reactToLevelUp(newLevel: newLevel);
      } catch (e) {
        logger.warn('Rive service not available', tag: 'gamification', error: e);
      }

      // Emit level up event
      await _emitEvent('level_up', {
        'old_level': state.gamification.level,
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
    state = state.copyWith(streakCadence: cadence);
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
    final lastLogin = state.gamification.lastLogin;
    final lastLoginDate =
        lastLogin != null ? DateTime(lastLogin.year, lastLogin.month, lastLogin.day) : null;

    if (lastLoginDate == today) {
      return;
    }

    final ethicalState = EthicalStreakState(
      cadence: state.streakCadence,
      currentStreak: state.gamification.dailyStreak,
      freezeTokens: state.gamification.freezeLeft,
      lastPracticeAt: lastLogin,
      practiceDaysThisWeek: state.practiceDaysThisWeek,
      brokenAt: state.streakBrokenAt,
    );
    final practice = EthicalStreakPolicy.recordPractice(ethicalState, now);
    state = state.copyWith(practiceDaysThisWeek: practice.state.practiceDaysThisWeek);
    state = state.copyWith(streakBrokenAt: practice.state.brokenAt);

    int newStreak = practice.state.currentStreak;
    int newFreezeLeft = practice.state.freezeTokens;

    if (practice.streakBroken) {
      state = state.copyWith(streakBeforeBreak: state.gamification.dailyStreak > 0
          ? state.gamification.dailyStreak
          : state.streakBeforeBreak);
    }
    if (practice.streakBroken && state.gamification.ubuntuStreakActive) {
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

    state = state.copyWith(gamification: state.gamification.copyWith(
      dailyStreak: newStreak,
      freezeLeft: newFreezeLeft,
      lastLogin: now,
      cowries: state.gamification.cowries + streakBonus,
    ));

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
      state = state.copyWith(gamification: state.gamification.copyWith(
        perfectWeekStreak: state.gamification.perfectWeekStreak + 1,
      ));
      await awardXP('perfect_week');
    }
  }

  /// Unlock a badge
  Future<bool> unlockBadge(String badgeId) async {
    if (state.gamification.unlockedBadges.contains(badgeId)) {
      return false; // Already unlocked
    }

    final badge = BadgeDefinitions.getBadgeById(badgeId);
    if (badge == null) {
      logger.warn('Badge not found', tag: 'gamification', context: {'badgeId': badgeId});
      return false;
    }

    final newBadges = List<String>.from(state.gamification.unlockedBadges)..add(badgeId);

    final cowriesBonus = badge.cowriesReward + badge.beadsReward;
    state = state.copyWith(gamification: state.gamification.copyWith(
      unlockedBadges: newBadges,
      cowries: state.gamification.cowries + cowriesBonus,
    ));

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
    if (state.gamification.dailyStreak >= 7 && !state.gamification.unlockedBadges.contains('streak_7')) {
      await unlockBadge('streak_7');
    }
    if (state.gamification.dailyStreak >= 30 && !state.gamification.unlockedBadges.contains('streak_30')) {
      await unlockBadge('streak_30');
    }
    if (state.gamification.dailyStreak >= 100 && !state.gamification.unlockedBadges.contains('streak_100')) {
      await unlockBadge('streak_100');
    }

    // Perfect week badge
    if (state.gamification.perfectWeekStreak >= 1 &&
        !state.gamification.unlockedBadges.contains('perfect_week')) {
      // Add perfect week badge if needed
    }

    // Tonal mastery badge
    if (state.gamification.tonalMasteryStreak >= 7 &&
        !state.gamification.unlockedBadges.contains('tonal_master')) {
      await unlockBadge('tonal_master');
    }
  }

  /// Set user's tribe
  Future<void> setTribe(String tribe) async {
    if (!Tribes.isValidTribe(tribe)) {
      throw ArgumentError('Invalid tribe: $tribe');
    }

    state = state.copyWith(gamification: state.gamification.copyWith(tribe: tribe));
    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
  }

  /// Activate a booster/item
  Future<bool> activateBooster(String boosterId, [int durationHours = 0]) async {
    // Check if user has the item (would need item inventory system)
    // For now, just track active boosters
    if (state.gamification.activeBoosters.contains(boosterId)) {
      return false; // Already active
    }

    final newBoosters = List<String>.from(state.gamification.activeBoosters)..add(boosterId);
    state = state.copyWith(gamification: state.gamification.copyWith(activeBoosters: newBoosters));

    await _saveGamification();
    state = state.copyWith();
    return true;
  }

  /// Select tribe
  Future<void> selectTribe(String tribeId) async {
    state = state.copyWith(gamification: state.gamification.copyWith(tribe: tribeId));
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
        state = state.copyWith(circleQuest: CircleQuestSnapshot.fromJson(questRes.data as Map<String, dynamic>));
      }
      if (phraseRes.data is Map<String, dynamic>) {
        state = state.copyWith(familyPhrase: FamilyPhraseSnapshot.fromJson(phraseRes.data as Map<String, dynamic>));
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
        state = state.copyWith(heritageTree: HeritageTreeSnapshot.fromJson(res.data as Map<String, dynamic>));
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
    final currentProgress = state.gamification.questProgress[questId] ?? 0;
    final newProgress = currentProgress + progress;

    final updatedProgress = Map<String, int>.from(state.gamification.questProgress)
      ..[questId] = newProgress;

    state = state.copyWith(gamification: state.gamification.copyWith(questProgress: updatedProgress));

    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
  }

  /// Update tonal mastery streak
  Future<void> updateTonalMasteryStreak(bool perfect) async {
    if (perfect) {
      state = state.copyWith(gamification: state.gamification.copyWith(
        tonalMasteryStreak: state.gamification.tonalMasteryStreak + 1,
      ));
      await _checkBadges();
    } else {
      state = state.copyWith(gamification: state.gamification.copyWith(tonalMasteryStreak: 0));
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
        final res = await ref.read(client).post(
          '/api/rewards/learning-event',
          data: {
            'evidence_id': evidenceId,
            'rule_id': 'streak_bonus_cowries',
          },
        );
        if (res.statusCode == 200) {
          state = state.copyWith(serverBalanceError: null);
          await _syncWithBackend();
          return;
        }
      } catch (e) {
        logger.error('Cowries award failed', tag: 'gamification', error: e);
      }
      state = state.copyWith(serverBalanceError: 'balance_unavailable');
      state = state.copyWith();
      return;
    }
  }

  bool ownsShopItem(CowriesShopItem item) {
    if (item.sink == 'cosmetic_avatar') {
      return state.gamification.unlockedBadges.contains('cosmetic:${item.id}');
    }
    if (item.sink == 'persona_early_access' &&
        item.personaId != null &&
        item.chapterId != null) {
      final key = 'persona_access:${item.personaId}:${item.chapterId}';
      return (state.gamification.questProgress[key] ?? 0) >= 1;
    }
    return false;
  }

  Future<void> loadCowriesShopCatalog() async {
    state = state.copyWith(shopCatalogLoading: true);
    state = state.copyWith();
    try {
      final res = await ref.read(client).get('/api/rewards/shop/catalog');
      if (res.statusCode == 200 && res.data is Map) {
        final data = (res.data as Map)['data'] as Map?;
        final items = data?['items'] as List<dynamic>? ?? [];
        state = state.copyWith(shopCatalog: items
            .map((e) => CowriesShopItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((item) => item.id.isNotEmpty)
            .toList());
      }
    } catch (e) {
      logger.error('Cowries shop catalog failed', tag: 'gamification', error: e);
    } finally {
      state = state.copyWith(shopCatalogLoading: false);
      state = state.copyWith();
    }
  }

  Future<CowriesShopPurchaseResult> purchaseCowriesShopItem(String itemId) async {
    final item = state.shopCatalog.firstWhere(
      (e) => e.id == itemId,
      orElse: () => const CowriesShopItem(
        id: '',
        sink: '',
        cost: 0,
        title: '',
        does: '',
      ),
    );
    if (item.id.isEmpty) {
      return const CowriesShopPurchaseResult(ok: false, message: 'Item not found.');
    }
    if (state.gamification.cowries < item.cost) {
      return const CowriesShopPurchaseResult(ok: false, message: 'Not enough Cowries.');
    }

    final evidenceId = 'shop_${itemId}_${DateTime.now().millisecondsSinceEpoch}';
    final payload = <String, dynamic>{
      'evidence_id': evidenceId,
      'item_id': itemId,
    };

    if (item.sink == 'streak_repair') {
      final now = DateTime.now();
      final streakState = EthicalStreakState(
        cadence: state.streakCadence,
        currentStreak: state.gamification.dailyStreak,
        freezeTokens: state.gamification.freezeLeft,
        lastPracticeAt: state.gamification.lastLogin,
        practiceDaysThisWeek: state.practiceDaysThisWeek,
        brokenAt: state.streakBrokenAt,
      );
      if (!EthicalStreakPolicy.repairOfferVisible(streakState, now)) {
        return const CowriesShopPurchaseResult(
          ok: false,
          message: 'Streak repair is not available right now.',
        );
      }
      final restoreTo =
          state.streakBeforeBreak > 0 ? state.streakBeforeBreak : state.gamification.dailyStreak;
      payload['streak_to_restore'] = restoreTo;
      payload['streak_state'] = {
        'cadence': state.streakCadence.name,
        'currentStreak': streakState.currentStreak,
        'freezeTokens': streakState.freezeTokens,
        'lastPracticeAt': streakState.lastPracticeAt?.toIso8601String(),
        'practiceDaysThisWeek': streakState.practiceDaysThisWeek,
        'brokenAt': streakState.brokenAt?.toIso8601String(),
        'practiceDaysSinceFreezeAward': streakState.practiceDaysSinceFreezeAward,
      };
    }

    try {
      final res = await ref.read(client).post('/api/rewards/shop/purchase', data: payload);
      if (res.statusCode == 200 && res.data is Map) {
        final data = (res.data as Map)['data'] as Map?;
        if (item.sink == 'streak_repair') {
          final restored = (data?['streak_restored_to'] as num?)?.toInt();
          if (restored != null && restored > 0) {
            state = state.copyWith(gamification: state.gamification.copyWith(dailyStreak: restored));
            state = state.copyWith(clearStreakBrokenAt: true);
          }
        }
        if (item.sink == 'cosmetic_avatar') {
          final keys = (data?['inventory_keys_added'] as List<dynamic>?) ?? [];
          final badges = List<String>.from(state.gamification.unlockedBadges);
          for (final key in keys) {
            badges.add(key.toString());
          }
          state = state.copyWith(gamification: state.gamification.copyWith(unlockedBadges: badges));
        }
        if (item.sink == 'persona_early_access') {
          final keys = (data?['inventory_keys_added'] as List<dynamic>?) ?? [];
          final progress = Map<String, int>.from(state.gamification.questProgress);
          for (final key in keys) {
            progress[key.toString()] = 1;
          }
          state = state.copyWith(gamification: state.gamification.copyWith(questProgress: progress));
        }
        await _syncWithBackend();
        await _saveGamification();
        state = state.copyWith();
        return const CowriesShopPurchaseResult(ok: true);
      }
      final body = res.data is Map ? res.data as Map : {};
      final message = body['error']?.toString() ?? 'Purchase could not complete.';
      return CowriesShopPurchaseResult(ok: false, message: message);
    } catch (e) {
      logger.error('Cowries shop purchase failed', tag: 'gamification', error: e);
      return const CowriesShopPurchaseResult(ok: false, message: 'Purchase could not complete.');
    }
  }

  /// Spend currency (deduct from current balance)
  Future<bool> spendCurrency({
    required int cowries,
  }) async {
    if (state.gamification.cowries < cowries) return false;

    state = state.copyWith(gamification: state.gamification.copyWith(
      cowries: state.gamification.cowries - cowries,
    ));
    await _saveGamification();
    await _syncToBackend();
    state = state.copyWith();
    return true;
  }

  /// Enable Ubuntu streak (never break - help others if you do)
  Future<void> enableUbuntuStreak() async {
    state = state.copyWith(gamification: state.gamification.copyWith(ubuntuStreakActive: true));
    await _saveGamification();
    state = state.copyWith();
  }

  /// Toggle Ubuntu streak on/off (used by the Ubuntu card switch).
  Future<void> setUbuntuStreakActive(bool isActive) async {
    state = state.copyWith(gamification: state.gamification.copyWith(ubuntuStreakActive: isActive));
    await _saveGamification();
    state = state.copyWith();
  }

  /// Persistence
  Future<void> _saveGamification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.gamification.toJson();
      await prefs.setString('user_gamification', jsonEncode(json));
      await prefs.setString('streak_cadence', state.streakCadence.name);
      await prefs.setStringList('streak_practice_week_days', state.practiceDaysThisWeek);
      if (state.streakBrokenAt != null) {
        await prefs.setString('streak_broken_at', state.streakBrokenAt!.toIso8601String());
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
        state = state.copyWith(gamification: UserGamificationModel.fromJson(json));
      }
      final cadenceName = prefs.getString('streak_cadence');
      if (cadenceName == StreakCadence.weekly.name) {
        state = state.copyWith(streakCadence: StreakCadence.weekly);
      }
      state = state.copyWith(practiceDaysThisWeek: prefs.getStringList('streak_practice_week_days') ?? []);
      final brokenRaw = prefs.getString('streak_broken_at');
      if (brokenRaw != null) {
        state = state.copyWith(streakBrokenAt: DateTime.tryParse(brokenRaw));
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
      final balanceRes = await ref.read(client).get('/api/rewards/balance');
      if (balanceRes.statusCode == 200 && balanceRes.data is Map) {
        final data = (balanceRes.data as Map)['data'] as Map?;
        final backendData = await api.getGamification(user.id.toString());
        if (backendData != null && backendData.isNotEmpty) {
          final merged = Map<String, dynamic>.from(backendData);
          if (data != null) {
            merged['xp'] = data['xp'];
            merged['cowries'] = data['cowries'];
          }
          state = state.copyWith(gamification: UserGamificationModel.fromJson(merged));
          state = state.copyWith(serverBalanceError: null);
          await _saveGamification();
          state = state.copyWith();
          return;
        }
      }
      state = state.copyWith(serverBalanceError: 'balance_unavailable');
      state = state.copyWith();
    } catch (e) {
      state = state.copyWith(serverBalanceError: 'balance_unavailable');
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
          'gamification': state.gamification.toSyncPayload(),
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
          'streakBefore': state.gamification.dailyStreak,
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

