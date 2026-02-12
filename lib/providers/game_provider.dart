import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game/phrase_card_model.dart';
import '../models/game/game_session_model.dart';
import '../providers/gamification_provider.dart';
import '../providers/backend_sync_provider.dart';
import '../providers/user_provider.dart';
import '../providers/dio_provider.dart';
import '../utils/diacritics_enforcer.dart';
import '../utils/progress_integration.dart';
import '../utils/api.dart';
import '../config/api_contract.dart';
import '../services/telemetry_service.dart';
import 'base_provider.dart';
import '../utils/structured_logger.dart';

final gameProvider = NotifierProvider<GameProvider, BaseProviderState>(() {
  return GameProvider();
});

/// Game Provider - Manages all game sessions, SRS integration, and telemetry
class GameProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  GameSession? _currentSession;
  Completer<GameSession>? _startGameLock;
  final List<PhraseCard> _availableCards = [];
  final Map<String, SRSState> _userSRS = {}; // user_id + card_id -> SRSState

  GameSession? get currentSession => _currentSession;
  List<PhraseCard> get availableCards => List.unmodifiable(_availableCards);

  @override
  BaseProviderState build() {
    _loadUserSRS();
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
    if (_startGameLock != null) {
      return _startGameLock!.future;
    }
    final completer = Completer<GameSession>();
    _startGameLock = completer;
    state = state.copyWith(isLoading: true);
    try {
      // Load cards for the game
      final cards = await _loadCardsForGame(language: language, level: level, count: cardCount ?? 10);

      // Expose loaded cards to game screens (they read gameProv.availableCards)
      _availableCards.clear();
      _availableCards.addAll(cards);

      // Create session
      final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
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
        logger.error('Non-critical telemetry/gamification error (game continues)', tag: 'game-provider', error: e);
      }

      state = state.copyWith(isLoading: false);
      if (!completer.isCompleted) completer.complete(_currentSession!);
      return _currentSession!;
    } catch (e) {
      logger.error('Error starting game', tag: 'game-provider', error: e, context: {'gameType': gameType});
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
      await _updateSRS(_currentSession!.userId, cardId, _currentSession!.language, quality);

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
      
      // Enhanced telemetry tracking
      final telemetry = ref.read(telemetryServiceProvider);
      await telemetry.trackGameSession(
        gameType: endedSession.gameType,
        language: endedSession.language,
        durationMs: endedSession.durationMs,
        accuracy: endedSession.accuracy,
        score: endedSession.correctCount,
        turns: endedSession.totalTurns,
      );

      // Award XP for completion
      final gamification = ref.read(gamificationProvider.notifier);
      await gamification.awardXP('game_complete');

      // Integrate with progress tracking
      await ProgressIntegration.onGameCompleted(
        ref,
        wordsLearned: endedSession.correctCount,
        pointsEarned: (endedSession.accuracy * 100).round(),
        perfect: endedSession.accuracy >= 0.9,
      );

      // Save session
      await _saveSession(endedSession);

      // Sync to backend
      await _syncSessionToBackend(endedSession);

      _currentSession = null;
      state = state.copyWith();
      return endedSession;
    } catch (e) {
      logger.error('Error ending game', tag: 'game-provider', error: e);
      rethrow;
    }
  }

  /// Load cards for a game
  /// Attempts to load from backend API, falls back to curated local data
  Future<List<PhraseCard>> _loadCardsForGame({
    required String language,
    String? level,
    int count = 10,
  }) async {
    final cards = <PhraseCard>[];

    // 1) Canonical route: POST /api/games/game-content
    // Backend mounts Polie game content under /api/games/*.
    try {
      final response = await ref.read(client).post(
        ApiContract.url(ApiContract.ai.polieGameContent),
        data: {
          'game_id': _currentSession?.gameType ?? 'phrase_cards',
          'language': language,
          'difficulty': level ?? 'A1',
          'user_id': _currentSession?.userId ?? 'guest',
          'session_id': _currentSession?.sessionId ?? 'local_session',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = response.data;
        if (payload is List) {
          for (final item in payload) {
            if (item is Map<String, dynamic>) {
              _appendCardFromMap(
                cards: cards,
                item: item,
                language: language,
                level: level,
              );
            }
          }
        } else if (payload is Map<String, dynamic>) {
          _appendCardFromMap(
            cards: cards,
            item: payload,
            language: language,
            level: level,
          );
        }

        if (cards.isNotEmpty) {
          // Pad to requested count with curated fallback cards.
          if (cards.length < count) {
            final needed = count - cards.length;
            cards.addAll(_generateFallbackCards(language, level, needed));
          } else if (cards.length > count) {
            cards.removeRange(count, cards.length);
          }

          try {
            for (var i = 0; i < cards.length; i++) {
              final card = cards[i];
              final enforced = DiacriticsEnforcer.enforceWithMetadata(
                card.text,
                language,
                enableFuzzy: true,
                fuzzyThreshold: 0.75,
              );
              if (enforced['changed'] == true) {
                cards[i] = card.copyWith(text: enforced['text'] as String);
              }
            }
          } catch (e) {
            logger.error(
              'Diacritics enforcement failed for canonical API cards (cards still usable)',
              tag: 'game-provider',
              error: e,
            );
          }

          return cards;
        }
      }
    } catch (e) {
      logger.error(
        'Error loading cards from canonical game-content API, trying legacy route',
        tag: 'game-provider',
        error: e,
      );
    }

    // 2) Legacy route: GET /api/games/cards (for backward compatibility)
    try {
      final queryParams = <String, dynamic>{
        'language': language,
        'count': count,
      };
      if (level != null) queryParams['level'] = level;

      final response = await ref.read(client).get(
        ApiContract.url(ApiContract.games.cards),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        final dataList = response.data as List;
        for (var item in dataList) {
          if (item is Map<String, dynamic>) {
            try {
              final cId = item['id'] ?? item['card_id'] ?? 'card_${cards.length}';
              final lang = item['language'] ?? language;
              cards.add(PhraseCard(
                cardId: cId.toString(),
                language: lang.toString(),
                text: item['text'] ?? item['phrase'] ?? '',
                ascii: item['ascii'] ?? item['text'] ?? '',
                gloss: item['gloss'] ?? item['translation'] ?? item['meaning'] ?? '',
                level: item['level'] ?? level ?? 'A0',
                tags: (item['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                srs: _userSRS['${_currentSession?.userId ?? 'user'}_${cId}_$lang'] ?? SRSState(),
              ));
            } catch (e) {
              logger.error('Error parsing card from API', tag: 'game-provider', error: e);
              continue;
            }
          }
        }

        // If we got cards from API, apply diacritics enforcement and return
        if (cards.isNotEmpty) {
          try {
            for (var i = 0; i < cards.length; i++) {
              final card = cards[i];
              final enforced = DiacriticsEnforcer.enforceWithMetadata(
                card.text,
                language,
                enableFuzzy: true,
                fuzzyThreshold: 0.75,
              );

              if (enforced['changed'] == true) {
                cards[i] = card.copyWith(text: enforced['text'] as String);
              }
            }
          } catch (e) {
            logger.error('Diacritics enforcement failed for API cards (cards still usable)', tag: 'game-provider', error: e);
          }
          return cards;
        }
      }
    } catch (e) {
      logger.error('Error loading cards from API, using fallback', tag: 'game-provider', error: e);
      // Continue to fallback
    }

    // Fallback to curated local data
    final fallbackCards = _generateFallbackCards(language, level, count);
    cards.addAll(fallbackCards);

    // Apply diacritics enforcement to all cards (non-fatal — cards work without it)
    try {
      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        final enforced = DiacriticsEnforcer.enforceWithMetadata(
          card.text,
          language,
          enableFuzzy: true,
          fuzzyThreshold: 0.75,
        );

        if (enforced['changed'] == true) {
          cards[i] = card.copyWith(text: enforced['text'] as String);
        }
      }
    } catch (e) {
      logger.error('Diacritics enforcement failed (cards still usable)', tag: 'game-provider', error: e);
    }

    return cards;
  }

  void _appendCardFromMap({
    required List<PhraseCard> cards,
    required Map<String, dynamic> item,
    required String language,
    required String? level,
  }) {
    final cardId = (item['id'] ?? item['card_id'] ?? item['content_id'] ?? 'card_${cards.length}').toString();
    final lang = (item['language'] ?? language).toString();
    final text = (item['text'] ?? item['phrase'] ?? item['content'] ?? '').toString();
    final gloss = (item['gloss'] ?? item['translation'] ?? item['meaning'] ?? '').toString();
    final parsedLevel = (item['level'] ?? level ?? 'A0').toString();

    if (text.trim().isEmpty) return;

    cards.add(PhraseCard(
      cardId: cardId,
      language: lang,
      text: text,
      ascii: (item['ascii'] ?? text).toString(),
      gloss: gloss,
      level: parsedLevel,
      tags: (item['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['ai-generated'],
      srs: _userSRS['${_currentSession?.userId ?? 'user'}_${cardId}_$lang'] ?? SRSState(),
    ));
  }

  /// Generate curated fallback cards (used only when API is unavailable and no cached data exists)
  List<PhraseCard> _generateFallbackCards(String language, String? level, int count) {
    final cards = <PhraseCard>[];
    final lang = language.toLowerCase();

    // Curated fallback phrase bank (offline-first; used only when backend is unreachable).
    final fallbackData = <String, List<Map<String, dynamic>>>{
      'yoruba': [
        {'text': 'Báwo ní?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Ẹ káàrọ̀', 'gloss': 'Good morning', 'tags': ['greeting', 'morning']},
        {'text': 'Mo dúpé', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Ẹ ṣéun', 'gloss': 'Thank you (polite)', 'tags': ['gratitude', 'polite']},
        {'text': 'Báwo ni o?', 'gloss': 'How are you? (informal)', 'tags': ['greeting', 'informal']},
        {'text': 'Mo fẹ́ kọ́ Yorùbá', 'gloss': 'I want to learn Yoruba', 'tags': ['learning']},
        {'text': 'Nibo ni ilé-ìtajà wà?', 'gloss': 'Where is the market?', 'tags': ['travel']},
        {'text': 'Ẹ jọ̀ọ́, ẹ ran mi lọ́wọ́', 'gloss': 'Please, help me', 'tags': ['polite']},
      ],
      'swahili': [
        {'text': 'Hujambo', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Asante', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Karibu', 'gloss': 'Welcome', 'tags': ['greeting']},
        {'text': 'Habari yako?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Nzuri', 'gloss': 'Good', 'tags': ['response']},
        {'text': 'Tafadhali', 'gloss': 'Please', 'tags': ['polite']},
        {'text': 'Ninakupenda', 'gloss': 'I love you', 'tags': ['social']},
        {'text': 'Chakula ni kitamu', 'gloss': 'The food is delicious', 'tags': ['food']},
      ],
      'hausa': [
        {'text': 'Sannu', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Ina kwana', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Na gode', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Barka da zuwa', 'gloss': 'Welcome', 'tags': ['greeting']},
        {'text': 'Lafiya lau?', 'gloss': 'Are you well?', 'tags': ['greeting']},
        {'text': 'Don Allah', 'gloss': 'Please', 'tags': ['polite']},
        {'text': 'Ina so in koya Hausa', 'gloss': 'I want to learn Hausa', 'tags': ['learning']},
        {'text': 'Ina kasuwa?', 'gloss': 'Where is the market?', 'tags': ['travel']},
      ],
      'igbo': [
        {'text': 'Ndewo', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Kedu?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Daalụ', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Biko', 'gloss': 'Please', 'tags': ['polite']},
        {'text': 'Aha m bụ...', 'gloss': 'My name is...', 'tags': ['intro']},
        {'text': 'Ebee ka ahịa dị?', 'gloss': 'Where is the market?', 'tags': ['travel']},
        {'text': 'Achọrọ m ịmụ Igbo', 'gloss': 'I want to learn Igbo', 'tags': ['learning']},
        {'text': 'Ọ dị mma', 'gloss': 'It is good / okay', 'tags': ['response']},
      ],
      'zulu': [
        {'text': 'Sawubona', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Unjani?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Ngiyabonga', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Ngiyacela', 'gloss': 'Please', 'tags': ['polite']},
        {'text': 'Igama lami ngu...', 'gloss': 'My name is...', 'tags': ['intro']},
        {'text': 'Uphi umakethe?', 'gloss': 'Where is the market?', 'tags': ['travel']},
        {'text': 'Ngifuna ukufunda isiZulu', 'gloss': 'I want to learn Zulu', 'tags': ['learning']},
        {'text': 'Kulungile', 'gloss': 'Okay', 'tags': ['response']},
      ],
      'xhosa': [
        {'text': 'Molo', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Unjani?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Enkosi', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Nceda', 'gloss': 'Please / Help', 'tags': ['polite']},
        {'text': 'Igama lam ngu...', 'gloss': 'My name is...', 'tags': ['intro']},
        {'text': 'Iphi imarike?', 'gloss': 'Where is the market?', 'tags': ['travel']},
        {'text': 'Ndifuna ukufunda isiXhosa', 'gloss': 'I want to learn Xhosa', 'tags': ['learning']},
        {'text': 'Kulungile', 'gloss': 'Okay', 'tags': ['response']},
      ],
      'amharic': [
        {'text': 'ሰላም', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'እንዴት ነህ?', 'gloss': 'How are you? (m)', 'tags': ['greeting']},
        {'text': 'እንዴት ነሽ?', 'gloss': 'How are you? (f)', 'tags': ['greeting']},
        {'text': 'አመሰግናለሁ', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'እባክህ', 'gloss': 'Please (m)', 'tags': ['polite']},
        {'text': 'እባክሽ', 'gloss': 'Please (f)', 'tags': ['polite']},
        {'text': 'ስሜ ... ነው', 'gloss': 'My name is ...', 'tags': ['intro']},
        {'text': 'ገበያ የት ነው?', 'gloss': 'Where is the market?', 'tags': ['travel']},
      ],
      'twi': [
        {'text': 'Maakye', 'gloss': 'Good morning', 'tags': ['greeting', 'morning']},
        {'text': 'Maaha', 'gloss': 'Good afternoon', 'tags': ['greeting']},
        {'text': 'Maadwo', 'gloss': 'Good evening', 'tags': ['greeting']},
        {'text': 'Medaase', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Mepa wo kyɛw', 'gloss': 'Please', 'tags': ['polite']},
        {'text': 'Wo ho te sɛn?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Mepɛ sɛ me sua Twi', 'gloss': 'I want to learn Twi', 'tags': ['learning']},
        {'text': 'Daben na ɛhe?', 'gloss': 'Where is the market?', 'tags': ['travel']},
      ],
      'afrikaans': [
        {'text': 'Hallo', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Hoe gaan dit?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Dankie', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Asseblief', 'gloss': 'Please', 'tags': ['polite']},
        {'text': 'My naam is ...', 'gloss': 'My name is ...', 'tags': ['intro']},
        {'text': 'Waar is die mark?', 'gloss': 'Where is the market?', 'tags': ['travel']},
        {'text': 'Ek wil Afrikaans leer', 'gloss': 'I want to learn Afrikaans', 'tags': ['learning']},
        {'text': 'Dit is lekker', 'gloss': 'This is nice/delicious', 'tags': ['social']},
      ],
      'pidgin': [
        {'text': 'How you dey?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'I dey fine', 'gloss': 'I am fine', 'tags': ['response']},
        {'text': 'Abeg', 'gloss': 'Please', 'tags': ['polite']},
        {'text': 'Thanks', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'My name na ...', 'gloss': 'My name is ...', 'tags': ['intro']},
        {'text': 'Where market dey?', 'gloss': 'Where is the market?', 'tags': ['travel']},
        {'text': 'I wan learn Pidgin', 'gloss': 'I want to learn Pidgin', 'tags': ['learning']},
        {'text': 'No wahala', 'gloss': 'No problem', 'tags': ['social']},
      ],
      'wolof': [
        {'text': 'Salaam aleekum', 'gloss': 'Peace be upon you', 'tags': ['greeting']},
        {'text': 'Maalekum salaam', 'gloss': 'And peace be upon you', 'tags': ['response']},
        {'text': 'Nanga def?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Jërëjëf', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Ba beneen yoon', 'gloss': 'See you later', 'tags': ['farewell']},
        {'text': 'Tudd naa ...', 'gloss': 'My name is ...', 'tags': ['intro']},
        {'text': 'Ana marché bi?', 'gloss': 'Where is the market?', 'tags': ['travel']},
        {'text': 'Dama bëgg jàng Wolof', 'gloss': 'I want to learn Wolof', 'tags': ['learning']},
      ],
      'somali': [
        {'text': 'Salaan', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Sidee tahay?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Mahadsanid', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Fadlan', 'gloss': 'Please', 'tags': ['polite']},
        {'text': 'Magacaygu waa ...', 'gloss': 'My name is ...', 'tags': ['intro']},
        {'text': 'Suuqa xaggee buu yahay?', 'gloss': 'Where is the market?', 'tags': ['travel']},
        {'text': 'Waxaan rabaa inaan barto Soomaali', 'gloss': 'I want to learn Somali', 'tags': ['learning']},
        {'text': 'Waa hagaag', 'gloss': 'Okay', 'tags': ['response']},
      ],
    };

      final data = fallbackData[lang] ?? fallbackData['yoruba']!;
    for (var i = 0; i < count; i++) {
      final item = data[i % data.length];
      final cardId = '${lang}_card_$i';
      cards.add(PhraseCard(
        cardId: cardId,
        language: language,
        text: item['text'] as String,
        ascii: item['text'] as String, // Simplified
        gloss: item['gloss'] as String,
        level: level ?? 'A0',
        tags: (item['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        srs: _userSRS['${_currentSession?.userId ?? 'user'}_${cardId}_$language'] ?? SRSState(),
      ));
    }

    return cards;
  }

  /// Map game result to SRS quality (0-5)
  int _mapResultToQuality(GameResult result, double? confidence) {
    switch (result) {
      case GameResult.correct:
        if (confidence != null) {
          if (confidence >= 0.95) return 5; // Perfect
          if (confidence >= 0.85) return 4; // Minor mistakes
          return 3; // Moderate
        }
        return 4; // Default for correct
      case GameResult.partial:
        return 3; // Moderate
      case GameResult.incorrect:
        return 2; // Major mistakes
      case GameResult.timeout:
        return 1; // No recall
      case GameResult.skipped:
        return 0; // System error / skipped
    }
  }

  /// Update SRS state for a card. Key includes language for backend sync (cardId_language).
  Future<void> _updateSRS(String userId, String cardId, String language, int quality) async {
    final key = '${userId}_${cardId}_$language';
    final current = _userSRS[key] ?? SRSState();

    // SM-2 algorithm variant
    double newEase = current.ease;
    int newRepetitions = current.repetitions;
    int newInterval = current.intervalDays;

    if (quality >= 3) {
      // Successful recall
      if (newRepetitions == 0) {
        newInterval = 1;
      } else if (newRepetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (newInterval * newEase).round();
      }
      newRepetitions += 1;
      newEase = newEase + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEase < 1.3) newEase = 1.3;
    } else {
      // Failed recall - reset
      newRepetitions = 0;
      newInterval = 1;
      newEase = current.ease * 0.8;
      if (newEase < 1.3) newEase = 1.3;
    }

    _userSRS[key] = SRSState(
      ease: newEase,
      repetitions: newRepetitions,
      intervalDays: newInterval,
      lastReview: DateTime.now(),
    );

    await _saveUserSRS();
    
    // Sync SRS to backend
    await _syncSRSToBackend();
  }

  /// Sync session to backend
  Future<void> _syncSessionToBackend(GameSession session) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final sessionJson = session.toJson();
      sessionJson['duration_ms'] = session.durationMs;
      sessionJson['accuracy'] = session.accuracy;
      sessionJson['correct_count'] = session.correctCount;
      sessionJson['total_turns'] = session.totalTurns;
      final syncProvider = ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.gameSession,
        data: {
          'user_id': user.id.toString(),
          'session': sessionJson,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      logger.error('Error queuing session sync', tag: 'game-provider', error: e);
    }
  }

  /// Sync SRS to backend. Sends keys as "cardId|language" so backend can parse card_id and language.
  Future<void> _syncSRSToBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final syncProvider = ref.read(backendSyncProvider.notifier);
      final srsData = <String, dynamic>{};
      final userIdPrefix = '${user.id}_';
      _userSRS.forEach((key, value) {
        if (!key.startsWith(userIdPrefix)) return;
        final rest = key.substring(userIdPrefix.length);
        final lastUnderscore = rest.lastIndexOf('_');
        if (lastUnderscore <= 0) return;
        final language = rest.substring(lastUnderscore + 1);
        if (language.isEmpty) return;
        final cardId = rest.substring(0, lastUnderscore);
        srsData['$cardId|$language'] = value.toJson();
      });

      if (srsData.isEmpty) return;

      await syncProvider.queueSync(SyncTask(
        type: SyncType.gameSRS,
        data: {
          'user_id': user.id.toString(),
          'srs': srsData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      logger.error('Error queuing SRS sync', tag: 'game-provider', error: e);
    }
  }

  /// Send telemetry event
  Future<void> _sendTelemetry(String event, Map<String, dynamic> data) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final syncProvider = ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.telemetry,
        data: {
          'user_id': user.id.toString(),
          'event': event,
          'timestamp': DateTime.now().toIso8601String(),
          ...data,
        },
      ));
      
      // Also log locally for offline access
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('telemetry_log') ?? [];
      existing.add(jsonEncode({
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        ...data,
      }));
      await prefs.setStringList('telemetry_log', existing);
    } catch (e) {
      logger.error('Error sending telemetry', tag: 'game-provider', error: e);
    }
  }

  /// Save session
  Future<void> _saveSession(GameSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('game_sessions') ?? [];
      existing.add(jsonEncode(session.toJson()));
      await prefs.setStringList('game_sessions', existing);
    } catch (e) {
      logger.error('Error saving session', tag: 'game-provider', error: e);
    }
  }

  /// Load user SRS state
  Future<void> _loadUserSRS() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('user_srs');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _userSRS.clear();
        json.forEach((key, value) {
          _userSRS[key] = SRSState.fromJson(value as Map<String, dynamic>);
        });
      }
    } catch (e) {
      logger.error('Error loading SRS', tag: 'game-provider', error: e);
    }
  }

  /// Save user SRS state
  Future<void> _saveUserSRS() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = <String, dynamic>{};
      _userSRS.forEach((key, value) {
        json[key] = value.toJson();
      });
      await prefs.setString('user_srs', jsonEncode(json));
    } catch (e) {
      logger.error('Error saving SRS', tag: 'game-provider', error: e);
    }
  }

  /// Warm up game content for a specific game type
  /// Preloads game data, cards, and assets to improve initial load time
  Future<void> warmupGameContent({
    required String gameType,
    String? language,
    String? difficulty,
  }) async {
    try {
      logger.info('Warming up game content', tag: 'game-provider', context: {
        'gameType': gameType,
        'language': language,
        'difficulty': difficulty,
      });

      // Preload cards for the game type
      if (language != null) {
        await _loadCardsForGame(
          language: language,
          level: difficulty,
          count: 20, // Preload more cards for warmup
        );
      }

      // Additional warmup logic can be added here (e.g., preload audio, images, etc.)
      logger.info('Game content warmed up', tag: 'game-provider', context: {'gameType': gameType});
    } catch (e) {
      logger.error('Error warming up game content', tag: 'game-provider', error: e, context: {
        'gameType': gameType,
      });
      // Don't throw - warmup is optional
    }
  }
}

