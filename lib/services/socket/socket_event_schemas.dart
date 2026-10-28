import 'dart:convert';

/// Wire schema version for Socket.IO payloads (must match server).
const int socketEventSchemaVersion = 1;
const int minSupportedSocketSchemaVersion = 1;
const int maxSupportedSocketSchemaVersion = 1;

const String socketErrorEventInvalid = 'EVENT_INVALID';
const String socketErrorUnsupportedVersion = 'UNSUPPORTED_VERSION';

const int maxInboundSocketPayloadBytes = 65536;

/// Last inbound validation failure for UI diagnostics (never partial-render bad data).
class SocketEventDiagnostic {
  const SocketEventDiagnostic({
    required this.eventName,
    required this.code,
    this.detail,
    this.receivedVersion,
    required this.at,
  });

  final String eventName;
  final String code;
  final String? detail;
  final int? receivedVersion;
  final DateTime at;
}

SocketEventDiagnostic? lastSocketEventDiagnostic;

void recordSocketEventDiagnostic(SocketEventDiagnostic diagnostic) {
  lastSocketEventDiagnostic = diagnostic;
}

Map<String, dynamic> wrapOutboundSocketPayload(Map<String, dynamic> body) {
  return {
    'schemaVersion': socketEventSchemaVersion,
    ...body,
  };
}

int? _readSchemaVersion(Map<String, dynamic> record) {
  final raw = record['schemaVersion'];
  if (raw == null) return socketEventSchemaVersion;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return null;
}

bool _payloadTooLarge(dynamic raw) {
  try {
    final bytes = utf8.encode(jsonEncode(raw));
    return bytes.length > maxInboundSocketPayloadBytes;
  } catch (_) {
    return true;
  }
}

String? _requireString(Map<String, dynamic> m, String key, {int maxLen = 4096}) {
  final v = m[key];
  if (v == null) return null;
  final s = v.toString();
  if (s.isEmpty || s.length > maxLen) return null;
  return s;
}

/// Validates a server→client event before merging into UI state.
/// Returns parsed map on success; records [SocketEventDiagnostic] and returns null on failure.
Map<String, dynamic>? validateInboundSocketEvent(String eventName, dynamic raw) {
  if (_payloadTooLarge(raw)) {
    recordSocketEventDiagnostic(SocketEventDiagnostic(
      eventName: eventName,
      code: socketErrorEventInvalid,
      detail: 'payload_too_large',
      at: DateTime.now().toUtc(),
    ));
    return null;
  }

  if (raw == null) {
    recordSocketEventDiagnostic(SocketEventDiagnostic(
      eventName: eventName,
      code: socketErrorEventInvalid,
      detail: 'null_payload',
      at: DateTime.now().toUtc(),
    ));
    return null;
  }

  if (raw is! Map) {
    if (eventName == 'online_users' && raw is List) {
      return {'users': raw};
    }
    recordSocketEventDiagnostic(SocketEventDiagnostic(
      eventName: eventName,
      code: socketErrorEventInvalid,
      detail: 'expected_map',
      at: DateTime.now().toUtc(),
    ));
    return null;
  }

  final record = Map<String, dynamic>.from(raw);
  final version = _readSchemaVersion(record);
  if (version == null) {
    recordSocketEventDiagnostic(SocketEventDiagnostic(
      eventName: eventName,
      code: socketErrorEventInvalid,
      detail: 'invalid_schemaVersion',
      at: DateTime.now().toUtc(),
    ));
    return null;
  }
  if (version < minSupportedSocketSchemaVersion || version > maxSupportedSocketSchemaVersion) {
    recordSocketEventDiagnostic(SocketEventDiagnostic(
      eventName: eventName,
      code: socketErrorUnsupportedVersion,
      receivedVersion: version,
      detail: 'unsupported_schema_version',
      at: DateTime.now().toUtc(),
    ));
    return null;
  }

  switch (eventName) {
    case 'message':
    case 'new_message':
      final room = _requireString(record, 'room', maxLen: 200);
      final userId = record['userId']?.toString();
      final message = _requireString(record, 'message', maxLen: 16384) ??
          _requireString(record, 'text', maxLen: 16384);
      if (room == null || userId == null || userId.isEmpty || message == null) {
        recordSocketEventDiagnostic(SocketEventDiagnostic(
          eventName: eventName,
          code: socketErrorEventInvalid,
          detail: 'chat_message_fields',
          at: DateTime.now().toUtc(),
        ));
        return null;
      }
      return record;
    case 'send_message_ack':
    case 'message_ack':
      final status = record['status']?.toString();
      if (status == null || status.isEmpty) {
        recordSocketEventDiagnostic(SocketEventDiagnostic(
          eventName: eventName,
          code: socketErrorEventInvalid,
          detail: 'ack_status',
          at: DateTime.now().toUtc(),
        ));
        return null;
      }
      return record;
    case 'message_deleted':
    case 'message_edited':
    case 'message_reacted':
      final messageId = record['messageId']?.toString() ?? record['id']?.toString();
      if (messageId == null || messageId.isEmpty) {
        recordSocketEventDiagnostic(SocketEventDiagnostic(
          eventName: eventName,
          code: socketErrorEventInvalid,
          detail: 'message_id',
          at: DateTime.now().toUtc(),
        ));
        return null;
      }
      return record;
    default:
      return record;
  }
}
