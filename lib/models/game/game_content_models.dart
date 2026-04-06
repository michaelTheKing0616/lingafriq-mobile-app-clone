import 'dart:convert';

/// A vocabulary word sourced from the game content database.
///
/// Each word carries linguistic metadata (phonetics, part of speech, tonal notes)
/// and game-routing metadata ([gameTags]) so the game engine can select
/// appropriate content per mini-game.
class GameWord {
  final int id;
  final String language;
  final String word;
  final String englishMeaning;
  final String? phoneticGuide;
  final String? partOfSpeech;
  final String cefr;
  final String? topic;
  final String? tonalNote;
  final String? culturalNote;
  final List<String> gameTags;

  const GameWord({
    required this.id,
    required this.language,
    required this.word,
    required this.englishMeaning,
    this.phoneticGuide,
    this.partOfSpeech,
    required this.cefr,
    this.topic,
    this.tonalNote,
    this.culturalNote,
    this.gameTags = const [],
  });

  factory GameWord.fromJson(Map<String, dynamic> json) => GameWord(
        id: json['id'] as int,
        language: json['language'] as String,
        word: json['word'] as String,
        englishMeaning: json['english_meaning'] as String,
        phoneticGuide: json['phonetic_guide'] as String?,
        partOfSpeech: json['part_of_speech'] as String?,
        cefr: json['cefr'] as String,
        topic: json['topic'] as String?,
        tonalNote: json['tonal_note'] as String?,
        culturalNote: json['cultural_note'] as String?,
        gameTags: _parseGameTags(json['game_tags']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'language': language,
        'word': word,
        'english_meaning': englishMeaning,
        'phonetic_guide': phoneticGuide,
        'part_of_speech': partOfSpeech,
        'cefr': cefr,
        'topic': topic,
        'tonal_note': tonalNote,
        'cultural_note': culturalNote,
        'game_tags': gameTags,
      };

  GameWord copyWith({
    int? id,
    String? language,
    String? word,
    String? englishMeaning,
    String? phoneticGuide,
    String? partOfSpeech,
    String? cefr,
    String? topic,
    String? tonalNote,
    String? culturalNote,
    List<String>? gameTags,
  }) =>
      GameWord(
        id: id ?? this.id,
        language: language ?? this.language,
        word: word ?? this.word,
        englishMeaning: englishMeaning ?? this.englishMeaning,
        phoneticGuide: phoneticGuide ?? this.phoneticGuide,
        partOfSpeech: partOfSpeech ?? this.partOfSpeech,
        cefr: cefr ?? this.cefr,
        topic: topic ?? this.topic,
        tonalNote: tonalNote ?? this.tonalNote,
        culturalNote: culturalNote ?? this.culturalNote,
        gameTags: gameTags ?? this.gameTags,
      );

  @override
  String toString() => 'GameWord(id: $id, language: $language, word: $word)';
}

/// A proverb entry for proverb-based games (e.g. Proverb Unlocker).
///
/// Includes the original-language text, its English translation,
/// an optional deeper [meaning], and [gameTags] for game selection.
class GameProverb {
  final int id;
  final String language;
  final String original;
  final String translation;
  final String? meaning;
  final String cefr;
  final List<String> gameTags;

  const GameProverb({
    required this.id,
    required this.language,
    required this.original,
    required this.translation,
    this.meaning,
    required this.cefr,
    this.gameTags = const [],
  });

  factory GameProverb.fromJson(Map<String, dynamic> json) => GameProverb(
        id: json['id'] as int,
        language: json['language'] as String,
        original: json['original'] as String,
        translation: json['translation'] as String,
        meaning: json['meaning'] as String?,
        cefr: json['cefr'] as String,
        gameTags: _parseGameTags(json['game_tags']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'language': language,
        'original': original,
        'translation': translation,
        'meaning': meaning,
        'cefr': cefr,
        'game_tags': gameTags,
      };

  GameProverb copyWith({
    int? id,
    String? language,
    String? original,
    String? translation,
    String? meaning,
    String? cefr,
    List<String>? gameTags,
  }) =>
      GameProverb(
        id: id ?? this.id,
        language: language ?? this.language,
        original: original ?? this.original,
        translation: translation ?? this.translation,
        meaning: meaning ?? this.meaning,
        cefr: cefr ?? this.cefr,
        gameTags: gameTags ?? this.gameTags,
      );

  @override
  String toString() =>
      'GameProverb(id: $id, language: $language, original: $original)';
}

/// A scenario prompt for interactive/roleplay games.
///
/// Ties a situational [prompt] to a specific [game] type and language,
/// optionally including an [expectedResponse] and [culturalNote].
class GameScenario {
  final int id;
  final String game;
  final String language;
  final String cefr;
  final String title;
  final String prompt;
  final String? expectedResponse;
  final String? culturalNote;

  const GameScenario({
    required this.id,
    required this.game,
    required this.language,
    required this.cefr,
    required this.title,
    required this.prompt,
    this.expectedResponse,
    this.culturalNote,
  });

