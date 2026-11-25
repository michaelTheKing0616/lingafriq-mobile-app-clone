// P1-012 Mode A spec-tests. No network, no real model calls, no sleeps.
// charter: v2
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/ai/personas/historical_roleplay_controller.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/persona_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gatewayPath = '/api/ai/persona/historical-roleplay/turn';
const _arbPath = 'lib/l10n/app_en.arb';
const _gatewayClientPath = 'lib/services/ai_gateway_client.dart';
const _providersPath = 'lib/providers/persona_providers.dart';
const _controllerPath = 'lib/ai/personas/historical_roleplay_controller.dart';
const _screenPath =
    'lib/screens/persona_missions/persona_mission_session_screen.dart';
const _cannedFallback = 'I hear you. Let us continue.';
const _cannedOpening = 'Response unavailable';
const _userMessage = 'Sawubona, Madiba.';
const _personaId = 'mandela_nelson';

class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('P1-012 tests must not open a network socket');
  }
}

class _RecordingGateway {
  _RecordingGateway();

  final requests = <RequestOptions>[];
  bool failNext = false;

  Dio dio() {
    final client = Dio(BaseOptions(baseUrl: 'http://127.0.0.1/'));
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (failNext) {
            failNext = false;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 502,
                data: const {'error': 'fixture gateway unreachable'},
              ),
            );
            return;
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: _fixtureGatewayBody(),
            ),
          );
        },
      ),
    );
    return client;
  }
}

Map<String, dynamic> _fixtureGatewayBody() {
  return {
    'ok': true,
    'speech_text': 'Sawubona, mntwana wam.',
    'language_teaching_points': [
      {'type': 'vocabulary', 'content': 'Sawubona'},
    ],
    'emotion': 'warm',
    'next_beat': 'greet',
    'closure_options': <String>[],
  };
}

