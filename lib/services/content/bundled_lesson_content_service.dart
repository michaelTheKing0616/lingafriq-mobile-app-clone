import 'package:lingafriq/models/curriculum_model.dart';

/// Maps authentic bundled curriculum lessons to lesson-detail UI shape (no AI stub).
class BundledLessonContentService {
  /// Returns display-ready content when the lesson has bundled dialogue/vocab.
  static Map<String, dynamic>? fromCurriculumLesson(CurriculumLesson lesson) {
    if (lesson.dialogue == null && lesson.vocabObjects.every((v) => v.meaning.isEmpty)) {
      return null;
    }

    final dialogue = lesson.dialogue;
    final script = dialogue?.script ?? [];
    final dialogueLines = script
        .map((line) => {
              'speaker': line['speaker'] ?? line['Speaker'] ?? 'A',
              'text': line['text'] ?? '',
              'translation': line['translation'] ?? '',
            })
        .toList();

    final examples = <Map<String, String>>[];
    for (final v in lesson.vocabObjects) {
      if (v.word.isEmpty) continue;
      examples.add({
        'word': v.word,
        'meaning': v.meaning,
        'example': v.example ?? '${v.word} — ${v.meaning}',
      });
    }

    final exercises = lesson.exercises.map((e) {
      return {
        'type': e.type,
        'items': e.items,
      };
    }).toList();

    return {
      'source': 'lingafriq_authentic_curriculum',
      'grammar_explanations': lesson.grammar ?? <String>[],
      'dialogue': {
        'script': dialogueLines,
        'notes': dialogue?.notes ?? dialogue?.culturalContext ?? '',
        'cultural_context': dialogue?.culturalContext ?? '',
        'scene': dialogue?.notes,
      },
      'examples': examples,
      'cultural_notes': dialogue?.culturalContext ?? '',
      'exercises': exercises,
      'vocab': lesson.vocabObjects.map((v) => v.toMap()).toList(),
    };
  }
}
