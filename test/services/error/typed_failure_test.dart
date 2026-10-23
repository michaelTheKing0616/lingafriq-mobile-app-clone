import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/groq_two_pass_orchestrator.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/services/error/typed_errors.dart';
import 'package:lingafriq/services/hybrid_polie/pronunciation_service.dart';
import 'package:lingafriq/services/pronunciation_scoring_service.dart';

void main() {
  test('an unavailable scorer throws and does not invent a score', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              message: 'scorer down',
            ),
          );
        },
      ),
    );
    final scoring = PronunciationScoringService.testing(dio);
    await expectLater(
      scoring.scorePronunciation(
        audioUrl: 'https://example.invalid/audio.wav',
        referenceText: 'Bawo ni',
        language: 'yoruba',
      ),
      throwsA(
        isA<LingAfriqFailure>().having(
          (error) => error.code,
          'code',
          'pronunciation_unavailable',
        ),
      ),
    );

    final polie = PronunciationService(dio: dio);
    await expectLater(
      polie.scorePronunciation(
        audioPath: '/tmp/lingafriq-missing-p2-018.wav',
        referenceText: 'Bawo ni',
        language: 'yoruba',
      ),
      throwsA(
        isA<LingAfriqFailure>().having(
          (error) => error.code,
          'code',
          'pronunciation_unavailable',
        ),
      ),
    );

    final source = File('lib/services/pronunciation_scoring_service.dart').readAsStringSync();
    expect(source.contains('basic-heuristic'), isFalse);
    expect(source.contains('score: 0.7'), isFalse);
  });

  test('a failed persona reply is a typed error and not a canned line', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'choices': [
                  {'message': <String, dynamic>{}},
                ],
              },
            ),
          );
        },
      ),
    );
    final persona = HistoricalPersonaRegistry.findById('mandela_nelson');
    expect(persona, isNotNull);
    final orchestrator = GroqTwoPassOrchestrator(
      dio: dio,
      apiKey: 'test-key',
      apiUrl: 'http://127.0.0.1/unused',
    );
    await expectLater(
      orchestrator.runPass2(
        userInput: 'Sawubona',
        persona: persona!,
        pass1: const Pass1Result(
          epistemicStatus: EpistemicStatus.uncertain,
          reasoningNotes: 'fixture',
          confidence: 0.4,
        ),
        learnerMastery: 0.2,
      ),
      throwsA(
        isA<LingAfriqFailure>().having((error) => error.code, 'code', 'persona_unavailable'),
      ),
    );

    final replySource = File('lib/ai/persona_cognition/groq_two_pass_orchestrator.dart').readAsStringSync();
    expect(replySource.contains('nods thoughtfully'), isFalse);
    expect(replySource.contains('responds with warmth'), isFalse);
    expect(File('lib/services/offline/offline_service.dart').existsSync(), isFalse);
    expect(syncNotPersisted.code, 'sync_not_persisted');
  });
}
