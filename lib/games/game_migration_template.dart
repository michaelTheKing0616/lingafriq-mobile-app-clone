/// Game Migration Template
/// Use this as a starting point when migrating existing games to GameKit
/// 
/// Steps:
/// 1. Copy this file to lib/games/[game_name]/[game_name]_game.dart
/// 2. Replace all [GameName] placeholders with your game name
/// 3. Implement game-specific models, scoring, and feedback
/// 4. Remove old implementation from cultural_games.dart

import 'gamekit/game.dart';
import 'gamekit/game_engine.dart';
import 'gamekit/game_session.dart';
import 'gamekit/game_result.dart';
import 'gamekit/game_turn_context.dart';
import 'gamekit/game_scoring.dart';
import 'gamekit/game_animation_bridge.dart';
import 'gamekit/game_difficulty.dart';
import 'gamekit/game_feedback.dart';
import '../../services/polie_game_client.dart';

// TODO: Create [GameName]Content model
class GameNameContent {
  final String text;
  final String correctAnswer;
  final List<String> options;
  final String contentId;
  // Add game-specific fields

  GameNameContent({
    required this.text,
    required this.correctAnswer,
    required this.options,
    required this.contentId,
  });

  factory GameNameContent.fromPolieContent(Map<String, dynamic> polieData) {
    return GameNameContent(
      text: polieData['text'] as String? ?? '',
      correctAnswer: polieData['correct_answer'] as String? ?? '',
      options: (polieData['options'] as List<dynamic>?)?.cast<String>() ?? [],
      contentId: polieData['content_id'] as String? ?? '',
    );
  }
}

// TODO: Create [GameName]Input model
class GameNameInput {
  final String selectedAnswer;
  // Add game-specific input fields

  GameNameInput({required this.selectedAnswer});
}

// TODO: Create [GameName]ScoringEngine
class GameNameScoringEngine implements GameScoringEngine {
  final PolieGameClient polieClient;

  GameNameScoringEngine({required this.polieClient});

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final content = context.content as GameNameContent;
    final input = context.input as GameNameInput;

    // Use Polie backend - NO RANDOM LOGIC
    final evaluation = await polieClient.evaluateTurn(
      gameId: 'game_name', // TODO: Replace with actual game ID
      contentId: content.contentId,
      language: context.session.language,
      userInput: {
        'selected_answer': input.selectedAnswer,
        'correct_answer': content.correctAnswer,
      },
      difficulty: context.session.level ?? 'A2',
      sessionMetrics: context.session.performanceProfile,
    );

    return GameScore(
      accuracy: evaluation.accuracy,
      isPerfect: evaluation.accuracy > 0.9,
      isFail: evaluation.accuracy < 0.4,
      details: {
        'correct': evaluation.correct,
        'feedback': evaluation.feedback,
      },
    );
  }
}

// TODO: Create [GameName]FeedbackEngine
class GameNameFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(GameTurnContext context, GameScore score) async {
    if (score.isPerfect) {
      return GameFeedback.success(
        message: 'Excellent! Perfect score!',
        animationEvent: AnimationEvent.proud,
      );
    }

    if (score.isFail) {
      return GameFeedback.failure(
        message: 'Not quite right. Try again!',
        animationEvent: AnimationEvent.encouraging,
      );
    }

    if (score.isCorrect) {
      return GameFeedback.success(
        message: 'Good job!',
        animationEvent: AnimationEvent.happy,
      );
    }

    return GameFeedback.neutral(
      message: 'Almost there. Keep trying!',
      animationEvent: AnimationEvent.thinking,
    );
  }
}

/// [GameName] Game - Migrated to GameKit
class GameNameGame extends Game<GameNameContent, GameNameInput> {
  final PolieGameClient polieClient;

  GameNameGame({
    required GameEngine engine,
    required this.polieClient,
  }) : super(engine);

  @override
  GameConfig get config => const GameConfig(
        gameId: 'game_name', // TODO: Replace with actual game ID
        displayName: 'Game Name', // TODO: Replace with display name
        defaultCardCount: 10,
        supportsAudio: false,
        supportsVoiceInput: false,
      );

  @override
  Future<GameNameContent> loadContent(GameSession session) async {
    try {
      final polieContent = await polieClient.generateContent(
        gameId: config.gameId,
        language: session.language,
        difficulty: session.level ?? 'A2',
        userId: session.userId,
        sessionId: session.sessionId,
        previousPerformance: session.performanceProfile,
        learningGoals: [], // TODO: Add relevant learning goals
      );

      return GameNameContent.fromPolieContent({
        'text': polieContent.text,
        'correct_answer': '', // TODO: Extract from polieContent
        'options': [], // TODO: Generate options
        'content_id': polieContent.contentId,
      });
    } catch (e) {
      // Return fallback content
      return GameNameContent(
        text: 'Loading...',
        correctAnswer: '',
        options: [],
        contentId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  @override
  Future<GameTurnResult> playTurn(
    GameNameContent content,
    GameNameInput input,
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

/// Factory to create [GameName] game
class GameNameGameFactory {
  static GameNameGame create({
    required PolieGameClient polieClient,
    required GameAnimationBridge animationBridge,
  }) {
    final engine = GameEngine(
      scoring: GameNameScoringEngine(polieClient: polieClient),
      difficulty: DefaultGameDifficultyEngine(),
      feedback: GameNameFeedbackEngine(),
      animation: animationBridge,
    );

    return GameNameGame(
      engine: engine,
      polieClient: polieClient,
    );
  }
}

