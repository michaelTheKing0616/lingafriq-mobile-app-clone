import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'game_engine.dart';
import 'game_animation_bridge.dart';
import 'game_session.dart';
import 'game_scoring.dart';
import '../../services/polie_game_client.dart' show PolieGameClient, PolieEvaluationResult;
import '../../services/rive_gamification_service.dart';
import '../animation/rive_game_guide.dart';
import 'game_result.dart';

/// Helper class to migrate games to GameKit framework
/// This provides standard patterns and utilities for game migration
class GameMigrationHelper {
  /// Create a standard game engine with Rive integration
  static GameEngine createStandardEngine(WidgetRef ref) {
    final riveService = ref.read(riveGamificationServiceProvider);
    final guideController = RiveGameGuideController();
    riveService.setController(guideController);
    
    final animationBridge = GameAnimationBridge(guideController: guideController);
    
    return GameEngine.defaultEngine(animationBridge);
  }

  /// Create a Polie client instance
  static PolieGameClient createPolieClient() {
    return PolieGameClient();
  }

  /// Create a game session from BaseGameScreen session
  static GameSession createGameSession({
    required String sessionId,
    required String userId,
    required String gameId,
    required String language,
    String? level,
    required DateTime startTime,
    List<GameTurnResult> turns = const [],
  }) {
    return GameSession(
      sessionId: sessionId,
      userId: userId,
      gameId: gameId,
      language: language,
      level: level ?? 'A2',
      startTime: startTime,
      turns: turns,
    );
  }

  /// Standard error handler for game content loading
  static Future<T> loadContentWithFallback<T>({
    required Future<T> Function() loadFunction,
    required T Function() fallbackFunction,
  }) async {
    try {
      return await loadFunction();
    } catch (e) {
      debugPrint('Error loading game content: $e');
      return fallbackFunction();
    }
  }
}

/// Base class for game-specific scoring engines that use Polie
abstract class PolieScoringEngine extends GameScoringEngine {
  final PolieGameClient polieClient;

  PolieScoringEngine({required this.polieClient});

  /// Evaluate using Polie backend - NO RANDOM LOGIC
  Future<PolieEvaluationResult> evaluateWithPolie({
    required String gameId,
    required String contentId,
    required String language,
    required Map<String, dynamic> userInput,
    required String difficulty,
    required Map<String, dynamic> sessionMetrics,
  }) async {
    return await polieClient.evaluateTurn(
      gameId: gameId,
      contentId: contentId,
      language: language,
      userInput: userInput,
      difficulty: difficulty,
      sessionMetrics: sessionMetrics,
    );
  }
}

