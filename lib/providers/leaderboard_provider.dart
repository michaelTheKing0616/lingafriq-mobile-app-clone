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
  final Map<String, List<LeaderboardEntry>> _cache = {};
  final Map<String, DateTime> _lastFetchByKey = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  String _key(
    LeaderboardType type, {
    String? tribe,
    String? country,
    String? continent,
  }) {
    return '${type.name}:${tribe ?? ''}:${country ?? ''}:${continent ?? ''}';
  }

  List<LeaderboardEntry> getGlobalLeaderboard() {
    return _cache[_key(LeaderboardType.global)] ?? [];
  }

  List<LeaderboardEntry> getTribeLeaderboard(String tribe) {
    return _cache[_key(LeaderboardType.tribe, tribe: tribe)] ?? [];
  }

  List<LeaderboardEntry> getCountryLeaderboard(String country) {
    return _cache[_key(LeaderboardType.country, country: country)] ?? [];
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
    final cacheKey = _key(
      type,
      tribe: tribe,
      country: country,
      continent: continent,
    );

    // Check cache
    final lastFetch = _lastFetchByKey[cacheKey];
    if (lastFetch != null &&
        DateTime.now().difference(lastFetch) < _cacheDuration &&
        _cache.containsKey(cacheKey)) {
      return; // Use cached data
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final leaderboardsService = ref.read(leaderboardsServiceProvider);

      List<LeaderboardEntry> entries = [];

      switch (type) {
        case LeaderboardType.global:
          final data = await leaderboardsService.getGlobalLeaderboard(
            period: 'weekly',
          );
          entries = _parseLeaderboardEntries(_extractEntriesList(data));
          break;
        case LeaderboardType.tribe:
          if (tribe != null && tribe.trim().isNotEmpty) {
            final data = await leaderboardsService.getTribeLeaderboard(
              tribe,
              period: 'season',
            );
            entries = _parseLeaderboardEntries(_extractEntriesList(data));
          }
          break;
        case LeaderboardType.country:
          if (country != null && country.trim().isNotEmpty) {
            final data = await leaderboardsService.getVillageLeaderboard(
              country,
              period: 'monthly',
            );
            entries = _parseLeaderboardEntries(_extractEntriesList(data));
          }
          break;
        case LeaderboardType.continental:
          final data = await leaderboardsService.getGlobalLeaderboard(
            period: 'monthly',
          );
          entries = _parseLeaderboardEntries(_extractEntriesList(data));
          break;
        case LeaderboardType.weekly:
        case LeaderboardType.monthly:
        case LeaderboardType.allTime:
          final period = type == LeaderboardType.weekly
              ? 'weekly'
              : type == LeaderboardType.monthly
              ? 'monthly'
              : 'alltime';
          final data = await leaderboardsService.getGlobalLeaderboard(
            period: period,
          );
          entries = _parseLeaderboardEntries(_extractEntriesList(data));
          break;
      }

      _cache[cacheKey] = entries;
      _lastFetchByKey[cacheKey] = DateTime.now();

      // Cache leaderboard data locally for offline access
      await _cacheLeaderboards();
    } catch (e) {
      logger.error('Error fetching leaderboards', tag: 'leaderboard', error: e);
      // Keep in-memory cache if present; otherwise try local storage fallback (up to 24h old)
      if (!_cache.containsKey(cacheKey) ||
          (_cache[cacheKey]?.isEmpty ?? true)) {
        await _loadLeaderboards(maxAge: const Duration(hours: 24));
      }
      _cache.putIfAbsent(cacheKey, () => []);
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
      final userDataMap = userData is Map
          ? userData as Map<String, dynamic>
          : <String, dynamic>{};

      // Extract XP/score (could be in entry or user data)
      final xp =
          (entry['xp'] ??
                  entry['score'] ??
                  userDataMap['xp'] ??
                  userDataMap['total_xp'] ??
                  0)
              .toInt();

      // Extract user information
      final userId =
          entry['user_id']?.toString() ??
          userDataMap['id']?.toString() ??
          userDataMap['user_id']?.toString() ??
          '';
      final username =
          entry['username']?.toString() ??
          userDataMap['username']?.toString() ??
          userDataMap['global_id']?.toString() ??
          'Unknown';

      // Extract gamification data if available
      final gamificationData =
          entry['gamification'] ??
          userDataMap['gamification'] ??
          <String, dynamic>{};
      final gamificationMap = gamificationData is Map
          ? gamificationData as Map<String, dynamic>
          : <String, dynamic>{};

      // Calculate level from XP
      final level = _calculateLevelFromXP(xp);

      // Get level title from gamification data or calculate from level
      final levelTitle =
          gamificationMap['level_title']?.toString() ??
          userDataMap['level_title']?.toString() ??
          LevelTitles.getTitleForLevel(level);

      // Get daily streak from gamification data
      final dailyStreak =
          (gamificationMap['daily_streak'] ??
                  userDataMap['daily_streak'] ??
                  entry['daily_streak'] ??
                  0)
              .toInt();

      // Get tribe from gamification data or user data
      final tribe =
          gamificationMap['tribe']?.toString() ??
          userDataMap['tribe']?.toString() ??
          entry['tribe']?.toString();

      final avatar =
          entry['avatar']?.toString() ??
          userDataMap['avatar']?.toString() ??
          userDataMap['avater']?.toString();
      final country =
          entry['nationality']?.toString() ??
          userDataMap['nationality']?.toString() ??
          entry['country']?.toString() ??
          userDataMap['country']?.toString();

      return LeaderboardEntry(
        userId: userId,
        username: username,
        avatar: avatar,
        xp: xp,
        level: level,
        levelTitle: levelTitle,
        dailyStreak: dailyStreak,
        tribe: tribe,
        country: country,
        rank: (entry['rank'] ?? entry['position'] ?? 0).toInt(),
      );
    }).toList();
  }

  /// Calculate level from XP (simplified)
  int _calculateLevelFromXP(int xp) {
    // Simple level calculation: level = sqrt(xp / 100)
    return math.sqrt(xp / 100).floor().clamp(1, 999);
  }

  Map<String, dynamic>? _userRanks;
  Map<String, dynamic>? get userRanks => _userRanks;

  /// Fetch user's ranks across all global leaderboard periods
  Future<void> fetchUserRanks(String userId) async {
    try {
      final leaderboardsService = ref.read(leaderboardsServiceProvider);
      final data = await leaderboardsService.getUserRanks(userId);
      final ranks = data['ranks'];
      if (ranks is List) {
        final result = <String, dynamic>{};
        for (final r in ranks) {
          if (r is Map) {
            result[r['leaderboard_id']?.toString() ?? ''] = {
              'rank': r['rank'],
              'score': r['score'],
            };
          }
        }
        _userRanks = result;
      }
    } catch (e) {
      logger.error('Error fetching user ranks', tag: 'leaderboard', error: e);
    }
  }

  /// Get user's rank for the same scope as [fetchLeaderboards] (global/tribe/country/continent).
  Future<int?> getUserRank(
    String userId, {
    LeaderboardType type = LeaderboardType.global,
    String? tribe,
    String? country,
    String? continent,
  }) async {
    final cacheKey = _key(
      type,
      tribe: tribe,
      country: country,
      continent: continent,
    );
    await fetchLeaderboards(
      type: type,
      tribe: tribe,
      country: country,
      continent: continent,
    );
    final leaderboard = _cache[cacheKey] ?? [];
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
        cacheData['data'][entry.key] = entry.value
            .map(
              (e) => {
                'user_id': e.userId,
                'username': e.username,
                'xp': e.xp,
                'level': e.level,
                'level_title': e.levelTitle,
                'daily_streak': e.dailyStreak,
                'tribe': e.tribe,
                'rank': e.rank,
              },
            )
            .toList();
      }

      await prefs.setString('leaderboard_cache', jsonEncode(cacheData));
    } catch (e) {
      logger.error('Error caching leaderboards', tag: 'leaderboard', error: e);
      // Continue without caching - not critical
    }
  }

  /// Load leaderboards from local cache.
  /// [maxAge] controls how old stored data can be before it's ignored.
  Future<void> _loadLeaderboards({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('leaderboard_cache');
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
        final cacheTimestamp = decoded['timestamp'] as int?;
        final cacheAge = cacheTimestamp != null
            ? DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
              )
            : const Duration(days: 365);

        if (cacheAge < maxAge && decoded['data'] is Map) {
          final data = decoded['data'] as Map<String, dynamic>;
          for (var entry in data.entries) {
            if (entry.value is List) {
              _cache[entry.key] = _parseLeaderboardEntries(entry.value as List);
            }
          }
        }
      }
    } catch (e) {
      logger.error(
        'Error loading cached leaderboards',
        tag: 'leaderboard',
        error: e,
      );
    }
  }

  /// Refresh leaderboards for one scope (invalidates only that cache key).
  Future<void> refresh({
    LeaderboardType type = LeaderboardType.global,
    String? tribe,
    String? country,
    String? continent,
  }) async {
    final cacheKey = _key(
      type,
      tribe: tribe,
      country: country,
      continent: continent,
    );
    _lastFetchByKey.remove(cacheKey);
    await fetchLeaderboards(
      type: type,
      tribe: tribe,
      country: country,
      continent: continent,
    );
  }
}
