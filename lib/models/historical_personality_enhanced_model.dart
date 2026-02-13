// Enhanced Historical Personality Model
// Comprehensive model for historical personalities with knowledge base, memory, and educational features

// Enhanced Historical Personality
class EnhancedHistoricalPersonality {
  final String id;
  final String name;
  final String? birthDate;
  final String? deathDate;
  final String country;
  final String language;
  final String biography;
  final List<String> achievements;
  final List<String> traits;
  final Map<String, dynamic> speechPatterns;
  final List<String> knowledgeTopics;
  final String? imageUrl;
  final Map<String, dynamic> culturalContext;
  
  // Enhanced fields
  final Map<String, String> knowledgeBase; // topic -> detailed information
  final List<String> famousQuotes;
  final List<HistoricalEvent> timelineEvents;
  final Map<String, String> regionalVariations; // region -> dialect/variation
  final List<String> relatedPersonalities;
  final Map<String, dynamic> educationalContent; // lessons, quizzes, facts
  final String? audioVoiceUrl; // Voice sample URL
  final Map<String, dynamic>? visualAssets; // portraits, backgrounds, etc.

  EnhancedHistoricalPersonality({
    required this.id,
    required this.name,
    this.birthDate,
    this.deathDate,
    required this.country,
    required this.language,
    required this.biography,
    required this.achievements,
    required this.traits,
    required this.speechPatterns,
    required this.knowledgeTopics,
    this.imageUrl,
    required this.culturalContext,
    this.knowledgeBase = const {},
    this.famousQuotes = const [],
    this.timelineEvents = const [],
    this.regionalVariations = const {},
    this.relatedPersonalities = const [],
    this.educationalContent = const {},
    this.audioVoiceUrl,
    this.visualAssets,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (birthDate != null) 'birth_date': birthDate,
        if (deathDate != null) 'death_date': deathDate,
        'country': country,
        'language': language,
        'biography': biography,
        'achievements': achievements,
        'traits': traits,
        'speech_patterns': speechPatterns,
        'knowledge_topics': knowledgeTopics,
        if (imageUrl != null) 'image_url': imageUrl,
        'cultural_context': culturalContext,
        'knowledge_base': knowledgeBase,
        'famous_quotes': famousQuotes,
        'timeline_events': timelineEvents.map((e) => e.toJson()).toList(),
        'regional_variations': regionalVariations,
        'related_personalities': relatedPersonalities,
        'educational_content': educationalContent,
        if (audioVoiceUrl != null) 'audio_voice_url': audioVoiceUrl,
        if (visualAssets != null) 'visual_assets': visualAssets,
      };

  factory EnhancedHistoricalPersonality.fromJson(Map<String, dynamic> json) {
    return EnhancedHistoricalPersonality(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      birthDate: json['birth_date'],
      deathDate: json['death_date'],
      country: json['country'] ?? '',
      language: json['language'] ?? '',
      biography: json['biography'] ?? '',
      achievements: List<String>.from(json['achievements'] ?? []),
      traits: List<String>.from(json['traits'] ?? []),
      speechPatterns: Map<String, dynamic>.from(json['speech_patterns'] ?? {}),
      knowledgeTopics: List<String>.from(json['knowledge_topics'] ?? []),
      imageUrl: json['image_url'],
      culturalContext: Map<String, dynamic>.from(json['cultural_context'] ?? {}),
      knowledgeBase: Map<String, String>.from(json['knowledge_base'] ?? {}),
      famousQuotes: List<String>.from(json['famous_quotes'] ?? []),
      timelineEvents: (json['timeline_events'] as List?)
              ?.map((e) => HistoricalEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      regionalVariations: Map<String, String>.from(json['regional_variations'] ?? {}),
      relatedPersonalities: List<String>.from(json['related_personalities'] ?? []),
      educationalContent: Map<String, dynamic>.from(json['educational_content'] ?? {}),
      audioVoiceUrl: json['audio_voice_url'],
      visualAssets: json['visual_assets'] != null
          ? Map<String, dynamic>.from(json['visual_assets'])
          : null,
    );
  }
}

/// Historical Event
class HistoricalEvent {
  final int year;
  final String event;
  final String? description;
  final String? significance;

  HistoricalEvent({
    required this.year,
    required this.event,
    this.description,
    this.significance,
  });

  Map<String, dynamic> toJson() => {
        'year': year,
        'event': event,
        if (description != null) 'description': description,
        if (significance != null) 'significance': significance,
      };

  factory HistoricalEvent.fromJson(Map<String, dynamic> json) {
    return HistoricalEvent(
      year: json['year'] ?? 0,
      event: json['event'] ?? '',
      description: json['description'],
      significance: json['significance'],
    );
  }
}

/// Personality Chat Memory
class PersonalityChatMemory {
  final String personalityId;
  final String userId;
  final List<ConversationContext> conversationHistory;
  final Set<String> topicsDiscussed;
  final Map<String, int> userInterests; // topic -> interest level (1-5)
  final DateTime? lastConversation;
  final Map<String, dynamic> preferences;

  PersonalityChatMemory({
    required this.personalityId,
    required this.userId,
    this.conversationHistory = const [],
    this.topicsDiscussed = const {},
    this.userInterests = const {},
    this.lastConversation,
    this.preferences = const {},
  });

  PersonalityChatMemory copyWith({
    String? personalityId,
    String? userId,
    List<ConversationContext>? conversationHistory,
    Set<String>? topicsDiscussed,
    Map<String, int>? userInterests,
    DateTime? lastConversation,
    Map<String, dynamic>? preferences,
  }) {
    return PersonalityChatMemory(
      personalityId: personalityId ?? this.personalityId,
      userId: userId ?? this.userId,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      topicsDiscussed: topicsDiscussed ?? this.topicsDiscussed,
      userInterests: userInterests ?? this.userInterests,
      lastConversation: lastConversation ?? this.lastConversation,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() => {
        'personality_id': personalityId,
        'user_id': userId,
        'conversation_history': conversationHistory.map((c) => c.toJson()).toList(),
        'topics_discussed': topicsDiscussed.toList(),
        'user_interests': userInterests,
        if (lastConversation != null) 'last_conversation': lastConversation!.toIso8601String(),
        'preferences': preferences,
      };

  factory PersonalityChatMemory.fromJson(Map<String, dynamic> json) {
    return PersonalityChatMemory(
      personalityId: json['personality_id'] ?? '',
      userId: json['user_id'] ?? '',
      conversationHistory: (json['conversation_history'] as List?)
              ?.map((c) => ConversationContext.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      topicsDiscussed: (json['topics_discussed'] as List?)?.cast<String>().toSet() ?? {},
      userInterests: Map<String, int>.from(
        (json['user_interests'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      ),
      lastConversation: json['last_conversation'] != null
          ? DateTime.parse(json['last_conversation'])
          : null,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }
}

/// Conversation Context
class ConversationContext {
  final String topic;
  final String summary;
  final DateTime timestamp;
  final List<String> keyPoints;

  ConversationContext({
    required this.topic,
    required this.summary,
    required this.timestamp,
    this.keyPoints = const [],
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'summary': summary,
        'timestamp': timestamp.toIso8601String(),
        'key_points': keyPoints,
      };

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      topic: json['topic'] ?? '',
      summary: json['summary'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      keyPoints: List<String>.from(json['key_points'] ?? []),
    );
  }
}

