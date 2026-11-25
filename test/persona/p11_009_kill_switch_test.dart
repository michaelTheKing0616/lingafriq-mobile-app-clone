import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/persona_providers.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.available);

  final bool available;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/api/ai/persona/availability/')) {
      return ResponseBody.fromString(
        '{"ok":true,"available":$available,"scope":null}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('{}', 404);
  }
}

void main() {
  test('setPersona marks unavailable when server reports disabled', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.test'));
    dio.httpClientAdapter = _FakeAdapter(false);

    final container = ProviderContainer(
      overrides: [
        client.overrideWithValue(dio),
      ],
    );

    final notifier = container.read(personaChatProvider.notifier);
    await notifier.setPersona('mandela_nelson');

    final state = container.read(personaChatProvider);
    expect(state.personaUnavailable, isTrue);
    expect(state.error, kPersonaUnavailableCopy);

    container.dispose();
  });

  test('sendMessage is blocked when personaUnavailable', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.test'));
    dio.httpClientAdapter = _FakeAdapter(false);

    final container = ProviderContainer(
      overrides: [
        client.overrideWithValue(dio),
      ],
    );

    final notifier = container.read(personaChatProvider.notifier);
    await notifier.setPersona('mandela_nelson');
    final result = await notifier.sendMessage('Hello');

    expect(result, isNull);
    expect(container.read(personaChatProvider).personaUnavailable, isTrue);

    container.dispose();
  });
}
