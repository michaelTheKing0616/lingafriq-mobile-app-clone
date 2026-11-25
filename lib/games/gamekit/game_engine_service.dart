import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'game_engine.dart';
import 'game.dart';
import 'game_session.dart' as gamekit_session;
import 'game_result.dart';
import 'game_turn_context.dart';
import 'game_animation_bridge.dart';
import 'all_games_registry.dart';
import 'generic_game_template.dart';
import '../../services/polie_game_client.dart';
import '../../services/rive_gamification_service.dart';
import '../../providers/dio_provider.dart';
import '../animation/rive_game_guide.dart';
import '../proverb_unlocker/proverb_unlocker_game.dart';
import '../tone_forge/tone_forge_game.dart';
import '../drum_rhythm/drum_rhythm_game.dart';
import '../../models/game/game_session_model.dart' show GameType;

/// Stable bot opponent id from matchmaking (P8-908).
const String kGamekitBotUserId = 'gamekit_bot';

/// Copy keys: games.gamekit_bot_label.* (l10n wired in a later card).
abstract final class GamekitBotLabelCopy {
  static const String title = 'Bot';
  static const String practiceLabel = 'Practice opponent';
  static const String levelSubtitle = 'Skill band';
}

/// Server-authoritative duel opponent bot flag (AC4).
bool resolveDuelOpponentIsBot(Map<String, dynamic> payload) {
  if (payload['isBot'] == true) return true;
  final opponent = payload['opponent'];
  if (opponent is Map) {
    final map = Map<String, dynamic>.from(opponent);
    if (map['isBot'] == true) return true;
    if (map['userId'] == kGamekitBotUserId) return true;
  }
  return false;
}

/// Display name for duel HUD — never a human-style name for bots (AC2).
String duelOpponentDisplayName({
  required bool isBot,
  String? serverDisplayName,
  String? levelLabel,
}) {
  if (isBot) return GamekitBotLabelCopy.title;
  final fromServer = serverDisplayName?.trim();
  if (fromServer != null && fromServer.isNotEmpty) return fromServer;
  return levelLabel?.trim().isNotEmpty == true
      ? levelLabel!.trim()
      : 'Opponent';
}

bool duelCountsForLeaderboard({required bool duelOpponentIsBot}) =>
    !duelOpponentIsBot;

/// Elite Game Engine Service
///
/// Unified service that provides game instances for ALL games in the system.
///
/// Handles both:
/// - Games with dedicated factories (ProverbUnlocker, ToneForge, DrumRhythm)
/// - Games using GenericGame template (all other 34+ games via AllGamesRegistry)
///
/// Features:
/// - Automatic factory selection (dedicated vs GenericGame)
/// - Game instance caching for performance
/// - Type-safe game access via GameType enum
/// - Consistent GameKit engine setup for all games
class GameEngineService {
  final PolieGameClient polieClient;
  final GameAnimationBridge animationBridge;
  final Map<String, Game<dynamic, dynamic>> _gameCache = {};

  GameEngineService({required this.polieClient, required this.animationBridge});

  /// Get game instance for a game ID
  /// Caches instances for performance
  Game<dynamic, dynamic> getGame(String gameId) {
    if (_gameCache.containsKey(gameId)) {
      return _gameCache[gameId]!;
    }

    final game = _createGame(gameId);
    _gameCache[gameId] = game;
    return game;
  }

  /// Create game instance - delegates to existing factories or GenericGame
  Game<dynamic, dynamic> _createGame(String gameId) {
    final engine = GameEngine.defaultEngine(animationBridge);

    // Use existing dedicated factories for games that have them
    switch (gameId) {
      case 'proverb_unlocker':
        return ProverbUnlockerGame(engine: engine, polieClient: polieClient);

      case 'tone_forge':
      case 'tone_trainer':
        return ToneForgeGame(engine: engine, polieClient: polieClient);

      case 'drum_rhythm_shadowing':
        return DrumRhythmGame(engine: engine, polieClient: polieClient);

      default:
        // Use AllGamesRegistry for all other games (creates GenericGame)
        final definition = AllGamesRegistry.getGame(gameId);
        if (definition != null) {
          return GenericGame(
            engine: engine,
            polieClient: polieClient,
            gameId: gameId,
            displayName: definition.displayName,
            learningGoals: definition.learningGoals,
          );
        }
        throw ArgumentError('Game not found: $gameId');
    }
  }

