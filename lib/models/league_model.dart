import 'package:flutter/material.dart';
import '../utils/pan_african_design_system.dart';

/// League tiers (promotion/demotion system like Duolingo)
enum LeagueTier {
  bronze,    // Starting tier
  silver,    // Top 10 from Bronze promote
  gold,      // Top 10 from Silver promote
  obsidian,  // Top 5 from Gold promote
  diamond,   // Top 3 from Obsidian promote
  legendary, // Top 1 from Diamond (permanent)
}

/// League tier configuration
class LeagueTierConfig {
  final LeagueTier tier;
  final String name;
  final String emoji;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;
  final int promoteCount;  // How many promote to next tier
  final int demoteCount;   // How many demote to previous tier
  final int xpMultiplier;  // XP multiplier for this tier (percentage)
  final int weeklyReward;  // Cowries reward for completing the week

  const LeagueTierConfig({
    required this.tier,
    required this.name,
    required this.emoji,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
    required this.promoteCount,
    required this.demoteCount,
    required this.xpMultiplier,
    required this.weeklyReward,
  });

  LinearGradient get gradient => LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// League tier definitions
class LeagueTiers {
  static const Map<LeagueTier, LeagueTierConfig> configs = {
    LeagueTier.bronze: LeagueTierConfig(
      tier: LeagueTier.bronze,
      name: 'Bronze',
      emoji: '🥉',
      color: Color(0xFFCD7F32),
      gradientStart: Color(0xFFCD7F32),
      gradientEnd: Color(0xFF8B4513),
      promoteCount: 10,
      demoteCount: 0, // Can't demote from Bronze
      xpMultiplier: 100,
      weeklyReward: 50,
    ),
    LeagueTier.silver: LeagueTierConfig(
      tier: LeagueTier.silver,
      name: 'Silver',
      emoji: '🥈',
      color: Color(0xFFC0C0C0),
      gradientStart: Color(0xFFE8E8E8),
      gradientEnd: Color(0xFF808080),
      promoteCount: 10,
      demoteCount: 5,
      xpMultiplier: 110,
      weeklyReward: 100,
    ),
    LeagueTier.gold: LeagueTierConfig(
      tier: LeagueTier.gold,
      name: 'Gold',
      emoji: '🥇',
      color: Color(0xFFFFD700),
      gradientStart: Color(0xFFFFD700),
      gradientEnd: Color(0xFFB8860B),
      promoteCount: 5,
      demoteCount: 5,
      xpMultiplier: 120,
      weeklyReward: 200,
    ),
    LeagueTier.obsidian: LeagueTierConfig(
      tier: LeagueTier.obsidian,
      name: 'Obsidian',
      emoji: '🖤',
      color: Color(0xFF1A1A2E),
      gradientStart: Color(0xFF2D2D44),
      gradientEnd: Color(0xFF0D0D1A),
      promoteCount: 3,
      demoteCount: 5,
      xpMultiplier: 130,
      weeklyReward: 350,
    ),
    LeagueTier.diamond: LeagueTierConfig(
      tier: LeagueTier.diamond,
      name: 'Diamond',
      emoji: '💎',
      color: Color(0xFF00BFFF),
      gradientStart: Color(0xFF87CEEB),
      gradientEnd: Color(0xFF1E90FF),
      promoteCount: 1,
      demoteCount: 5,
      xpMultiplier: 150,
      weeklyReward: 500,
    ),
    LeagueTier.legendary: LeagueTierConfig(
      tier: LeagueTier.legendary,
      name: 'Legendary',
      emoji: '👑',
      color: PanAfricanColors.secondary,
      gradientStart: Color(0xFFFFD700),
      gradientEnd: Color(0xFFFF6B00),
      promoteCount: 0, // Can't promote further
      demoteCount: 0, // Can't demote from Legendary
      xpMultiplier: 200,
      weeklyReward: 1000,
    ),
  };

  static LeagueTierConfig getConfig(LeagueTier tier) => configs[tier]!;
  
  static LeagueTier? getNextTier(LeagueTier current) {
    final index = LeagueTier.values.indexOf(current);
    if (index < LeagueTier.values.length - 1) {
      return LeagueTier.values[index + 1];
    }
    return null;
  }

  static LeagueTier? getPreviousTier(LeagueTier current) {
    final index = LeagueTier.values.indexOf(current);
    if (index > 0) {
      return LeagueTier.values[index - 1];
    }
    return null;
  }
}

/// User's position in a league
class LeaguePosition {
  final String oduserId;
  final String username;
  final String? profilePicUrl;
  final LeagueTier tier;
  final int weeklyXP;
  final int rank;
  final bool willPromote;
  final bool willDemote;
  final bool isCurrentUser;

  LeaguePosition({
    required this.oduserId,
    required this.username,
    this.profilePicUrl,
    required this.tier,
    required this.weeklyXP,
    required this.rank,
    this.willPromote = false,
    this.willDemote = false,
    this.isCurrentUser = false,
  });

  factory LeaguePosition.fromJson(Map<String, dynamic> json) {
    return LeaguePosition(
      oduserId: json['userId'] as String,
      username: json['username'] as String,
      profilePicUrl: json['profilePicUrl'] as String?,
      tier: LeagueTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => LeagueTier.bronze,
      ),
      weeklyXP: json['weeklyXP'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      willPromote: json['willPromote'] as bool? ?? false,
      willDemote: json['willDemote'] as bool? ?? false,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': oduserId,
    'username': username,
    'profilePicUrl': profilePicUrl,
    'tier': tier.name,
    'weeklyXP': weeklyXP,
    'rank': rank,
    'willPromote': willPromote,
    'willDemote': willDemote,
    'isCurrentUser': isCurrentUser,
  };
}

/// League state for the week
class LeagueState {
  final LeagueTier currentTier;
  final List<LeaguePosition> leaderboard;
  final int userRank;
  final int userWeeklyXP;
  final DateTime weekStarted;
  final DateTime weekEnds;
  final bool weekEnded;

  LeagueState({
    required this.currentTier,
    this.leaderboard = const [],
    this.userRank = 0,
    this.userWeeklyXP = 0,
    required this.weekStarted,
    required this.weekEnds,
    this.weekEnded = false,
  });

  /// Time remaining in the week
  Duration get timeRemaining => weekEnds.difference(DateTime.now());

  /// Check if user will be promoted
  bool get willPromote {
    final config = LeagueTiers.getConfig(currentTier);
    return userRank > 0 && userRank <= config.promoteCount;
  }

  /// Check if user will be demoted
  bool get willDemote {
    final config = LeagueTiers.getConfig(currentTier);
    if (config.demoteCount == 0) return false;
    return userRank > leaderboard.length - config.demoteCount;
  }

  /// Get the tier config
  LeagueTierConfig get tierConfig => LeagueTiers.getConfig(currentTier);

  LeagueState copyWith({
    LeagueTier? currentTier,
    List<LeaguePosition>? leaderboard,
    int? userRank,
    int? userWeeklyXP,
    DateTime? weekStarted,
    DateTime? weekEnds,
    bool? weekEnded,
  }) {
    return LeagueState(
      currentTier: currentTier ?? this.currentTier,
      leaderboard: leaderboard ?? this.leaderboard,
      userRank: userRank ?? this.userRank,
      userWeeklyXP: userWeeklyXP ?? this.userWeeklyXP,
      weekStarted: weekStarted ?? this.weekStarted,
      weekEnds: weekEnds ?? this.weekEnds,
      weekEnded: weekEnded ?? this.weekEnded,
    );
  }
}