  factory GameScenario.fromJson(Map<String, dynamic> json) => GameScenario(
        id: json['id'] as int,
        game: json['game'] as String,
        language: json['language'] as String,
        cefr: json['cefr'] as String,
        title: json['title'] as String,
        prompt: json['prompt'] as String,
        expectedResponse: json['expected_response'] as String?,
        culturalNote: json['cultural_note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'game': game,
        'language': language,
        'cefr': cefr,
        'title': title,
        'prompt': prompt,
        'expected_response': expectedResponse,
        'cultural_note': culturalNote,
      };

  GameScenario copyWith({
    int? id,
    String? game,
    String? language,
    String? cefr,
    String? title,
    String? prompt,
    String? expectedResponse,
    String? culturalNote,
  }) =>
      GameScenario(
        id: id ?? this.id,
        game: game ?? this.game,
        language: language ?? this.language,
        cefr: cefr ?? this.cefr,
        title: title ?? this.title,
        prompt: prompt ?? this.prompt,
        expectedResponse: expectedResponse ?? this.expectedResponse,
        culturalNote: culturalNote ?? this.culturalNote,
      );

  @override
  String toString() =>
      'GameScenario(id: $id, game: $game, language: $language, title: $title)';
}

/// Aggregate container for the full game content database.
///
/// Parses the top-level `game_content.json` structure and provides
/// typed, filtered access to [words], [proverbs], and [scenarios].
class GameContentData {
  final List<GameWord> words;
  final List<GameProverb> proverbs;
  final List<GameScenario> scenarios;

  const GameContentData({
    this.words = const [],
    this.proverbs = const [],
    this.scenarios = const [],
  });

  /// Parses the full game_content.json structure.
  ///
  /// Expects a map with optional keys `"words"`, `"proverbs"`, `"scenarios"`,
  /// each containing a JSON array of the respective model.
  factory GameContentData.fromJson(Map<String, dynamic> json) =>
      GameContentData(
        words: (json['words'] as List<dynamic>?)
                ?.map((e) => GameWord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        proverbs: (json['proverbs'] as List<dynamic>?)
                ?.map((e) => GameProverb.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        scenarios: (json['scenarios'] as List<dynamic>?)
                ?.map((e) => GameScenario.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  /// Convenience factory that decodes a raw JSON string.
  factory GameContentData.fromRawJson(String source) =>
      GameContentData.fromJson(json.decode(source) as Map<String, dynamic>);

  // ---------------------------------------------------------------------------
  // Word filters
  // ---------------------------------------------------------------------------

  List<GameWord> wordsByLanguage(String language) =>
      words.where((w) => w.language == language).toList();

  List<GameWord> wordsByCefr(String cefr) =>
      words.where((w) => w.cefr == cefr).toList();

  List<GameWord> wordsByGameTag(String tag) =>
      words.where((w) => w.gameTags.contains(tag)).toList();

  List<GameWord> wordsByLanguageAndTag(String language, String tag) => words
      .where((w) => w.language == language && w.gameTags.contains(tag))
      .toList();

  // ---------------------------------------------------------------------------
  // Proverb filters
  // ---------------------------------------------------------------------------

  List<GameProverb> proverbsByLanguage(String language) =>
      proverbs.where((p) => p.language == language).toList();

  List<GameProverb> proverbsByGameTag(String tag) =>
      proverbs.where((p) => p.gameTags.contains(tag)).toList();

  // ---------------------------------------------------------------------------
  // Scenario filters
  // ---------------------------------------------------------------------------

  List<GameScenario> scenariosByGame(String game) =>
      scenarios.where((s) => s.game == game).toList();

  List<GameScenario> scenariosByLanguage(String language) =>
      scenarios.where((s) => s.language == language).toList();

  // ---------------------------------------------------------------------------
  // Aggregate accessors
  // ---------------------------------------------------------------------------

  /// All distinct languages present across words, proverbs, and scenarios.
  Set<String> get availableLanguages => {
        ...words.map((w) => w.language),
        ...proverbs.map((p) => p.language),
        ...scenarios.map((s) => s.language),
      };

  /// All distinct CEFR levels present across words, proverbs, and scenarios.
  Set<String> get availableCefrLevels => {
        ...words.map((w) => w.cefr),
        ...proverbs.map((p) => p.cefr),
        ...scenarios.map((s) => s.cefr),
      };

  @override
  String toString() => 'GameContentData('
      'words: ${words.length}, '
      'proverbs: ${proverbs.length}, '
      'scenarios: ${scenarios.length})';
}

// -----------------------------------------------------------------------------
// Shared helpers
// -----------------------------------------------------------------------------

/// Parses a game_tags value that may arrive as a [List<dynamic>] or a
/// comma-separated [String]. Returns an empty list on null/empty input.
List<String> _parseGameTags(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.map((e) => (e as String).trim()).where((s) => s.isNotEmpty).toList();
  }
  if (value is String) {
    if (value.trim().isEmpty) return const [];
    return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
  return const [];
}
