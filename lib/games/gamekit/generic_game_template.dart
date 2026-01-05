import 'game.dart';
import 'game_engine.dart';
import 'game_session.dart';
import 'game_result.dart';
import 'game_turn_context.dart';
import 'game_scoring.dart';
import 'game_feedback.dart';
import 'game_difficulty.dart';
import 'game_animation_bridge.dart';
import '../../services/polie_game_client.dart';
import 'batch_game_factory.dart';

/// Generic game content model - can be used by simple games
class GenericGameContent {
  final String contentId;
  final String text;
  final String? correctAnswer;
  final List<String>? options;
  final Map<String, dynamic> metadata;

  GenericGameContent({
    required this.contentId,
    required this.text,
    this.correctAnswer,
    this.options,
    this.metadata = const {},
  });

  factory GenericGameContent.fromPolieContent(PolieGameContent polieContent) {
    return GenericGameContent(
      contentId: polieContent.contentId,
      text: polieContent.text,
      correctAnswer: polieContent.metadata?['correct_answer'] as String?,
      options: polieContent.metadata?['options'] != null
          ? List<String>.from(polieContent.metadata!['options'] as List)
          : null,
      metadata: polieContent.metadata ?? {},
    );
  }
}

/// Generic game input - can be used by simple games
class GenericGameInput {
  final String? selectedAnswer;
  final String? textInput;
  final Map<String, dynamic>? customData;

  GenericGameInput({
    this.selectedAnswer,
    this.textInput,
    this.customData,
  });

  Map<String, dynamic> toMap() {
    return {
      'selected_answer': selectedAnswer,
      'text_input': textInput,
      ...?customData,
    };
  }
}

/// Generic game that can be used for any game type
/// This provides a standard implementation that all games can use
class GenericGame extends Game<GenericGameContent, GenericGameInput> {
  final PolieGameClient polieClient;
  final String gameId;
  final String displayName;
  final List<String>? learningGoals;

  GenericGame({
    required GameEngine engine,
    required this.polieClient,
    required this.gameId,
    required this.displayName,
    this.learningGoals,
  }) : super(engine);

  @override
  GameConfig get config => GameConfig(
        gameId: gameId,
        displayName: displayName,
        defaultCardCount: 10,
        supportsAudio: false,
        supportsVoiceInput: false,
      );

  @override
  Future<GenericGameContent> loadContent(GameSession session) async {
    try {
      final polieContent = await polieClient.generateContent(
        gameId: gameId,
        language: session.language,
        difficulty: session.level ?? 'A2',
        userId: session.userId,
        sessionId: session.sessionId,
        previousPerformance: session.performanceProfile,
        learningGoals: learningGoals ?? [],
      );

      return GenericGameContent.fromPolieContent(polieContent);
    } catch (e) {
      // Return fallback content
      return GenericGameContent(
        contentId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Loading content...',
        metadata: {'error': e.toString()},
      );
    }
  }

  @override
  Future<GameTurnResult> playTurn(
    GenericGameContent content,
    GenericGameInput input,
    GameSession session,
  ) async {
    final context = GameTurnContext(
      content: content,
      input: input,
      session: session,
    );

    return await engine.resolve(context);
  }
}

/// Generic scoring engine that uses Polie for all evaluation
class GenericGameScoringEngine extends PolieScoringEngine {
  final String gameId;

  GenericGameScoringEngine({
    required super.polieClient,
    required this.gameId,
  });

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final content = context.content;
    final input = context.input;
    final session = context.session;

    // Extract user input
    Map<String, dynamic> userInput;
    if (input is GenericGameInput) {
      userInput = input.toMap();
    } else if (input is Map<String, dynamic>) {
      userInput = input;
    } else {
      userInput = {'user_input': input.toString()};
    }

    // Extract content ID
    String contentId;
    if (content is GenericGameContent) {
      contentId = content.contentId;
    } else if (content is Map<String, dynamic>) {
      contentId = content['contentId'] as String? ?? 
                  content['content_id'] as String? ?? 
                  'unknown';
    } else {
      contentId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }

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
      // Use simple comparison if possible
      bool isCorrect = false;
      if (content is GenericGameContent && input is GenericGameInput) {
        if (content.correctAnswer != null && input.selectedAnswer != null) {
          isCorrect = content.correctAnswer == input.selectedAnswer;
        } else if (content.correctAnswer != null && input.textInput != null) {
          isCorrect = content.correctAnswer!.toLowerCase().trim() == 
                     input.textInput!.toLowerCase().trim();
        }
      }

      return GameScore(
        accuracy: isCorrect ? 1.0 : 0.0,
        isPerfect: isCorrect,
        isFail: !isCorrect,
        details: {
          'correct': isCorrect,
          'error': e.toString(),
        },
      );
    }
  }
}

/// Factory for creating generic games
class GenericGameFactory {
  static GenericGame create({
    required WidgetRef ref,
    required String gameId,
    required String displayName,
    List<String>? learningGoals,
  }) {
    final polieClient = PolieGameClient();
    final engine = BatchGameFactory.createStandardEngine(ref);
    
    // Replace default scoring with Polie-based scoring
    final scoringEngine = GenericGameScoringEngine(
      polieClient: polieClient,
      gameId: gameId,
    );

    final gameEngine = GameEngine(
      scoring: scoringEngine,
      difficulty: engine.difficulty,
      feedback: engine.feedback,
      animation: engine.animation,
    );

    return GenericGame(
      engine: gameEngine,
      polieClient: polieClient,
      gameId: gameId,
      displayName: displayName,
      learningGoals: learningGoals,
    );
  }
}

