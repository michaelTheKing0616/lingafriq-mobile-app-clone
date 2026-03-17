import 'generic_game_template.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart' show GameTypeExtension, GameType;
import '../../screens/games/game_catalog.dart';

/// Registry of all 37+ games with their configurations
/// This centralizes game definitions for easy migration
class AllGamesRegistry {
  static const Map<String, String> _canonicalAliases = {
    // Legacy/alternate IDs -> canonical GameType.name IDs
    'wordmatch_audio': 'wordmatch_audio',
    'speed_round': 'speed_round_remix',
    'tone_forge': 'tone_trainer',
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
      ),
  };

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
}

/// Game definition
class GameDefinition {
  final String gameId;
  final String displayName;
  final List<String> learningGoals;

  GameDefinition({
    required this.gameId,
    required this.displayName,
    this.learningGoals = const [],
  });
}

