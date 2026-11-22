import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_challenge_model.dart';
import '../services/sound_effects_service.dart';
import 'gamification_provider.dart';
import '../utils/structured_logger.dart';

/// Provider for daily challenges
final dailyChallengesProvider =
    NotifierProvider<DailyChallengesNotifier, DailyChallengesState>(() {
      return DailyChallengesNotifier();
    });

/// Keys for the on-device challenge board. Nothing here is a server save.
abstract final class DailyChallengeStoreKeys {
  static const String challenges = 'daily_challenges';
  static const String day = 'daily_challenges_date';
}

/// What a challenge load returned. [ready] is the only status with rows.
enum DailyChallengeBoardStatus { loading, ready, empty, error, offline }

class DailyChallengeBoard {
  const DailyChallengeBoard._(this.status, this.challenges);

  const DailyChallengeBoard.ready(List<DailyChallenge> challenges)
    : this._(DailyChallengeBoardStatus.ready, challenges);

  const DailyChallengeBoard.empty()
    : this._(DailyChallengeBoardStatus.empty, const <DailyChallenge>[]);

  const DailyChallengeBoard.error()
    : this._(DailyChallengeBoardStatus.error, const <DailyChallenge>[]);

  const DailyChallengeBoard.offline()
    : this._(DailyChallengeBoardStatus.offline, const <DailyChallenge>[]);

  final DailyChallengeBoardStatus status;
  final List<DailyChallenge> challenges;
}

String dailyChallengeDayKey(DateTime day) =>
    '${day.year}-${day.month}-${day.day}';

/// Reads the board saved on the phone. An empty store is an empty board.
/// A read or parse failure returns no rows.
Future<DailyChallengeBoard> loadSavedDailyChallenges() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String today = dailyChallengeDayKey(DateTime.now());
    final String? savedDay = prefs.getString(DailyChallengeStoreKeys.day);
    if (savedDay != today) {
      return const DailyChallengeBoard.empty();
    }
    final String? raw = prefs.getString(DailyChallengeStoreKeys.challenges);
    if (raw == null || raw.trim().isEmpty) {
      return const DailyChallengeBoard.empty();
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const DailyChallengeBoard.error();
    }
    final List<DailyChallenge> rows = <DailyChallenge>[];
    for (final Object? item in decoded) {
      if (item is! Map) {
        return const DailyChallengeBoard.error();
      }
      rows.add(DailyChallenge.fromJson(Map<String, dynamic>.from(item)));
    }
    final List<DailyChallenge> visible = <DailyChallenge>[
      for (final DailyChallenge row in rows)
        if (!row.isExpired && row.title.trim().isNotEmpty) row,
    ];
    if (visible.isEmpty) {
      return const DailyChallengeBoard.empty();
    }
    return DailyChallengeBoard.ready(
      List<DailyChallenge>.unmodifiable(visible),
    );
  } catch (_) {
    return const DailyChallengeBoard.error();
  }
}

/// A failed load. The previous rows are not copied onto the new state.
DailyChallengesState dailyChallengesAfterLoadFailure(Object error) {
  return DailyChallengesState(
    isLoading: false,
    error: error.toString(),
    challenges: const <DailyChallenge>[],
    weekendChallenges: const <DailyChallenge>[],
  );
}

class DailyChallengesState {
  final List<DailyChallenge> challenges;
  final List<DailyChallenge> weekendChallenges;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefresh;

  DailyChallengesState({
    this.challenges = const [],
    this.weekendChallenges = const [],
    this.isLoading = false,
    this.error,
    this.lastRefresh,
  });

  /// Get active (non-expired, non-claimed) challenges
  List<DailyChallenge> get activeChallenges =>
      challenges.where((c) => !c.isExpired && !c.isClaimed).toList();

  /// Get completed but unclaimed challenges
  List<DailyChallenge> get claimableChallenges =>
      challenges.where((c) => c.canClaim).toList();

  /// Get total potential XP from unclaimed challenges
  int get totalClaimableXP =>
      claimableChallenges.fold(0, (sum, c) => sum + c.xpReward);

