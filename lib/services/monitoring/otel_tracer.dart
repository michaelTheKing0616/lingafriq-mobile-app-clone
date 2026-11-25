import 'dart:math';

/// Builds a W3C `traceparent` for one request.
///
/// The same trace id is what the API, the AI gateway, and speech continue.
/// Attribute names outside [allowedAttributes] are dropped, so a prompt or an
/// email address cannot ride along on a span.
class OtelTracer {
  OtelTracer({Random? random}) : _random = random ?? Random.secure();

  static const allowedAttributes = <String>{
    'http.method',
    'http.route',
    'http.status_code',
    'peer.service',
    'service.name',
    'lingafriq.stage',
  };

  final Random _random;

  /// `00-{trace-id}-{span-id}-01`, the header the API extracts.
  String newTraceparent() {
    return '00-${_hex(16)}-${_hex(8)}-01';
  }

  Map<String, String> headers() {
    return {'traceparent': newTraceparent()};
  }

  /// Returns only the attributes this service is allowed to export.
  Map<String, Object> attributes(Map<String, Object> input) {
    final kept = <String, Object>{};
    input.forEach((key, value) {
      if (!allowedAttributes.contains(key)) return;
      if (value is String || value is num || value is bool) kept[key] = value;
    });
    return kept;
  }

  String _hex(int bytes) {
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
