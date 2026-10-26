/// Nigerian Pidgin TTS: Intron → Spitch, licensed-human n/a, listen + ASR gates (P5-064, EXT-01).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:lingafriq/services/quiz/diacritic_grader.dart';
import 'package:lingafriq/services/tts/ig_tts.dart';

const String pcmTtsCardId = 'P5-064';

/// Documented Pidgin TTS fallback per LINGAFRIQ_AI_MODEL_STACK §3.3 / CP-§7-pcm-01.
const pcmTtsProviderFallbackOrder = <String>['intron', 'spitch'];

/// CP-§7-pcm-02: no licensed human Pidgin pool in the register yet.
const pcmLicensedHumanAudioUsableNow = 'n/a';

/// Linguist listen batch before production TTS use (same bar as Yoruba listen gate).
const pcmRequiredListenSamples = 100;

class PcmTtsInputEmpty implements Exception {
  @override
  String toString() => 'PcmTtsInputEmpty';
}

class PcmAsrRoundTripFailure implements Exception {
  PcmAsrRoundTripFailure(this.code);

  final String code;

  @override
  String toString() => 'PcmAsrRoundTripFailure:$code';
}

class PcmListenCheckFailure implements Exception {
  PcmListenCheckFailure(this.code);

  final String code;

  @override
  String toString() => 'PcmListenCheckFailure:$code';
}

class PcmTtsSynthesis {
  const PcmTtsSynthesis({
    required this.bytes,
    required this.provider,
  });

  final Uint8List bytes;
  final String provider;
}

typedef PcmTtsHttpPost = Future<PcmTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

typedef PcmTtsHttpGet = Future<PcmTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
});

class PcmTtsHttpResponse {
  const PcmTtsHttpResponse({
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

void assertPcmTtsInput(String text) {
  if (nfc(text.trim()).isEmpty) {
    throw PcmTtsInputEmpty();
  }
}

String _normalizeAsrMatchText(String text) {
  return nfc(text).split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');
}

/// CP-§7-pcm-03: Intron ASR transcript must match the source phrase (NFC, collapsed whitespace).
void assertPcmAsrRoundTrip({
  required String sourceText,
  required String transcript,
}) {
  final ref = _normalizeAsrMatchText(sourceText);
  final hyp = _normalizeAsrMatchText(transcript);
  if (ref.isEmpty) {
    throw PcmAsrRoundTripFailure('SOURCE_TEXT_EMPTY');
  }
  if (ref != hyp) {
    throw PcmAsrRoundTripFailure('ASR_TEXT_MISMATCH');
  }
}

class PcmListenSample {
  const PcmListenSample({
    required this.sampleId,
    required this.sourceText,
    required this.audioRef,
    this.linguistPass,
  });

  final String sampleId;
  final String sourceText;
  final String audioRef;
  final bool? linguistPass;
}

bool pcmListenBatchApproved(
  List<PcmListenSample> samples, {
  int required = pcmRequiredListenSamples,
}) {
  if (samples.length < required) {
    return false;
  }
  final reviewed = samples.where((s) => s.linguistPass != null).toList();
  if (reviewed.length < required) {
    return false;
  }
  for (var i = 0; i < required; i++) {
    if (reviewed[i].linguistPass != true) {
      return false;
    }
  }
  return true;
}

void assertPcmListenBatchApproved(
  List<PcmListenSample> samples, {
  int required = pcmRequiredListenSamples,
}) {
  if (samples.length < required) {
    throw PcmListenCheckFailure('SAMPLE_SHORTFALL');
  }
  final reviewed = samples.where((s) => s.linguistPass != null).toList();
  if (reviewed.length < required) {
    throw PcmListenCheckFailure('REVIEW_SHORTFALL');
  }
  for (var i = 0; i < required; i++) {
    if (reviewed[i].linguistPass != true) {
      throw PcmListenCheckFailure('LISTEN_CHECK_FAILED');
    }
  }
}

/// Reads `assets/data/audio/licensed_human.json` language pools (CP-§7-pcm-02).
List<Map<String, dynamic>> pcmLicensedHumanPoolsFromRegistry(
  Map<String, dynamic> registry,
) {
  final status = registry['languages'];
  if (status is! Map) {
    return const [];
  }
  final pcm = status['pcm'];
  if (pcm is! List) {
    return const [];
  }
  return pcm
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// Server routes (keys stay on backend; Doppler).
class PcmTtsPaths {
  static const intronGenerate = '/api/voice/intron/tts/generate';
  static const spitchSynthesize = '/api/voice/tts/synthesize';
}

/// Licensed Nigerian Pidgin TTS with Intron → Spitch fallback per EXT-01.
class PcmTtsService {
  PcmTtsService({
    required this.baseUrl,
    this.authToken,
    PcmTtsHttpPost? post,
    PcmTtsHttpGet? get,
  })  : _post = post ?? _unimplementedPost,
        _get = get ?? _unimplementedGet;

  final String baseUrl;
  final String? authToken;
  final PcmTtsHttpPost _post;
  final PcmTtsHttpGet _get;

  static Future<PcmTtsHttpResponse> _unimplementedPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw StateError('PcmTtsHttpPost not configured');
  }

  static Future<PcmTtsHttpResponse> _unimplementedGet(
    Uri url, {
    Map<String, String>? headers,
  }) {
    throw StateError('PcmTtsHttpGet not configured');
  }

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  Future<PcmTtsSynthesis> synthesize({
    required String text,
    String language = 'pcm',
  }) async {
    final clipped =
        text.length > 500 ? text.substring(0, 500) : text.trim();
    assertPcmTtsInput(clipped);

    try {
      final bytes = await _synthesizeIntron(clipped, language);
      return PcmTtsSynthesis(bytes: bytes, provider: 'intron');
    } on IntronTtsFailure {
      final bytes = await _synthesizeSpitch(clipped, language);
      return PcmTtsSynthesis(bytes: bytes, provider: 'spitch');
    }
  }

  Future<Uint8List> _synthesizeIntron(String text, String language) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${PcmTtsPaths.intronGenerate}'),
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
            final audio =
                await _get(Uri.parse(audioUrl), headers: _jsonHeaders());
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
      Uri.parse('$root${PcmTtsPaths.spitchSynthesize}'),
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
