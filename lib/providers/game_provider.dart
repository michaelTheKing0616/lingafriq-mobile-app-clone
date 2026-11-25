import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game/phrase_card_model.dart';
import '../models/game/game_session_model.dart';
import '../models/game/game_content_failure.dart';
import '../providers/gamification_provider.dart';
import '../providers/user_provider.dart';
import '../services/learning/fsrs6_scheduler.dart';
import '../services/learning/memory_state.dart';
import '../services/offline/persisted_outbox_service.dart';
import '../providers/dio_provider.dart';
import '../utils/diacritics_enforcer.dart';
import '../utils/progress_integration.dart';
import '../services/telemetry_service.dart';
import 'base_provider.dart';
import '../utils/structured_logger.dart';
import '../utils/media_url_resolver.dart';
import '../data/language_words.dart';
import '../features/games/providers/game_mode_certification.dart';
part '../features/games/providers/game_provider_card_loader.dart';
part '../features/games/providers/game_provider_card_parse.dart';
part '../features/games/providers/game_provider_asset_repo.dart';
part '../features/games/providers/game_fallback_phrase_bank.dart';
part '../features/games/providers/game_fallback_phrase_bank_west.dart';
part '../features/games/providers/game_fallback_phrase_bank_east.dart';
part '../features/games/providers/game_provider_fallback_cards.dart';
part '../features/games/providers/game_provider_persistence.dart';


final gameProvider = NotifierProvider<GameProvider, BaseProviderState>(() {
  return GameProvider();
});

/// Game Provider - Manages all game sessions, SRS integration, and telemetry
class GameProvider extends Notifier<BaseProviderState> with BaseProviderMixin, GameProviderCardLoaderMixin, GameProviderCardParseMixin, GameProviderAssetRepoMixin, GameProviderFallbackMixin, GameProviderPersistenceMixin {
  static final Map<String, List<PhraseCard>> _cardCache = {};
  static Map<String, List<Map<String, dynamic>>>? _assetWordRepoByLanguage;
  static Map<String, Map<String, String>>? _assetEnglishToTargetByLanguage;
  /// Extra lookup table so UI labels like "Fula" can resolve to repo keys like "fula (fulfulde)".
  static final Map<String, String> _assetWordRepoAliasToCanonicalKey = {};

  GameSession? _currentSession;
  Completer<GameSession>? _startGameLock;
  final List<PhraseCard> _availableCards = [];
  final Map<String, SRSState> _userSRS = {}; // user_id + card_id -> SRSState
  final Map<String, GameModeCertification> _modeCertifications = {};
  GameContentFailure _lastContentFailure = GameContentFailure.none();

  GameSession? get currentSession => _currentSession;
  List<PhraseCard> get availableCards => List.unmodifiable(_availableCards);
  Map<String, GameModeCertification> get modeCertifications =>
      Map.unmodifiable(_modeCertifications);
  GameContentFailure get lastContentFailure => _lastContentFailure;

  @override
  BaseProviderState build() {
    _loadUserSRS();
    _loadModeCertifications();
    return BaseProviderState();
  }

  /// Start a new game session
  Future<GameSession> startGame({
    required String userId,
    required GameType gameType,
    required String language,
    String? level,
    int? cardCount,
  }) async {
    // Prevent a race where callers await the session Future but read `availableCards`
    // before `_availableCards` has been populated (duplicate start attempts during init).
    if (_startGameLock != null) {
      final existing = await _startGameLock!.future;
      if (_availableCards.isNotEmpty) return existing;
    }
    final completer = Completer<GameSession>();
    _startGameLock = completer;
    state = state.copyWith(isLoading: true);
    try {
      final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';

      // Load cards for the game
      final cards = await _loadCardsForGame(
        language: language,
        level: level,
        count: cardCount ?? 10,
        userId: userId,
        sessionId: sessionId,
        gameId: gameType.name,
      );

      // Expose loaded cards to game screens (they read gameProv.availableCards)
      _availableCards.clear();
      _availableCards.addAll(cards);
      _lastContentFailure = GameContentFailure.none();

      // Create session
      _currentSession = GameSession(
        sessionId: sessionId,
        userId: userId,
        gameType: gameType.name,
        language: language,
        level: level,
        startTime: DateTime.now(),
        metadata: {
          'cards': cards.map((c) => c.cardId).toList(),
          'game_type': gameType.name,
        },
      );

      // Non-critical: telemetry + gamification should never block gameplay
      try {
        await _sendTelemetry('game_start', {
          'session_id': sessionId,
          'game': gameType.name,
          'language': language,
          'level': level,
        });
        _currentSession = _currentSession!.copyWith(
          metadata: {
            ..._currentSession!.metadata,
            'launch_telemetry_sent': true,
          },
        );
        
        final telemetry = ref.read(telemetryServiceProvider);
        await telemetry.trackFeatureUsage(
          featureName: 'games',
          metadata: {
            'action': 'game_start',
            'game_type': gameType.name,
            'language': language,
            'level': level,
          },
        );

        final gamification = ref.read(gamificationProvider.notifier);
        await gamification.awardXP('game_start');
      } catch (e) {
        logger.error(
          'Non-critical telemetry/gamification error (game continues)',
          tag: 'game-provider',
          error: e,
        );
      }

      state = state.copyWith(isLoading: false);
      if (!completer.isCompleted) completer.complete(_currentSession!);
      return _currentSession!;
    } catch (e) {
      logger.error(
        'Error starting game',
        tag: 'game-provider',
        error: e,
        context: {'gameType': gameType},
      );
      state = state.copyWith(isLoading: false);
      if (!completer.isCompleted) completer.completeError(e);
      rethrow;
    } finally {
      _startGameLock = null;
    }
  }

