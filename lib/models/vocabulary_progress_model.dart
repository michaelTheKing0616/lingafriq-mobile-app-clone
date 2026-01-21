/// Vocabulary Progress Model
/// Tracks vocabulary learning, mastery, and spaced repetition
import 'dart:convert';

/// Vocabulary Word
class VocabularyWord {
  final String word;
  final String meaning;
  final String language;
  final String? pronunciation;
  final String? partOfSpeech;
  final List<String>? examples;
  final String? imageUrl;
  final String? audioUrl;
  final Map<String, dynamic>? metadata;

  VocabularyWord({
    required this.word,
    required this.meaning,
    required this.language,
    this.pronunciation,
    this.partOfSpeech,
    this.examples,
    this.imageUrl,
    this.audioUrl,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
        'language': language,
        if (pronunciation != null) 'pronunciation': pronunciation,
        if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
        if (examples != null) 'examples': examples,
        if (imageUrl != null) 'image_url': imageUrl,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (metadata != null) 'metadata': metadata,
      };

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      language: json['language'] ?? '',
      pronunciation: json['pronunciation'],
      partOfSpeech: json['part_of_speech'],
      examples: json['examples'] != null ? List<String>.from(json['examples']) : null,
      imageUrl: json['image_url'],
      audioUrl: json['audio_url'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

/// Word Mastery
class WordMastery {
  final String word;
  final String language;
  final int timesSeen;
  final int timesCorrect;
  final double masteryLevel; // 0.0 to 1.0
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final DateTime? nextReview; // SRS next review date
  final int intervalDays; // SRS interval
  final double easeFactor; // SRS ease factor
  final String category;
  final Map<String, dynamic>? metadata;

  WordMastery({
    required this.word,
    required this.language,
    this.timesSeen = 0,
    this.timesCorrect = 0,
    this.masteryLevel = 0.0,
    this.firstSeen,
    this.lastSeen,
    this.nextReview,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    this.category = 'general',
    this.metadata,
  });

  bool get isMastered => masteryLevel >= 0.9;
  bool get isDueForReview => nextReview != null && DateTime.now().isAfter(nextReview!);

  WordMastery copyWith({
    String? word,
    String? language,
    int? timesSeen,
    int? timesCorrect,
    double? masteryLevel,
    DateTime? firstSeen,
    DateTime? lastSeen,
    DateTime? nextReview,
    int? intervalDays,
    double? easeFactor,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return WordMastery(
      word: word ?? this.word,
      language: language ?? this.language,
      timesSeen: timesSeen ?? this.timesSeen,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      nextReview: nextReview ?? this.nextReview,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'language': language,
        'times_seen': timesSeen,
        'times_correct': timesCorrect,
        'mastery_level': masteryLevel,
        if (firstSeen != null) 'first_seen': firstSeen!.toIso8601String(),
        if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
        if (nextReview != null) 'next_review': nextReview!.toIso8601String(),
        'interval_days': intervalDays,
        'ease_factor': easeFactor,
        'category': category,
        if (metadata != null) 'metadata': metadata,
      };

  factory WordMastery.fromJson(Map<String, dynamic> json) {
    return WordMastery(
      word: json['word'] ?? '',
      language: json['language'] ?? '',
      timesSeen: json['times_seen'] ?? 0,
      timesCorrect: json['times_correct'] ?? 0,
      masteryLevel: (json['mastery_level'] ?? 0.0).toDouble(),
      firstSeen: json['first_seen'] != null
          ? DateTime.parse(json['first_seen'])
          : null,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      nextReview: json['next_review'] != null
          ? DateTime.parse(json['next_review'])
          : null,
      intervalDays: json['interval_days'] ?? 1,
      easeFactor: (json['ease_factor'] ?? 2.5).toDouble(),
      category: json['category'] ?? 'general',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

/// Vocabulary Progress
class VocabularyProgress {
  final String language;
  final Map<String, WordMastery> words; // word -> mastery
  final Map<String, int> categoryCounts; // category -> count
  final int totalWordsLearned;
  final int totalWordsMastered;
  final int wordsDueForReview;
  final DateTime? lastActivity;

  VocabularyProgress({
    required this.language,
    this.words = const {},
    this.categoryCounts = const {},
    this.totalWordsLearned = 0,
    this.totalWordsMastered = 0,
    this.wordsDueForReview = 0,
    this.lastActivity,
  });

  VocabularyProgress copyWith({
    String? language,
    Map<String, WordMastery>? words,
    Map<String, int>? categoryCounts,
    int? totalWordsLearned,
    int? totalWordsMastered,
    int? wordsDueForReview,
    DateTime? lastActivity,
  }) {
    return VocabularyProgress(
      language: language ?? this.language,
      words: words ?? this.words,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      totalWordsMastered: totalWordsMastered ?? this.totalWordsMastered,
      wordsDueForReview: wordsDueForReview ?? this.wordsDueForReview,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  /// Get words due for review
  List<WordMastery> getDueWords() {
    return words.values.where((w) => w.isDueForReview).toList();
  }

  /// Get words by category
  List<WordMastery> getWordsByCategory(String category) {
    return words.values.where((w) => w.category == category).toList();
  }

  /// Get mastered words
  List<WordMastery> getMasteredWords() {
    return words.values.where((w) => w.isMastered).toList();
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'words': words.map((k, v) => MapEntry(k, v.toJson())),
        'category_counts': categoryCounts,
        'total_words_learned': totalWordsLearned,
        'total_words_mastered': totalWordsMastered,
        'words_due_for_review': wordsDueForReview,
        if (lastActivity != null) 'last_activity': lastActivity!.toIso8601String(),
      };

  factory VocabularyProgress.fromJson(Map<String, dynamic> json) {
    final wordsMap = (json['words'] as Map<String, dynamic>?) ?? {};
    final words = wordsMap.map(
      (k, v) => MapEntry(k, WordMastery.fromJson(v as Map<String, dynamic>)),
    );

    // Calculate derived metrics
    final totalLearned = words.length;
    final totalMastered = words.values.where((w) => w.isMastered).length;
    final dueForReview = words.values.where((w) => w.isDueForReview).length;

    // Calculate category counts
    final categoryCounts = <String, int>{};
    for (final word in words.values) {
      categoryCounts[word.category] = (categoryCounts[word.category] ?? 0) + 1;
    }

    return VocabularyProgress(
      language: json['language'] ?? '',
      words: words,
      categoryCounts: categoryCounts,
      totalWordsLearned: totalLearned,
      totalWordsMastered: totalMastered,
      wordsDueForReview: dueForReview,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory VocabularyProgress.fromJsonString(String jsonString) {
    return VocabularyProgress.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

