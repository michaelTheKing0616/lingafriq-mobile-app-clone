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
    expect(lesson.guidedPrompt.split('____').length - 1, 1);
    expect(
      lesson.guidedPrompt.replaceFirst('____', lesson.guidedAnswer),
      lesson.modelText,
    );
    expect(lesson.checkAnswer, lesson.modelText);
    expect(lesson.checkProvenance, 'AI-generated, unreviewed');
    expect(lesson.shadowingText, lesson.modelText);
    expect(lesson.toneStep.contains(lesson.modelText) || lesson.toneStep.contains('your media'), isTrue);
    expect(lesson.toneStep.contains('marks respect'), isFalse);
    expect(lesson.flashcards, isNotEmpty);
    expect(lesson.flashcards.length, lessThanOrEqualTo(10));
    final answers = <String>{};
    for (final card in lesson.flashcards) {
      expect(source.toLowerCase().contains(card.answer.toLowerCase()), isTrue);
      expect(card.mediaId, 'media-42');
      expect(card.span, '00:01:02-00:01:08');
      answers.add(card.answer.toLowerCase());
    }
    expect(answers.length, lesson.flashcards.length);
    for (final gloss in lesson.glosses) {
      expect(gloss.gloss.toLowerCase(), isNot(equals(gloss.word.toLowerCase())));
      expect(gloss.provenance, 'AI-generated, unreviewed');
    }
  });

  test('uses the first sentence as the model when two sentences are present', () {
    const two = 'E kaaro. Mo n lo si oja lati ra ewa.';
    final lesson = pipeline.buildLesson(
      text: two,
      sourceLanguage: 'yo',
      mediaId: 'm1',
      span: '0-2',
    );
    expect(lesson.modelText, 'E kaaro');
    expect(two.contains(lesson.modelText), isTrue);
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
