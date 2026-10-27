import 'package:lingafriq/learning/learner_model/learner_model_service.dart';

/// Transforms imported user media into actionable learning items.
///
/// When a user imports text, audio, or video, this pipeline:
/// 1. Parses the content into linguistic units
/// 2. Extracts vocabulary, phrases, and grammar patterns
/// 3. Generates spaced repetition review items
/// 4. Creates pronunciation drill targets
/// 5. Produces comprehension questions
///
/// This creates a power-user flywheel: any content becomes learning material.
class MediaLearningPipeline {
  final LearnerModelService _learnerModel;

  MediaLearningPipeline({
    LearnerModelService? learnerModel,
  }) : _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Processes imported text and generates learning items.
  Future<MediaLearningResult> processText({
    required String text,
    required String sourceLanguage,
    required String learnerId,
    String? title,
  }) async {
    final words = _tokenize(text);
    final sentences = _splitSentences(text);

    // 1. Extract vocabulary
    final vocabulary = _extractVocabulary(words, sourceLanguage);

    // 2. Extract phrases (multi-word units)
    final phrases = _extractPhrases(sentences, sourceLanguage);

    // 3. Generate review items
    final reviewItems = _generateReviewItems(
      vocabulary: vocabulary,
      phrases: phrases,
      sentences: sentences,
      sourceLanguage: sourceLanguage,
    );

    // 4. Generate pronunciation targets
    final pronunciationTargets = _generatePronunciationTargets(
      vocabulary: vocabulary,
      sourceLanguage: sourceLanguage,
    );

    // 5. Generate comprehension questions
    final comprehensionQuestions = _generateComprehensionQuestions(
      sentences: sentences,
      vocabulary: vocabulary,
    );

    // 6. Identify which items are new vs. already known
    final knownIds = _learnerModel.getMasteredSkillIds(learnerId, sourceLanguage);
    final newVocab = vocabulary.where((v) => !knownIds.contains(v.skillId)).toList();

    return MediaLearningResult(
      title: title ?? 'Imported content',
      sourceText: text,
      sourceLanguage: sourceLanguage,
      totalWords: words.length,
      uniqueWords: words.toSet().length,
      vocabulary: vocabulary,
      newVocabulary: newVocab,
      phrases: phrases,
      reviewItems: reviewItems,
      pronunciationTargets: pronunciationTargets,
      comprehensionQuestions: comprehensionQuestions,
      processedAt: DateTime.now(),
    );
  }

  /// Processes imported audio by first transcribing, then generating items.
  ///
  /// Transcription is handled by the existing STT service — this method
  /// accepts the transcription result and processes it.
  Future<MediaLearningResult> processTranscription({
    required String transcription,
    required String sourceLanguage,
    required String learnerId,
    String? title,
  }) async {
    final result = await processText(
      text: transcription,
      sourceLanguage: sourceLanguage,
      learnerId: learnerId,
      title: title ?? 'Audio import',
    );

    // Audio imports get extra pronunciation targets
    final extraTargets = result.vocabulary.map((v) => PronunciationTarget(
      word: v.word,
      skillId: v.skillId,
      priority: 0.8, // Higher priority since learner chose this audio
    )).toList();

    return MediaLearningResult(
      title: result.title,
      sourceText: result.sourceText,
      sourceLanguage: result.sourceLanguage,
      totalWords: result.totalWords,
      uniqueWords: result.uniqueWords,
      vocabulary: result.vocabulary,
      newVocabulary: result.newVocabulary,
      phrases: result.phrases,
      reviewItems: result.reviewItems,
      pronunciationTargets: [...result.pronunciationTargets, ...extraTargets],
      comprehensionQuestions: result.comprehensionQuestions,
      processedAt: result.processedAt,
    );
  }

