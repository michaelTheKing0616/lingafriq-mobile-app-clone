import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/leaderboard_entry_model.dart';
import 'api_provider.dart';
import 'base_provider.dart';
import 'gamification_provider.dart';
import 'user_provider.dart';

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
      // TODO: Implement backend API call
      // final api = ref.read(apiProvider.notifier);
      // final data = await api.getLeaderboard(
      //   type: type,
      //   tribe: tribe,
      //   country: country,
      //   continent: continent,
      // );
      // 
      // final entries = (data as List)
      //     .map((e) => LeaderboardEntry.fromJson(e))
      //     .toList();
      // 
      // _cache[type] = entries;
      // _lastFetch = DateTime.now();

      // For now, generate mock data from current user's gamification
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
        _lastFetch = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error fetching leaderboards: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
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

  /// Load leaderboards from local cache
  Future<void> _loadLeaderboards() async {
    // TODO: Load from SharedPreferences if needed
  }

  /// Refresh leaderboards
  Future<void> refresh() async {
    _cache.clear();
    _lastFetch = null;
    await fetchLeaderboards();
  }
}

