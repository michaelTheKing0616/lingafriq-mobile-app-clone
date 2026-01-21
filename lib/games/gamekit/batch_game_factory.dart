import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'game_engine.dart';
import 'game_animation_bridge.dart';
import '../../services/polie_game_client.dart';
import '../../services/rive_gamification_service.dart';
import '../animation/rive_game_guide.dart';
import 'game_scoring.dart';
import 'game_feedback.dart';
import 'game_difficulty.dart';
import 'game_migration_helper.dart';
import 'game_turn_context.dart';

/// Factory for creating standard game engines for all games
/// This ensures consistency across all 35+ games
class BatchGameFactory {
  /// Create a standard game engine with Polie evaluation and Rive integration
  static GameEngine createStandardEngine(WidgetRef ref) {
    final riveService = ref.read(riveGamificationServiceProvider);
    final guideController = RiveGameGuideController();
    riveService.setController(guideController);
    
    final animationBridge = GameAnimationBridge(guideController: guideController);
    
    return GameEngine.defaultEngine(animationBridge);
  }

  /// Create a Polie-based scoring engine
  static GameScoringEngine createPolieScoringEngine({
    required PolieGameClient polieClient,
    required String gameId,
  }) {
    return _PolieGameScoringEngine(
      polieClient: polieClient,
      gameId: gameId,
    );
  }

  /// Create a standard feedback engine
  static GameFeedbackEngine createStandardFeedbackEngine() {
    return DefaultGameFeedbackEngine();
  }

  /// Create a standard difficulty engine
  static GameDifficultyEngine createStandardDifficultyEngine() {
    return DefaultGameDifficultyEngine();
  }
}

/// Generic Polie-based scoring engine for games that don't need custom scoring
class _PolieGameScoringEngine extends PolieScoringEngine {
  final String gameId;

  _PolieGameScoringEngine({
    required super.polieClient,
    required this.gameId,
  });

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final session = context.session;
    
    // Extract user input from context
    final userInput = _extractUserInput(context);
    
    // Get content ID from context
    final contentId = _extractContentId(context);

    try {
      final evaluation = await evaluateWithPolie(
        gameId: gameId,
        contentId: contentId,
        language: session.language,
        userInput: userInput,
        difficulty: session.level ?? 'A2',
        sessionMetrics: session.performanceProfile,
      );

      return GameScore(
        accuracy: evaluation.accuracy,
        isPerfect: evaluation.accuracy > 0.9,
        isFail: evaluation.accuracy < 0.4,
        details: {
          'correct': evaluation.correct,
          'feedback': evaluation.feedback,
          'animation_event': evaluation.animationEvent,
        },
      );
    } catch (e) {
      // Fallback - still no random logic
      return GameScore(
        accuracy: 0.5,
        isPerfect: false,
        isFail: false,
        details: {
          'error': e.toString(),
        },
      );
    }
  }

  Map<String, dynamic> _extractUserInput(GameTurnContext context) {
    // Try to extract user input from context
    // This is a generic extractor - games can override with custom scoring
    if (context.input is Map<String, dynamic>) {
      return context.input as Map<String, dynamic>;
    }
    
    // Try to convert input to map
    try {
      final input = context.input;
      if (input.toString().contains('selected')) {
        return {'user_input': input.toString()};
      }
    } catch (e) {
      // Ignore
    }
    
    return {'user_input': context.input.toString()};
  }

  String _extractContentId(GameTurnContext context) {
    // Try to extract content ID from content
    if (context.content is Map<String, dynamic>) {
      final content = context.content as Map<String, dynamic>;
      return content['contentId'] as String? ?? 
             content['content_id'] as String? ?? 
             content['id'] as String? ?? 
             'unknown';
    }
    
    // Try to get contentId property
    try {
      final content = context.content;
      if (content.toString().contains('contentId')) {
        return 'extracted_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      // Ignore
    }
    
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }
}

