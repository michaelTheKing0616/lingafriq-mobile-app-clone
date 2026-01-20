/// Game Session Model
class GameSession {
  final String sessionId;
  final String userId;
  final String gameType; // e.g., "wordmatch_audio", "pronunciation_duel"
  final String language;
  final String? level; // CEFR level
  final DateTime startTime;
  final DateTime? endTime;
  final List<GameTurn> turns;
  final Map<String, dynamic> metadata; // Game-specific data

  GameSession({
    required this.sessionId,
    required this.userId,
    required this.gameType,
    required this.language,
    this.level,
    required this.startTime,
    this.endTime,
    this.turns = const [],
    this.metadata = const {},
  });

  int get durationMs => endTime != null
      ? endTime!.difference(startTime).inMilliseconds
      : DateTime.now().difference(startTime).inMilliseconds;

  int get correctCount => turns.where((t) => t.result == GameResult.correct).length;
  int get totalTurns => turns.length;
  double get accuracy => totalTurns > 0 ? correctCount / totalTurns : 0.0;

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'user_id': userId,
        'game': gameType,
        'language': language,
        'level': level,
        'start_ts': startTime.toIso8601String(),
        'end_ts': endTime?.toIso8601String(),
        'turns': turns.map((t) => t.toJson()).toList(),
        'metadata': metadata,
      };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
        sessionId: json['session_id'] as String,
        userId: json['user_id'] as String,
        gameType: json['game'] as String,
        language: json['language'] as String,
        level: json['level'] as String?,
        startTime: DateTime.parse(json['start_ts'] as String),
        endTime: json['end_ts'] != null
            ? DateTime.parse(json['end_ts'] as String)
            : null,
        turns: (json['turns'] as List<dynamic>?)
                ?.map((t) => GameTurn.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      );

  GameSession copyWith({
    String? sessionId,
    String? userId,
    String? gameType,
    String? language,
    String? level,
    DateTime? startTime,
    DateTime? endTime,
    List<GameTurn>? turns,
    Map<String, dynamic>? metadata,
  }) =>
      GameSession(
        sessionId: sessionId ?? this.sessionId,
        userId: userId ?? this.userId,
        gameType: gameType ?? this.gameType,
        language: language ?? this.language,
        level: level ?? this.level,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        turns: turns ?? this.turns,
        metadata: metadata ?? this.metadata,
      );
}

/// Game Turn Model
class GameTurn {
  final String cardId;
  final String? userAction; // e.g., "matched_audio_played", "pronounced"
  final GameResult result;
  final int durationMs; // Time taken for this turn
  final double? confidence; // 0.0 to 1.0
  final Map<String, dynamic>? feedback; // Game-specific feedback
  final DateTime timestamp;

