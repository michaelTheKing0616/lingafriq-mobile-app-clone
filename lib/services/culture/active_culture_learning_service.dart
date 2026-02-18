import 'dart:math';

import 'package:lingafriq/learning/learner_model/learner_model_service.dart';

/// Exercise types for culture magazine active learning.
enum CultureExerciseType {
  cloze,
  vocabulary,
  comprehension,
  listening,
  wordMatch,
  sentenceReorder,
  factCheck,
}

/// A single culture learning exercise (cloze, vocab, comprehension, micro-task).
class CultureExercise {
  final String id;
  final CultureExerciseType type;
  final String prompt;
  final List<String>? options;
  final String correctAnswer;
  final String skillId;
  final double difficulty;
  final String? explanation;

  const CultureExercise({
    required this.id,
    required this.type,
    required this.prompt,
    this.options,
    required this.correctAnswer,
    required this.skillId,
    this.difficulty = 0.5,
    this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'prompt': prompt,
        if (options != null) 'options': options,
        'correctAnswer': correctAnswer,
        'skillId': skillId,
        'difficulty': difficulty,
        if (explanation != null) 'explanation': explanation,
      };
}

/// Session summary for article-based learning.
class ArticleLearningSession {
  final String articleId;
  final List<CultureExercise> exercises;
  final int completedCount;
  final int correctCount;
  final List<String> skillsUpdated;

  const ArticleLearningSession({
    required this.articleId,
    required this.exercises,
    required this.completedCount,
    required this.correctCount,
    required this.skillsUpdated,
  });

  double get accuracy =>
      completedCount > 0 ? correctCount / completedCount : 0.0;
}

/// Transforms static culture magazine content into active learning exercises
/// using deterministic NLP heuristics (no LLM). Integrates with [LearnerModelService].
class ActiveCultureLearningService {
  ActiveCultureLearningService._();
  static final ActiveCultureLearningService _instance =
      ActiveCultureLearningService._();
  static ActiveCultureLearningService get instance => _instance;

  static const _stopWords = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'must', 'shall', 'can', 'to', 'of', 'in',
    'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during',
  };

  final Random _random = Random(42);

  /// Generates fill-in-the-blank exercises by removing key words from sentences.
  /// Deterministic: picks words by length and position.
  List<CultureExercise> generateClozeExercises(
    String articleText,
    String targetLanguage, {
    int count = 5,
  }) {
    final sentences = _splitSentences(articleText);
    if (sentences.isEmpty) return [];

    final exercises = <CultureExercise>[];
    final skillId = 'culture_cloze_${_normalizeLang(targetLanguage)}';
    var used = 0;

    for (var i = 0; i < sentences.length && used < count; i++) {
      final sentence = sentences[i].trim();
      if (sentence.length < 20) continue;

      final words = sentence.split(RegExp(r'\s+'));
      if (words.length < 4) continue;

      // Pick a word to remove: prefer content words (longer, not stop)
      final candidates = <int>[];
      for (var j = 0; j < words.length; j++) {
        final w = words[j].replaceAll(RegExp(r'[^\w\s]'), '');
        if (w.length >= 4 && !_stopWords.contains(w.toLowerCase())) {
          candidates.add(j);
        }
      }
      if (candidates.isEmpty) continue;

      final idx = candidates[_random.nextInt(candidates.length)];
      final correctWord = words[idx].replaceAll(RegExp(r'[^\w\s]'), '');
      if (correctWord.isEmpty) continue;

      final blanked = words.toList();
      blanked[idx] = '_____';
      final prompt = blanked.join(' ');

      exercises.add(CultureExercise(
        id: 'cloze_${targetLanguage}_$i',
        type: CultureExerciseType.cloze,
        prompt: prompt,
        correctAnswer: correctWord,
        skillId: skillId,
        difficulty: 0.3 + (i % 3) * 0.2,
        explanation: 'The missing word is "$correctWord".',
      ));
      used++;
    }

    return exercises;
  }

  /// Extracts key vocabulary with definitions/usage from the article.
  List<CultureExercise> generateVocabularyTasks(
    String articleText,
    String targetLanguage, {
    int count = 8,
  }) {
    final words = _extractSignificantWords(articleText, minLength: 5);
    if (words.isEmpty) return [];

    final sentences = _splitSentences(articleText);
    final skillId = 'culture_vocab_${_normalizeLang(targetLanguage)}';
    final exercises = <CultureExercise>[];
    var taken = 0;

    for (final word in words) {
      if (taken >= count) break;
      final lower = word.toLowerCase();
      if (_stopWords.contains(lower)) continue;

      final contextSentence = sentences
          .where((s) => s.toLowerCase().contains(lower))
          .firstOrNull;
      final usage = contextSentence ?? 'Used in the article.';
      final definition = contextSentence != null
          ? 'Key term from the text: "${word.trim()}".'
          : 'Vocabulary from the article.';

      exercises.add(CultureExercise(
        id: 'vocab_${targetLanguage}_$taken',
        type: CultureExerciseType.vocabulary,
        prompt: 'What does "$word" mean in this context?',
        options: [definition, usage, 'None of the above'],
        correctAnswer: definition,
        skillId: skillId,
        difficulty: 0.4,
        explanation: usage,
      ));
      taken++;
    }

    return exercises;
  }

