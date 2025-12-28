import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game/phrase_card_model.dart';
import '../models/game/game_session_model.dart';
import '../providers/gamification_provider.dart';
import '../providers/api_provider.dart';
import '../providers/backend_sync_provider.dart';
import '../providers/user_provider.dart';
import '../providers/dio_provider.dart';
import '../utils/diacritics_enforcer.dart';
import '../utils/progress_integration.dart';
import '../utils/api.dart';
import '../services/telemetry_service.dart';
import 'base_provider.dart';

final gameProvider = NotifierProvider<GameProvider, BaseProviderState>(() {
  return GameProvider();
});

/// Game Provider - Manages all game sessions, SRS integration, and telemetry
class GameProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  GameSession? _currentSession;
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
    state = state.copyWith(isLoading: true);

    try {
      // Load cards for the game
      final cards = await _loadCardsForGame(language: language, level: level, count: cardCount ?? 10);

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

      // Send telemetry (legacy method for backward compatibility)
      await _sendTelemetry('game_start', {
        'session_id': sessionId,
        'game': gameType.name,
        'language': language,
        'level': level,
      });
      
      // Enhanced telemetry tracking
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

      // Award XP for starting game
      final gamification = ref.read(gamificationProvider.notifier);
      await gamification.awardXP('game_start');

      state = state.copyWith(isLoading: false);
      return _currentSession!;
    } catch (e) {
      debugPrint('Error starting game: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
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
      
      // Update SRS
      await _updateSRS(_currentSession!.userId, cardId, quality);

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
      debugPrint('Error completing turn: $e');
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
      debugPrint('Error ending game: $e');
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

    // Try to load from backend API
    try {
      final queryParams = <String, dynamic>{
        'language': language,
        'count': count,
      };
      if (level != null) queryParams['level'] = level;

      final response = await ref.read(client).get(
        '${Api.baseurl}api/games/cards',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        final dataList = response.data as List;
        for (var item in dataList) {
          if (item is Map<String, dynamic>) {
            try {
              cards.add(PhraseCard(
                cardId: item['id'] ?? item['card_id'] ?? 'card_${cards.length}',
                language: item['language'] ?? language,
                text: item['text'] ?? item['phrase'] ?? '',
                ascii: item['ascii'] ?? item['text'] ?? '',
                gloss: item['gloss'] ?? item['translation'] ?? item['meaning'] ?? '',
                level: item['level'] ?? level ?? 'A0',
                tags: (item['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                srs: _userSRS['${_currentSession?.userId ?? 'user'}_${item['id'] ?? cards.length}'] ?? SRSState(),
              ));
            } catch (e) {
              debugPrint('Error parsing card from API: $e');
              continue;
            }
          }
        }

        // If we got cards from API, apply diacritics enforcement and return
        if (cards.isNotEmpty) {
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
          return cards;
        }
      }
    } catch (e) {
      debugPrint('Error loading cards from API, using fallback: $e');
      // Continue to fallback
    }

    // Fallback to curated local data
    final fallbackCards = _generateFallbackCards(language, level, count);
    cards.addAll(fallbackCards);

    // Apply diacritics enforcement to all cards
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

    return cards;
  }

  /// Generate curated fallback cards (used when API is unavailable)
  List<PhraseCard> _generateFallbackCards(String language, String? level, int count) {
    final cards = <PhraseCard>[];
    final lang = language.toLowerCase();

    // Language-specific mock data
    final mockData = {
      'yoruba': [
        {'text': 'Báwo ní?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Ẹ káàrọ̀', 'gloss': 'Good morning', 'tags': ['greeting', 'morning']},
        {'text': 'Mo dúpé', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Ẹ ṣéun', 'gloss': 'Thank you (polite)', 'tags': ['gratitude', 'polite']},
        {'text': 'Báwo ni o?', 'gloss': 'How are you? (informal)', 'tags': ['greeting', 'informal']},
      ],
      'swahili': [
        {'text': 'Hujambo', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Asante', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Karibu', 'gloss': 'Welcome', 'tags': ['greeting']},
        {'text': 'Habari yako?', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Nzuri', 'gloss': 'Good', 'tags': ['response']},
      ],
      'hausa': [
        {'text': 'Sannu', 'gloss': 'Hello', 'tags': ['greeting']},
        {'text': 'Ina kwana', 'gloss': 'How are you?', 'tags': ['greeting']},
        {'text': 'Na gode', 'gloss': 'Thank you', 'tags': ['gratitude']},
        {'text': 'Barka da zuwa', 'gloss': 'Welcome', 'tags': ['greeting']},
        {'text': 'Lafiya lau?', 'gloss': 'Are you well?', 'tags': ['greeting']},
      ],
    };

    final data = mockData[lang] ?? mockData['yoruba']!;
    for (var i = 0; i < count && i < data.length; i++) {
      final item = data[i % data.length];
      cards.add(PhraseCard(
        cardId: '${lang}_card_${i}',
        language: language,
        text: item['text'] as String,
        ascii: item['text'] as String, // Simplified
        gloss: item['gloss'] as String,
        level: level ?? 'A0',
        tags: (item['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        srs: _userSRS['${_currentSession?.userId ?? 'user'}_${lang}_card_$i'] ?? SRSState(),
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

  /// Update SRS state for a card
  Future<void> _updateSRS(String userId, String cardId, int quality) async {
    final key = '${userId}_$cardId';
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

      final syncProvider = ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.gameSession,
        data: {
          'user_id': user.id.toString(),
          'session': session.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error queuing session sync: $e');
    }
  }

  /// Sync SRS to backend
  Future<void> _syncSRSToBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final syncProvider = ref.read(backendSyncProvider.notifier);
      final srsData = <String, dynamic>{};
      _userSRS.forEach((key, value) {
        srsData[key] = value.toJson();
      });

      await syncProvider.queueSync(SyncTask(
        type: SyncType.gameSRS,
        data: {
          'user_id': user.id.toString(),
          'srs': srsData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error queuing SRS sync: $e');
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
      debugPrint('Error sending telemetry: $e');
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
      debugPrint('Error saving session: $e');
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
      debugPrint('Error loading SRS: $e');
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
      debugPrint('Error saving SRS: $e');
    }
  }
}

