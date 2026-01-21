/// Translation History Model
/// Stores translation history with alternatives, grammar breakdown, and cultural context
import 'dart:convert';

/// Grammar Breakdown
class GrammarBreakdown {
  final String word;
  final String partOfSpeech;
  final String root;
  final String? prefix;
  final String? suffix;
  final Map<String, dynamic>? grammaticalInfo; // tense, mood, aspect, etc.
  final String? explanation;

  GrammarBreakdown({
    required this.word,
    required this.partOfSpeech,
    required this.root,
    this.prefix,
    this.suffix,
    this.grammaticalInfo,
    this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'part_of_speech': partOfSpeech,
        'root': root,
        if (prefix != null) 'prefix': prefix,
        if (suffix != null) 'suffix': suffix,
        if (grammaticalInfo != null) 'grammatical_info': grammaticalInfo,
        if (explanation != null) 'explanation': explanation,
      };

  factory GrammarBreakdown.fromJson(Map<String, dynamic> json) {
    return GrammarBreakdown(
      word: json['word'] ?? '',
      partOfSpeech: json['part_of_speech'] ?? '',
      root: json['root'] ?? '',
      prefix: json['prefix'],
      suffix: json['suffix'],
      grammaticalInfo: json['grammatical_info'] != null
          ? Map<String, dynamic>.from(json['grammatical_info'])
          : null,
      explanation: json['explanation'],
    );
  }
}

/// Cultural Context
class CulturalContext {
  final String? context;
  final String? regionalVariation;
  final String? formalityLevel;
  final String? usageNote;
  final List<String>? relatedExpressions;
  final Map<String, dynamic>? additionalInfo;

