import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/socket/socket_event_schemas.dart';

void main() {
  setUp(() {
    lastSocketEventDiagnostic = null;
  });

  test('discards invalid inbound chat message and records diagnostic', () {
    final parsed = validateInboundSocketEvent('message', {
      'schemaVersion': 1,
      'room': 'general',
    });
    expect(parsed, isNull);
    expect(lastSocketEventDiagnostic?.code, socketErrorEventInvalid);
    expect(lastSocketEventDiagnostic?.eventName, 'message');
  });

  test('UNSUPPORTED_VERSION on future schema', () {
    final parsed = validateInboundSocketEvent('new_message', {
      'schemaVersion': 99,
      'room': 'general',
      'userId': 'u1',
      'message': 'hi',
    });
    expect(parsed, isNull);
    expect(lastSocketEventDiagnostic?.code, socketErrorUnsupportedVersion);
    expect(lastSocketEventDiagnostic?.receivedVersion, 99);
  });

  test('accepts valid inbound message', () {
    final parsed = validateInboundSocketEvent('message', {
      'schemaVersion': 1,
      'room': 'general',
      'userId': 'u1',
      'message': 'Ẹ kú àárọ̀',
    });
    expect(parsed, isNotNull);
    expect(parsed!['message'], 'Ẹ kú àárọ̀');
  });

  test('wrapOutbound adds schemaVersion', () {
    final wrapped = wrapOutboundSocketPayload({'room': 'general'});
    expect(wrapped['schemaVersion'], socketEventSchemaVersion);
    expect(wrapped['room'], 'general');
  });
}