  /// Complete a game turn
  Future<void> completeTurn({
    required String cardId,
    required GameResult result,
    required int durationMs,
    double? confidence,
    Map<String, dynamic>? feedback,
    String? userAction,
  }) async {
    if (_currentSession == null) return;

    try {
      final turn = GameTurn(
        cardId: cardId,
        userAction: userAction,
        result: result,
        durationMs: durationMs,
        confidence: confidence,
        feedback: feedback,
      );

      final updatedTurns = [..._currentSession!.turns, turn];
      _currentSession = _currentSession!.copyWith(turns: updatedTurns);

      // Map result to SRS quality (0-5)
      final quality = _mapResultToQuality(result, confidence);
      
      // Update SRS (include language for backend sync key)
      await _updateSRS(
        _currentSession!.userId,
        cardId,
        _currentSession!.language,
        quality,
      );

      // Send telemetry
      await _sendTelemetry('game_turn', {
        'session_id': _currentSession!.sessionId,
        'game': _currentSession!.gameType,
        'card_id': cardId,
        'result': result.name,
        'duration_ms': durationMs,
        'confidence': confidence,
        'quality': quality,
      });
      _currentSession = _currentSession!.copyWith(
        metadata: {..._currentSession!.metadata, 'turn_telemetry_sent': true},
      );

      // Award XP based on result
      final gamification = ref.read(gamificationProvider.notifier);
      if (result == GameResult.correct) {
        await gamification.awardXP('game_turn_correct');
      } else if (result == GameResult.partial) {
        await gamification.awardXP('game_turn_partial');
      }

      state = state.copyWith();
    } catch (e) {
      logger.error('Error completing turn', tag: 'game-provider', error: e);
    }
  }

  /// End game session
  Future<GameSession> endGame() async {
    if (_currentSession == null) {
      throw StateError('No active session');
    }

    try {
      final endedSession = _currentSession!.copyWith(endTime: DateTime.now());

      // Send telemetry (legacy method for backward compatibility)
      await _sendTelemetry('game_complete', {
        'session_id': endedSession.sessionId,
        'game': endedSession.gameType,
        'duration_ms': endedSession.durationMs,
        'accuracy': endedSession.accuracy,
        'correct_count': endedSession.correctCount,
        'total_turns': endedSession.totalTurns,
      });
      final withCompletionMetadata = endedSession.copyWith(
        metadata: {...endedSession.metadata, 'completion_telemetry_sent': true},
      );
      
      // Enhanced telemetry tracking
      final telemetry = ref.read(telemetryServiceProvider);
      await telemetry.trackGameSession(
        gameType: withCompletionMetadata.gameType,
        language: withCompletionMetadata.language,
        durationMs: withCompletionMetadata.durationMs,
        accuracy: withCompletionMetadata.accuracy,
        score: withCompletionMetadata.correctCount,
        turns: withCompletionMetadata.totalTurns,
      );

      // Award XP for completion
      final gamification = ref.read(gamificationProvider.notifier);
      await gamification.awardXP('game_complete');

      // Integrate with progress tracking
      await ProgressIntegration.onGameCompleted(
        ref,
        wordsLearned: withCompletionMetadata.correctCount,
        pointsEarned: (withCompletionMetadata.accuracy * 100).round(),
        perfect: withCompletionMetadata.accuracy >= 0.9,
      );

      // Save session
      await _saveSession(withCompletionMetadata);

      // Sync to backend
      await _syncSessionToBackend(withCompletionMetadata);
      await _recordGameCertification(withCompletionMetadata);

      _currentSession = null;
      state = state.copyWith();
      return withCompletionMetadata;
    } catch (e) {
      logger.error('Error ending game', tag: 'game-provider', error: e);
      rethrow;
    }
  }

  @visibleForTesting
  static GameContentFailure classifyGameContentFailure(
    Object error, {
    required GameContentFailureType defaultType,
    required String defaultMessage,
  }) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return GameContentFailure(
          type: GameContentFailureType.authFailure,
          message: 'Authentication failed while loading game content.',
          timestamp: DateTime.now(),
        );
      }
      if (status == 422) {
        return GameContentFailure(
          type: GameContentFailureType.parseFailure,
          message: 'Game content response validation failed.',
          timestamp: DateTime.now(),
        );
      }
    }

    return GameContentFailure(
      type: defaultType,
      message: defaultMessage,
      timestamp: DateTime.now(),
    );
  }
}