  /// Check if it's weekend
  bool get isWeekend {
    final now = DateTime.now();
    return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  }

  DailyChallengesState copyWith({
    List<DailyChallenge>? challenges,
    List<DailyChallenge>? weekendChallenges,
    bool? isLoading,
    String? error,
    DateTime? lastRefresh,
  }) {
    return DailyChallengesState(
      challenges: challenges ?? this.challenges,
      weekendChallenges: weekendChallenges ?? this.weekendChallenges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }
}

class DailyChallengesNotifier extends Notifier<DailyChallengesState> {
  static const String _storageKey = DailyChallengeStoreKeys.challenges;
  static const String _lastDateKey = DailyChallengeStoreKeys.day;

  @override
  DailyChallengesState build() {
    _loadChallenges();
    return DailyChallengesState(isLoading: true);
  }

  /// Load challenges saved on the phone. A failed read drops any rows already
  /// held in memory. It does not fill the board with a new list.
  Future<void> _loadChallenges() async {
    try {
      final DailyChallengeBoard board = await loadSavedDailyChallenges();
      if (board.status == DailyChallengeBoardStatus.error ||
          board.status == DailyChallengeBoardStatus.offline) {
        state = dailyChallengesAfterLoadFailure(
          board.status == DailyChallengeBoardStatus.offline
              ? 'offline'
              : 'load-failed',
        );
        return;
      }
      if (board.challenges.isEmpty) {
        await _generateNewChallenges();
        return;
      }
      state = DailyChallengesState(
        challenges: board.challenges,
        weekendChallenges: const <DailyChallenge>[],
        isLoading: false,
        lastRefresh: DateTime.now(),
      );
    } catch (e) {
      logger.error(
        'Error loading daily challenges',
        tag: 'daily-challenges',
        error: e,
      );
      state = dailyChallengesAfterLoadFailure(e);
    }
  }

  /// Generate new daily challenges
  Future<void> _generateNewChallenges() async {
    final challenges = DailyChallengeTemplates.generateDailyChallenges();
    final weekendChallenges = state.isWeekend
        ? DailyChallengeTemplates.generateWeekendChallenges()
        : <DailyChallenge>[];

    state = state.copyWith(
      challenges: challenges,
      weekendChallenges: weekendChallenges,
      isLoading: false,
      lastRefresh: DateTime.now(),
    );

    await _saveChallenges();
  }

  /// Save challenges to storage
  Future<void> _saveChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String todayStr = dailyChallengeDayKey(DateTime.now());

      final allChallenges = [...state.challenges, ...state.weekendChallenges];
      final challengesJson = jsonEncode(
        allChallenges.map((c) => c.toJson()).toList(),
      );

