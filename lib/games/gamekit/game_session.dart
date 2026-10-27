import '../../models/game/game_session_model.dart' as backend;
import 'game_result.dart';

/// Extended game session with performance tracking
class GameSession {
  final String sessionId;
  final String userId;
  final String gameId;
  final String language;
  final String? level;
  final DateTime startTime;
  final int plannedDurationSeconds;
  final List<GameTurnResult> turns;
  final List<String> turnQueue;
  final bool queueLoadFailed;
  final Map<String, dynamic> metadata;

  /// P8-906 duel matchmaking (server-authoritative levels; never trust client level).
  String? get duelMatchId => metadata['duel_match_id'] as String?;
  String? get duelOpponentUserId => metadata['duel_opponent_user_id'] as String?;
  String? get duelOpponentLevelLabel => metadata['duel_opponent_level_label'] as String?;
  String? get duelSelfLevelLabel => metadata['duel_self_level_label'] as String?;
  bool get duelOpponentIsBot => metadata['duel_opponent_is_bot'] == true;
  String? get duelMatchmakingStatus => metadata['duel_matchmaking_status'] as String?;

  GameSession({
    required this.sessionId,
    required this.userId,
    required this.gameId,
    required this.language,
    this.level,
    required this.startTime,
    int? plannedDurationSeconds,
    this.turns = const [],
    this.turnQueue = const [],
    this.queueLoadFailed = false,
    this.metadata = const {},
  }) : plannedDurationSeconds = plannedDurationSeconds ??
            (metadata['planned_duration_seconds'] as int?) ??
            120;

  DateTime get plannedEndTime =>
      startTime.add(Duration(seconds: plannedDurationSeconds));

  int elapsedSeconds(DateTime now) => now.difference(startTime).inSeconds;

  /// Visible retry state when due-item query failed (never serves a hardcoded list).
  bool get needsQueueRetry => queueLoadFailed;

  String? get queueSource => metadata['queue_source'] as String?;

  int get correctCount => turns.where((t) => t.score.isCorrect).length;
  int get totalTurns => turns.length;
  int get learnerEventsRecorded =>
      (metadata['learner_events_recorded'] as int?) ?? turns.length;
  double get accuracy => totalTurns > 0 ? correctCount / totalTurns : 0.0;
  int get streak => _calculateStreak();
  double get averageConfidence => _calculateAverageConfidence();

  int _calculateStreak() {
    if (turns.isEmpty) return 0;
    int currentStreak = 0;
    for (var i = turns.length - 1; i >= 0; i--) {
      if (turns[i].score.isCorrect) {
        currentStreak++;
      } else {
        break;
      }
    }
    return currentStreak;
  }

  double _calculateAverageConfidence() {
    if (turns.isEmpty) return 0.0;
    final sum = turns.fold<double>(0.0, (acc, turn) => acc + turn.score.accuracy);
    return sum / turns.length;
  }

  /// Performance profile for Polie backend
  Map<String, dynamic> get performanceProfile => {
        'accuracy': accuracy,
        'streak': streak,
        'average_confidence': averageConfidence,
        'total_turns': totalTurns,
        'recent_accuracy': turns.length >= 3
            ? turns.sublist(turns.length - 3).where((t) => t.score.isCorrect).length / 3
            : accuracy,
      };

  GameSession copyWith({
    String? sessionId,
    String? userId,
    String? gameId,
    String? language,
    String? level,
    DateTime? startTime,
    int? plannedDurationSeconds,
    List<GameTurnResult>? turns,
    List<String>? turnQueue,
    bool? queueLoadFailed,
    Map<String, dynamic>? metadata,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      language: language ?? this.language,
      level: level ?? this.level,
      startTime: startTime ?? this.startTime,
      plannedDurationSeconds:
          plannedDurationSeconds ?? this.plannedDurationSeconds,
      turns: turns ?? this.turns,
      turnQueue: turnQueue ?? this.turnQueue,
      queueLoadFailed: queueLoadFailed ?? this.queueLoadFailed,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to backend GameSession model
  backend.GameSession toBackendModel() {
    return backend.GameSession(
      sessionId: sessionId,
      userId: userId,
      gameType: gameId,
      language: language,
      level: level,
      startTime: startTime,
      turns: turns.map((t) => t.toGameTurn(cardId: '')).toList(), // cardId should be provided by caller
      metadata: metadata,
    );
  }
}

