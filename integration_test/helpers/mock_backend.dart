import 'dart:convert';
import 'dart:io';

/// Records learning events once per client id.
class MockLearningBackend {
  MockLearningBackend();

  HttpServer? _server;
  final Map<String, Map<String, Object?>> events = {};

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen((request) async {
      try {
        if (request.method != 'POST' || request.uri.path != '/api/learning/events') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
        final incoming = body['events'];
        if (incoming is! List) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }
        var applied = 0;
        for (final raw in incoming) {
          if (raw is! Map) continue;
          final id = raw['clientEventId']?.toString() ?? '';
          if (id.isEmpty) continue;
          if (events.containsKey(id)) continue;
          events[id] = Map<String, Object?>.from(raw);
          applied += 1;
        }
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'applied': applied, 'count': events.length}));
        await request.response.close();
      } catch (error) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('step:sync $error');
        await request.response.close();
      }
    });
  }

  Uri get eventsUri {
    final server = _server;
    if (server == null) throw StateError('step:sync backend is not started');
    return Uri.parse('http://${server.address.host}:${server.port}/api/learning/events');
  }

  Future<void> close() async {
    await _server?.close(force: true);
  }
}