      await prefs.setString(_storageKey, challengesJson);
      await prefs.setString(_lastDateKey, todayStr);
    } catch (e) {
      logger.error(
        'Error saving daily challenges',
        tag: 'daily-challenges',
        error: e,
      );
    }
  }

  /// Update progress for a challenge type
  Future<void> updateProgress(ChallengeType type, int amount) async {
    final updatedChallenges = state.challenges.map((challenge) {
      if (challenge.type == type &&
          !challenge.isCompleted &&
          !challenge.isExpired) {
        final newProgress = (challenge.progress + amount).clamp(
          0,
          challenge.target,
        );
        final isCompleted = newProgress >= challenge.target;

        if (isCompleted && !challenge.isCompleted) {
          // Play completion sound
          ref.read(soundEffectsProvider).play(SoundEffect.celebration);
        }

        return challenge.copyWith(
          progress: newProgress,
          isCompleted: isCompleted,
        );
      }
      return challenge;
    }).toList();

    // Update weekend challenges too
    final updatedWeekendChallenges = state.weekendChallenges.map((challenge) {
      if (challenge.type == type &&
          !challenge.isCompleted &&
          !challenge.isExpired) {
        final newProgress = (challenge.progress + amount).clamp(
          0,
          challenge.target,
        );
        final isCompleted = newProgress >= challenge.target;
        return challenge.copyWith(
          progress: newProgress,
          isCompleted: isCompleted,
        );
      }
      return challenge;
    }).toList();

    state = state.copyWith(
      challenges: updatedChallenges,
      weekendChallenges: updatedWeekendChallenges,
    );

    await _saveChallenges();
  }

  /// Claim rewards for a completed challenge
  Future<bool> claimChallenge(String challengeId) async {
    final challengeIndex = state.challenges.indexWhere(
      (c) => c.id == challengeId,
    );
    final weekendIndex = state.weekendChallenges.indexWhere(
      (c) => c.id == challengeId,
    );

    DailyChallenge? challenge;
    bool isWeekendChallenge = false;

    if (challengeIndex != -1) {
      challenge = state.challenges[challengeIndex];
    } else if (weekendIndex != -1) {
      challenge = state.weekendChallenges[weekendIndex];
      isWeekendChallenge = true;
    }

    if (challenge == null || !challenge.canClaim) {
      return false;
    }

    try {
      // Award XP and cowries
      await ref
          .read(gamificationProvider.notifier)
          .awardXP(
            'daily_challenge',
            multiplier: _getDifficultyMultiplier(challenge.difficulty),
            sourceId: challengeId,
          );

      await ref
          .read(gamificationProvider.notifier)
          .awardCurrency(cowries: challenge.cowriesReward);

      // Play reward sound
      ref.read(soundEffectsProvider).playCelebration();

      // Update challenge as claimed
      if (isWeekendChallenge) {
        final updated = List<DailyChallenge>.from(state.weekendChallenges);
        updated[weekendIndex] = challenge.copyWith(isClaimed: true);
        state = state.copyWith(weekendChallenges: updated);
      } else {
        final updated = List<DailyChallenge>.from(state.challenges);
        updated[challengeIndex] = challenge.copyWith(isClaimed: true);
        state = state.copyWith(challenges: updated);
      }

      await _saveChallenges();
      return true;
    } catch (e) {
      logger.error(
        'Error claiming challenge',
        tag: 'daily-challenges',
        error: e,
      );
      return false;
    }
  }

  /// Claim all completed challenges
  Future<int> claimAllChallenges() async {
    int claimedCount = 0;

    for (final challenge in state.claimableChallenges) {
      final success = await claimChallenge(challenge.id);
      if (success) claimedCount++;
    }

    return claimedCount;
  }

  double _getDifficultyMultiplier(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 1.0;
      case ChallengeDifficulty.medium:
        return 1.5;
      case ChallengeDifficulty.hard:
        return 2.0;
      case ChallengeDifficulty.expert:
        return 3.0;
    }
  }

  /// Force refresh challenges. Rows from the previous load are cleared first
  /// so a failed refresh cannot keep them on screen.
  Future<void> refresh() async {
    state = DailyChallengesState(isLoading: true);
    await _loadChallenges();
  }
}

/// Extension for tracking challenge progress from activities
extension DailyChallengeTracking on WidgetRef {
  /// Track lesson completion
  void trackLessonComplete() {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.lessonsComplete, 1);
  }

  /// Track XP earned
  void trackXPEarned(int amount) {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.xpEarned, amount);
  }

  /// Track perfect quiz
  void trackPerfectQuiz() {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.perfectQuiz, 1);
  }

  /// Track words learned
  void trackWordsLearned(int count) {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.wordsLearned, count);
  }

  /// Track games played
  void trackGamesPlayed() {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.gamesPlayed, 1);
  }

  /// Track time spent (in minutes)
  void trackTimeSpent(int minutes) {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.timeSpent, minutes);
  }

  /// Track chat messages
  void trackChatMessage() {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.chatMessages, 1);
  }

  /// Track story chapters
  void trackStoryChapter() {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.storyChapters, 1);
  }

  /// Track cultural content read
  void trackCulturalContent() {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.culturalContent, 1);
  }

  /// Track voice recordings
  void trackVoiceRecording() {
    read(
      dailyChallengesProvider.notifier,
    ).updateProgress(ChallengeType.voiceRecordings, 1);
  }
}
