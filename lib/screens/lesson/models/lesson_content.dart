import 'package:flutter/foundation.dart';
import 'package:lingafriq/utils/media_url_resolver.dart';

/// Enum for lesson section types - replaces string-based type checking
enum LessonSectionType {
  tutorial,
  instantQuiz,
  wordQuiz,
  longQuiz;

  /// Parse from backend string format
  static LessonSectionType fromString(String? type) {
    if (type == null) return tutorial;
    final normalized = type.toLowerCase().trim();
    switch (normalized) {
      case 'tutorial':
      case 'lesson':
      case 'lesson_lesson':
        return tutorial;
      case 'instant quiz':
      case 'instant_quiz':
      case 'instant':
        return instantQuiz;
      case 'word quiz':
      case 'word_quiz':
      case 'word':
        return wordQuiz;
      case 'long quiz':
      case 'long_quiz':
        return longQuiz;
      default:
        // Be defensive with unknown server labels to avoid routing quiz sections
        // to tutorial completion endpoints.
        if (normalized.contains('word')) return wordQuiz;
        if (normalized.contains('quiz') || normalized.contains('question')) {
          return instantQuiz;
        }
        return tutorial;
    }
  }

  /// Convert to backend string format
  String toBackendString() {
    switch (this) {
      case tutorial:
        return 'Tutorial';
      case instantQuiz:
        return 'Instant Quiz';
      case wordQuiz:
        return 'Word Quiz';
      case longQuiz:
        return 'Long Quiz';
    }
  }

  bool get isTutorial => this == tutorial;
  bool get isQuiz => this == instantQuiz || this == longQuiz;
  bool get isWordQuiz => this == wordQuiz;
}

/// Strongly-typed lesson content model
class LessonContent {
  final int id;
  final int sectionId;
  final String title;
  final LessonSectionType type;
  final int score;
  final bool isCompleted;
  final DateTime? dateTime;

  // Tutorial-specific fields
  final String? text;
  final String? audioUrl;
  final String? videoUrl;
  final String? imageUrl;

  // Quiz-specific fields
  final List<QuizQuestion>? questions;
  final List<WordQuizQuestion>? wordQuestions;
  final String? quizType;

  LessonContent({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.type,
    required this.score,
    this.isCompleted = false,
    this.dateTime,
    this.text,
    this.audioUrl,
    this.videoUrl,
    this.imageUrl,
    this.questions,
    this.wordQuestions,
    this.quizType,
  });

