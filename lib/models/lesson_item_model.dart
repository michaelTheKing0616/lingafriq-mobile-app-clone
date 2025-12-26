/// Lesson Item Model
/// Represents a lesson item (vocabulary, sentence, proverb, etc.)

class LessonItem {
  final String id;
  final String language;
  final String languageCode;
  final String level; // A0, A1, A2, B1, B2, C1
  final String category;
  final String type; // vocabulary, grammar, pronunciation, conversation, proverb, dialogue
  final String text;
  final String? ipa;
  final String? transliteration;
  final String translation;
  final List<String>? tonePattern;
  final double difficulty;
  final String? culturalNote;
  final String usageContext;
  final List<ExampleSentence>? exampleSentences;
  final List<String>? relatedWords;
  final String? grammarNotes;
  final double qualityScore;
  final bool verifiedByNative;
  final String? audioUrl;
  final DateTime? createdAt;

  LessonItem({
    required this.id,
    required this.language,
    required this.languageCode,
    required this.level,
    required this.category,
    required this.type,
    required this.text,
    this.ipa,
    this.transliteration,
    required this.translation,
    this.tonePattern,
    required this.difficulty,
    this.culturalNote,
    this.usageContext = 'general',
    this.exampleSentences,
    this.relatedWords,
    this.grammarNotes,
    required this.qualityScore,
    this.verifiedByNative = false,
    this.audioUrl,
    this.createdAt,
  });

  factory LessonItem.fromJson(Map<String, dynamic> json) {
    return LessonItem(
      id: json['id'] as String,
      language: json['language'] as String,
      languageCode: json['language_code'] as String,
      level: json['level'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      text: json['text'] as String,
      ipa: json['ipa'] as String?,
      transliteration: json['transliteration'] as String?,
      translation: json['translation'] as String,
      tonePattern: json['tone_pattern'] != null
          ? List<String>.from(json['tone_pattern'] as List)
          : null,
      difficulty: (json['difficulty'] as num).toDouble(),
      culturalNote: json['cultural_note'] as String?,
      usageContext: json['usage_context'] as String? ?? 'general',
      exampleSentences: json['example_sentences'] != null
          ? (json['example_sentences'] as List)
              .map((e) => ExampleSentence.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      relatedWords: json['related_words'] != null
          ? List<String>.from(json['related_words'] as List)
          : null,
      grammarNotes: json['grammar_notes'] as String?,
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
      verifiedByNative: json['verified_by_native'] as bool? ?? false,
      audioUrl: json['audio_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'language_code': languageCode,
      'level': level,
      'category': category,
      'type': type,
      'text': text,
      'ipa': ipa,
      'transliteration': transliteration,
      'translation': translation,
      'tone_pattern': tonePattern,
      'difficulty': difficulty,
      'cultural_note': culturalNote,
      'usage_context': usageContext,
      'example_sentences': exampleSentences?.map((e) => e.toJson()).toList(),
      'related_words': relatedWords,
      'grammar_notes': grammarNotes,
      'quality_score': qualityScore,
      'verified_by_native': verifiedByNative,
      'audio_url': audioUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ExampleSentence {
  final String text;
  final String translation;
  final String? ipa;
  final String? audioUrl;

  ExampleSentence({
    required this.text,
    required this.translation,
    this.ipa,
    this.audioUrl,
  });

  factory ExampleSentence.fromJson(Map<String, dynamic> json) {
    return ExampleSentence(
      text: json['text'] as String,
      translation: json['translation'] as String,
      ipa: json['ipa'] as String?,
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'translation': translation,
      'ipa': ipa,
      'audio_url': audioUrl,
    };
  }
}

