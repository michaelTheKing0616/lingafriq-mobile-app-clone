import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/content/import_media/media_learning_pipeline.dart';

void main() {
  const source = 'Mo n lo si oja lati ra ewa ati isu.';
  final pipeline = MediaLearningPipeline();

  test('builds a structured lesson from the media line', () {
    final lesson = pipeline.buildLesson(
      text: source,
      sourceLanguage: 'yo',
      mediaId: 'media-42',
      span: '00:01:02-00:01:08',
    );

    expect(lesson.provenance, 'from your media');
    expect(lesson.mediaId, 'media-42');
    expect(lesson.span, '00:01:02-00:01:08');
    expect(source.contains(lesson.modelText), isTrue);
    expect(lesson.modelText.toLowerCase().contains(lesson.guidedAnswer.toLowerCase()), isTrue);
    expect(lesson.guidedPrompt.contains('____'), isTrue);
    expect(lesson.checkAnswer, lesson.modelText);
    expect(lesson.checkProvenance, 'AI-generated, unreviewed');
    expect(lesson.shadowingText, lesson.modelText);
    expect(lesson.toneStep.contains(lesson.modelText) || lesson.toneStep.contains('your media'), isTrue);
    expect(lesson.toneStep.contains('marks respect'), isFalse);
    expect(lesson.flashcards, isNotEmpty);
    expect(lesson.flashcards.length, lessThanOrEqualTo(10));
    for (final card in lesson.flashcards) {
      expect(source.toLowerCase().contains(card.answer.toLowerCase()), isTrue);
    }
  });

  test('refuses a lesson when the media text or citation is missing', () {
    expect(
      () => pipeline.buildLesson(text: '   ', sourceLanguage: 'yo', mediaId: 'media-42', span: '0-1'),
      throwsArgumentError,
    );
    expect(
      () => pipeline.buildLesson(text: source, sourceLanguage: 'yo', mediaId: ' ', span: '0-1'),
      throwsArgumentError,
    );
    expect(
      () => pipeline.buildLesson(text: source, sourceLanguage: 'yo', mediaId: 'media-42', span: ''),
      throwsArgumentError,
    );
  });

  test('still extracts vocabulary and review items from imported text', () async {
    final result = await pipeline.processText(
      text: source,
      sourceLanguage: 'yo',
      learnerId: 'learner-1',
    );
    expect(result.vocabulary, isNotEmpty);
    expect(result.reviewItems, isNotEmpty);
  });
}