  /// Parse from SectionLessonModel and otherData
  factory LessonContent.fromSectionLesson({
    required int id,
    required int sectionId,
    required String title,
    required String types,
    required int score,
    required bool isCompleted,
    DateTime? dateTime,
    required dynamic otherData,
  }) {
    final type = LessonSectionType.fromString(types);
    final otherDataMap = otherData is Map<String, dynamic> ? otherData : <String, dynamic>{};

    // Parse tutorial fields
    String? text = otherDataMap['text']?.toString() ?? otherDataMap['title']?.toString();
    final audioUrl = _resolveMediaFromMap(otherDataMap, const [
      'audio_url',
      'audioUrl',
      'audio',
      'lesson_audio_url',
      'lessonAudioUrl',
      'media_audio_url',
      'mediaAudioUrl',
      'file_url',
      'url',
    ]);
    final videoUrl = _resolveMediaFromMap(otherDataMap, const [
      'video_url',
      'videoUrl',
      'video',
      'lesson_video_url',
      'lessonVideoUrl',
      'media_video_url',
      'mediaVideoUrl',
    ]);
    final imageUrl = _resolveMediaFromMap(otherDataMap, const [
      'image_url',
      'imageUrl',
      'image',
      'thumbnail_url',
      'thumbnailUrl',
      'poster_url',
      'posterUrl',
    ]);

    // Parse quiz fields
    List<QuizQuestion>? questions;
    List<WordQuizQuestion>? wordQuestions;
    final quizType = otherDataMap['quiz_type']?.toString();

    if (type.isQuiz && otherDataMap['question'] != null) {
      final rawQuestions = otherDataMap['question'];
      if (rawQuestions is List) {
        questions = rawQuestions
            .where((e) => e is Map && e['question'] is Map && e['choices'] is List)
            .map((e) {
          try {
            final questionMap = e['question'] as Map;
            final questionText = questionMap['question']?.toString() ?? '';
            final choices = (e['choices'] as List)
                .map((c) => c is Map ? c['text']?.toString() ?? '' : c.toString())
                .where((t) => t.isNotEmpty)
                .toList();

            final correctAnswers = choices
                .where((c) {
                  final choiceIndex = (e['choices'] as List).indexWhere(
                    (ch) => ch is Map && (ch['text']?.toString() ?? '') == c,
                  );
                  if (choiceIndex >= 0) {
                    return (e['choices'] as List)[choiceIndex] is Map &&
                        ((e['choices'] as List)[choiceIndex] as Map)['correct_answer'] == true;
                  }
                  return false;
                })
                .toList();

            if (correctAnswers.isEmpty || choices.isEmpty) return null;

            return QuizQuestion(
              id: e['id'] is int ? e['id'] : 0,
              question: questionText,
              text: questionMap['text']?.toString(),
              hint: questionMap['hint']?.toString(),
              funFact: questionMap['fun_fact']?.toString(),
              imageUrl: _resolveMediaFromMap(questionMap, const [
                'image_url',
                'imageUrl',
                'image',
                'thumbnail_url',
                'thumbnailUrl',
                'poster_url',
                'posterUrl',
              ]),
              audioUrl: _resolveMediaFromMap(questionMap, const [
                'audio_url',
                'audioUrl',
                'audio',
                'media_audio_url',
                'mediaAudioUrl',
                'file_url',
                'url',
              ]),
              videoUrl: _resolveMediaFromMap(questionMap, const [
                'video_url',
                'videoUrl',
                'video',
                'media_video_url',
                'mediaVideoUrl',
              ]),
              options: choices.asMap().entries.map((e) {
                return QuizOption(
                  id: e.key,
                  text: e.value,
                  imageUrl: null,
                  isCorrect: correctAnswers.contains(e.value),
                );
              }).toList(),
            );
          } catch (e) {
            debugPrint('Error parsing quiz question: $e');
            return null;
          }
        }).whereType<QuizQuestion>().toList();
      }
    }

    if (type.isWordQuiz && otherDataMap['word_question'] != null) {
      final rawWordQuestions = otherDataMap['word_question'];
      if (rawWordQuestions is List && rawWordQuestions.isNotEmpty) {
        try {
          final firstQuestion = (rawWordQuestions.first as List).first;
          if (firstQuestion is Map) {
            final questionText = firstQuestion['text']?.toString() ?? '';
            final textWithBrackets = '$questionText[]';
            final regex = RegExp(r'\[(.*?)\]');
            final brackets = <String>[];
            textWithBrackets.splitMapJoin(regex, onMatch: (match) {
              brackets.add(match[1].toString());
              return '';
            });
            final splittedText = textWithBrackets.split(regex);
            final choiceQuestions = brackets.map((e) => e.split('/').first.trim()).toList();

            wordQuestions = choiceQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              return WordQuizQuestion(
                id: index,
                question: value,
                content: splittedText[index],
                hint: null,
              );
            }).toList();
          }
        } catch (e) {
          debugPrint('Error parsing word quiz: $e');
        }
      }
    }

    return LessonContent(
      id: id,
      sectionId: sectionId,
      title: title,
      type: type,
      score: score,
      isCompleted: isCompleted,
      dateTime: dateTime,
      text: text?.isNotEmpty == true ? text : null,
      audioUrl: audioUrl?.isNotEmpty == true ? audioUrl : null,
      videoUrl: videoUrl?.isNotEmpty == true ? videoUrl : null,
      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
      questions: questions?.isNotEmpty == true ? questions : null,
      wordQuestions: wordQuestions?.isNotEmpty == true ? wordQuestions : null,
      quizType: quizType,
    );
  }

  static String? _resolveMediaFromMap(
    Map<dynamic, dynamic>? source,
    List<String> keys,
  ) {
    if (source == null) return null;

    for (final key in keys) {
      final resolved = _resolveMediaFromValue(source[key]);
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }

    final media = source['media'];
    if (media is Map) {
      for (final key in keys) {
        final resolved = _resolveMediaFromValue(media[key]);
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
        }
      }
    }

    return null;
  }

  static String? _resolveMediaFromValue(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return resolveMediaUrl(value);
    }

    if (value is List) {
      for (final item in value) {
        final resolved = _resolveMediaFromValue(item);
        if (resolved != null && resolved.isNotEmpty) return resolved;
      }
      return null;
    }

    if (value is Map) {
      final candidates = [
        value['url'],
        value['file_url'],
        value['path'],
        value['src'],
        value['audio_url'],
        value['video_url'],
        value['image_url'],
      ];
      for (final candidate in candidates) {
        final resolved = _resolveMediaFromValue(candidate);
        if (resolved != null && resolved.isNotEmpty) return resolved;
      }
      return null;
    }

    return resolveMediaUrl(value.toString());
  }

  LessonContent copyWith({
    int? id,
    int? sectionId,
    String? title,
    LessonSectionType? type,
    int? score,
    bool? isCompleted,
    DateTime? dateTime,
    String? text,
    String? audioUrl,
    String? videoUrl,
    String? imageUrl,
    List<QuizQuestion>? questions,
    List<WordQuizQuestion>? wordQuestions,
    String? quizType,
  }) {
    return LessonContent(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      title: title ?? this.title,
      type: type ?? this.type,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
      dateTime: dateTime ?? this.dateTime,
      text: text ?? this.text,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      questions: questions ?? this.questions,
      wordQuestions: wordQuestions ?? this.wordQuestions,
      quizType: quizType ?? this.quizType,
    );
  }
}

/// Quiz question model with full media support
class QuizQuestion {
  final int id;
  final String question;
  final String? text;
  final String? hint;
  final String? funFact;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final List<QuizOption> options;

  QuizQuestion({
    required this.id,
    required this.question,
    this.text,
    this.hint,
    this.funFact,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    required this.options,
  });

  QuizQuestion copyWith({
    int? id,
    String? question,
    String? text,
    String? hint,
    String? funFact,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
    List<QuizOption>? options,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      text: text ?? this.text,
      hint: hint ?? this.hint,
      funFact: funFact ?? this.funFact,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      options: options ?? this.options,
    );
  }
}

/// Quiz option model
class QuizOption {
  final int id;
  final String text;
  final String? imageUrl;
  final bool isCorrect;

  QuizOption({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.isCorrect,
  });

  QuizOption copyWith({
    int? id,
    String? text,
    String? imageUrl,
    bool? isCorrect,
  }) {
    return QuizOption(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

/// Word quiz question model
class WordQuizQuestion {
  final int id;
  final String question;
  final String content;
  final String? hint;

  WordQuizQuestion({
    required this.id,
    required this.question,
    required this.content,
    this.hint,
  });

  WordQuizQuestion copyWith({
    int? id,
    String? question,
    String? content,
    String? hint,
  }) {
    return WordQuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      content: content ?? this.content,
      hint: hint ?? this.hint,
    );
  }
}
