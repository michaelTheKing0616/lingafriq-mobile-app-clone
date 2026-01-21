import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'game_engine_service.dart';
import 'game.dart';
import 'game_session.dart' as gamekit_session;
import '../../models/game/game_session_model.dart' show GameType, GameSession, GameResult;
import '../../screens/games/base_game_screen.dart';

/// Elite Game Screen Integration
///
/// Provides seamless integration between BaseGameScreen (UI layer)
/// and the GameKit engine (logic layer).
///
/// Benefits:
/// - Eliminates manual GameKit session creation duplication
/// - Provides type-safe game operations
/// - Simplifies game content loading and turn processing
/// - Works with both dedicated factories and GenericGame
class GameScreenIntegration {
  final GameEngineService engineService;

  GameScreenIntegration(this.engineService);

  /// Get game instance for a GameType
  /// Works with both dedicated factories and GenericGame
  Game<dynamic, dynamic> getGameForType(GameType gameType) {
    return engineService.getGameByType(gameType);
  }

  /// Create a GameKit session from a model session
  /// Eliminates duplication of manual session creation in game screens
  gamekit_session.GameSession createGameKitSession({
    required GameSession modelSession,
    required String gameId,
  }) {
    return engineService.createGameKitSession(
      sessionId: modelSession.sessionId,
      userId: modelSession.userId,
      gameId: gameId,
      language: modelSession.language,
      level: modelSession.level?.toString(),
      startTime: modelSession.startTime,
      performanceProfile: _getPerformanceProfile(modelSession),
    );
  }

  /// Get game configuration for a GameType
  GameConfig getGameConfigForType(GameType gameType) {
    final game = getGameForType(gameType);
    return game.config;
  }

  /// Calculate performance profile from model session
  /// GameSession model doesn't have performanceProfile, so we calculate it
  Map<String, dynamic> _getPerformanceProfile(GameSession modelSession) {
    return {
      'accuracy': modelSession.accuracy,
      'total_turns': modelSession.totalTurns,
      'correct_count': modelSession.correctCount,
      'recent_accuracy': modelSession.totalTurns >= 3
          ? modelSession.turns
              .sublist(modelSession.turns.length - 3)
              .where((t) => t.result == GameResult.correct)
              .length /
              3
          : modelSession.accuracy,
    };
  }
}

/// Provider for GameScreenIntegration
final gameScreenIntegrationProvider = Provider<GameScreenIntegration>((ref) {
  final engineService = ref.read(gameEngineServiceProvider);
  return GameScreenIntegration(engineService);
});

/// Extension on BaseGameScreenState for GameKit integration
/// 
/// Provides convenient methods to work with GameKit without
/// manually creating sessions or accessing services.
extension GameKitIntegration on BaseGameScreenState {
  /// Get GameKit integration service
  GameScreenIntegration get gameKit => ref.read(gameScreenIntegrationProvider);

  /// Get game instance for this screen's game type
  /// Works with both dedicated factories and GenericGame
  Game<dynamic, dynamic> get game => gameKit.getGameForType(widget.getGameType());

  /// Get game configuration
  GameConfig get gameConfig => gameKit.getGameConfigForType(widget.getGameType());

  /// Create a GameKit session from the current model session
  /// Eliminates manual session creation duplication
  gamekit_session.GameSession createGameKitSession() {
    if (session == null) {
      throw StateError('Session must be initialized before creating GameKit session');
    }
    
    final game = this.game;
    return gameKit.createGameKitSession(
      modelSession: session!,
      gameId: game.config.gameId,
    );
  }
}
