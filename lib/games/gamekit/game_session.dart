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
  final List<GameTurnResult> turns;
  final Map<String, dynamic> metadata;

  GameSession({
    required this.sessionId,
    required this.userId,
    required this.gameId,
    required this.language,
    this.level,
    required this.startTime,
    this.turns = const [],
    this.metadata = const {},
  });

  int get correctCount => turns.where((t) => t.score.isCorrect).length;
  int get totalTurns => turns.length;
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
    List<GameTurnResult>? turns,
    Map<String, dynamic>? metadata,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      language: language ?? this.language,
      level: level ?? this.level,
      startTime: startTime ?? this.startTime,
      turns: turns ?? this.turns,
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