  /// Get game by GameType enum
  Game<dynamic, dynamic> getGameByType(GameType gameType) {
    final gameId = _gameTypeToId(gameType);
    return getGame(gameId);
  }

  /// Convert GameType enum to game ID string
  String _gameTypeToId(GameType gameType) {
    switch (gameType) {
      case GameType.proverbUnlocker:
        return 'proverb_unlocker';
      case GameType.toneTrainer:
        return 'tone_forge';
      case GameType.drumRhythmShadowing:
        return 'drum_rhythm_shadowing';
      default:
        // Extension-provided canonical snake_case contract.
        return gameType.name;
    }
  }

  /// Get game configuration
  GameConfig getGameConfig(String gameId) {
    final game = getGame(gameId);
    return game.config;
  }

  final GameKitLearnerGraphWriter _graphWriter = GameKitLearnerGraphWriter();

  /// Resolves a turn and writes learner-graph + SRS before returning (P8-901).
  Future<GameTurnResolution> resolveTurnWithGraphWrite({
    required GameEngine engine,
    required gamekit_session.GameSession session,
    required GameTurnContext context,
    required String turnId,
    bool queueOnly = false,
  }) async {
    final ctx = GameTurnContext(
      content: context.content,
      input: context.input,
      session: session,
      turnStartTime: context.turnStartTime,
      metadata: context.metadata,
      queueIndex: context.queueIndex,
    );
    return engine.resolveTurnRecording(
      _graphWriter,
      ctx,
      turnId: turnId,
      queueOnly: queueOnly,
    );
  }

  GameKitLearnerGraphWriter get graphWriter => _graphWriter;

  /// Duel match payload from `gamekit:duel:matched` (levels are server-resolved).
  gamekit_session.GameSession applyDuelServerMatched(
    gamekit_session.GameSession session,
    Map<String, dynamic> payload,
  ) {
    if (resolveDuelOpponentIsBot(payload)) {
      final opponent = payload['opponent'] as Map<String, dynamic>? ?? {};
      return applyDuelBotMatch(
        session,
        matchId: payload['matchId']?.toString() ?? 'duel_bot',
        botLevelLabel:
            opponent['levelLabel']?.toString() ??
            payload['botLevelLabel']?.toString() ??
            'Building',
      );
    }
    return applyDuelHumanMatch(session, payload);
  }

  gamekit_session.GameSession applyDuelHumanMatch(
    gamekit_session.GameSession session,
    Map<String, dynamic> payload,
  ) {
    final self = payload['self'] as Map<String, dynamic>? ?? {};
    final opponent = payload['opponent'] as Map<String, dynamic>? ?? {};
    final isBot = resolveDuelOpponentIsBot(payload);
    return session.copyWith(
      metadata: {
        ...session.metadata,
        'duel_match_id': payload['matchId'],
        'duel_matchmaking_status': isBot ? 'matched_bot' : 'matched_human',
        'duel_self_level_label': self['levelLabel'],
        'duel_opponent_handle': opponent['handle'],
        'duel_opponent_level_label': opponent['levelLabel'],
        'duel_opponent_is_bot': isBot,
        'duel_opponent_display_name': duelOpponentDisplayName(
          isBot: isBot,
          serverDisplayName: opponent['displayName']?.toString(),
          levelLabel: opponent['levelLabel']?.toString(),
        ),
        'duel_exclude_from_leaderboard': !duelCountsForLeaderboard(
          duelOpponentIsBot: isBot,
        ),
      },
    );
  }

