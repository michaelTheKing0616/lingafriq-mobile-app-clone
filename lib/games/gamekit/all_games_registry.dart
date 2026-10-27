import 'generic_game_template.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart' show GameTypeExtension, GameType;
import '../../screens/games/game_catalog.dart';
import 'game_engine.dart';

/// Skill shelves in the Arcade hub (P8-914 / P8-917).
enum ArcadeSkillShelf {
  tone('tone', 'Tone & pitch'),
  listening('listening', 'Listening'),
  speaking('speaking', 'Speaking'),
  vocabulary('vocabulary', 'Words'),
  grammar('grammar', 'Grammar'),
  culture('culture', 'Culture'),
  traditional('traditional', 'Traditional play');

  const ArcadeSkillShelf(this.id, this.title);
  final String id;
  final String title;
}

/// Hub listing for one playable game (elevation card id only — §18.5).
class ArcadeGameListing {
  const ArcadeGameListing({
    required this.gameId,
    required this.shelf,
    required this.elevationCardId,
    this.featured = false,
    this.elevationPending = true,
    this.routeGameType,
  });

  final String gameId;
  final ArcadeSkillShelf shelf;
  final String elevationCardId;
  final bool featured;
  final bool elevationPending;
  final GameType? routeGameType;
}

/// Registry of all 37+ games with their configurations
/// This centralizes game definitions for easy migration
class AllGamesRegistry {
  static const String toneForgeGameId = 'tone_forge';

  static const Map<String, String> _canonicalAliases = {
    // Legacy/alternate IDs -> canonical GameType.name IDs
    'wordmatch_audio': 'wordmatch_audio',
    'speed_round': 'speed_round_remix',
    'clan_story': 'clan_lineage_story_builder',
    'market_bargaining': 'market_bargaining_simulator',
    'taxi_survival': 'taxi_bus_stop_survival',
    'call_response': 'call_and_response',
    'greeting_diplomacy': 'greeting_diplomacy_challenge',
    'folktale': 'folktale_reconstruction',
    'accent_puzzle': 'accent_decoding_puzzle',
    'tongue_twister': 'rapid_tongue_twister_race',
    'elders_blessings': 'elders_blessings_challenge',
    'multilingual_relay': 'multilingual_relay_race',
    'cultural_etiquette': 'cultural_etiquette_scenarios',
    'drum_word': 'drum_to_word_matching',
    'listen_sketch': 'listen_and_sketch',
    'picture_word': 'picture_word_association',
  };

  /// Canonical game definitions keyed by GameType.name.
  static final Map<String, GameDefinition> games = {
    for (final entry in GameCatalog.entries)
      entry.type.name: GameDefinition(
        gameId: entry.type.name,
        displayName: entry.name,
        learningGoals: _deriveLearningGoals(entry),
        coreVerb: _inferCoreVerb(entry.type.name, entry),
      ),
    toneForgeGameId: GameDefinition(
      gameId: toneForgeGameId,
      displayName: 'Tone Forge',
      learningGoals: const ['tones', 'pronunciation', 'listening'],
      coreVerb: GameCoreVerb.choose,
    ),
  };

  static final Map<String, ArcadeGameListing> _arcadeListings = {
    toneForgeGameId: ArcadeGameListing(
      gameId: toneForgeGameId,
      shelf: ArcadeSkillShelf.tone,
      elevationCardId: 'P8-914',
      featured: true,
      elevationPending: false,
      routeGameType: GameType.toneTrainer,
    ),
    for (final entry in GameCatalog.entries)
      entry.type.name: ArcadeGameListing(
        gameId: entry.type.name,
        shelf: _shelfForCatalogEntry(entry),
        elevationCardId: _elevationCardFor(entry.type.name),
        featured: false,
        elevationPending: true,
        routeGameType: entry.type,
      ),
  };

  static ArcadeSkillShelf _shelfForCatalogEntry(GameCatalogEntry entry) {
    final category = entry.category.toLowerCase();
    final id = entry.type.name.toLowerCase();
    if (id.contains('tone') || category.contains('pronunciation')) {
      return ArcadeSkillShelf.tone;
    }
    if (id.contains('drum') ||
        id.contains('listen') ||
        id.contains('accent') ||
        category.contains('listening')) {
      return ArcadeSkillShelf.listening;
    }
    if (id.contains('pronunciation') ||
        id.contains('karaoke') ||
        id.contains('tongue') ||
        id.contains('call_and')) {
      return ArcadeSkillShelf.speaking;
    }
    if (id.contains('ayo') ||
        id.contains('suwe') ||
        id.contains('ludo') ||
        id.contains('snakes') ||
        id.contains('whot')) {
      return ArcadeSkillShelf.traditional;
    }
    if (category.contains('cultural')) return ArcadeSkillShelf.culture;
    if (category.contains('grammar')) return ArcadeSkillShelf.grammar;
    return ArcadeSkillShelf.vocabulary;
  }

  static String _elevationCardFor(String gameId) {
    return 'P8-917';
  }

  static List<ArcadeGameListing> listingsOnShelf(ArcadeSkillShelf shelf) {
    return _arcadeListings.values
        .where((l) => l.shelf == shelf)
        .toList(growable: false);
  }