  CulturalContext({
    this.context,
    this.regionalVariation,
    this.formalityLevel,
    this.usageNote,
    this.relatedExpressions,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() => {
        if (context != null) 'context': context,
        if (regionalVariation != null) 'regional_variation': regionalVariation,
        if (formalityLevel != null) 'formality_level': formalityLevel,
        if (usageNote != null) 'usage_note': usageNote,
        if (relatedExpressions != null) 'related_expressions': relatedExpressions,
        if (additionalInfo != null) 'additional_info': additionalInfo,
      };

  factory CulturalContext.fromJson(Map<String, dynamic> json) {
    return CulturalContext(
      context: json['context'],
      regionalVariation: json['regional_variation'],
      formalityLevel: json['formality_level'],
      usageNote: json['usage_note'],
      relatedExpressions: json['related_expressions'] != null
          ? List<String>.from(json['related_expressions'])
          : null,
      additionalInfo: json['additional_info'] != null
          ? Map<String, dynamic>.from(json['additional_info'])
          : null,
    );
  }
}

/// Translation Alternative
class TranslationAlternative {
  final String translation;
  final String? context;
  final String? formalityLevel;
  final double? confidence;
  final CulturalContext? culturalContext;

  TranslationAlternative({
    required this.translation,
    this.context,
    this.formalityLevel,
    this.confidence,
    this.culturalContext,
  });

  Map<String, dynamic> toJson() => {
        'translation': translation,
        if (context != null) 'context': context,
        if (formalityLevel != null) 'formality_level': formalityLevel,
        if (confidence != null) 'confidence': confidence,
        if (culturalContext != null) 'cultural_context': culturalContext!.toJson(),
      };

  factory TranslationAlternative.fromJson(Map<String, dynamic> json) {
    return TranslationAlternative(
      translation: json['translation'] ?? '',
      context: json['context'],
      formalityLevel: json['formality_level'],
      confidence: json['confidence'] != null ? (json['confidence'] as num).toDouble() : null,
      culturalContext: json['cultural_context'] != null
          ? CulturalContext.fromJson(json['cultural_context'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Translation Entry
class TranslationEntry {
  final String id;
  final String sourceText;
  final String sourceLanguage;
  final String targetLanguage;
  final String primaryTranslation;
  final List<TranslationAlternative> alternatives;
  final List<GrammarBreakdown> grammarBreakdown;
  final CulturalContext? culturalContext;
  final DateTime timestamp;
  final bool isFavorite;
  final String? notes;
  final Map<String, dynamic>? metadata;

  TranslationEntry({
    required this.id,
    required this.sourceText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.primaryTranslation,
    this.alternatives = const [],
    this.grammarBreakdown = const [],
    this.culturalContext,
    required this.timestamp,
    this.isFavorite = false,
    this.notes,
    this.metadata,
  });

  TranslationEntry copyWith({
    String? id,
    String? sourceText,
    String? sourceLanguage,
    String? targetLanguage,
    String? primaryTranslation,
    List<TranslationAlternative>? alternatives,
    List<GrammarBreakdown>? grammarBreakdown,
    CulturalContext? culturalContext,
    DateTime? timestamp,
    bool? isFavorite,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return TranslationEntry(
      id: id ?? this.id,
      sourceText: sourceText ?? this.sourceText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      primaryTranslation: primaryTranslation ?? this.primaryTranslation,
      alternatives: alternatives ?? this.alternatives,
      grammarBreakdown: grammarBreakdown ?? this.grammarBreakdown,
      culturalContext: culturalContext ?? this.culturalContext,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_text': sourceText,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
        'primary_translation': primaryTranslation,
        'alternatives': alternatives.map((a) => a.toJson()).toList(),
        'grammar_breakdown': grammarBreakdown.map((g) => g.toJson()).toList(),
        if (culturalContext != null) 'cultural_context': culturalContext!.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'is_favorite': isFavorite,
        if (notes != null) 'notes': notes,
        if (metadata != null) 'metadata': metadata,
      };

  factory TranslationEntry.fromJson(Map<String, dynamic> json) {
    return TranslationEntry(
      id: json['id'] ?? '',
      sourceText: json['source_text'] ?? '',
      sourceLanguage: json['source_language'] ?? '',
      targetLanguage: json['target_language'] ?? '',
      primaryTranslation: json['primary_translation'] ?? '',
      alternatives: (json['alternatives'] as List?)
              ?.map((a) => TranslationAlternative.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      grammarBreakdown: (json['grammar_breakdown'] as List?)
              ?.map((g) => GrammarBreakdown.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
      culturalContext: json['cultural_context'] != null
          ? CulturalContext.fromJson(json['cultural_context'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.parse(json['timestamp']),
      isFavorite: json['is_favorite'] ?? false,
      notes: json['notes'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

/// Translation History
class TranslationHistory {
  final List<TranslationEntry> entries;
  final Map<String, int> languagePairCounts; // "en-yo" -> count
  final DateTime? lastUpdated;

  TranslationHistory({
    this.entries = const [],
    this.languagePairCounts = const {},
    this.lastUpdated,
  });

  TranslationHistory copyWith({
    List<TranslationEntry>? entries,
    Map<String, int>? languagePairCounts,
    DateTime? lastUpdated,
  }) {
    return TranslationHistory(
      entries: entries ?? this.entries,
      languagePairCounts: languagePairCounts ?? this.languagePairCounts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  List<TranslationEntry> getFavorites() {
    return entries.where((e) => e.isFavorite).toList();
  }

  List<TranslationEntry> getByLanguagePair(String sourceLang, String targetLang) {
    return entries.where((e) =>
        e.sourceLanguage == sourceLang && e.targetLanguage == targetLang).toList();
  }

  List<TranslationEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return entries.where((e) =>
        e.sourceText.toLowerCase().contains(lowerQuery) ||
        e.primaryTranslation.toLowerCase().contains(lowerQuery)).toList();
  }

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
        'language_pair_counts': languagePairCounts,
        if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
      };

  factory TranslationHistory.fromJson(Map<String, dynamic> json) {
    return TranslationHistory(
      entries: (json['entries'] as List?)
              ?.map((e) => TranslationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languagePairCounts: Map<String, int>.from(json['language_pair_counts'] ?? {}),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory TranslationHistory.fromJsonString(String jsonString) {
    return TranslationHistory.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

