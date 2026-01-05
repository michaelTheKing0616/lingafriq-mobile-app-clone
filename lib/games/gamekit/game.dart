/// Core Game Interface
/// All games must implement this interface to use the GameKit framework
abstract class Game<TContent, TInput> {
  final GameEngine engine;

  Game(this.engine);

  /// Load game content from Polie backend
  Future<TContent> loadContent(GameSession session);

  /// Process a single game turn
  Future<GameTurnResult> playTurn(
    TContent content,
    TInput input,
    GameSession session,
  );

  /// Get game-specific configuration
  GameConfig get config;
}

/// Game configuration
class GameConfig {
  final String gameId;
  final String displayName;
  final int defaultCardCount;
  final bool supportsAudio;
  final bool supportsVoiceInput;
  final List<String> requiredPermissions;

  const GameConfig({
    required this.gameId,
    required this.displayName,
    this.defaultCardCount = 10,
    this.supportsAudio = false,
    this.supportsVoiceInput = false,
    this.requiredPermissions = const [],
  });
}

