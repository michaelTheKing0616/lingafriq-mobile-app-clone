import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:lingafriq/config/api_contract.dart';

class EventsService {
  final Dio _dio;
  final String _eventSecret;

  EventsService(this._dio, {String? eventSecret})
      : _eventSecret = eventSecret ?? 'default-secret';

  /// Generate HMAC signature for event
  String _generateSignature(String eventType, Map<String, dynamic> payload, String userId) {
    final message = jsonEncode({
      'event_type': eventType,
      'payload': payload,
      'user_id': userId,
    });
    final key = utf8.encode(_eventSecret);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Ingest canonical event
  Future<Map<String, dynamic>> ingestEvent({
    required String eventType,
    required Map<String, dynamic> payload,
    required String userId,
  }) async {
    try {
      final signature = _generateSignature(eventType, payload, userId);
      
      final response = await _dio.post(
        ApiContract.url(ApiContract.events.list),
        data: {
          'event_type': eventType,
          'payload': payload,
          'signature': signature,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

