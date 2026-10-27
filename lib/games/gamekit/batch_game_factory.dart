import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'game_engine.dart';
import 'game_animation_bridge.dart';
import '../../models/game/game_content_failure.dart';
import '../../models/game/game_content_models.dart';
import '../../models/verified_lexeme.dart';
import '../../services/lexicon_lookup_service.dart';
import '../../services/offline/lexicon_pack_service.dart';
import '../../services/polie_game_client.dart';
import '../../services/rive_gamification_service.dart';
import '../../utils/api_service.dart';
import '../animation/rive_game_guide.dart';
import 'game_scoring.dart';
import 'game_feedback.dart';
import 'game_difficulty.dart';
import 'game_migration_helper.dart';
import 'game_turn_context.dart';

/// Fetches ranked lexicon rows for GameKit (verified lexicon API or offline pack).
typedef GameLexiconPoolFetch = Future<List<VerifiedLexeme>> Function(
  String languageCode, {
  required int limit,
});

void _logGameKitAudioExcluded(String lexemeId) {
  if (kDebugMode) {
    debugPrint('gamekit.pool.audio_excluded lexeme_id=$lexemeId');
  }
}

@visibleForTesting
String gameLexiconLicenceTag(VerifiedLexeme lexeme) {
  final audio = lexeme.raw['audio'];
  if (audio is List) {
    for (final clip in audio) {
      if (clip is Map) {
        final licence = clip['licence_id'] ?? clip['licence'];
        if (licence is String && licence.trim().isNotEmpty) {
          return licence.trim();
        }
        final kind = clip['kind'];
        if (kind is String && kind.trim().isNotEmpty) {
          return kind.trim();
        }
      }
    }
  }
  if (lexeme.verificationStatus.trim().isNotEmpty) {
    return lexeme.verificationStatus.trim();
  }
  return 'verification_unknown';
}

@visibleForTesting
String? gameLexiconPrimaryAudioUri(VerifiedLexeme lexeme) {
  if (lexeme.audioUris.isNotEmpty) {
    final uri = lexeme.audioUris.first.trim();
    if (uri.isNotEmpty) return uri;
  }
  final audio = lexeme.raw['audio'];
  if (audio is List) {
    for (final clip in audio) {
      if (clip is Map) {
        final uri = clip['uri'];
        if (uri is String && uri.trim().isNotEmpty) {
          return uri.trim();
        }
      }
    }
  }
  return null;
}

@visibleForTesting
GameLexiconPoolItem verifiedLexemeToPoolItem(VerifiedLexeme lexeme) {
  final form = lexeme.standardOrthography.trim().isNotEmpty
      ? lexeme.standardOrthography.trim()
      : lexeme.lemma.trim();
  return GameLexiconPoolItem(
    id: lexeme.lexemeId,
    language: lexeme.language,
    toneMarkedForm: form,
    audioUri: gameLexiconPrimaryAudioUri(lexeme),
    licenceTag: gameLexiconLicenceTag(lexeme),
    englishGloss: lexeme.exampleSentence,
  );
}

@visibleForTesting
List<VerifiedLexeme> lexiconPoolFromPack({
  required InstalledLexiconPack pack,
  required String languageCode,
  required int limit,
}) {
  if (pack.manifest.language.trim().toLowerCase() !=
      languageCode.trim().toLowerCase()) {
    return const [];
  }
  final sorted = List<LexiconPackEntry>.from(pack.entries)
    ..sort((a, b) => a.adjustedRank.compareTo(b.adjustedRank));
  return sorted
      .take(limit)
      .map(
        (row) => verifiedLexemeFromPackRow(row, languageCode: languageCode),
      )
      .toList();
}

