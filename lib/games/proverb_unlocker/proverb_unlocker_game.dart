import '../gamekit/game.dart';
import '../gamekit/game_engine.dart';
import '../gamekit/game_session.dart';
import '../gamekit/game_result.dart';
import '../gamekit/game_animation_bridge.dart';
import '../gamekit/game_difficulty.dart';
import '../../services/polie_game_client.dart';
import 'proverb_unlocker_models.dart';
import 'proverb_unlocker_scoring.dart';
import 'proverb_unlocker_feedback.dart';

/// ProverbUnlocker game - Refactored to use GameKit
/// This replaces the old implementation with random logic
class ProverbUnlockerGame extends Game<ProverbUnlockerContent, ProverbUnlockerInput> {
  final PolieGameClient polieClient;

  ProverbUnlockerGame({
    required GameEngine engine,
    required this.polieClient,
  }) : super(engine);

  @override
  GameConfig get config => const GameConfig(
        gameId: 'proverb_unlocker',
        displayName: 'Proverb Unlocker',
        defaultCardCount: 5,
        supportsAudio: false,
        supportsVoiceInput: false,
      );

  @override
  Future<ProverbUnlockerContent> loadContent(GameSession session) async {
    try {
      final polieContent = await polieClient.generateContent(
        gameId: config.gameId,
        language: session.language,
        difficulty: session.level ?? 'A2',
        userId: session.userId,
        sessionId: session.sessionId,
        previousPerformance: session.performanceProfile,
        learningGoals: ['proverbs', 'cultural_wisdom'],
      );

      // Convert Polie content to game-specific format
      // Polie returns structured data that we parse
      return ProverbUnlockerContent.fromPolieContent({
        'proverb': polieContent.text,
        'translation': polieContent.metadata?['translation'] ?? '',
        'meaning': polieContent.culturalContext ?? polieContent.metadata?['meaning'] ?? '',
        'context': polieContent.culturalContext ?? '',
        'content_id': polieContent.contentId,
      });
    } catch (e) {
      // Return fallback content
      return ProverbUnlockerContent(
        proverb: 'Wisdom comes from experience',
        translation: 'Wisdom comes from experience',
        meaning: 'Learning through practice and experience',
        context: 'A common saying about the value of experience',
        options: [
          'Learning through practice and experience',
          'A common greeting',
          'A traditional dance',
          'A type of food',
        ],
        correctAnswer: 'Learning through practice and experience',
        contentId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  @override
  Future<GameTurnResult> playTurn(
    ProverbUnlockerContent content,
    ProverbUnlockerInput input,
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

/// Factory to create ProverbUnlocker game
class ProverbUnlockerGameFactory {
  static ProverbUnlockerGame create({
    required PolieGameClient polieClient,
    required GameAnimationBridge animationBridge,
  }) {
    final engine = GameEngine(
      scoring: ProverbUnlockerScoringEngine(polieClient: polieClient),
      difficulty: DefaultGameDifficultyEngine(),
      feedback: ProverbUnlockerFeedbackEngine(),
      animation: animationBridge,
    );

    return ProverbUnlockerGame(
      engine: engine,
      polieClient: polieClient,
    );
  }
}