  /// Multiple choice and open comprehension questions from article content.
  List<CultureExercise> generateComprehensionQuestions(
    String articleText,
    String targetLanguage, {
    int count = 4,
  }) {
    final sentences = _splitSentences(articleText);
    if (sentences.length < 2) return [];

    final skillId = 'culture_comprehension_${_normalizeLang(targetLanguage)}';
    final exercises = <CultureExercise>[];

    for (var i = 0; i < count && i < sentences.length; i++) {
      final main = sentences[i].trim();
      if (main.length < 15) continue;

      final others = sentences
          .where((s) => s != main && s.trim().length > 10)
          .take(3)
          .map((s) => s.trim())
          .toList();
      while (others.length < 3 && sentences.length > others.length + 1) {
        final extra = sentences
            .where((s) => !others.contains(s.trim()))
            .where((s) => s.trim().length > 10)
            .take(1)
            .toList();
        if (extra.isEmpty) break;
        others.add(extra.first.trim());
      }

      final question = main.endsWith('?')
          ? main
          : 'According to the text: $main';
      final correct = main;
      final options = [correct, ...others.take(3)];
      options.shuffle(_random);

      exercises.add(CultureExercise(
        id: 'comp_${targetLanguage}_$i',
        type: CultureExerciseType.comprehension,
        prompt: question,
        options: options.length >= 2 ? options : null,
        correctAnswer: correct,
        skillId: skillId,
        difficulty: 0.3 + i * 0.15,
        explanation: 'This is stated in the article.',
      ));
    }

    return exercises;
  }

  /// Quick micro-tasks: word matching, sentence reordering, cultural fact check.
  List<CultureExercise> generateMicroTasks(
    String articleText,
    String targetLanguage,
  ) {
    final sentences = _splitSentences(articleText);
    final words = _extractSignificantWords(articleText, minLength: 4);
    final skillId = 'culture_micro_${_normalizeLang(targetLanguage)}';
    final exercises = <CultureExercise>[];

    // Word matching: pair words from article
    if (words.length >= 4) {
      final half = words.length ~/ 2;
      final left = words.take(half).toList();
      final right = words.skip(half).take(half).toList();
      if (left.isNotEmpty && right.isNotEmpty) {
        final matchWord = left.first;
        final matchDef = 'Matches: $matchWord';
        exercises.add(CultureExercise(
          id: 'micro_match_${targetLanguage}_0',
          type: CultureExerciseType.wordMatch,
          prompt: 'Match the word to its meaning from the article.',
          options: [matchWord, ...right.take(2)],
          correctAnswer: matchWord,
          skillId: skillId,
          difficulty: 0.4,
          explanation: matchDef,
        ));
      }
    }

    // Sentence reorder: one sentence split into parts
    if (sentences.isNotEmpty) {
      final long = sentences
          .map((s) => s.trim())
          .where((s) => s.length > 30 && s.split(RegExp(r'\s+')).length >= 5)
          .firstOrNull;
      if (long != null) {
        final parts = long.split(RegExp(r'[,;]')).map((s) => s.trim()).toList();
        if (parts.length >= 2) {
          final correct = parts.join(', ');
          final shuffled = parts.toList()..shuffle(_random);
          exercises.add(CultureExercise(
            id: 'micro_reorder_${targetLanguage}_0',
            type: CultureExerciseType.sentenceReorder,
            prompt: 'Put the parts in order: ${shuffled.join(' / ')}',
            correctAnswer: correct,
            skillId: skillId,
            difficulty: 0.5,
            explanation: 'Correct order: $correct',
          ));
        }
      }
    }

    // Fact check: true/false from a sentence
    if (sentences.isNotEmpty) {
      final fact = sentences.first.trim();
      if (fact.length > 15) {
        exercises.add(CultureExercise(
          id: 'micro_fact_${targetLanguage}_0',
          type: CultureExerciseType.factCheck,
          prompt: 'True or false: $fact',
          options: ['True', 'False'],
          correctAnswer: 'True',
          skillId: skillId,
          difficulty: 0.3,
          explanation: 'This appears in the article.',
        ));
      }
    }

    return exercises.take(5).toList();
  }

  /// Returns 3 discussion prompts for community engagement.
  List<String> generateDiscussionPrompts(String articleText) {
    final sentences = _splitSentences(articleText);
    final first = sentences.isNotEmpty ? sentences.first.trim() : '';
    final topic = first.length > 60 ? '${first.substring(0, 57)}...' : first;

    return [
      'What did you find most interesting about this article?',
      'How does this topic relate to your own experience or culture?',
      if (topic.isNotEmpty)
        'Discuss: "$topic" — share your thoughts with the community.',
    ];
  }

  /// Updates learner model based on completed exercises and outcomes.
  Future<void> recordArticleEngagement({
    required String learnerId,
    required String articleId,
    required List<CultureExercise> completed,
    required List<bool> outcomes,
  }) async {
    if (completed.length != outcomes.length) return;

    final learner = LearnerModelService.instance;
    await learner.initialize();

    for (var i = 0; i < completed.length; i++) {
      final ex = completed[i];
      final correct = outcomes[i];
      await learner.recordAttempt(
        learnerId: learnerId,
        skillId: ex.skillId,
        wasCorrect: correct,
      );
    }
  }

  List<String> _splitSentences(String text) {
    if (text.isEmpty) return [];
    return text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _extractSignificantWords(String text, {int minLength = 4}) {
    final tokens = text.split(RegExp(r'\s+'));
    final seen = <String>{};
    final list = <String>[];
    for (final t in tokens) {
      final w = t.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      if (w.length >= minLength &&
          !_stopWords.contains(w.toLowerCase()) &&
          seen.add(w.toLowerCase())) {
        list.add(w);
      }
    }
    return list;
  }

  String _normalizeLang(String lang) {
    return lang.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '_');
  }
}