  /// Timeout path: labelled bot or retry — never silent out-of-band pairing.
  gamekit_session.GameSession applyDuelTimeoutOffer(
    gamekit_session.GameSession session,
    Map<String, dynamic> payload,
  ) {
    return session.copyWith(
      metadata: {
        ...session.metadata,
        'duel_matchmaking_status': 'timeout',
        'duel_timeout_offer_bot': payload['offerBot'] == true,
        'duel_bot_level_label': payload['botLevelLabel'],
        'duel_retry_allowed': payload['retryAllowed'] == true,
      },
    );
  }

  gamekit_session.GameSession applyDuelBotMatch(
    gamekit_session.GameSession session, {
    required String matchId,
    required String botLevelLabel,
  }) {
    return session.copyWith(
      metadata: {
        ...session.metadata,
        'duel_match_id': matchId,
        'duel_matchmaking_status': 'matched_bot',
        'duel_opponent_handle': 'gamekit_bot',
        'duel_opponent_level_label': botLevelLabel,
        'duel_opponent_is_bot': true,
        'duel_opponent_display_name': GamekitBotLabelCopy.title,
        'duel_exclude_from_leaderboard': true,
      },
    );
  }

  /// Request body for duel matchmaking — deliberately omits client level (AC4).
  Map<String, dynamic> buildDuelMatchRequest({
    required String requestId,
    required String language,
    required String skillId,
    required String gameId,
  }) {
    return {
      'requestId': requestId,
      'language': language,
      'skillId': skillId,
      'gameId': gameId,
    };
  }

  /// Create a GameKit session from parameters
  /// Used by GameScreenIntegration to eliminate manual session creation
  gamekit_session.GameSession createGameKitSession({
    required String sessionId,
    required String userId,
    required String gameId,
    required String language,
    String? level,
    required DateTime startTime,
    Map<String, dynamic>? performanceProfile,
  }) {
    return gamekit_session.GameSession(
      sessionId: sessionId,
      userId: userId,
      gameId: gameId,
      language: language,
      level: level ?? 'A2',
      startTime: startTime,
      turns: [],
      // Performance profile is calculated from turns, but we can store it in metadata if needed
      metadata: performanceProfile != null
          ? {'initial_performance': performanceProfile}
          : {},
    );
  }

  /// Clear game cache (for memory management)
  void clearCache() {
    _gameCache.clear();
  }

  /// Clear specific game from cache
  void clearGameCache(String gameId) {
    _gameCache.remove(gameId);
  }

  /// Get all available game IDs
  List<String> getAllGameIds() {
    return AllGamesRegistry.getAllGameIds();
  }

  /// Check if a game is available
  bool isGameAvailable(String gameId) {
    try {
      getGameConfig(gameId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Preload games for better performance
  Future<void> preloadGames(List<String> gameIds) async {
    for (final gameId in gameIds) {
      if (!_gameCache.containsKey(gameId)) {
        try {
          getGame(gameId); // This will cache the game
        } catch (e) {
          // Skip games that can't be loaded
          continue;
        }
      }
    }
  }
}

/// Provider for GameEngineService
final gameEngineServiceProvider = Provider<GameEngineService>((ref) {
  // Create PolieGameClient instance (no provider exists, create directly)
  final dio = ref.read(client);
  final polieClient = PolieGameClient(dio: dio);

  // Get Rive service and create guide controller
  final riveService = ref.read(riveGamificationServiceProvider);
  final guideController = RiveGameGuideController();
  riveService.setController(guideController);
  final animationBridge = GameAnimationBridge(guideController: guideController);

  return GameEngineService(
    polieClient: polieClient,
    animationBridge: animationBridge,
  );
});

/// Provider for getting a specific game instance by ID via GameKit
/// Note: This is different from providers/game_provider.dart which handles game sessions
final gameKitProvider = Provider.family<Game<dynamic, dynamic>, String>((
  ref,
  gameId,
) {
  final engineService = ref.read(gameEngineServiceProvider);
  return engineService.getGame(gameId);
});

/// Provider for getting game configuration
final gameKitConfigProvider = Provider.family<GameConfig, String>((
  ref,
  gameId,
) {
  final engineService = ref.read(gameEngineServiceProvider);
  return engineService.getGameConfig(gameId);
});
