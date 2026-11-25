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

/// P10-905 — daily or weekly cadence with earned freezes and a repair window.
enum StreakCadence { daily, weekly }

class EthicalStreakConfig {
  const EthicalStreakConfig({
    this.weeklyTargetDays = 5,
    this.freezeMax = 5,
    this.practiceDaysPerFreeze = 3,
    this.repairWindowHours = 48,
  });

  final int weeklyTargetDays;
  final int freezeMax;
  final int practiceDaysPerFreeze;
  final int repairWindowHours;

  static const EthicalStreakConfig defaults = EthicalStreakConfig();
}

class EthicalStreakState {
  const EthicalStreakState({
    this.cadence = StreakCadence.daily,
    this.currentStreak = 0,
    this.freezeTokens = 0,
    this.lastPracticeAt,
    this.practiceDaysThisWeek = const [],
    this.brokenAt,
    this.practiceDaysSinceFreezeAward = 0,
  });

  final StreakCadence cadence;
  final int currentStreak;
  final int freezeTokens;
  final DateTime? lastPracticeAt;
  final List<String> practiceDaysThisWeek;
  final DateTime? brokenAt;
  final int practiceDaysSinceFreezeAward;

  EthicalStreakState copyWith({
    StreakCadence? cadence,
    int? currentStreak,
    int? freezeTokens,
    DateTime? lastPracticeAt,
    List<String>? practiceDaysThisWeek,
    DateTime? brokenAt,
    int? practiceDaysSinceFreezeAward,
  }) {
    return EthicalStreakState(
      cadence: cadence ?? this.cadence,
      currentStreak: currentStreak ?? this.currentStreak,
      freezeTokens: freezeTokens ?? this.freezeTokens,
      lastPracticeAt: lastPracticeAt ?? this.lastPracticeAt,
      practiceDaysThisWeek: practiceDaysThisWeek ?? this.practiceDaysThisWeek,
      brokenAt: brokenAt ?? this.brokenAt,
      practiceDaysSinceFreezeAward:
          practiceDaysSinceFreezeAward ?? this.practiceDaysSinceFreezeAward,
    );
  }
}

class EthicalStreakPracticeResult {
  const EthicalStreakPracticeResult({
    required this.state,
    this.freezeSpent = false,
    this.streakBroken = false,
    this.repairOffered = false,
  });

  final EthicalStreakState state;
  final bool freezeSpent;
  final bool streakBroken;
  final bool repairOffered;
}

class EthicalStreakPolicy {
  static final RegExp _guiltCopy = RegExp(
    r"\b(at risk|don't break|do not break|you('ll| will) lose|losing your|before you lose|streak is at risk|keep it alive|shame|failed you)\b",
    caseSensitive: false,
  );

  static bool streakCopyIsNeutral(String text) => !_guiltCopy.hasMatch(text);

  static String utcDateKey(DateTime when) {
    final u = when.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-'
        '${u.month.toString().padLeft(2, '0')}-'
        '${u.day.toString().padLeft(2, '0')}';
  }

  static EthicalStreakPracticeResult recordPractice(
    EthicalStreakState state,
    DateTime now, [
    EthicalStreakConfig config = EthicalStreakConfig.defaults,
  ]) {
    if (state.lastPracticeAt != null &&
        utcDateKey(state.lastPracticeAt!) == utcDateKey(now)) {
      return EthicalStreakPracticeResult(
        state: state,
        repairOffered: repairOfferVisible(state, now, config),
      );
    }

    if (state.cadence == StreakCadence.weekly) {
      final weekly = _recordWeekly(state, now, config);
      final withFreeze = _awardFreeze(weekly, config);
      return EthicalStreakPracticeResult(
        state: withFreeze,
        streakBroken: withFreeze.brokenAt == now,
        repairOffered: repairOfferVisible(withFreeze, now, config),
      );
    }

    final daily = _recordDaily(state, now, config);
    return EthicalStreakPracticeResult(
      state: daily.state,
      freezeSpent: daily.freezeSpent,
      streakBroken: daily.streakBroken,
      repairOffered: repairOfferVisible(daily.state, now, config),
    );
  }

  static bool repairOfferVisible(
    EthicalStreakState state,
    DateTime now, [
    EthicalStreakConfig config = EthicalStreakConfig.defaults,
  ]) {
    if (state.brokenAt == null || state.currentStreak > 0) return false;
    final hours = now.difference(state.brokenAt!).inMinutes / 60.0;
    return hours >= 0 && hours <= config.repairWindowHours;
  }

