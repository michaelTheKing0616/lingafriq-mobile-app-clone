import 'game_session.dart';

/// Context for a single game turn
/// Contains all information needed to evaluate a turn
class GameTurnContext {
  final dynamic content; // Game-specific content (e.g., ToneForgeContent)
  final dynamic input; // User input (e.g., ToneForgeInput)
  final GameSession session;
  final DateTime turnStartTime;
  final Map<String, dynamic>? metadata;
  final int? queueIndex;

  GameTurnContext({
    required this.content,
    required this.input,
    required this.session,
    DateTime? turnStartTime,
    this.metadata,
    this.queueIndex,
  }) : turnStartTime = turnStartTime ?? DateTime.now();

  int get durationMs => DateTime.now().difference(turnStartTime).inMilliseconds;

  String? get queuedItemId {
    if (queueIndex == null || queueIndex! < 0 || queueIndex! >= session.turnQueue.length) {
      return null;
    }
    return session.turnQueue[queueIndex!];
  }
}

