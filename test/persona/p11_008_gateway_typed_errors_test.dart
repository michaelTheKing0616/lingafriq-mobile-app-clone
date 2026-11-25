import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/persona_cognition/groq_two_pass_orchestrator.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/personas/historical_roleplay_controller.dart';

String _stripped(String path) {
  return File(path)
      .readAsStringSync()
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

void main() {
  test('P11-008_AC2_no_groq_key_in_persona_controller_source', () {
    const paths = [
      'lib/ai/personas/historical_roleplay_controller.dart',
      'lib/ai/persona_cognition/groq_two_pass_orchestrator.dart',
    ];
    for (final path in paths) {
      final code = _stripped(path);
      expect(code.contains('GROQ_API_KEY'), isFalse, reason: path);
      expect(code.contains('api.groq.com'), isFalse, reason: path);
    }
    expect(
      PersonaHistoricalRoleplayGateway.turnPath,
      '/api/ai/persona/historical-roleplay/turn',
    );
  });

  test('P11-008_AC3_gateway_failure_surfaces_typed_error', () async {
    final persona = HistoricalPersonaRegistry.findById('mandela_nelson');
    expect(persona, isNotNull);
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1/'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 502,
              data: const {'error': 'persona_gateway_failed'},
            ),
          );
        },
      ),
    );
    final controller = HistoricalRoleplayController(dio: dio);
    Object? caught;
    try {
      await controller.startPersonaSession(
        learnerId: 'p11_008',
        languageCode: 'zu',
        personaId: persona!.id,
        engagementType: HistoricalEngagementType.freeConversation,
      );
    } catch (e) {
      caught = e;
    }
    expect(caught, isA<PersonaTurnGatewayError>());
    expect((caught as PersonaTurnGatewayError).retryable, isTrue);
  });
}
