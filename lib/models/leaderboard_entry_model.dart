/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatar;
  final int xp;
  final int level;
  final String levelTitle;
  final int dailyStreak;
  final String? tribe;
  final String? country;
  final int rank;
  final int? previousRank; // For showing rank change

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatar,
    required this.xp,
    required this.level,
    required this.levelTitle,
    required this.dailyStreak,
    this.tribe,
    this.country,
    required this.rank,
    this.previousRank,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'avatar': avatar,
        'xp': xp,
        'level': level,
        'levelTitle': levelTitle,
        'dailyStreak': dailyStreak,
        'tribe': tribe,
        'country': country,
        'rank': rank,
        'previousRank': previousRank,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        userId: json['userId'] as String,
        username: json['username'] as String,
        avatar: json['avatar'] as String?,
        xp: json['xp'] as int,
        level: json['level'] as int,
        levelTitle: json['levelTitle'] as String,
        dailyStreak: json['dailyStreak'] as int,
        tribe: json['tribe'] as String?,
        country: json['country'] as String?,
        rank: json['rank'] as int,
        previousRank: json['previousRank'] as int?,
      );
}

/// Leaderboard type
enum LeaderboardType {
  global,
  tribe,
  country,
  continental,
  weekly,
  monthly,
  allTime,
}

/// Leaderboard filter
class LeaderboardFilter {
  final LeaderboardType type;
  final String? tribe;
  final String? country;
  final String? continent;

  LeaderboardFilter({
    required this.type,
    this.tribe,
    this.country,
    this.continent,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'tribe': tribe,
        'country': country,
        'continent': continent,
      };
}

