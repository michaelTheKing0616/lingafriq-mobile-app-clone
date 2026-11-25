import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/quiz_model.dart';

void main() {
  const choices = [
    {'text': 'ọkọ̀', 'correct_answer': false},
    {'text': 'àárọ̀', 'correct_answer': true, 'rationale': 'This is the morning greeting.'},
  ];

  test('each quiz system ports onto one bank item', () {
    for (final system in ['language_quiz', 'history_quiz', 'random_quiz', 'unit_quiz']) {
      final quiz = QuizModel.fromChoice(
        system: system,
        id: '12',
        language: 'yo',
        prompt: 'Pick the morning word',
        choices: choices,
        funFact: 'Morning comes before noon.',
      );
      expect(quiz, isNotNull);
      expect(quiz!.bankItem!.skillTags, [system]);
      expect(quiz.bankItem!.type, 'multiple_choice');
      expect(quiz.bankItem!.diacriticInsensitive, isTrue);
      expect(quiz.answer, 'àárọ̀');
      expect(quiz.bankItem!.distractors.single.text, 'ọkọ̀');
      expect(quiz.bankItem!.distractors.single.rationale, 'Morning comes before noon.');
    }

    final sentence = QuizModel.sentenceItem(
      system: 'random_quiz',
      id: 'word-1',
      prompt: 'The [Father/Baba] waved.',
    );
    expect(sentence!.type, 'sentence_building');
    expect(sentence.correct, 'Baba');
    expect(sentence.skillTags, ['random_quiz']);
  });

  test('a Sample MCQ is not imported', () {
    final quiz = QuizModel.fromChoice(
      system: 'language_quiz',
      id: 'sample',
      prompt: 'Sample MCQ',
      choices: choices,
    );
    expect(quiz, isNull);
    expect(
      QuizModel.sentenceItem(system: 'unit_quiz', id: 'sample', prompt: 'Fill the sample blank'),
      isNull,
    );
  });
}
