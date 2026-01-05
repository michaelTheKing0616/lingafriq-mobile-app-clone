import 'game_session.dart';
import 'game_result.dart';

/// Context for a single game turn
/// Contains all information needed to evaluate a turn
class GameTurnContext {
  final dynamic content; // Game-specific content (e.g., ToneForgeContent)
  final dynamic input; // User input (e.g., ToneForgeInput)
  final GameSession session;
  final DateTime turnStartTime;
  final Map<String, dynamic>? metadata;

  GameTurnContext({
    required this.content,
    required this.input,
    required this.session,
    DateTime? turnStartTime,
    this.metadata,
  }) : turnStartTime = turnStartTime ?? DateTime.now();

  int get durationMs => DateTime.now().difference(turnStartTime).inMilliseconds;
}