String _stripped(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return file
      .readAsStringSync()
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

String _retryCopy() {
  final arb =
      jsonDecode(File(_arbPath).readAsStringSync()) as Map<String, dynamic>;
  final copy = arb['persona.error.retry'] ?? arb['persona_error_retry'];
  expect(
    copy,
    isA<String>(),
    reason: 'app_en.arb must define persona.error.retry or persona_error_retry',
  );
  return copy as String;
}

void _assertGatewayRequest(RequestOptions request) {
  final uri = request.uri.toString();
  expect(
    uri.contains(_gatewayPath) || request.path.contains(_gatewayPath),
    isTrue,
    reason: 'persona turn must POST $_gatewayPath, got $uri',
  );
  expect(
    uri.contains('api.groq.com'),
    isFalse,
    reason: 'release mission must not target a provider host',
  );
  final body = request.data;
  expect(body, isA<Map>());
  expect((body as Map)['persona_id'], isNotNull);
  expect(body['persona'], isNotNull);
}

void _assertNoClientAiKeyRead() {
  for (final path in [_providersPath, _controllerPath, _screenPath]) {
    final code = _stripped(path);
    expect(
      code.contains('groqApiKey') || code.contains('GROQ_API_KEY'),
      isFalse,
      reason: '$path must not read a client AI key',
    );
    expect(
      code.contains('api.groq.com'),
      isFalse,
      reason: '$path must not target a provider host',
    );
  }
}

void _assertRetrySurface() {
  final copy = _retryCopy();
  final screen = _stripped(_screenPath);
  expect(
    screen.contains('persona.error.retry') ||
        screen.contains('persona_error_retry'),
    isTrue,
    reason: '$_screenPath must use copy key persona.error.retry',
  );
  expect(
    screen.contains(copy) ||
        screen.contains('Retry') ||
        screen.contains('persona.error.retry'),
    isTrue,
    reason: 'error state must expose a Retry action',
  );
  expect(
    screen.contains(_cannedFallback),
    isFalse,
    reason: 'screen must never show the canned fallback reply',
  );
}

HistoricalRoleplayController _controllerFor(Dio dio) {
  final container = ProviderContainer(
    overrides: [client.overrideWithValue(dio)],
  );
  addTearDown(container.dispose);
  return container.read(historicalRoleplayControllerProvider);
}

Future<PersonaSessionStart> _startMission(
  HistoricalRoleplayController controller,
  String learnerId,
) {
  return controller.startPersonaSession(
    learnerId: learnerId,
    languageCode: 'zu',
    personaId: _personaId,
    engagementType: HistoricalEngagementType.freeConversation,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _NoNetworkHttpOverrides();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'P1-012_AC1_release_mission_message_goes_through_gateway_without_client_ai_key',
    () async {
      // No client AI key can exist: EnvConfig has no AI key getters and
      // test/security/no_client_secrets_test.dart guards lib/.

      final recorder = _RecordingGateway();
      final controller = _controllerFor(recorder.dio());
      await _startMission(controller, 'p1_012_ac1');
      await controller.processLearnerResponse(
        learnerId: 'p1_012_ac1',
        response: _userMessage,
      );

      expect(recorder.requests, isNotEmpty);
      _assertGatewayRequest(recorder.requests.last);
      expect(File(_gatewayClientPath).existsSync(), isTrue);
      _assertNoClientAiKeyRead();
      expect(
        _stripped(_screenPath).contains('groqChatProvider'),
        isFalse,
        reason: 'mission send must not go through groqChatProvider',
      );
    },
  );

  test(
    'P1-012_AC2_gateway_error_shows_retry_never_canned_fallback',
    () async {
      final recorder = _RecordingGateway();
      final controller = _controllerFor(recorder.dio());
      await _startMission(controller, 'p1_012_ac2');

      recorder.failNext = true;
      Object? error;
      HistoricalRoleplayTurn? turn;
      try {
        turn = await controller.processLearnerResponse(
          learnerId: 'p1_012_ac2',
          response: _userMessage,
        );
      } catch (e) {
        error = e;
      }

      expect(
        turn?.speechText.contains(_cannedFallback) ?? false,
        isFalse,
        reason: 'canned fallback reply must never be shown',
      );
      expect(
        turn?.speechText.contains(_cannedOpening) ?? false,
        isFalse,
        reason: 'canned opening fallback must never be shown',
      );
      expect(
        error,
        isNotNull,
        reason: 'gateway or network error must surface, not a canned reply',
      );
      _assertRetrySurface();
    },
  );

  test(
    'P1-012_AC3_retry_after_recovery_replaces_error_without_duplicating_user_message',
    () async {
      final recorder = _RecordingGateway();
      final controller = _controllerFor(recorder.dio());
      await _startMission(controller, 'p1_012_ac3');

      recorder.failNext = true;
      try {
        await controller.processLearnerResponse(
          learnerId: 'p1_012_ac3',
          response: _userMessage,
        );
      } catch (_) {}

      recorder.failNext = false;
      try {
        await controller.processLearnerResponse(
          learnerId: 'p1_012_ac3',
          response: _userMessage,
        );
      } catch (_) {}

      final report = controller.getSessionReport('p1_012_ac3');
      expect(report, isNotNull);
      expect(
        report!.contextMemory.where((line) => line == _userMessage).length,
        1,
        reason: 'Retry must not duplicate the user message',
      );
      expect(
        report.turns.any((t) => t.speechText.contains(_cannedFallback)),
        isFalse,
        reason: 'recovered reply must replace the error state',
      );
      _assertRetrySurface();
    },
  );

  test(
    'P1-012_AC4_release_mode_without_injected_ai_key_starts_mission_through_gateway',
    () async {
      // Release config cannot inject a client AI key (see
      // test/security/no_client_secrets_test.dart).

      final recorder = _RecordingGateway();
      final controller = _controllerFor(recorder.dio());
      final opening = await _startMission(controller, 'p1_012_ac4');
      expect(opening, isA<PersonaSessionStart>());
      expect(recorder.requests, isNotEmpty);
      _assertGatewayRequest(recorder.requests.first);
      expect(
        opening.openingTurn.speechText.contains(_cannedOpening),
        isFalse,
        reason: 'start must use the gateway reply, not a canned fallback',
      );
      expect(
        File(_gatewayClientPath).existsSync(),
        isTrue,
        reason: 'lib/services/ai_gateway_client.dart must exist',
      );
      _assertNoClientAiKeyRead();
    },
  );
}
