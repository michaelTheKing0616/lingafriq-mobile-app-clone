import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/validation/response_validator.dart';

void main() {
  test('P11-003 rejects confidence and accepts ADR-030 emotion', () {
    expect(
      () => ResponseValidator.validatePersonaAnswerContract('''
{
  "speech_text": "Hello learner",
  "language_teaching_points": [{"type": "vocabulary", "content": "stool"}],
  "claims": [],
  "emotion": "focused",
  "next_beat": "continue",
  "confidence": 0.5
}'''),
      throwsA(isA<AiResponseValidationError>()),
    );

    final parsed = ResponseValidator.validatePersonaAnswerContract('''
{
  "speech_text": "Hello learner",
  "language_teaching_points": [{"type": "vocabulary", "content": "stool"}],
  "claims": [{"text": "fact", "support": "inferred", "source_ids": []}],
  "emotion": "calm",
  "next_beat": "reflect"
}''');

    expect(parsed['emotion'], 'neutral');
    expect(parsed['next_beat'], 'reflect');
  });

  test('P11-003 requires at least one teaching point', () {
    expect(
      () => ResponseValidator.validatePersonaAnswerContract('''
{
  "speech_text": "Hello learner",
  "language_teaching_points": [],
  "claims": [],
  "emotion": "neutral",
  "next_beat": "continue"
}'''),
      throwsA(isA<AiResponseValidationError>()),
    );
  });
}
