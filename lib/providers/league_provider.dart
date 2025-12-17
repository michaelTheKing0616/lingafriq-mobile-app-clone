import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/league_model.dart';
import '../services/sound_effects_service.dart';
import 'api_provider.dart';
import 'user_provider.dart';

/// Provider for league/division system
final leagueProvider = NotifierProvider<LeagueNotifier, LeagueState>(() {
  return LeagueNotifier();
});

class LeagueNotifier extends Notifier<LeagueState> {
  static const String _storageKey = 'league_state';

  @override
  LeagueState build() {
    _loadState();
    return _getInitialState();
  }

  LeagueState _getInitialState() {
    final now = DateTime.now();
    // Week starts on Monday
    final daysToSubtract = now.weekday - 1;
    final weekStart = DateTime(now.year, now.month, now.day - daysToSubtract);
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return LeagueState(
      currentTier: LeagueTier.bronze,
      weekStarted: weekStart,
      weekEnds: weekEnd,
    );
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_storageKey);
      
      if (stateJson != null) {
        final data = jsonDecode(stateJson) as Map<String, dynamic>;
        final savedTier = LeagueTier.values.firstWhere(
          (t) => t.name == data['currentTier'],
          orElse: () => LeagueTier.bronze,
        );
        
        final weekEnds = DateTime.parse(data['weekEnds'] as String);
        final now = DateTime.now();
        
        // Check if week has ended
        if (now.isAfter(weekEnds)) {
          await _processWeekEnd(savedTier, data['userRank'] as int? ?? 0);
        } else {
          state = state.copyWith(
            currentTier: savedTier,
            userWeeklyXP: data['userWeeklyXP'] as int? ?? 0,
            userRank: data['userRank'] as int? ?? 0,
          );
        }
      }
      
      // Fetch fresh leaderboard from server
      await refreshLeaderboard();
    } catch (e) {
      debugPrint('Error loading league state: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'currentTier': state.currentTier.name,
        'userWeeklyXP': state.userWeeklyXP,
        'userRank': state.userRank,
        'weekEnds': state.weekEnds.toIso8601String(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving league state: $e');
    }
  }

  /// Process end of week - promotions/demotions
  Future<void> _processWeekEnd(LeagueTier previousTier, int previousRank) async {
    final config = LeagueTiers.getConfig(previousTier);
    LeagueTier newTier = previousTier;
    
    // Check for promotion
    if (previousRank > 0 && previousRank <= config.promoteCount) {
      final nextTier = LeagueTiers.getNextTier(previousTier);
      if (nextTier != null) {
        newTier = nextTier;
        // Play promotion sound
        ref.read(soundEffectsProvider).playCelebration();
      }
    }
    // Check for demotion
    else if (config.demoteCount > 0) {
      // This would require knowing total users in league
      // For now, we'll handle this server-side
    }
    
    // Reset for new week
    final now = DateTime.now();
    final daysToSubtract = now.weekday - 1;
    final weekStart = DateTime(now.year, now.month, now.day - daysToSubtract);
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    state = LeagueState(
      currentTier: newTier,
      weekStarted: weekStart,
      weekEnds: weekEnd,
      userWeeklyXP: 0,
      userRank: 0,
    );
    
    await _saveState();
  }

  /// Add XP to weekly total
  Future<void> addWeeklyXP(int amount) async {
    state = state.copyWith(
      userWeeklyXP: state.userWeeklyXP + amount,
    );
    await _saveState();
    
    // Refresh leaderboard to get updated rank
    await refreshLeaderboard();
  }

  /// Refresh leaderboard from server
  Future<void> refreshLeaderboard() async {
    try {
      final api = ref.read(apiProvider.notifier);
      final user = ref.read(userProvider);
      
      // Fetch leaderboard from API
      final response = await api.getLeaderboard(
        tier: state.currentTier.name,
        type: 'weekly',
      );
      
      if (response != null && response['leaderboard'] != null) {
        final leaderboardData = response['leaderboard'] as List<dynamic>;
        final leaderboard = leaderboardData
            .map((item) => LeaguePosition.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Find user's rank
        int userRank = 0;
        for (int i = 0; i < leaderboard.length; i++) {
          if (leaderboard[i].oduserId == user?.id) {
            userRank = i + 1;
            break;
          }
        }
        
        // Determine promotion/demotion status
        final config = LeagueTiers.getConfig(state.currentTier);
        final updatedLeaderboard = leaderboard.asMap().entries.map((entry) {
          final pos = entry.value;
          final rank = entry.key + 1;
          return LeaguePosition(
            oduserId: pos.oduserId,
            username: pos.username,
            profilePicUrl: pos.profilePicUrl,
            tier: pos.tier,
            weeklyXP: pos.weeklyXP,
            rank: rank,
            willPromote: rank <= config.promoteCount,
            willDemote: config.demoteCount > 0 && 
                rank > leaderboard.length - config.demoteCount,
            isCurrentUser: pos.oduserId == user?.id,
          );
        }).toList();
        
        state = state.copyWith(
          leaderboard: updatedLeaderboard,
          userRank: userRank,
        );
      }
    } catch (e) {
      debugPrint('Error refreshing leaderboard: $e');
    }
  }

  /// Get user's league status message
  String getStatusMessage() {
    final config = state.tierConfig;
    
    if (state.willPromote) {
      final nextTier = LeagueTiers.getNextTier(state.currentTier);
      return '🎉 You\'re in the promotion zone! Keep it up to reach ${nextTier?.name ?? "the top"}!';
    } else if (state.willDemote) {
      return '⚠️ You\'re in the demotion zone. Earn more XP to stay in ${config.name}!';
    } else if (state.userRank > 0) {
      final toPromote = state.userRank - config.promoteCount;
      if (toPromote > 0) {
        return '📈 ${toPromote} more spots to reach the promotion zone!';
      }
    }
    return '💪 Keep learning to climb the leaderboard!';
  }
}

