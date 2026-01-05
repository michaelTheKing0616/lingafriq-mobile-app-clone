/// Game Streak Model
/// Tracks user streaks across games and languages
class GameStreak {
  final String userId;
  final String? language; // null for global streak
  final int currentStreak;
  final int longestStreak;
  final DateTime lastPlayed;
  final DateTime streakStartDate;

  GameStreak({
    required this.userId,
    this.language,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastPlayed,
    DateTime? streakStartDate,
  })  : lastPlayed = lastPlayed ?? DateTime.now(),
        streakStartDate = streakStartDate ?? DateTime.now();

  /// Check if streak is still active (played today)
  bool get isActive {
    final now = DateTime.now();
    final lastPlayedDate = DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
    final today = DateTime(now.year, now.month, now.day);
    return lastPlayedDate.isAtSameMomentAs(today);
  }

  /// Check if streak is broken (last played more than 1 day ago)
  bool get isBroken {
    final now = DateTime.now();
    final lastPlayedDate = DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(lastPlayedDate).inDays > 1;
  }

  /// Increment streak
  GameStreak increment() {
    final newStreak = currentStreak + 1;
    return GameStreak(
      userId: userId,
      language: language,
      currentStreak: newStreak,
      longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
      lastPlayed: DateTime.now(),
      streakStartDate: isActive ? streakStartDate : DateTime.now(),
    );
  }

  /// Reset streak
  GameStreak reset() {
    return GameStreak(
      userId: userId,
      language: language,
      currentStreak: 0,
      longestStreak: longestStreak,
      lastPlayed: DateTime.now(),
      streakStartDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language': language,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_played': lastPlayed.toIso8601String(),
      'streak_start_date': streakStartDate.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory GameStreak.fromJson(Map<String, dynamic> json) {
    return GameStreak(
      userId: json['user_id'] as String,
      language: json['language'] as String?,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastPlayed: json['last_played'] != null
          ? DateTime.parse(json['last_played'] as String)
          : DateTime.now(),
      streakStartDate: json['streak_start_date'] != null
          ? DateTime.parse(json['streak_start_date'] as String)
          : DateTime.now(),
    );
  }
}