  static ArcadeGameListing? listingFor(String gameId) {
    final normalized = gameId.trim();
    final direct = _arcadeListings[normalized];
    if (direct != null) return direct;
    final alias = _canonicalAliases[normalized];
    if (alias != null) return _arcadeListings[alias];
    return null;
  }

  static ArcadeGameListing? featuredOnShelf(ArcadeSkillShelf shelf) {
    for (final listing in _arcadeListings.values) {
      if (listing.shelf == shelf && listing.featured) return listing;
    }
    return null;
  }

  /// CI: every catalog game must appear on exactly one shelf.
  static List<String> validateArcadeShelfCoverage() {
    final missing = <String>[];
    for (final entry in GameCatalog.entries) {
      if (!_arcadeListings.containsKey(entry.type.name)) {
        missing.add(entry.type.name);
      }
    }
    if (!_arcadeListings.containsKey(toneForgeGameId)) {
      missing.add(toneForgeGameId);
    }
    return missing;
  }

  /// Get game definition by ID
  static GameDefinition? getGame(String gameId) {
    final normalized = gameId.trim();
    final direct = games[normalized];
    if (direct != null) return direct;
    final alias = _canonicalAliases[normalized];
    if (alias != null) return games[alias];
    return null;
  }

  /// Get all game IDs
  static List<String> getAllGameIds() {
    final ids = <String>{...games.keys, ..._canonicalAliases.keys};
    for (final type in GameType.values) {
      ids.add(type.name);
    }
    return ids.toList();
  }

  /// Create a generic game instance
  static GenericGame createGame(WidgetRef ref, String gameId) {
    final definition = getGame(gameId);
    if (definition == null) {
      throw ArgumentError('Game not found: $gameId');
    }

    return GenericGameFactory.create(
      ref: ref,
      gameId: definition.gameId,
      displayName: definition.displayName,
      learningGoals: definition.learningGoals,
    );
  }

  static List<String> _deriveLearningGoals(GameCatalogEntry entry) {
    final category = entry.category.toLowerCase();
    if (category.contains('pronunciation')) return ['pronunciation', 'listening'];
    if (category.contains('grammar')) return ['grammar', 'structure'];
    if (category.contains('cultural')) return ['culture', 'context'];
    return ['vocabulary', 'recall'];
  }

  static GameCoreVerb _inferCoreVerb(String gameId, GameCatalogEntry entry) {
    final id = gameId.toLowerCase();
    if (id.contains('drum') ||
        id.contains('listen') ||
        id.contains('accent') ||
        id.contains('danfo') ||
        id.contains('taxi') ||
        id.contains('bus_stop')) {
      return GameCoreVerb.listen;
    }
    if (id.contains('speak') ||
        id.contains('shadow') ||
        id.contains('call_and_response') ||
        id.contains('haggle') ||
        id.contains('roleplay')) {
      return GameCoreVerb.speak;
    }
    if (id.contains('match') || id.contains('wordmatch') || id.contains('picture_word')) {
      return GameCoreVerb.match;
    }
    if (id.contains('trace') || id.contains('script') || id.contains('fidel')) {
      return GameCoreVerb.trace;
    }
    if (id.contains('proverb') ||
        id.contains('story') ||
        id.contains('folktale') ||
        id.contains('clan')) {
      return GameCoreVerb.assemble;
    }
    if (id.contains('morph') || id.contains('word_forge') || id.contains('grammar')) {
      return GameCoreVerb.build;
    }
    if (id.contains('speed') || id.contains('rush') || id.contains('gauntlet')) {
      return GameCoreVerb.tap;
    }
    final category = entry.category.toLowerCase();
    if (category.contains('pronunciation')) return GameCoreVerb.listen;
    if (category.contains('grammar')) return GameCoreVerb.build;
    if (category.contains('cultural')) return GameCoreVerb.assemble;
    return GameCoreVerb.choose;
  }

  static GamePracticeTarget _practiceTargetFor(GameDefinition definition) {
    final goals = definition.learningGoals.map((g) => g.toLowerCase()).toList();
    if (goals.any((g) => g.contains('listen') || g.contains('pronunciation'))) {
      return GamePracticeTarget.perception;
    }
    return GamePracticeTarget.retrieval;
  }

  /// Registers every catalog game with [GameKitCatalog] (one core verb each).
  static void registerGameKitManifests() {
    for (final definition in games.values) {
      GameKitCatalog.register(
        GameManifest(
          gameId: definition.gameId,
          practiceTargets: {_practiceTargetFor(definition)},
          coreVerb: definition.coreVerb,
        ),
      );
    }
  }

  static GameManifest manifestForDefinition(GameDefinition definition) {
    return GameManifest(
      gameId: definition.gameId,
      practiceTargets: {_practiceTargetFor(definition)},
      coreVerb: definition.coreVerb,
    );
  }
}

/// Game definition
class GameDefinition {
  final String gameId;
  final String displayName;
  final List<String> learningGoals;
  final GameCoreVerb coreVerb;

  GameDefinition({
    required this.gameId,
    required this.displayName,
    this.learningGoals = const [],
    required this.coreVerb,
  });
}

