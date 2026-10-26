/// Igbo TTS: Intron primary, Spitch fallback (P5-061, EXT-01, CP-§7-ig-01).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:lingafriq/services/quiz/diacritic_grader.dart';

/// Learner-facing Igbo TTS input must be non-empty NFC (tone convention is lexicon-first; P4-038).
class IgTtsInputEmpty implements Exception {
  @override
  String toString() => 'IgTtsInputEmpty';
}

/// Intron path failed; caller may retry via Spitch.
class IntronTtsFailure implements Exception {
  IntronTtsFailure(this.code);

  final String code;

  @override
  String toString() => 'IntronTtsFailure:$code';
}

class IgTtsSynthesis {
  const IgTtsSynthesis({
    required this.bytes,
    required this.provider,
  });

  final Uint8List bytes;
  final String provider;
}

typedef IgTtsHttpPost = Future<IgTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

typedef IgTtsHttpGet = Future<IgTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
});

class IgTtsHttpResponse {
  const IgTtsHttpResponse({
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

void assertIgTtsInput(String text) {
  if (nfc(text.trim()).isEmpty) {
    throw IgTtsInputEmpty();
  }
}

/// Server routes (keys stay on backend; Doppler).
class IgTtsPaths {
  static const intronGenerate = '/api/voice/intron/tts/generate';
  static const spitchSynthesize = '/api/voice/tts/synthesize';
}

/// Licensed Igbo TTS with Intron → Spitch fallback per LINGAFRIQ_AI_MODEL_STACK §3.3.
class IgTtsService {
  IgTtsService({
    required this.baseUrl,
    this.authToken,
    IgTtsHttpPost? post,
    IgTtsHttpGet? get,
  })  : _post = post ?? _unimplementedPost,
        _get = get ?? _unimplementedGet;

  final String baseUrl;
  final String? authToken;
  final IgTtsHttpPost _post;
  final IgTtsHttpGet _get;

  static Future<IgTtsHttpResponse> _unimplementedPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw StateError('IgTtsHttpPost not configured');
  }

  static Future<IgTtsHttpResponse> _unimplementedGet(
    Uri url, {
    Map<String, String>? headers,
  }) {
    throw StateError('IgTtsHttpGet not configured');
  }

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  Future<IgTtsSynthesis> synthesize({
    required String text,
    String language = 'ig',
  }) async {
    final clipped =
        text.length > 500 ? text.substring(0, 500) : text.trim();
    assertIgTtsInput(clipped);

    try {
      final bytes = await _synthesizeIntron(clipped, language);
      return IgTtsSynthesis(bytes: bytes, provider: 'intron');
    } on IntronTtsFailure {
      final bytes = await _synthesizeSpitch(clipped, language);
      return IgTtsSynthesis(bytes: bytes, provider: 'spitch');
    }
  }

  Future<Uint8List> _synthesizeIntron(String text, String language) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${IgTtsPaths.intronGenerate}'),
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
            Uri.parse('$root/api/voice/tts/proxy?path=${Uri.encodeComponent(audioUrl)}'),
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
      Uri.parse('$root${IgTtsPaths.spitchSynthesize}'),
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
