part of 'package:lingafriq/providers/game_provider.dart';

mixin GameProviderPersistenceMixin on Notifier<BaseProviderState> {
  GameProvider get _game => this as GameProvider;
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
Future<void> _updateSRS(
    String userId,
    String cardId,
    String language,
    int quality,
) async {
    final key = '${userId}_${cardId}_$language';
    final current = _game._userSRS[key] ?? SRSState();

    final now = DateTime.now();
    const scheduler = Fsrs6Scheduler.days();
    final reviewed = scheduler.review(
      MemoryState(
        stability: current.intervalDays > 0 ? current.intervalDays.toDouble() : null,
        difficulty: Fsrs6Scheduler.difficultyFromEase(current.ease),
        phase: current.intervalDays > 0 ? FsrsPhase.review : FsrsPhase.learning,
        lastReview: current.lastReview,
      ),
      FsrsRating.fromQuality(quality),
      now,
    );
    _game._userSRS[key] = SRSState(
      ease: Fsrs6Scheduler.easeFromDifficulty(reviewed.difficulty!),
      repetitions: quality < 3 ? 0 : current.repetitions + 1,
      intervalDays: reviewed.due!.difference(now).inDays.clamp(1, 36500),
      lastReview: now,
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
      await PersistedOutboxService.instance.enqueue(
          type: 'game_session_sync',
          data: {
          'user_id': user.id.toString(),
          'session': sessionJson,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      logger.error(
        'Error queuing session sync',
        tag: 'game-provider',
        error: e,
      );
    }
}

/// Sync SRS to backend via Sync v2 outbox (`game_srs_upsert_many`), matching
/// `applyGameSrsUpsertMany` in `syncV2.controller.ts`. Survives restarts via Hive.
/// Game SRS is queued on the durable outbox as `game_srs_upsert_many`.
Future<void> _syncSRSToBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final entries = <Map<String, dynamic>>[];
      final userIdPrefix = '${user.id}_';
      _game._userSRS.forEach((key, value) {
        if (!key.startsWith(userIdPrefix)) return;
        final rest = key.substring(userIdPrefix.length);
        final lastUnderscore = rest.lastIndexOf('_');
        if (lastUnderscore <= 0) return;
        final language = rest.substring(lastUnderscore + 1);
        if (language.isEmpty) return;
        final cardId = rest.substring(0, lastUnderscore);
        if (cardId.isEmpty) return;
        final lastReview = value.lastReview ?? DateTime.now();
        entries.add({
          'cardId': cardId,
          'language': language.toLowerCase(),
          'ease': value.ease,
          'repetitions': value.repetitions,
          'intervalDays': value.intervalDays < 1 ? 1 : value.intervalDays,
          'lastReview': lastReview.toUtc().toIso8601String(),
        });
      });

      if (entries.isEmpty) return;

      await PersistedOutboxService.instance.ensureOpen();
      await PersistedOutboxService.instance.enqueue(
        type: 'game_srs_upsert_many',
        payload: {'entries': entries},
      );
      // Flush is triggered when the app is online and by the periodic background task.
    } catch (e) {
      logger.error('Error enqueueing game_srs_upsert_many', tag: 'game-provider', error: e);
    }
}

/// Send telemetry event
Future<void> _sendTelemetry(String event, Map<String, dynamic> data) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      await PersistedOutboxService.instance.enqueue(
          type: 'telemetry_sync',
          data: {
          'user_id': user.id.toString(),
          'event': event,
          'timestamp': DateTime.now().toIso8601String(),
          ...data,
        },
      );
      
      // Also log locally for offline access
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('telemetry_log') ?? [];
      existing.add(
        jsonEncode({
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        ...data,
        }),
      );
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

Future<void> _recordGameCertification(GameSession session) async {
    try {
      final report = GameModeCertification(
        gameType: session.gameType,
        sessionId: session.sessionId,
        launchTelemetrySent: session.metadata['launch_telemetry_sent'] == true,
        turnTelemetrySent: session.metadata['turn_telemetry_sent'] == true,
        completionTelemetrySent:
            session.metadata['completion_telemetry_sent'] == true,
        hasTurns: session.totalTurns > 0,
        completed: session.endTime != null,
        updatedAt: DateTime.now(),
      );
      _game._modeCertifications[session.gameType] = report;
      await _saveModeCertifications();
    } catch (e) {
      logger.error(
        'Error recording game certification',
        tag: 'game-provider',
        error: e,
      );
    }
}

Future<void> _loadModeCertifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('game_mode_certifications');
      if (raw == null || raw.trim().isEmpty) return;

      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) return;

      _game._modeCertifications.clear();
      parsed.forEach((gameType, value) {
        if (value is! Map<String, dynamic>) return;
        final updatedAtRaw = value['updated_at']?.toString();
        final updatedAt =
            DateTime.tryParse(updatedAtRaw ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        _game._modeCertifications[gameType] = GameModeCertification(
          gameType: (value['game_type'] ?? gameType).toString(),
          sessionId: (value['session_id'] ?? '').toString(),
          launchTelemetrySent: value['launch_telemetry_sent'] == true,
          turnTelemetrySent: value['turn_telemetry_sent'] == true,
          completionTelemetrySent: value['completion_telemetry_sent'] == true,
          hasTurns: value['has_turns'] == true,
          completed: value['completed'] == true,
          updatedAt: updatedAt,
        );
      });
    } catch (e) {
      logger.error(
        'Error loading game certifications',
        tag: 'game-provider',
        error: e,
      );
    }
}

Future<void> _saveModeCertifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = <String, dynamic>{};
      _game._modeCertifications.forEach((gameType, report) {
        json[gameType] = report.toJson();
      });
      await prefs.setString('game_mode_certifications', jsonEncode(json));
    } catch (e) {
      logger.error(
        'Error saving game certifications',
        tag: 'game-provider',
        error: e,
      );
    }
}

/// Load user SRS state
Future<void> _loadUserSRS() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('user_srs');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _game._userSRS.clear();
        json.forEach((key, value) {
          _game._userSRS[key] = SRSState.fromJson(value as Map<String, dynamic>);
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
      _game._userSRS.forEach((key, value) {
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
      logger.info(
        'Warming up game content',
        tag: 'game-provider',
        context: {
        'gameType': gameType,
        'language': language,
        'difficulty': difficulty,
        },
      );

      // Preload cards for the game type
      if (language != null) {
        await _game._loadCardsForGame(
          language: language,
          level: difficulty,
          count: 20, // Preload more cards for warmup
        );
      }

      // Additional warmup logic can be added here (e.g., preload audio, images, etc.)
      logger.info(
        'Game content warmed up',
        tag: 'game-provider',
        context: {'gameType': gameType},
      );
    } catch (e) {
      logger.error(
        'Error warming up game content',
        tag: 'game-provider',
        error: e,
        context: {'gameType': gameType},
      );
      // Don't throw - warmup is optional
    }
}
}
