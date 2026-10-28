// P6-019 spec tests: client uses gateway only; no provider keys in allowlisted sources.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';

const _providerPath = 'lib/providers/ai_chat_provider_groq.dart';
const _screenPath = 'lib/screens/ai_chat/polie_workspace_screen.dart';
const _workspaceLibraryPath =
    'lib/features/polie_workspace/polie_workspace_screen_body.dart';
const _clientPath = 'lib/services/ai_gateway_client.dart';

String _stripped(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return file
      .readAsStringSync()
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

void main() {
  group('AiGatewayClient error mapping', () {
    test('quota_exceeded maps to visible message', () {
      const err = AiGatewayException('x', body: {'error': 'quota_exceeded'});
      final msg = AiGatewayClient.userMessageFor(err, body: err.body);
      expect(msg.toLowerCase(), contains('limit'));
    });

    test('fromDio preserves gateway error code', () {
      final ex = AiGatewayClient.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/api/ai/chat/completion'),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 429,
            data: {'error': 'quota_exceeded'},
          ),
        ),
      );
      expect(ex.errorCode, 'quota_exceeded');
    });
  });

  group('P6-019 allowlist security scan', () {
    test('no Groq host or bearer tokens in provider or screen', () {
      for (final path in [_providerPath, _screenPath]) {
        final src = _stripped(path).toLowerCase();
        expect(src.contains('api.groq.com'), isFalse, reason: path);
        expect(src.contains('openai.com/v1'), isFalse, reason: path);
        expect(src.contains('huggingface.co'), isFalse, reason: path);
        expect(src.contains('authorization:'), isFalse, reason: path);
        expect(src.contains('bearer '), isFalse, reason: path);
        expect(src.contains('envconfig.groqapikey'), isFalse, reason: path);
      }
    });

    test('polie workspace imports gateway client', () {
      final src = File(_workspaceLibraryPath).readAsStringSync();
      expect(src.contains('ai_gateway_client.dart'), isTrue);
    });

    test('provider references AiGatewayClient', () {
      final src = File(_providerPath).readAsStringSync();
      expect(src.contains('AiGatewayClient'), isTrue);
    });
  });

  group('gateway mode map', () {
    test('translation maps to translate', () {
      expect(
        AiGatewayClient.gatewayModeForPolie('translation'),
        'translate',
      );
    });
  });
}
