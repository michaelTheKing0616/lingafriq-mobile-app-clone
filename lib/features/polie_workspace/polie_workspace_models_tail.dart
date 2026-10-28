
import 'package:lingafriq/models/correction_result.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';

class ConversationPayload {
  final String messageTarget;
  final String? englishTranslation;
  final ConversationCorrection correction;
  final List<String> suggestedReplies;
  final List<ConversationVocab> newVocab;
  /// When true, this turn represents a failed generation. UI shows a retry CTA.
  final bool isError;
  /// User-facing error message when [isError] is true.
  final String? errorMessage;
  const ConversationPayload({
    required this.messageTarget,
    required this.englishTranslation,
    required this.correction,
    required this.suggestedReplies,
    required this.newVocab,
    this.isError = false,
    this.errorMessage,
  });

  /// Constructs an error payload for failed generations so the UI can render a
  /// proper retry state instead of the legacy "-" placeholder.
  factory ConversationPayload.error(String message) {
    return ConversationPayload(
      messageTarget: '',
      englishTranslation: null,
      correction: const ConversationCorrection(
        tier: 'correct',
        hasCorrection: false,
        wasCorrect: true,
        correction: null,
        note: '',
      ),
      suggestedReplies: const [],
      newVocab: const [],
      isError: true,
      errorMessage: message,
    );
  }