  /// Builds one lesson from a learner's media. The model line is quoted from
  /// that media. Generated checks are tagged unreviewed and are not a CI lint.
  ImportedMediaLesson buildLesson({
    required String text,
    required String sourceLanguage,
    required String mediaId,
    required String span,
    String? title,
  }) {
    final source = text.trim();
    final id = mediaId.trim();
    final cite = span.trim();
    if (source.isEmpty) {
      throw ArgumentError('Import Media lesson needs text from the media');
    }
    if (id.isEmpty || cite.isEmpty) {
      throw ArgumentError('Import Media lesson needs a media id and a timestamp or span');
    }

    final sentences = _splitSentences(source);
    final model = sentences.isNotEmpty ? sentences.first : source;
    final words = _tokenize(model);
    final vocabulary = _extractVocabulary(words, sourceLanguage);
    final focus = vocabulary.isNotEmpty
        ? _surfaceFormInText(model, vocabulary.first.word)
        : (words.isNotEmpty ? words.first : model);
    final cards = <ReviewItemFromMedia>[];
    final seenAnswers = <String>{};
    for (final item in vocabulary) {
      if (cards.length >= 10) break;
      final answer = _surfaceFormInText(source, item.word);
      final key = answer.toLowerCase();
      if (seenAnswers.contains(key)) continue;
      if (!source.toLowerCase().contains(key)) continue;
      seenAnswers.add(key);
      cards.add(ReviewItemFromMedia(
        skillId: item.skillId,
        type: MediaReviewType.cloze,
        prompt: _singleWordCloze(model, answer),
        answer: answer,
        context: model,
        mediaId: id,
        span: cite,
      ));
    }

    final glosses = _buildUncitedGlosses(
      words: _tokenize(model),
      sourceLanguage: sourceLanguage,
    );

    return ImportedMediaLesson(
      title: title ?? 'From your media',
      mediaId: id,
      span: cite,
      sourceLanguage: sourceLanguage,
      provenance: 'from your media',
      objective: 'Notice and reuse one line from your media',
      modelText: model,
      focus: focus,
      guidedPrompt: _singleWordCloze(model, focus),
      guidedAnswer: focus,
      glosses: glosses,
      checkQuestion: 'Which line is from your media?',
      checkAnswer: model,
      checkProvenance: 'AI-generated, unreviewed',
      toneStep: 'Listen to the tone in this line from your media: $model. No tone pattern is claimed.',
      shadowingText: model,
      flashcards: cards,
    );
  }

  // ─── Extraction logic ──────────────────────────────────────────────

  List<ExtractedVocabulary> _extractVocabulary(
    List<String> words,
    String language,
  ) {
    final frequency = <String, int>{};
    for (final word in words) {
      final normalized = word.toLowerCase().trim();
      if (normalized.length > 1) {
        frequency[normalized] = (frequency[normalized] ?? 0) + 1;
      }
    }

    // Sort by frequency (most common first) — more useful to learn
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((entry) {
      return ExtractedVocabulary(
        word: entry.key,
        frequency: entry.value,
        skillId: '${language}_vocab_${entry.key}',
        context: _findContext(entry.key, words),
      );
    }).toList();
  }

  List<ExtractedPhrase> _extractPhrases(
    List<String> sentences,
    String language,
  ) {
    final phrases = <ExtractedPhrase>[];

    for (final sentence in sentences) {
      final words = _tokenize(sentence);
      if (words.length < 3 || words.length > 12) continue;

      phrases.add(ExtractedPhrase(
        phrase: sentence.trim(),
        wordCount: words.length,
        skillId: '${language}_phrase_${sentence.trim().hashCode.abs()}',
      ));
    }

    return phrases;
  }

