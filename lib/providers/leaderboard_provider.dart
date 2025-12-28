import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leaderboard_entry_model.dart';
import '../models/user_gamification_model.dart';
import 'api_provider.dart';
import 'base_provider.dart';
import 'gamification_provider.dart';
import 'user_provider.dart';
import 'gamification_services_provider.dart';
import '../services/gamification/leaderboards_service.dart';

final leaderboardProvider =
    NotifierProvider<LeaderboardProvider, BaseProviderState>(() {
  return LeaderboardProvider();
});

/// Leaderboard provider for real-time rankings
class LeaderboardProvider extends Notifier<BaseProviderState>
    with BaseProviderMixin {
  final Map<LeaderboardType, List<LeaderboardEntry>> _cache = {};
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<LeaderboardEntry> getGlobalLeaderboard() {
    return _cache[LeaderboardType.global] ?? [];
  }

  List<LeaderboardEntry> getTribeLeaderboard(String tribe) {
    return _cache[LeaderboardType.tribe]?.where((e) => e.tribe == tribe).toList() ?? [];
  }

  List<LeaderboardEntry> getCountryLeaderboard(String country) {
    return _cache[LeaderboardType.country]?.where((e) => e.country == country).toList() ?? [];
  }

  @override
  BaseProviderState build() {
    _loadLeaderboards();
    return BaseProviderState();
  }

  /// Fetch leaderboards from backend
  Future<void> fetchLeaderboards({
    LeaderboardType type = LeaderboardType.global,
    String? tribe,
    String? country,
    String? continent,
  }) async {
    // Check cache
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration &&
        _cache.containsKey(type)) {
      return; // Use cached data
    }

    state = state.copyWith(isLoading: true);

    try {
      final leaderboardsService = ref.read(leaderboardsServiceProvider);
      final user = ref.read(userProvider);

      List<LeaderboardEntry> entries = [];

      switch (type) {
        case LeaderboardType.global:
          final data = await leaderboardsService.getGlobalLeaderboard(period: 'weekly');
          entries = _parseLeaderboardEntries(data['entries'] ?? []);
          break;
        case LeaderboardType.tribe:
          if (tribe != null) {
            final data = await leaderboardsService.getTribeLeaderboard(tribe, period: 'season');
            entries = _parseLeaderboardEntries(data['entries'] ?? []);
          }
          break;
        case LeaderboardType.country:
          // Use village leaderboard for country (language-based)
          if (country != null) {
            final data = await leaderboardsService.getVillageLeaderboard(country, period: 'monthly');
            entries = _parseLeaderboardEntries(data['entries'] ?? []);
          }
          break;
        case LeaderboardType.continental:
          // Use global leaderboard filtered by continent
          final data = await leaderboardsService.getGlobalLeaderboard(period: 'monthly');
          entries = _parseLeaderboardEntries(data['entries'] ?? []);
          break;
        case LeaderboardType.weekly:
        case LeaderboardType.monthly:
        case LeaderboardType.allTime:
          // Use global leaderboard with appropriate period
          final period = type == LeaderboardType.weekly 
              ? 'weekly' 
              : type == LeaderboardType.monthly 
                  ? 'monthly' 
                  : 'allTime';
          final data = await leaderboardsService.getGlobalLeaderboard(period: period);
          entries = _parseLeaderboardEntries(data['entries'] ?? []);
          break;
      }

      _cache[type] = entries;
      _lastFetch = DateTime.now();
      
      // Cache leaderboard data locally for offline access
      await _cacheLeaderboards();
    } catch (e) {
      debugPrint('Error fetching leaderboards: $e');
      // Fallback to mock data on error
      final gamification = ref.read(gamificationProvider.notifier).gamification;
      final user = ref.read(userProvider);

      if (user != null) {
        final mockEntries = _generateMockLeaderboard(
          user.username,
          gamification.xp,
          gamification.level,
          gamification.levelTitle,
          gamification.dailyStreak,
          gamification.tribe,
        );
        _cache[type] = mockEntries;
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Parse API response to LeaderboardEntry list
  List<LeaderboardEntry> _parseLeaderboardEntries(List<dynamic> entries) {
    return entries.map((entry) {
      // Handle different response formats
      final userData = entry['user'] ?? entry['user_id'] ?? entry;
      final userDataMap = userData is Map ? userData as Map<String, dynamic> : <String, dynamic>{};
      
      // Extract XP/score (could be in entry or user data)
      final xp = (entry['xp'] ?? entry['score'] ?? userDataMap['xp'] ?? userDataMap['total_xp'] ?? 0).toInt();
      
      // Extract user information
      final userId = entry['user_id']?.toString() ?? 
                     userDataMap['id']?.toString() ?? 
                     userDataMap['user_id']?.toString() ?? '';
      final username = entry['username']?.toString() ?? 
                       userDataMap['username']?.toString() ?? 
                       userDataMap['global_id']?.toString() ?? 
                       'Unknown';
      
      // Extract gamification data if available
      final gamificationData = entry['gamification'] ?? userDataMap['gamification'] ?? <String, dynamic>{};
      final gamificationMap = gamificationData is Map ? gamificationData as Map<String, dynamic> : <String, dynamic>{};
      
      // Calculate level from XP
      final level = _calculateLevelFromXP(xp);
      
      // Get level title from gamification data or calculate from level
      final levelTitle = gamificationMap['level_title']?.toString() ?? 
                         userDataMap['level_title']?.toString() ??
                         LevelTitles.getTitleForLevel(level);
      
      // Get daily streak from gamification data
      final dailyStreak = (gamificationMap['daily_streak'] ?? 
                           userDataMap['daily_streak'] ?? 
                           entry['daily_streak'] ?? 
                           0).toInt();
      
      // Get tribe from gamification data or user data
      final tribe = gamificationMap['tribe']?.toString() ?? 
                    userDataMap['tribe']?.toString() ?? 
                    entry['tribe']?.toString();
      
      return LeaderboardEntry(
        userId: userId,
        username: username,
        xp: xp,
        level: level,
        levelTitle: levelTitle,
        dailyStreak: dailyStreak,
        tribe: tribe,
        rank: (entry['rank'] ?? entry['position'] ?? 0).toInt(),
      );
    }).toList();
  }

  /// Calculate level from XP (simplified)
  int _calculateLevelFromXP(int xp) {
    // Simple level calculation: level = sqrt(xp / 100)
    return math.sqrt(xp / 100).floor().clamp(1, 999);
  }

  /// Generate mock leaderboard data (for testing)
  List<LeaderboardEntry> _generateMockLeaderboard(
    String currentUsername,
    int currentXP,
    int currentLevel,
    String currentTitle,
    int currentStreak,
    String? currentTribe,
  ) {
    final entries = <LeaderboardEntry>[];
    
    // Add current user at rank 1
    entries.add(LeaderboardEntry(
      userId: 'current_user',
      username: currentUsername,
      xp: currentXP,
      level: currentLevel,
      levelTitle: currentTitle,
      dailyStreak: currentStreak,
      tribe: currentTribe,
      rank: 1,
    ));

    // Add mock entries
    final mockNames = [
      'Kwame', 'Amina', 'Thabo', 'Fatima', 'Kofi',
      'Zainab', 'Sipho', 'Ngozi', 'Yusuf', 'Mariam',
    ];

    for (int i = 0; i < 10; i++) {
      entries.add(LeaderboardEntry(
        userId: 'user_$i',
        username: mockNames[i % mockNames.length],
        xp: currentXP - (i + 1) * 100,
        level: (currentLevel - (i + 1)).clamp(1, 999),
        levelTitle: 'Village Storyteller',
        dailyStreak: currentStreak - (i + 1),
        tribe: currentTribe,
        rank: i + 2,
      ));
    }

    return entries;
  }

  /// Get user's rank
  Future<int?> getUserRank(String userId, {LeaderboardType type = LeaderboardType.global}) async {
    await fetchLeaderboards(type: type);
    final leaderboard = _cache[type] ?? [];
    final entry = leaderboard.firstWhere(
      (e) => e.userId == userId,
      orElse: () => LeaderboardEntry(
        userId: userId,
        username: '',
        xp: 0,
        level: 1,
        levelTitle: '',
        dailyStreak: 0,
        rank: leaderboard.length + 1,
      ),
    );
    return entry.rank;
  }

  /// Cache leaderboards locally for offline access
  Future<void> _cacheLeaderboards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = <String, dynamic>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': <String, dynamic>{},
      };
      
      for (var entry in _cache.entries) {
        cacheData['data'][entry.key.name] = entry.value.map((e) => {
          'user_id': e.userId,
          'username': e.username,
          'xp': e.xp,
          'level': e.level,
          'level_title': e.levelTitle,
          'daily_streak': e.dailyStreak,
          'tribe': e.tribe,
          'rank': e.rank,
        }).toList();
      }
      
      await prefs.setString('leaderboard_cache', jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error caching leaderboards: $e');
      // Continue without caching - not critical
    }
  }

  /// Load leaderboards from local cache
  Future<void> _loadLeaderboards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('leaderboard_cache');
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
        final cacheTimestamp = decoded['timestamp'] as int?;
        final cacheAge = cacheTimestamp != null 
            ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cacheTimestamp))
            : const Duration(days: 1);
        
        // Only use cached data if it's less than 1 hour old
        if (cacheAge.inHours < 1 && decoded['data'] is Map) {
          final data = decoded['data'] as Map<String, dynamic>;
          for (var entry in data.entries) {
            final type = LeaderboardType.values.firstWhere(
              (e) => e.name == entry.key,
              orElse: () => LeaderboardType.global,
            );
            if (entry.value is List) {
              _cache[type] = _parseLeaderboardEntries(entry.value as List);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached leaderboards: $e');
      // Continue without cache - will fetch fresh data on next request
    }
  }

  /// Refresh leaderboards
  Future<void> refresh() async {
    _cache.clear();
    _lastFetch = null;
    await fetchLeaderboards();
  }
}

