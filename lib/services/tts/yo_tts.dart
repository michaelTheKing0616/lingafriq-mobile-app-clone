/// Yoruba TTS: tone-mark gate, Intron primary, Spitch fallback (P5-060, EXT-01).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:lingafriq/services/quiz/diacritic_grader.dart';

/// Thrown when learner-facing Yoruba text is not fully tone-marked (CP-§7-yo-02).
class ToneMarksMissing implements Exception {
  ToneMarksMissing(this.word);

  final String word;

  @override
  String toString() => 'ToneMarksMissing';
}

/// Intron path failed; caller may retry via Spitch.
class IntronTtsFailure implements Exception {
  IntronTtsFailure(this.code);

  final String code;

  @override
  String toString() => 'IntronTtsFailure:$code';
}

class YoTtsSynthesis {
  const YoTtsSynthesis({
    required this.bytes,
    required this.provider,
  });

  final Uint8List bytes;
  final String provider;
}

typedef YoTtsHttpPost = Future<YoTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

typedef YoTtsHttpGet = Future<YoTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
});

class YoTtsHttpResponse {
  const YoTtsHttpResponse({
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

const _toneMarks = {
  '\u0300',
  '\u0301',
  '\u0304',
  '\u0302',
  '\u030c',
  '\u030b',
  '\u030f',
};

final _wordPattern = RegExp(r'[\p{L}\p{M}]+', unicode: true);

bool yoWordHasToneMark(String word) {
  for (final unit in word.runes) {
    final ch = String.fromCharCode(unit);
    if (_toneMarks.contains(ch)) return true;
    if (unit >= 0x00C0 && unit <= 0x024F) return true;
  }
  return false;
}

/// Every Yoruba word in [text] must carry at least one tone mark (NFC).
void assertYoFullyToneMarked(String text) {
  final trimmed = nfc(text.trim());
  if (trimmed.isEmpty) {
    throw ToneMarksMissing('');
  }
  for (final match in _wordPattern.allMatches(trimmed)) {
    final word = match.group(0)!;
    if (!yoWordHasToneMark(word)) {
      throw ToneMarksMissing(word);
    }
  }
}

/// Server routes (keys stay on backend; Doppler).
class YoTtsPaths {
  static const intronGenerate = '/api/voice/intron/tts/generate';
  static const spitchSynthesize = '/api/voice/tts/synthesize';
}

/// Licensed Yoruba TTS with Intron → Spitch fallback per LINGAFRIQ_AI_MODEL_STACK §3.3.
class YoTtsService {
  YoTtsService({
    required this.baseUrl,
    this.authToken,
    YoTtsHttpPost? post,
    YoTtsHttpGet? get,
  })  : _post = post ?? _unimplementedPost,
        _get = get ?? _unimplementedGet;

  final String baseUrl;
  final String? authToken;
  final YoTtsHttpPost _post;
  final YoTtsHttpGet _get;

  static Future<YoTtsHttpResponse> _unimplementedPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw StateError('YoTtsHttpPost not configured');
  }

  static Future<YoTtsHttpResponse> _unimplementedGet(
    Uri url, {
    Map<String, String>? headers,
  }) {
    throw StateError('YoTtsHttpGet not configured');
  }

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  Future<YoTtsSynthesis> synthesize({
    required String text,
    String language = 'yo',
  }) async {
    final clipped =
        text.length > 500 ? text.substring(0, 500) : text.trim();
    assertYoFullyToneMarked(clipped);

    try {
      final bytes = await _synthesizeIntron(clipped, language);
      return YoTtsSynthesis(bytes: bytes, provider: 'intron');
    } on IntronTtsFailure {
      final bytes = await _synthesizeSpitch(clipped, language);
      return YoTtsSynthesis(bytes: bytes, provider: 'spitch');
    }
  }

  Future<Uint8List> _synthesizeIntron(String text, String language) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${YoTtsPaths.intronGenerate}'),
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
      Uri.parse('$root${YoTtsPaths.spitchSynthesize}'),
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
