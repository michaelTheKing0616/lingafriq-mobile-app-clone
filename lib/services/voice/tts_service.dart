/// Licensed server TTS for lens flows. No on-device voice fallback.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Server returned 503 with a known unavailable code (e.g. voice_coming).
class LicensedVoiceUnavailable implements Exception {
  LicensedVoiceUnavailable(this.code);
  final String code;

  @override
  String toString() => code;
}

typedef LicensedTtsHttpClient = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

/// Calls `/api/voice/tts/synthesize` only — used when human audio is absent.
class TtsService {
  TtsService({
    required this.baseUrl,
    this.authToken,
    LicensedTtsHttpClient? post,
    http.Client? client,
  })  : _post = post ??
            ((url, {headers, body}) {
              final c = client ?? http.Client();
              return c.post(url, headers: headers, body: body as String?);
            });

  final String baseUrl;
  final String? authToken;
  final LicensedTtsHttpClient _post;

  static const synthesizePath = '/api/voice/tts/synthesize';

  Future<Uint8List> synthesize({
    required String language,
    required String text,
    String? voice,
    double speed = 1.0,
  }) async {
    final clipped =
        text.length > 500 ? text.substring(0, 500) : text.trim();
    if (clipped.isEmpty) {
      throw LicensedVoiceUnavailable('audio_unavailable');
    }

    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final resp = await _post(
      Uri.parse('$root$synthesizePath'),
      headers: headers,
      body: jsonEncode({
        'text': clipped,
        'language': language.trim(),
        if (voice != null && voice.trim().isNotEmpty) 'voice': voice.trim(),
        'speed': speed,
      }),
    );

    if (resp.statusCode == 200 &&
        resp.bodyBytes.isNotEmpty &&
        !resp.headers['content-type'].toString().contains('json')) {
      return resp.bodyBytes;
    }

    if (resp.statusCode == 503) {
      final code = _readUnavailableCode(resp.body);
      if (code == 'voice_coming' || code == 'audio_unavailable') {
        throw LicensedVoiceUnavailable(code!);
      }
      throw LicensedVoiceUnavailable('audio_unavailable');
    }

    throw LicensedVoiceUnavailable('audio_unavailable');
  }

  String? _readUnavailableCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['code'] is String) {
        return decoded['code'] as String;
      }
    } catch (_) {}
    return null;
  }
}