  List<ReviewItemFromMedia> _generateReviewItems({
    required List<ExtractedVocabulary> vocabulary,
    required List<ExtractedPhrase> phrases,
    required List<String> sentences,
    required String sourceLanguage,
  }) {
    final items = <ReviewItemFromMedia>[];

    // Vocab review items: recall + recognition
    for (final vocab in vocabulary.take(20)) {
      items.add(ReviewItemFromMedia(
        skillId: vocab.skillId,
        type: MediaReviewType.vocabularyRecall,
        prompt: 'What does "${vocab.word}" mean?',
        answer: vocab.word,
        context: vocab.context,
      ));

      items.add(ReviewItemFromMedia(
        skillId: vocab.skillId,
        type: MediaReviewType.cloze,
        prompt: _generateCloze(vocab.word, vocab.context),
        answer: vocab.word,
        context: vocab.context,
      ));
    }

    // Phrase review items: translation
    for (final phrase in phrases.take(10)) {
      items.add(ReviewItemFromMedia(
        skillId: phrase.skillId,
        type: MediaReviewType.phraseTranslation,
        prompt: 'Translate: "${phrase.phrase}"',
        answer: phrase.phrase,
      ));
    }

    return items;
  }

  List<PronunciationTarget> _generatePronunciationTargets({
    required List<ExtractedVocabulary> vocabulary,
    required String sourceLanguage,
  }) {
    return vocabulary.take(15).map((vocab) {
      return PronunciationTarget(
        word: vocab.word,
        skillId: '${sourceLanguage}_pron_${vocab.word}',
        priority: vocab.frequency > 3 ? 0.9 : 0.5,
      );
    }).toList();
  }

  List<ComprehensionQuestion> _generateComprehensionQuestions({
    required List<String> sentences,
    required List<ExtractedVocabulary> vocabulary,
  }) {
    final questions = <ComprehensionQuestion>[];

    // True/false comprehension
    for (int i = 0; i < sentences.length && questions.length < 5; i++) {
      if (sentences[i].split(' ').length >= 4) {
        questions.add(ComprehensionQuestion(
          type: ComprehensionType.trueFalse,
          question: 'The text mentions: "${sentences[i].trim()}"',
          correctAnswer: 'true',
          context: sentences[i],
        ));
      }
    }

    // Vocabulary in context
    for (final vocab in vocabulary.take(5)) {
      questions.add(ComprehensionQuestion(
        type: ComprehensionType.vocabularyMeaning,
        question: 'In the text, what role does "${vocab.word}" play?',
        correctAnswer: vocab.word,
        context: vocab.context,
      ));
    }

    return questions;
  }

  // ─── Utility methods ───────────────────────────────────────────────

  List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'[\s,;:!?.]+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.split(' ').length >= 2)
        .toList();
  }

  String _findContext(String word, List<String> allWords) {
    final idx = allWords.indexWhere(
      (w) => w.toLowerCase() == word.toLowerCase(),
    );
    if (idx < 0) return word;

    final start = (idx - 3).clamp(0, allWords.length);
    final end = (idx + 4).clamp(0, allWords.length);
    return allWords.sublist(start, end).join(' ');
  }

  String _generateCloze(String word, String context) {
    return context.replaceAll(
      RegExp(word, caseSensitive: false),
      '____',
    );
  }

  /// Hides exactly one token in [sentence] for guided practice.
  String _surfaceFormInText(String text, String normalized) {
    for (final token in _tokenize(text)) {
      if (token.toLowerCase() == normalized.toLowerCase()) {
        return token;
      }
    }
    return normalized;
  }

  String _singleWordCloze(String sentence, String word) {
    final escaped = RegExp.escape(word);
    final pattern = RegExp('\\b$escaped\\b', caseSensitive: false);
    if (!pattern.hasMatch(sentence)) {
      return sentence.replaceFirst(word, '____');
    }
    return sentence.replaceFirst(pattern, '____');
  }

  /// Glosses without a lexicon citation stay unreviewed (no invented meanings).
  List<MediaWordGloss> _buildUncitedGlosses({
    required List<String> words,
    required String sourceLanguage,
  }) {
    final glosses = <MediaWordGloss>[];
    final seen = <String>{};
    for (final raw in words) {
      final token = raw.trim();
      if (token.length < 2) continue;
      final key = token.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      glosses.add(MediaWordGloss(
        word: token,
        gloss: 'Confirm meaning in context ($sourceLanguage)',
        provenance: 'AI-generated, unreviewed',
      ));
    }
    return glosses;
  }
}