Future<List<VerifiedLexeme>> _defaultLexiconPoolFetch(
  String languageCode, {
  required int limit,
}) async {
  await ApiService.initialize();
  try {
    final response = await ApiService.get(
      verifiedLexiconSearchPath,
      queryParameters: {
        'language': languageCode.trim().toLowerCase(),
        'q': '',
        'limit': limit.clamp(1, 100).toString(),
      },
    );
    if (response.statusCode != 200) return const [];
    final body = response.data;
    if (body is! Map) return const [];
    final entries = body['entries'];
    if (entries is! List) return const [];
    final out = <VerifiedLexeme>[];
    for (final row in entries) {
      if (row is Map<String, dynamic>) {
        out.add(VerifiedLexeme.fromApiJson(row));
      } else if (row is Map) {
        out.add(VerifiedLexeme.fromApiJson(row.cast<String, dynamic>()));
      }
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Builds GameKit word pools from verified lexicon (never legacy bundled seed JSON).
class GameLexiconPoolBuilder {
  GameLexiconPoolBuilder({
    GameLexiconPoolFetch? fetch,
    LexiconPackService? packService,
  })  : _fetch = fetch ?? _defaultLexiconPoolFetch,
        _packService = packService;

  final GameLexiconPoolFetch _fetch;
  final LexiconPackService? _packService;

  Future<GameLexiconPoolBuildResult> build(GameLexiconPoolRequest request) async {
    final lang = request.languageCode.trim().toLowerCase();
    if (lang.isEmpty) {
      return GameLexiconPoolBuildResult(
        items: const [],
        failure: GameContentFailure(
          type: GameContentFailureType.parseFailure,
          message: 'Choose a language before starting this game.',
          timestamp: DateTime.now(),
        ),
        excludedMissingAudio: 0,
        queriedCount: 0,
        source: 'none',
      );
    }

    final limit = request.fetchLimit.clamp(request.minimumItems, 100);
    var source = 'verified_lexicon_api';
    var lexemes = await _fetch(lang, limit: limit);

    final pack = _packService?.activePack;
    if (lexemes.isEmpty && pack != null) {
      lexemes = lexiconPoolFromPack(
        pack: pack,
        languageCode: lang,
        limit: limit,
      );
      if (lexemes.isNotEmpty) {
        source = 'offline_lexicon_pack';
      }
    } else if (pack != null && lexemes.length < request.minimumItems) {
      final merged = <String, VerifiedLexeme>{};
      for (final row in lexemes) {
        merged[row.lexemeId] = row;
      }
      for (final row in lexiconPoolFromPack(
        pack: pack,
        languageCode: lang,
        limit: limit,
      )) {
        merged[row.lexemeId] = row;
      }
      lexemes = merged.values.toList();
      if (merged.isNotEmpty) {
        source = 'verified_lexicon_api+offline_lexicon_pack';
      }
    }

    if (lexemes.isEmpty) {
      return GameLexiconPoolBuildResult(
        items: const [],
        failure: GameContentFailure(
          type: GameContentFailureType.noContent,
          message:
              'We could not load words for this language yet. Check your connection or download the lexicon pack, then try again.',
          timestamp: DateTime.now(),
        ),
        excludedMissingAudio: 0,
        queriedCount: 0,
        source: source,
      );
    }

    final poolItems = <GameLexiconPoolItem>[];
    var excludedAudio = 0;
    for (final lexeme in lexemes) {
      final item = verifiedLexemeToPoolItem(lexeme);
      if (request.requireAudio && !item.hasPlayableAudio) {
        excludedAudio++;
        _logGameKitAudioExcluded(item.id);
        continue;
      }
      poolItems.add(item);
    }

    if (poolItems.length < request.minimumItems) {
      return GameLexiconPoolBuildResult(
        items: poolItems,
        failure: GameContentFailure(
          type: GameContentFailureType.insufficientPool,
          message:
              'Not enough words with audio are ready for this game yet (${poolItems.length} of ${request.minimumItems} needed). Try another mode or check back after more lexicon audio is verified.',
          timestamp: DateTime.now(),
        ),
        excludedMissingAudio: excludedAudio,
        queriedCount: lexemes.length,
        source: source,
      );
    }

    return GameLexiconPoolBuildResult(
      items: poolItems,
      failure: GameContentFailure.none(),
      excludedMissingAudio: excludedAudio,
      queriedCount: lexemes.length,
      source: source,
    );
  }
}

/// Factory for creating standard game engines for all games
/// This ensures consistency across all 35+ games
class BatchGameFactory {
  static final GameLexiconPoolBuilder _lexiconPoolBuilder =
      GameLexiconPoolBuilder();

  /// Verified-lexicon word pool for any GameKit title (P8-912).
  static Future<GameLexiconPoolBuildResult> buildLexiconWordPool(
    GameLexiconPoolRequest request, {
    GameLexiconPoolFetch? fetch,
    LexiconPackService? packService,
  }) {
    final builder = fetch != null || packService != null
        ? GameLexiconPoolBuilder(fetch: fetch, packService: packService)
        : _lexiconPoolBuilder;
    return builder.build(request);
  }

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