  factory ConversationPayload.fromJson(
    Map<String, dynamic> json,
    String fallback,
  ) {
    final c = (polieJsonField(json, 'correction', const {}) as Map).cast<String, dynamic>();
    final replies = (polieJsonField(json, 'suggested_replies', const []) as List)
        .map((e) => e.toString())
        .toList();
    final vocabRaw = (polieJsonField(json, 'new_vocab', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    final rawEnglish = json['message_english'];
    // Fallback chain prefers the raw model text (cleaned) over a literal "-".
    final cleanedFallback = cleanAiText(fallback);
    return ConversationPayload(
      messageTarget: cleanAiText(
        (polieJsonField(json, 'message_target', polieJsonField(json, 'message', cleanedFallback)) as String),
        fallback: cleanedFallback,
      ),
      englishTranslation: (rawEnglish is String && rawEnglish.trim().isNotEmpty)
          ? cleanAiText(rawEnglish)
          : null,
      correction: ConversationCorrection(
        tier: CorrectionResult.fromJson(c).tier,
        hasCorrection: (polieJsonField(c, 'has_correction', false) as bool?) ?? false,
        wasCorrect: (polieJsonField(c, 'was_correct', true) as bool?) ?? true,
        correction: (polieJsonField(c, 'correction', '') as String?)?.trim().isEmpty ?? true
            ? null
            : (polieJsonField(c, 'correction', '') as String),
        note: cleanAiText((polieJsonField(c, 'note', '') as String)),
      ),
      suggestedReplies: replies
          .map((e) => cleanAiText(e, fallback: ''))
          .where((e) => e.isNotEmpty)
          .toList(),
      newVocab: vocabRaw
          .map(
            (e) => ConversationVocab(
              word: (polieJsonField(e, 'word', '') as String),
              meaning: (polieJsonField(e, 'meaning', '') as String),
            ),
          )
          .where((e) => e.word.trim().isNotEmpty)
          .toList(),
    );
  }
}

class ConversationCorrection {
  final String tier;
  final bool hasCorrection;
  final bool wasCorrect;
  final String? correction;
  final String note;
  const ConversationCorrection({
    required this.tier,
    required this.hasCorrection,
    required this.wasCorrect,
    required this.correction,
    required this.note,
  });

  String uxFeedbackLine() {
    return CorrectionResult(
      tier: tier,
      hasCorrection: hasCorrection,
      wasCorrect: wasCorrect,
      correction: correction,
      note: note,
    ).uxFeedbackLine();
  }
}

class ConversationVocab {
  final String word;
  final String meaning;
  const ConversationVocab({required this.word, required this.meaning});
}

class ConversationTurn {
  final String? userText;
  final ConversationPayload? ai;
  /// Indicates the user message that should be re-sent if this is an AI error
  /// turn. Used to power the "Retry" CTA in the conversation bubble.
  final String? userMessageForRetry;
  const ConversationTurn._({
    this.userText,
    this.ai,
    this.userMessageForRetry,
  });
  factory ConversationTurn.user(String text) =>
      ConversationTurn._(userText: text);
  factory ConversationTurn.ai(ConversationPayload ai) =>
      ConversationTurn._(ai: ai);
  factory ConversationTurn.aiError(String message, {String? retryUserText}) =>
      ConversationTurn._(
        ai: ConversationPayload.error(message),
        userMessageForRetry: retryUserText,
      );
}

class VocabPayload {
  final String word;
  final String pronunciation;
  final String partOfSpeech;
  final String english;
  final VocabExample example;
  final String memoryPeg;
  final String? culturalNote;
  final List<VocabRelatedWord> relatedWords;
  final String difficulty;
  const VocabPayload({
    required this.word,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.english,
    required this.example,
    required this.memoryPeg,
    required this.culturalNote,
    required this.relatedWords,
    required this.difficulty,
  });
  factory VocabPayload.fromJson(Map<String, dynamic> json, String fallback) {
    final ex = (polieJsonField(json, 'example', const {}) as Map).cast<String, dynamic>();
    final relatedRaw = (polieJsonField(json, 'related_words', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    return VocabPayload(
      word: cleanAiText(
        (polieJsonField(json, 'word', fallback) as String),
        fallback: 'New word',
      ),
      pronunciation: cleanAiText((polieJsonField(json, 'pronunciation', '-') as String)),
      partOfSpeech: cleanAiText(
        (polieJsonField(json, 'part_of_speech', 'word') as String),
        fallback: 'word',
      ),
      english: cleanAiText((polieJsonField(json, 'english', '-') as String)),
      example: VocabExample(
        target: cleanAiText((polieJsonField(ex, 'target', '-') as String)),
        english: cleanAiText((polieJsonField(ex, 'english', '-') as String)),
      ),
      memoryPeg: cleanAiText((polieJsonField(json, 'memory_peg', '-') as String)),
      culturalNote:
          (polieJsonField(json, 'cultural_note', '') as String?)?.trim().isEmpty ?? true
          ? null
          : (polieJsonField(json, 'cultural_note', '') as String),
      relatedWords: relatedRaw
          .map(
            (e) => VocabRelatedWord(
              word: (polieJsonField(e, 'word', '') as String),
              relationship: (polieJsonField(e, 'relationship', '') as String),
            ),
          )
          .where((e) => e.word.trim().isNotEmpty)
          .toList(),
      difficulty: cleanAiText(
        (polieJsonField(json, 'difficulty', 'beginner') as String),
        fallback: 'beginner',
      ),
    );
  }
}

class VocabExample {
  final String target;
  final String english;
  const VocabExample({required this.target, required this.english});
}

class VocabRelatedWord {
  final String word;
  final String relationship;
  const VocabRelatedWord({required this.word, required this.relationship});
}

class ReviewPayload {
  final String headlineInsight;
  final List<ReviewArea> strengths;
  final List<ReviewGrowthArea> growthAreas;
  final String coachingParagraph;
  final List<ReviewNextStep> nextSteps;
  final String motivationalClose;
  final int wordsSeen;
  final double accuracy;
  final int streak;
  final int lessonsDone;
  final Map<String, double> skillBars;
  const ReviewPayload({
    required this.headlineInsight,
    required this.strengths,
    required this.growthAreas,
    required this.coachingParagraph,
    required this.nextSteps,
    required this.motivationalClose,
    required this.wordsSeen,
    required this.accuracy,
    required this.streak,
    required this.lessonsDone,
    required this.skillBars,
  });
  factory ReviewPayload.fromJson(
    Map<String, dynamic> json,
    String fallback, {
    required int wordsSeen,
    required double accuracy,
    required int streak,
    required int lessonsDone,
  }) {
    final strengthsRaw = (polieJsonField(json, 'strengths', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    final growthRaw = (polieJsonField(json, 'growth_areas', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    final nextRaw = (polieJsonField(json, 'next_steps', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    return ReviewPayload(
      headlineInsight: (polieJsonField(json, 'headline_insight', fallback) as String),
      strengths: strengthsRaw
          .map(
            (e) => ReviewArea(
              area: (polieJsonField(e, 'area', '') as String),
              note: (polieJsonField(e, 'note', '') as String),
            ),
          )
          .where((e) => e.area.isNotEmpty)
          .toList(),
      growthAreas: growthRaw
          .map(
            (e) => ReviewGrowthArea(
              area: (polieJsonField(e, 'area', '') as String),
              note: (polieJsonField(e, 'note', '') as String),
              quickWin: (polieJsonField(e, 'quick_win', '') as String),
            ),
          )
          .where((e) => e.area.isNotEmpty)
          .toList(),
      coachingParagraph: (polieJsonField(json, 'coaching_paragraph', '-') as String),
      nextSteps: nextRaw
          .map(
            (e) => ReviewNextStep(
              type: (polieJsonField(e, 'type', '') as String),
              title: (polieJsonField(e, 'title', '') as String),
              why: (polieJsonField(e, 'why', '') as String),
            ),
          )
          .where((e) => e.title.isNotEmpty)
          .toList(),
      motivationalClose: (polieJsonField(json, 'motivational_close', '-') as String),
      wordsSeen: wordsSeen,
      accuracy: accuracy,
      streak: streak,
      lessonsDone: lessonsDone,
      skillBars: {
        'Vocabulary': ((accuracy / 100) + 0.05).clamp(0, 1).toDouble(),
        'Grammar': ((accuracy / 100) - 0.07).clamp(0, 1).toDouble(),
        'Pronunciation': ((accuracy / 100) - 0.12).clamp(0, 1).toDouble(),
        'Conversation': ((accuracy / 100) + 0.02).clamp(0, 1).toDouble(),
      },
    );
  }
}

class ReviewArea {
  final String area;
  final String note;
  const ReviewArea({required this.area, required this.note});
}

class ReviewGrowthArea {
  final String area;
  final String note;
  final String quickWin;
  const ReviewGrowthArea({
    required this.area,
    required this.note,
    required this.quickWin,
  });
}

class ReviewNextStep {
  final String type;
  final String title;
  final String why;
  const ReviewNextStep({
    required this.type,
    required this.title,
    required this.why,
  });
}

dynamic buildVocabularyWord(VocabPayload card, String language) {
  return VocabularyWord(
    word: card.word,
    meaning: card.english,
    language: language,
    pronunciation: card.pronunciation,
    partOfSpeech: card.partOfSpeech,
    examples: ['${card.example.target} - ${card.example.english}'],
    metadata: {
      'difficulty': card.difficulty,
      if (card.culturalNote != null) 'cultural_note': card.culturalNote,
    },
  );
}

bool isUnavailableWord(String word) {
  final w = word.trim().toLowerCase();
  return w.isEmpty ||
      w == 'word unavailable' ||
      w == 'unavailable' ||
      w == 'n/a' ||
      w == '-';
}

VocabPayload fallbackVocabPayload(String language) {
  final lang = language.trim().toLowerCase();
  if (lang.contains('yoruba')) {
    return const VocabPayload(
      word: 'ẹ̀kọ́',
      pronunciation: '/ɛ̀.kɔ́/',
      partOfSpeech: 'noun',
      english: 'lesson',
      example: VocabExample(
        target: 'Ẹ̀kọ́ yìí dára.',
        english: 'This lesson is good.',
      ),
      memoryPeg: 'Think of EKO as learning in action.',
      culturalNote: null,
      relatedWords: [VocabRelatedWord(word: 'kọ́', relationship: 'related')],
      difficulty: 'beginner',
    );
  }
  if (lang.contains('igbo')) {
    return const VocabPayload(
      word: 'mmụta',
      pronunciation: '/m.mu.ta/',
      partOfSpeech: 'noun',
      english: 'learning',
      example: VocabExample(
        target: 'Mmụ̀ta dị mkpa.',
        english: 'Learning is important.',
      ),
      memoryPeg: 'Learning grows step by step.',
      culturalNote: null,
      relatedWords: [VocabRelatedWord(word: 'mụ', relationship: 'related')],
      difficulty: 'beginner',
    );
  }
  if (lang.contains('swahili')) {
    return const VocabPayload(
      word: 'kujifunza',
      pronunciation: '/ku.dʒi.fun.za/',
      partOfSpeech: 'verb',
      english: 'to learn',
      example: VocabExample(
        target: 'Ninapenda kujifunza.',
        english: 'I like to learn.',
      ),
      memoryPeg: 'Learning is a daily journey.',
      culturalNote: null,
      relatedWords: [VocabRelatedWord(word: 'soma', relationship: 'related')],
      difficulty: 'beginner',
    );
  }
  return const VocabPayload(
    word: 'learning',
    pronunciation: '/lɜːrnɪŋ/',
    partOfSpeech: 'noun',
    english: 'learning',
    example: VocabExample(
      target: 'Learning opens opportunities.',
      english: 'Learning opens opportunities.',
    ),
    memoryPeg: 'Keep one new word every day.',
    culturalNote: null,
    relatedWords: [VocabRelatedWord(word: 'study', relationship: 'related')],
    difficulty: 'beginner',
  );
}