// ─── Data classes ──────────────────────────────────────────────────

class MediaLearningResult {
  final String title;
  final String sourceText;
  final String sourceLanguage;
  final int totalWords;
  final int uniqueWords;
  final List<ExtractedVocabulary> vocabulary;
  final List<ExtractedVocabulary> newVocabulary;
  final List<ExtractedPhrase> phrases;
  final List<ReviewItemFromMedia> reviewItems;
  final List<PronunciationTarget> pronunciationTargets;
  final List<ComprehensionQuestion> comprehensionQuestions;
  final DateTime processedAt;

  const MediaLearningResult({
    required this.title,
    required this.sourceText,
    required this.sourceLanguage,
    required this.totalWords,
    required this.uniqueWords,
    required this.vocabulary,
    required this.newVocabulary,
    required this.phrases,
    required this.reviewItems,
    required this.pronunciationTargets,
    required this.comprehensionQuestions,
    required this.processedAt,
  });

  int get totalLearningItems =>
      reviewItems.length + pronunciationTargets.length + comprehensionQuestions.length;
}

class ExtractedVocabulary {
  final String word;
  final int frequency;
  final String skillId;
  final String context;

  const ExtractedVocabulary({
    required this.word,
    required this.frequency,
    required this.skillId,
    required this.context,
  });
}

class ExtractedPhrase {
  final String phrase;
  final int wordCount;
  final String skillId;

  const ExtractedPhrase({
    required this.phrase,
    required this.wordCount,
    required this.skillId,
  });
}

class ReviewItemFromMedia {
  final String skillId;
  final MediaReviewType type;
  final String prompt;
  final String answer;
  final String? context;
  final String? mediaId;
  final String? span;

  const ReviewItemFromMedia({
    required this.skillId,
    required this.type,
    required this.prompt,
    required this.answer,
    this.context,
    this.mediaId,
    this.span,
  });
}

class MediaWordGloss {
  final String word;
  final String gloss;
  final String provenance;

  const MediaWordGloss({
    required this.word,
    required this.gloss,
    required this.provenance,
  });
}

class PronunciationTarget {
  final String word;
  final String skillId;
  final double priority;

  const PronunciationTarget({
    required this.word,
    required this.skillId,
    required this.priority,
  });
}

class ComprehensionQuestion {
  final ComprehensionType type;
  final String question;
  final String correctAnswer;
  final String context;

  const ComprehensionQuestion({
    required this.type,
    required this.question,
    required this.correctAnswer,
    required this.context,
  });
}

enum MediaReviewType { vocabularyRecall, cloze, phraseTranslation }
enum ComprehensionType { trueFalse, vocabularyMeaning, inference }

/// A personal lesson built from one Import Media item.
class ImportedMediaLesson {
  final String title;
  final String mediaId;
  final String span;
  final String sourceLanguage;
  final String provenance;
  final String objective;
  final String modelText;
  final String focus;
  final String guidedPrompt;
  final String guidedAnswer;
  final String checkQuestion;
  final String checkAnswer;
  final String checkProvenance;
  final String toneStep;
  final String shadowingText;
  final List<ReviewItemFromMedia> flashcards;
  final List<MediaWordGloss> glosses;

  const ImportedMediaLesson({
    required this.title,
    required this.mediaId,
    required this.span,
    required this.sourceLanguage,
    required this.provenance,
    required this.objective,
    required this.modelText,
    required this.focus,
    required this.guidedPrompt,
    required this.guidedAnswer,
    required this.checkQuestion,
    required this.checkAnswer,
    required this.checkProvenance,
    required this.toneStep,
    required this.shadowingText,
    required this.flashcards,
    required this.glosses,
  });
}
