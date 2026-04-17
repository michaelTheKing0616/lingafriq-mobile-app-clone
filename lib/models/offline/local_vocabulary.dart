class LocalVocabulary {
  String id;
  String word;
  String translation;
  String language;
  String? pronunciation;
  String? audioPath;
  String? exampleSentence;
  String? exampleTranslation;
  String? sourceMediaId;
  int? sourceStartMs;
  int? sourceEndMs;
  double easeFactor;
  int interval;
  int repetitions;
  DateTime? nextReviewDate;
  DateTime? lastReviewedAt;
  int quality;
  int totalReviews;
  int correctReviews;
  String? category;
  DateTime addedAt;
  bool isMastered;

  LocalVocabulary({
    required this.id,
    required this.word,
    required this.translation,
    required this.language,
    this.pronunciation,
    this.audioPath,
    this.exampleSentence,
    this.exampleTranslation,
    this.sourceMediaId,
    this.sourceStartMs,
    this.sourceEndMs,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.nextReviewDate,
    this.lastReviewedAt,
    this.quality = 0,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.category,
    DateTime? addedAt,
    this.isMastered = false,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'language': language,
      'pronunciation': pronunciation,
      'audioPath': audioPath,
      'exampleSentence': exampleSentence,
      'exampleTranslation': exampleTranslation,
      'sourceMediaId': sourceMediaId,
      'sourceStartMs': sourceStartMs,
      'sourceEndMs': sourceEndMs,
      'easeFactor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'quality': quality,
      'totalReviews': totalReviews,
      'correctReviews': correctReviews,
      'category': category,
      'addedAt': addedAt.toIso8601String(),
      'isMastered': isMastered,
    };
  }

  factory LocalVocabulary.fromJson(Map<String, dynamic> json) {
    return LocalVocabulary(
      id: json['id'] as String,
      word: json['word'] as String,
      translation: json['translation'] as String,
      language: json['language'] as String,
      pronunciation: json['pronunciation'] as String?,
      audioPath: json['audioPath'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
      exampleTranslation: json['exampleTranslation'] as String?,
      sourceMediaId: json['sourceMediaId'] as String?,
      sourceStartMs: json['sourceStartMs'] as int?,
      sourceEndMs: json['sourceEndMs'] as int?,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      interval: json['interval'] as int? ?? 0,
      repetitions: json['repetitions'] as int? ?? 0,
      nextReviewDate: json['nextReviewDate'] != null
          ? DateTime.parse(json['nextReviewDate'] as String)
          : null,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
      quality: json['quality'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      correctReviews: json['correctReviews'] as int? ?? 0,
      category: json['category'] as String?,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
      isMastered: json['isMastered'] as bool? ?? false,
    );
  }

  LocalVocabulary copyWith({
    String? id,
    String? word,
    String? translation,
    String? language,
    String? pronunciation,
    String? audioPath,
    String? exampleSentence,
    String? exampleTranslation,
    String? sourceMediaId,
    int? sourceStartMs,
    int? sourceEndMs,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReviewDate,
    DateTime? lastReviewedAt,
    int? quality,
    int? totalReviews,
    int? correctReviews,
    String? category,
    DateTime? addedAt,
    bool? isMastered,
  }) {
    return LocalVocabulary(
      id: id ?? this.id,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      language: language ?? this.language,
      pronunciation: pronunciation ?? this.pronunciation,
      audioPath: audioPath ?? this.audioPath,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      sourceMediaId: sourceMediaId ?? this.sourceMediaId,
      sourceStartMs: sourceStartMs ?? this.sourceStartMs,
      sourceEndMs: sourceEndMs ?? this.sourceEndMs,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      quality: quality ?? this.quality,
      totalReviews: totalReviews ?? this.totalReviews,
      correctReviews: correctReviews ?? this.correctReviews,
      category: category ?? this.category,
      addedAt: addedAt ?? this.addedAt,
      isMastered: isMastered ?? this.isMastered,
    );
  }
}
