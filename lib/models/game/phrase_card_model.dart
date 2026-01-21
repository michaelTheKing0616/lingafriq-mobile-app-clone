/// Phrase Card Model - Core data structure for all games
class PhraseCard {
  final String cardId;
  final String language;
  final String text; // With diacritics
  final String ascii; // ASCII fallback
  final String gloss; // Translation/meaning
  final String? ipa; // IPA transcription
  final String level; // CEFR level (A0, A1, A2, B1, B2, C1, C2)
  final List<String> tags; // e.g., ["greeting", "polite", "spoken"]
  final String? audioNativeUrl; // Native speaker audio URL
  final String? imageUrl; // Image URL for visual games
  final List<String> contextExamples; // Usage examples
  final SRSState srs; // Spaced Repetition System state

  PhraseCard({
    required this.cardId,
    required this.language,
    required this.text,
    required this.ascii,
    required this.gloss,
    this.ipa,
    required this.level,
    this.tags = const [],
    this.audioNativeUrl,
    this.imageUrl,
    this.contextExamples = const [],
    SRSState? srs,
  }) : srs = srs ?? SRSState();

  Map<String, dynamic> toJson() => {
        'card_id': cardId,
        'language': language,
        'text': text,
        'ascii': ascii,
        'gloss': gloss,
        'ipa': ipa,
        'level': level,
        'tags': tags,
        'audio_native_url': audioNativeUrl,
        'image_url': imageUrl,
        'context_examples': contextExamples,
        'srs': srs.toJson(),
      };

  factory PhraseCard.fromJson(Map<String, dynamic> json) => PhraseCard(
        cardId: json['card_id'] as String,
        language: json['language'] as String,
        text: json['text'] as String,
        ascii: json['ascii'] as String,
        gloss: json['gloss'] as String,
        ipa: json['ipa'] as String?,
        level: json['level'] as String,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        audioNativeUrl: json['audio_native_url'] as String?,
        imageUrl: json['image_url'] as String?,
        contextExamples: (json['context_examples'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        srs: json['srs'] != null
            ? SRSState.fromJson(json['srs'] as Map<String, dynamic>)
            : null,
      );

  PhraseCard copyWith({
    String? cardId,
    String? language,
    String? text,
    String? ascii,
    String? gloss,
    String? ipa,
    String? level,
    List<String>? tags,
    String? audioNativeUrl,
    String? imageUrl,
    List<String>? contextExamples,
    SRSState? srs,
  }) =>
      PhraseCard(
        cardId: cardId ?? this.cardId,
        language: language ?? this.language,
        text: text ?? this.text,
        ascii: ascii ?? this.ascii,
        gloss: gloss ?? this.gloss,
        ipa: ipa ?? this.ipa,
        level: level ?? this.level,
        tags: tags ?? this.tags,
        audioNativeUrl: audioNativeUrl ?? this.audioNativeUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        contextExamples: contextExamples ?? this.contextExamples,
        srs: srs ?? this.srs,
      );
}

/// SRS (Spaced Repetition System) State
class SRSState {
  final double ease; // Ease factor (default 2.5)
  final int repetitions; // Number of successful reviews
  final int intervalDays; // Days until next review
  final DateTime? lastReview;

  SRSState({
    this.ease = 2.5,
    this.repetitions = 0,
    this.intervalDays = 0,
    this.lastReview,
  });

  Map<String, dynamic> toJson() => {
        'ease': ease,
        'repetitions': repetitions,
        'interval_days': intervalDays,
        'last_review': lastReview?.toIso8601String(),
      };

  factory SRSState.fromJson(Map<String, dynamic> json) => SRSState(
        ease: (json['ease'] as num?)?.toDouble() ?? 2.5,
        repetitions: json['repetitions'] as int? ?? 0,
        intervalDays: json['interval_days'] as int? ?? 0,
        lastReview: json['last_review'] != null
            ? DateTime.parse(json['last_review'] as String)
            : null,
      );

  SRSState copyWith({
    double? ease,
    int? repetitions,
    int? intervalDays,
    DateTime? lastReview,
  }) =>
      SRSState(
        ease: ease ?? this.ease,
        repetitions: repetitions ?? this.repetitions,
        intervalDays: intervalDays ?? this.intervalDays,
        lastReview: lastReview ?? this.lastReview,
      );
}

