import 'generic_game_template.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Registry of all 37+ games with their configurations
/// This centralizes game definitions for easy migration
class AllGamesRegistry {
  /// All game definitions
  static final Map<String, GameDefinition> games = {
    // Already migrated games
    'proverb_unlocker': GameDefinition(
      gameId: 'proverb_unlocker',
      displayName: 'Proverb Unlocker',
      learningGoals: ['proverbs', 'cultural_wisdom'],
    ),
    'tone_forge': GameDefinition(
      gameId: 'tone_forge',
      displayName: 'Tone Forge',
      learningGoals: ['tones', 'pronunciation'],
    ),
    'drum_rhythm_shadowing': GameDefinition(
      gameId: 'drum_rhythm_shadowing',
      displayName: 'Drum Rhythm Shadowing',
      learningGoals: ['rhythm', 'cultural_context'],
    ),

    // Cultural games from cultural_games.dart
    'clan_story': GameDefinition(
      gameId: 'clan_story',
      displayName: 'Clan Story',
      learningGoals: ['storytelling', 'narrative'],
    ),
    'market_bargaining': GameDefinition(
      gameId: 'market_bargaining',
      displayName: 'Market Bargaining',
      learningGoals: ['negotiation', 'commerce'],
    ),
    'taxi_survival': GameDefinition(
      gameId: 'taxi_survival',
      displayName: 'Taxi Survival',
      learningGoals: ['transportation', 'directions'],
    ),
    'food_quest': GameDefinition(
      gameId: 'food_quest',
      displayName: 'Food Quest',
      learningGoals: ['food', 'cuisine'],
    ),

    // Games from cultural/ folder
    'call_response': GameDefinition(
      gameId: 'call_response',
      displayName: 'Call & Response',
      learningGoals: ['rhythm', 'interaction'],
    ),
    'greeting_diplomacy': GameDefinition(
      gameId: 'greeting_diplomacy',
      displayName: 'Greeting Diplomacy',
      learningGoals: ['etiquette', 'greetings'],
    ),
    'folktale': GameDefinition(
      gameId: 'folktale',
      displayName: 'Folktale',
      learningGoals: ['storytelling', 'culture'],
    ),
    'phrase_sniper': GameDefinition(
      gameId: 'phrase_sniper',
      displayName: 'Phrase Sniper',
      learningGoals: ['phrases', 'accuracy'],
    ),
    'liar_liar': GameDefinition(
      gameId: 'liar_liar',
      displayName: 'Liar Liar',
      learningGoals: ['detection', 'comprehension'],
    ),
    'village_quest': GameDefinition(
      gameId: 'village_quest',
      displayName: 'Village Quest',
      learningGoals: ['adventure', 'exploration'],
    ),
    'accent_puzzle': GameDefinition(
      gameId: 'accent_puzzle',
      displayName: 'Accent Puzzle',
      learningGoals: ['accents', 'pronunciation'],
    ),
    'flashcard_safari': GameDefinition(
      gameId: 'flashcard_safari',
      displayName: 'Flashcard Safari',
      learningGoals: ['vocabulary', 'memory'],
    ),
    'tongue_twister': GameDefinition(
      gameId: 'tongue_twister',
      displayName: 'Tongue Twister',
      learningGoals: ['pronunciation', 'fluency'],
    ),
    'emoji_translator': GameDefinition(
      gameId: 'emoji_translator',
      displayName: 'Emoji Translator',
      learningGoals: ['expression', 'meaning'],
    ),
    'rhythm_typing': GameDefinition(
      gameId: 'rhythm_typing',
      displayName: 'Rhythm Typing',
      learningGoals: ['typing', 'rhythm'],
    ),
    'elders_blessings': GameDefinition(
      gameId: 'elders_blessings',
      displayName: 'Elders Blessings',
      learningGoals: ['respect', 'traditions'],
    ),
    'multilingual_relay': GameDefinition(
      gameId: 'multilingual_relay',
      displayName: 'Multilingual Relay',
      learningGoals: ['translation', 'multilingual'],
    ),
    'cultural_etiquette': GameDefinition(
      gameId: 'cultural_etiquette',
      displayName: 'Cultural Etiquette',
      learningGoals: ['etiquette', 'culture'],
    ),
    'drum_word': GameDefinition(
      gameId: 'drum_word',
      displayName: 'Drum Word',
      learningGoals: ['rhythm', 'vocabulary'],
    ),

    // Games from game_templates.dart
    'listen_sketch': GameDefinition(
      gameId: 'listen_sketch',
      displayName: 'Listen & Sketch',
      learningGoals: ['listening', 'comprehension'],
    ),
    'picture_word': GameDefinition(
      gameId: 'picture_word',
      displayName: 'Picture Word',
      learningGoals: ['vocabulary', 'visual'],
    ),
    'memory_map': GameDefinition(
      gameId: 'memory_map',
      displayName: 'Memory Map',
      learningGoals: ['memory', 'spatial'],
    ),
    'conversation_relay': GameDefinition(
      gameId: 'conversation_relay',
      displayName: 'Conversation Relay',
      learningGoals: ['conversation', 'fluency'],
    ),
    'grammar_jam': GameDefinition(
      gameId: 'grammar_jam',
      displayName: 'Grammar Jam',
      learningGoals: ['grammar', 'structure'],
    ),
    'pronunciation_karaoke': GameDefinition(
      gameId: 'pronunciation_karaoke',
      displayName: 'Pronunciation Karaoke',
      learningGoals: ['pronunciation', 'singing'],
    ),
    'quiz_chef': GameDefinition(
      gameId: 'quiz_chef',
      displayName: 'Quiz Chef',
      learningGoals: ['quiz', 'knowledge'],
    ),

    // Standalone games
    'story_builder': GameDefinition(
      gameId: 'story_builder',
      displayName: 'Story Builder',
      learningGoals: ['storytelling', 'creativity'],
    ),
    'pronunciation_duel': GameDefinition(
      gameId: 'pronunciation_duel',
      displayName: 'Pronunciation Duel',
      learningGoals: ['pronunciation', 'competition'],
    ),
    'tone_trainer': GameDefinition(
      gameId: 'tone_trainer',
      displayName: 'Tone Trainer',
      learningGoals: ['tones', 'training'],
    ),
    'speed_round': GameDefinition(
      gameId: 'speed_round',
      displayName: 'Speed Round',
      learningGoals: ['speed', 'reflexes'],
    ),
    'roleplay_adventure': GameDefinition(
      gameId: 'roleplay_adventure',
      displayName: 'Roleplay Adventure',
      learningGoals: ['roleplay', 'adventure'],
    ),
    'grammar_detective': GameDefinition(
      gameId: 'grammar_detective',
      displayName: 'Grammar Detective',
      learningGoals: ['grammar', 'detection'],
    ),
  };

  /// Get game definition by ID
  static GameDefinition? getGame(String gameId) {
    return games[gameId];
  }

  /// Get all game IDs
  static List<String> getAllGameIds() {
    return games.keys.toList();
  }

  /// Create a generic game instance
  static GenericGame createGame(WidgetRef ref, String gameId) {
    final definition = games[gameId];
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

