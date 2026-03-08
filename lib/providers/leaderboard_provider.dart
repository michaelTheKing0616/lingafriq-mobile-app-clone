import 'dart:convert';
import 'dart:math' as math;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leaderboard_entry_model.dart';
import '../models/user_gamification_model.dart';
import 'base_provider.dart';
import 'gamification_services_provider.dart';
import '../utils/structured_logger.dart';

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

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final leaderboardsService = ref.read(leaderboardsServiceProvider);

      List<LeaderboardEntry> entries = [];

      switch (type) {
        case LeaderboardType.global:
          final data = await leaderboardsService.getGlobalLeaderboard(period: 'weekly');
          entries = _parseLeaderboardEntries(_extractEntriesList(data));
          break;
        case LeaderboardType.tribe:
          if (tribe != null) {
            final data = await leaderboardsService.getTribeLeaderboard(tribe, period: 'season');
            entries = _parseLeaderboardEntries(_extractEntriesList(data));
          }
          break;
        case LeaderboardType.country:
          if (country != null) {
            final data = await leaderboardsService.getVillageLeaderboard(country, period: 'monthly');
            entries = _parseLeaderboardEntries(_extractEntriesList(data));
          }
          break;
        case LeaderboardType.continental:
          final data = await leaderboardsService.getGlobalLeaderboard(period: 'monthly');
          entries = _parseLeaderboardEntries(_extractEntriesList(data));
          break;
        case LeaderboardType.weekly:
        case LeaderboardType.monthly:
        case LeaderboardType.allTime:
          final period = type == LeaderboardType.weekly 
              ? 'weekly' 
              : type == LeaderboardType.monthly 
                  ? 'monthly' 
                  : 'allTime';
          final data = await leaderboardsService.getGlobalLeaderboard(period: period);
          entries = _parseLeaderboardEntries(_extractEntriesList(data));
          break;
      }

      _cache[type] = entries;
      _lastFetch = DateTime.now();
      
      // Cache leaderboard data locally for offline access
      await _cacheLeaderboards();
    } catch (e) {
      logger.error('Error fetching leaderboards', tag: 'leaderboard', error: e);
      // Fail closed: keep last known cached data (if any). Never fabricate leaderboard entries.
      _cache.putIfAbsent(type, () => []);
      state = state.copyWith(
        errorMessage: 'Unable to load leaderboard right now. Pull to retry.',
        errorTimestamp: DateTime.now(),
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Extract entries list from various backend response shapes
  List<dynamic> _extractEntriesList(Map<String, dynamic> data) {
    if (data['entries'] is List) return data['entries'] as List;
    if (data['data'] is List) return data['data'] as List;
    if (data['leaderboard'] is List) return data['leaderboard'] as List;
    if (data['results'] is List) return data['results'] as List;
    if (data['data'] is Map && (data['data'] as Map)['entries'] is List) {
      return ((data['data'] as Map)['entries']) as List;
    }
    return [];
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
      logger.error('Error caching leaderboards', tag: 'leaderboard', error: e);
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
      logger.error('Error loading cached leaderboards', tag: 'leaderboard', error: e);
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

