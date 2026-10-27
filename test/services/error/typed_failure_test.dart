import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/persona_cognition_gateway.dart';
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
    final gateway = PersonaCognitionGateway(dio);
    await expectLater(
      gateway.runTurn(
        personaId: persona!.id,
        userInput: 'Sawubona',
        languageCode: 'en',
        learnerMastery: 0.2,
        epistemicStatus: EpistemicStatus.uncertain.name,
        epistemicReasoning: 'fixture',
        epistemicConfidence: 0.4,
        persona: persona,
      ),
      throwsA(
        isA<LingAfriqFailure>().having((error) => error.code, 'code', 'persona_unavailable'),
      ),
    );

    final cognitionDir = Directory('lib/ai/persona_cognition');
    for (final entity in cognitionDir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      expect(source.contains('Authorization'), isFalse, reason: entity.path);
      expect(source.contains('llama-3.3'), isFalse, reason: entity.path);
    }
    expect(File('lib/services/offline/offline_service.dart').existsSync(), isFalse);
    expect(syncNotPersisted.code, 'sync_not_persisted');
  });
}
