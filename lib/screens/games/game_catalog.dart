import 'package:flutter/material.dart';
import 'package:lingafriq/models/game/game_session_model.dart';

enum GameCatalogSection { core, cultural }

class GameCatalogEntry {
  final GameType type;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final GameCatalogSection section;
  final List<String> rules;

  const GameCatalogEntry({
    required this.type,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.section,
    this.rules = const [],
  });
}

class GameCatalog {
  GameCatalog._();

  static const List<GameCatalogEntry> entries = [
    GameCatalogEntry(
      type: GameType.wordMatchAudio,
      name: 'Word Match Audio',
      description: 'Match words with audio',
      category: 'Vocabulary',
      icon: Icons.headphones,
      section: GameCatalogSection.core,
      rules: [
        'Match words in your target language with their English meaning.',
        'Tap a word to hear pronunciation before matching.',
        'Work quickly to build streak and score.',
      ],
    ),
    GameCatalogEntry(
      type: GameType.pronunciationDuel,
      name: 'Pronunciation Duel',
      description: 'Master pronunciation',
      category: 'Pronunciation',
      icon: Icons.record_voice_over,
      section: GameCatalogSection.core,
      rules: [
        'Listen to the native pronunciation first.',
        'Record your voice clearly in a quiet environment.',
        'Aim for 85+ to win each round.',
      ],
    ),
    GameCatalogEntry(
      type: GameType.speedRoundRemix,
      name: 'Speed Round',
      description: 'Fast-paced vocabulary',
      category: 'Vocabulary',
      icon: Icons.speed,
      section: GameCatalogSection.core,
      rules: [
        'Choose the correct translation before time runs out.',
        'Accuracy matters as much as speed.',
        'You have 60 seconds per run.',
      ],
    ),
    GameCatalogEntry(
      type: GameType.storyBuilder,
      name: 'Story Builder',
      description: 'Build stories',
      category: 'Grammar',
      icon: Icons.auto_stories,
      section: GameCatalogSection.core,
      rules: [
        'Continue the story using your target language.',
        'Keep your sentence coherent with the prior context.',
        'Use feedback tips to improve grammar and style.',
      ],
    ),
    GameCatalogEntry(
      type: GameType.roleplayAdventure,
      name: 'Roleplay Adventure',
      description: 'Interactive conversations',
      category: 'Cultural',
      icon: Icons.theater_comedy,
      section: GameCatalogSection.core,
      rules: [
        'Choose the best response for each real-life scenario.',
        'Prioritize culturally appropriate phrasing.',
        'Different choices lead to different outcomes.',
      ],
    ),
    GameCatalogEntry(
      type: GameType.grammarDetective,
      name: 'Grammar Detective',
      description: 'Solve grammar mysteries',
      category: 'Grammar',
      icon: Icons.search,
      section: GameCatalogSection.core,
      rules: [
        'Find the grammar mistake in each sentence.',
        'Pick the best correction based on context.',
        'Focus on tense, agreement, and word order.',
      ],
    ),
    GameCatalogEntry(
      type: GameType.listenAndSketch,
      name: 'Listen & Sketch',
      description: 'Draw what you hear',
      category: 'Vocabulary',
      icon: Icons.draw,
      section: GameCatalogSection.core,
    ),
    GameCatalogEntry(
      type: GameType.pictureWordAssociation,
      name: 'Picture Word Match',
      description: 'Match words with images',
      category: 'Vocabulary',
      icon: Icons.image,
      section: GameCatalogSection.core,
    ),
    GameCatalogEntry(
      type: GameType.memoryMap,
      name: 'Memory Map',
      description: 'Memory challenge',
      category: 'Vocabulary',
      icon: Icons.map,
      section: GameCatalogSection.core,
    ),
    GameCatalogEntry(
      type: GameType.conversationRelay,
      name: 'Conversation Relay',
      description: 'Chain conversations',
      category: 'Cultural',
      icon: Icons.chat,
      section: GameCatalogSection.core,
    ),
    GameCatalogEntry(
      type: GameType.grammarJam,
      name: 'Grammar Jam',
      description: 'Grammar rhythm game',
      category: 'Grammar',
      icon: Icons.music_note,
      section: GameCatalogSection.core,
    ),
    GameCatalogEntry(
      type: GameType.pronunciationKaraoke,
      name: 'Pronunciation Karaoke',
      description: 'Sing and pronounce',
      category: 'Pronunciation',
      icon: Icons.mic,
      section: GameCatalogSection.core,
    ),
    GameCatalogEntry(
      type: GameType.quizChef,
      name: 'Quiz Chef',
      description: 'Cook up answers',
      category: 'Vocabulary',
      icon: Icons.restaurant,
      section: GameCatalogSection.core,
    ),
    GameCatalogEntry(
      type: GameType.toneTrainer,
      name: 'Tone Trainer',
      description: 'Master tonal pronunciation',
      category: 'Pronunciation',
      icon: Icons.graphic_eq,
      section: GameCatalogSection.core,
    ),
    GameCatalogEntry(
      type: GameType.scrabbleSprintArena,
      name: 'Scrabble Sprint',
      description: 'Build words under pressure',
      category: 'Vocabulary',
      icon: Icons.spellcheck,
      section: GameCatalogSection.core,
      rules: [
        'Build valid words using the provided letters.',
        'Longer words usually score higher.',
        'Use all tiles if possible for bonus points.',
      ],
    ),
    GameCatalogEntry(
      type: GameType.proverbUnlocker,
      name: 'Proverb Unlocker',
      description: 'Unlock wisdom',
      category: 'Cultural',
      icon: Icons.auto_awesome,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.drumRhythmShadowing,
      name: 'Drum Rhythm',
      description: 'Follow the rhythm',
      category: 'Pronunciation',
      icon: Icons.music_note,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.clanLineageStoryBuilder,
      name: 'Clan Story Builder',
      description: 'Build clan stories',
      category: 'Cultural',
      icon: Icons.account_tree,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.marketBargainingSimulator,
      name: 'Market Bargaining',
      description: 'Practice bargaining',
      category: 'Cultural',
      icon: Icons.store,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.taxiBusStopSurvival,
      name: 'Taxi Survival',
      description: 'Navigate transportation',
      category: 'Cultural',
      icon: Icons.directions_transit,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.foodQuest,
      name: 'Food Quest',
      description: 'Explore cuisine',
      category: 'Cultural',
      icon: Icons.restaurant_menu,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.callAndResponse,
      name: 'Call & Response',
      description: 'Traditional patterns',
      category: 'Cultural',
      icon: Icons.call,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.greetingDiplomacyChallenge,
      name: 'Greeting Diplomacy',
      description: 'Master greetings',
      category: 'Cultural',
      icon: Icons.waving_hand,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.folktaleReconstruction,
      name: 'Folktale Builder',
      description: 'Rebuild stories',
      category: 'Cultural',
      icon: Icons.book,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.phraseSniper,
      name: 'Phrase Sniper',
      description: 'Target phrases',
      category: 'Vocabulary',
      icon: Icons.center_focus_strong,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.liarLiar,
      name: 'Liar Liar',
      description: 'Detect truth',
      category: 'Grammar',
      icon: Icons.psychology,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.villageQuest,
      name: 'Village Quest',
      description: 'Adventure quest',
      category: 'Cultural',
      icon: Icons.explore,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.accentDecodingPuzzle,
      name: 'Accent Puzzle',
      description: 'Decode accents',
      category: 'Pronunciation',
      icon: Icons.extension,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.flashcardSafari,
      name: 'Flashcard Safari',
      description: 'Safari vocabulary',
      category: 'Vocabulary',
      icon: Icons.flash_on,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.rapidTongueTwisterRace,
      name: 'Tongue Twister',
      description: 'Master twisters',
      category: 'Pronunciation',
      icon: Icons.speed,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.emojiTranslator,
      name: 'Emoji Translator',
      description: 'Translate emojis',
      category: 'Vocabulary',
      icon: Icons.emoji_emotions,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.rhythmTyping,
      name: 'Rhythm Typing',
      description: 'Type to rhythm',
      category: 'Vocabulary',
      icon: Icons.keyboard,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.eldersBlessingsChallenge,
      name: 'Elders Blessings',
      description: 'Learn blessings',
      category: 'Cultural',
      icon: Icons.favorite,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.multilingualRelayRace,
      name: 'Multilingual Relay',
      description: 'Language relay',
      category: 'Cultural',
      icon: Icons.swap_horiz,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.culturalEtiquetteScenarios,
      name: 'Cultural Etiquette',
      description: 'Learn etiquette',
      category: 'Cultural',
      icon: Icons.groups,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.drumToWordMatching,
      name: 'Drum Word Match',
      description: 'Match drum patterns',
      category: 'Cultural',
      icon: Icons.music_note,
      section: GameCatalogSection.cultural,
    ),
    GameCatalogEntry(
      type: GameType.marketMonopolyChallenge,
      name: 'Market Monopoly',
      description: 'Strategic market negotiations',
      category: 'Cultural',
      icon: Icons.storefront,
      section: GameCatalogSection.cultural,
    ),
  ];

  static final Map<GameType, GameCatalogEntry> byType = {
    for (final entry in entries) entry.type: entry,
  };

  static List<GameCatalogEntry> bySection(GameCatalogSection section) {
    return entries.where((entry) => entry.section == section).toList();
  }
}