  GameTurn({
    required this.cardId,
    this.userAction,
    required this.result,
    required this.durationMs,
    this.confidence,
    this.feedback,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'card_id': cardId,
        'user_action': userAction,
        'result': result.name,
        'duration_ms': durationMs,
        'confidence': confidence,
        'feedback': feedback,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GameTurn.fromJson(Map<String, dynamic> json) => GameTurn(
        cardId: json['card_id'] as String,
        userAction: json['user_action'] as String?,
        result: GameResult.values.firstWhere(
          (e) => e.name == json['result'],
          orElse: () => GameResult.incorrect,
        ),
        durationMs: json['duration_ms'] as int,
        confidence: (json['confidence'] as num?)?.toDouble(),
        feedback: json['feedback'] as Map<String, dynamic>?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );
}

/// Game Result Enum
enum GameResult {
  correct,
  incorrect,
  partial,
  timeout,
  skipped;
}

/// Game Type Enum
enum GameType {
  wordMatchAudio,
  pronunciationDuel,
  speedRoundRemix,
  toneTrainer,
  storyBuilder,
  roleplayAdventure,
  grammarDetective,
  listenAndSketch,
  pictureWordAssociation,
  memoryMap,
  conversationRelay,
  grammarJam,
  pronunciationKaraoke,
  quizChef,
  proverbUnlocker,
  drumRhythmShadowing,
  clanLineageStoryBuilder,
  marketBargainingSimulator,
  taxiBusStopSurvival,
  foodQuest,
  callAndResponse,
  greetingDiplomacyChallenge,
  folktaleReconstruction,
  phraseSniper,
  liarLiar,
  villageQuest,
  accentDecodingPuzzle,
  flashcardSafari,
  rapidTongueTwisterRace,
  emojiTranslator,
  rhythmTyping,
  eldersBlessingsChallenge,
  multilingualRelayRace,
  culturalEtiquetteScenarios,
  drumToWordMatching,
}

extension GameTypeExtension on GameType {
  String get name {
    switch (this) {
      case GameType.wordMatchAudio:
        return 'wordmatch_audio';
      case GameType.pronunciationDuel:
        return 'pronunciation_duel';
      case GameType.speedRoundRemix:
        return 'speed_round_remix';
      case GameType.toneTrainer:
        return 'tone_trainer';
      case GameType.storyBuilder:
        return 'story_builder';
      case GameType.roleplayAdventure:
        return 'roleplay_adventure';
      case GameType.grammarDetective:
        return 'grammar_detective';
      case GameType.listenAndSketch:
        return 'listen_and_sketch';
      case GameType.pictureWordAssociation:
        return 'picture_word_association';
      case GameType.memoryMap:
        return 'memory_map';
      case GameType.conversationRelay:
        return 'conversation_relay';
      case GameType.grammarJam:
        return 'grammar_jam';
      case GameType.pronunciationKaraoke:
        return 'pronunciation_karaoke';
      case GameType.quizChef:
        return 'quiz_chef';
      case GameType.proverbUnlocker:
        return 'proverb_unlocker';
      case GameType.drumRhythmShadowing:
        return 'drum_rhythm_shadowing';
      case GameType.clanLineageStoryBuilder:
        return 'clan_lineage_story_builder';
      case GameType.marketBargainingSimulator:
        return 'market_bargaining_simulator';
      case GameType.taxiBusStopSurvival:
        return 'taxi_bus_stop_survival';
      case GameType.foodQuest:
        return 'food_quest';
      case GameType.callAndResponse:
        return 'call_and_response';
      case GameType.greetingDiplomacyChallenge:
        return 'greeting_diplomacy_challenge';
      case GameType.folktaleReconstruction:
        return 'folktale_reconstruction';
      case GameType.phraseSniper:
        return 'phrase_sniper';
      case GameType.liarLiar:
        return 'liar_liar';
      case GameType.villageQuest:
        return 'village_quest';
      case GameType.accentDecodingPuzzle:
        return 'accent_decoding_puzzle';
      case GameType.flashcardSafari:
        return 'flashcard_safari';
      case GameType.rapidTongueTwisterRace:
        return 'rapid_tongue_twister_race';
      case GameType.emojiTranslator:
        return 'emoji_translator';
      case GameType.rhythmTyping:
        return 'rhythm_typing';
      case GameType.eldersBlessingsChallenge:
        return 'elders_blessings_challenge';
      case GameType.multilingualRelayRace:
        return 'multilingual_relay_race';
      case GameType.culturalEtiquetteScenarios:
        return 'cultural_etiquette_scenarios';
      case GameType.drumToWordMatching:
        return 'drum_to_word_matching';
    }
  }

  String get displayName {
    switch (this) {
      case GameType.wordMatchAudio:
        return 'Word Match + Audio';
      case GameType.pronunciationDuel:
        return 'Pronunciation Duel';
      case GameType.speedRoundRemix:
        return 'Speed Round Remix';
      case GameType.toneTrainer:
        return 'Tone Trainer';
      case GameType.storyBuilder:
        return 'Story Builder';
      case GameType.roleplayAdventure:
        return 'Roleplay Adventure';
      case GameType.grammarDetective:
        return 'Grammar Detective';
      case GameType.listenAndSketch:
        return 'Listen & Sketch';
      case GameType.pictureWordAssociation:
        return 'Picture-Word Association';
      case GameType.memoryMap:
        return 'Memory Map';
      case GameType.conversationRelay:
        return 'Conversation Relay';
      case GameType.grammarJam:
        return 'Grammar Jam';
      case GameType.pronunciationKaraoke:
        return 'Pronunciation Karaoke';
      case GameType.quizChef:
        return 'Quiz Chef';
      case GameType.proverbUnlocker:
        return 'Proverb Unlocker';
      case GameType.drumRhythmShadowing:
        return 'Drum Rhythm Shadowing';
      case GameType.clanLineageStoryBuilder:
        return 'Clan Lineage Story Builder';
      case GameType.marketBargainingSimulator:
        return 'Market Bargaining Simulator';
      case GameType.taxiBusStopSurvival:
        return 'Taxi & Bus Stop Survival';
      case GameType.foodQuest:
        return 'Food Quest';
      case GameType.callAndResponse:
        return 'Call and Response';
      case GameType.greetingDiplomacyChallenge:
        return 'Greeting Diplomacy Challenge';
      case GameType.folktaleReconstruction:
        return 'Folktale Reconstruction';
      case GameType.phraseSniper:
        return 'Phrase Sniper';
      case GameType.liarLiar:
        return 'Liar Liar';
      case GameType.villageQuest:
        return 'Village Quest';
      case GameType.accentDecodingPuzzle:
        return 'Accent Decoding Puzzle';
      case GameType.flashcardSafari:
        return 'Flashcard Safari';
      case GameType.rapidTongueTwisterRace:
        return 'Rapid Tongue Twister Race';
      case GameType.emojiTranslator:
        return 'Emoji Translator';
      case GameType.rhythmTyping:
        return 'Rhythm Typing';
      case GameType.eldersBlessingsChallenge:
        return 'Elders\' Blessings Challenge';
      case GameType.multilingualRelayRace:
        return 'Multilingual Relay Race';
      case GameType.culturalEtiquetteScenarios:
        return 'Cultural Etiquette Scenarios';
      case GameType.drumToWordMatching:
        return 'Drum-to-Word Matching';
    }
  }

  // displayName is already defined earlier in this extension (keep a single definition).
}