  static int repairWindowHoursRemaining(
    EthicalStreakState state,
    DateTime now, [
    EthicalStreakConfig config = EthicalStreakConfig.defaults,
  ]) {
    if (!repairOfferVisible(state, now, config) || state.brokenAt == null) {
      return 0;
    }
    final end = state.brokenAt!.add(Duration(hours: config.repairWindowHours));
    final remaining = end.difference(now).inHours;
    return remaining < 0 ? 0 : remaining;
  }

  static int _dayDiffCalendar(DateTime a, DateTime b) {
    final da = DateTime.utc(a.year, a.month, a.day);
    final db = DateTime.utc(b.year, b.month, b.day);
    return db.difference(da).inDays;
  }

  static EthicalStreakState _awardFreeze(
    EthicalStreakState state,
    EthicalStreakConfig config,
  ) {
    if (state.practiceDaysSinceFreezeAward < config.practiceDaysPerFreeze) {
      return state;
    }
    if (state.freezeTokens >= config.freezeMax) {
      return state.copyWith(practiceDaysSinceFreezeAward: 0);
    }
    return state.copyWith(
      freezeTokens: state.freezeTokens + 1,
      practiceDaysSinceFreezeAward: 0,
    );
  }

  static _DailyGap _applyDailyGap(
    EthicalStreakState state,
    DateTime now,
  ) {
    if (state.lastPracticeAt == null) {
      return _DailyGap(state: state);
    }
    final gap = _dayDiffCalendar(state.lastPracticeAt!, now);
    if (gap <= 1) return _DailyGap(state: state);
    if (gap == 2 && state.freezeTokens > 0) {
      return _DailyGap(
        state: state.copyWith(freezeTokens: state.freezeTokens - 1),
        freezeSpent: true,
      );
    }
    return _DailyGap(
      state: state.copyWith(currentStreak: 0, brokenAt: now),
      streakBroken: true,
    );
  }

  static _DailyResult _recordDaily(
    EthicalStreakState state,
    DateTime now,
    EthicalStreakConfig config,
  ) {
    final gap = _applyDailyGap(state, now);
    var next = gap.state;
    var currentStreak = next.currentStreak;
    if (next.lastPracticeAt == null) {
      currentStreak = 1;
    } else if (gap.streakBroken) {
      currentStreak = 1;
    } else if (!gap.freezeSpent) {
      currentStreak = next.currentStreak + 1;
    }
    next = next.copyWith(
      currentStreak: currentStreak,
      lastPracticeAt: now,
      practiceDaysSinceFreezeAward: next.practiceDaysSinceFreezeAward + 1,
      brokenAt: gap.streakBroken ? next.brokenAt : null,
    );
    return _DailyResult(
      state: _awardFreeze(next, config),
      freezeSpent: gap.freezeSpent,
      streakBroken: gap.streakBroken,
    );
  }

  static EthicalStreakState _recordWeekly(
    EthicalStreakState state,
    DateTime now,
    EthicalStreakConfig config,
  ) {
    final day = utcDateKey(now);
    var practiceDays = List<String>.from(state.practiceDaysThisWeek);
    var currentStreak = state.currentStreak;

    if (state.lastPracticeAt != null) {
      final priorWeek = _isoWeekKey(state.lastPracticeAt!);
      final week = _isoWeekKey(now);
      if (week != priorWeek) {
        final met = practiceDays.length >= config.weeklyTargetDays;
        currentStreak = met ? currentStreak + 1 : 0;
        if (!met) {
          return state.copyWith(
            currentStreak: 0,
            brokenAt: now,
            practiceDaysThisWeek: [day],
            lastPracticeAt: now,
            practiceDaysSinceFreezeAward: state.practiceDaysSinceFreezeAward + 1,
          );
        }
        practiceDays = [];
      }
    }

    if (!practiceDays.contains(day)) {
      practiceDays.add(day);
    }

    return state.copyWith(
      currentStreak: currentStreak,
      practiceDaysThisWeek: practiceDays,
      lastPracticeAt: now,
      practiceDaysSinceFreezeAward: state.practiceDaysSinceFreezeAward + 1,
    );
  }

  static String _isoWeekKey(DateTime when) {
    final u = when.toUtc();
    final thursday = u.add(Duration(days: 4 - (u.weekday)));
    final yearStart = DateTime.utc(thursday.year, 1, 1);
    final week =
        ((thursday.difference(yearStart).inDays + 1) / 7).ceil();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }
}

class _DailyGap {
  _DailyGap({
    required this.state,
    this.freezeSpent = false,
    this.streakBroken = false,
  });

  final EthicalStreakState state;
  final bool freezeSpent;
  final bool streakBroken;
}

class _DailyResult {
  _DailyResult({
    required this.state,
    this.freezeSpent = false,
    this.streakBroken = false,
  });

  final EthicalStreakState state;
  final bool freezeSpent;
  final bool streakBroken;
}

