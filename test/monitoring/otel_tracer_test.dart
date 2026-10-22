import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/monitoring/otel_tracer.dart';

void main() {
  test('a chat request header is one W3C trace and drops prompt text', () {
    final tracer = OtelTracer();
    final header = tracer.headers()['traceparent']!;
    final parts = header.split('-');

    expect(parts, hasLength(4));
    expect(parts[0], '00');
    expect(parts[1], hasLength(32));
    expect(parts[2], hasLength(16));
    expect(parts[3], '01');

    final kept = tracer.attributes({
      'http.method': 'POST',
      'http.route': '/ai/chat/completion',
      'lingafriq.stage': 'app',
      'prompt': 'secret prompt text',
      'user.email': 'seeded-person@example.com',
    });

    expect(kept['http.method'], 'POST');
    expect(kept.containsKey('prompt'), isFalse);
    expect(kept.containsKey('user.email'), isFalse);
    expect(kept.values.join(' '), isNot(contains('secret prompt text')));
    expect(kept.values.join(' '), isNot(contains('seeded-person@example.com')));
  });
}
