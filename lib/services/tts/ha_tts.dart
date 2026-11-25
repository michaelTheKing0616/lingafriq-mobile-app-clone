/// Hausa TTS: tone-mark gate (same as Yoruba), Intron → Spitch → ElevenLabs v3 (P5-062, EXT-01).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:lingafriq/services/tts/yo_tts.dart';

/// Documented Hausa TTS fallback order per LINGAFRIQ_AI_MODEL_STACK §3.3.
const haTtsProviderFallbackOrder = <String>[
  'intron',
  'spitch',
  'elevenlabs_v3',
];

class HaTtsSynthesis {
  const HaTtsSynthesis({
    required this.bytes,
    required this.provider,
  });

  final Uint8List bytes;
  final String provider;
}

typedef HaTtsHttpPost = Future<HaTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

typedef HaTtsHttpGet = Future<HaTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
});

class HaTtsHttpResponse {
  const HaTtsHttpResponse({
    required this.statusCode,
    required this.bodyBytes,
    this.headers = const {},
    this.bodyText = '',
  });

  final int statusCode;
  final Uint8List bodyBytes;
  final Map<String, String> headers;
  final String bodyText;
}

/// Server routes (keys stay on backend; Doppler).
class HaTtsPaths {
  static const intronGenerate = '/api/voice/intron/tts/generate';
  static const synthesize = '/api/voice/tts/synthesize';
}

/// Licensed Hausa TTS with Intron → Spitch → ElevenLabs v3 per EXT-01.
class HaTtsService {
  HaTtsService({
    required this.baseUrl,
    this.authToken,
    HaTtsHttpPost? post,
    HaTtsHttpGet? get,
  })  : _post = post ?? _unimplementedPost,
        _get = get ?? _unimplementedGet;

  final String baseUrl;
  final String? authToken;
  final HaTtsHttpPost _post;
  final HaTtsHttpGet _get;

  static Future<HaTtsHttpResponse> _unimplementedPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw StateError('HaTtsHttpPost not configured');
  }

  static Future<HaTtsHttpResponse> _unimplementedGet(
    Uri url, {
    Map<String, String>? headers,
  }) {
    throw StateError('HaTtsHttpGet not configured');
  }

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  Future<HaTtsSynthesis> synthesize({
    required String text,
    String language = 'ha',
  }) async {
    final clipped =
        text.length > 500 ? text.substring(0, 500) : text.trim();
    assertYoFullyToneMarked(clipped);

    try {
      final bytes = await _synthesizeIntron(clipped, language);
      return HaTtsSynthesis(bytes: bytes, provider: 'intron');
    } on IntronTtsFailure {
      try {
        final bytes = await _synthesizeSpitch(clipped, language);
        return HaTtsSynthesis(bytes: bytes, provider: 'spitch');
      } on IntronTtsFailure {
        final bytes = await _synthesizeElevenLabsV3(clipped, language);
        return HaTtsSynthesis(bytes: bytes, provider: 'elevenlabs_v3');
      }
    }
  }

  Future<Uint8List> _synthesizeIntron(String text, String language) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${HaTtsPaths.intronGenerate}'),
      headers: _jsonHeaders(),
      body: jsonEncode({'text': text, 'language': language}),
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(
        resp.bodyText.isNotEmpty
            ? resp.bodyText
            : utf8.decode(resp.bodyBytes, allowMalformed: true),
      );
      if (decoded is Map) {
        final audioUrl = decoded['audioUrl'] ?? decoded['audioPath'];
        if (audioUrl is String && audioUrl.isNotEmpty) {
          if (audioUrl.startsWith('http')) {
            final audio = await _get(Uri.parse(audioUrl), headers: _jsonHeaders());
            if (audio.statusCode == 200 && audio.bodyBytes.isNotEmpty) {
              return audio.bodyBytes;
            }
          }
          final proxied = await _get(
            Uri.parse(
              '$root/api/voice/tts/proxy?path=${Uri.encodeComponent(audioUrl)}',
            ),
            headers: _jsonHeaders(),
          );
          if (proxied.statusCode == 200 && proxied.bodyBytes.isNotEmpty) {
            return proxied.bodyBytes;
          }
        }
        if (decoded['audio'] is String) {
          return base64Decode(decoded['audio'] as String);
        }
      }
      if (resp.bodyBytes.isNotEmpty &&
          !resp.headers['content-type'].toString().contains('json')) {
        return resp.bodyBytes;
      }
    }
    if (resp.statusCode == 503) {
      throw IntronTtsFailure(_readCode(resp.bodyText, resp.bodyBytes));
    }
    throw IntronTtsFailure('intron_http_${resp.statusCode}');
  }

  Future<Uint8List> _synthesizeSpitch(String text, String language) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${HaTtsPaths.synthesize}'),
      headers: {
        ..._jsonHeaders(),
        'X-Tts-Provider': 'spitch',
      },
      body: jsonEncode({
        'text': text,
        'language': language,
        'provider': 'spitch',
      }),
    );
    if (resp.statusCode == 200 &&
        resp.bodyBytes.isNotEmpty &&
        !resp.headers['content-type'].toString().contains('json')) {
      return resp.bodyBytes;
    }
    throw IntronTtsFailure(_readCode(resp.bodyText, resp.bodyBytes));
  }

  Future<Uint8List> _synthesizeElevenLabsV3(String text, String language) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${HaTtsPaths.synthesize}'),
      headers: {
        ..._jsonHeaders(),
        'X-Tts-Provider': 'elevenlabs_v3',
      },
      body: jsonEncode({
        'text': text,
        'language': language,
        'provider': 'elevenlabs_v3',
      }),
    );
    if (resp.statusCode == 200 &&
        resp.bodyBytes.isNotEmpty &&
        !resp.headers['content-type'].toString().contains('json')) {
      return resp.bodyBytes;
    }
    throw IntronTtsFailure(_readCode(resp.bodyText, resp.bodyBytes));
  }

  String _readCode(String bodyText, Uint8List bodyBytes) {
    try {
      final raw = bodyText.isNotEmpty
          ? bodyText
          : utf8.decode(bodyBytes, allowMalformed: true);
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['code'] is String) {
        return decoded['code'] as String;
      }
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return 'audio_unavailable';
  }
}
