/// Swahili TTS: Chirp 3 HD sw-KE primary, Intron → Azure fallback (P5-066, P5-065, EXT-01).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:lingafriq/services/quiz/diacritic_grader.dart';
import 'package:lingafriq/services/tts/ig_tts.dart';

const String swTtsCardId = 'P5-066';

/// Documented order after P5-065 blind-test artefact (`assets/data/audio/sw_tts_decision.json`).
const swTtsPrimaryProvider = 'google_chirp3_hd_sw_ke';

const swTtsProviderFallbackOrder = <String>[
  'intron',
  'azure_sw_ke',
];

/// Full dynamic synthesis order: primary then fallbacks.
const swTtsSynthesisProviderOrder = <String>[
  swTtsPrimaryProvider,
  ...swTtsProviderFallbackOrder,
];

const swTtsLocale = 'sw-KE';

/// Linguist listen batch before production TTS use (CURRICULUM §7 Swahili row).
const swRequiredListenSamples = 100;

const _ownSentencesScope = 'own_sentences_only';

const _licensedCommunityProviders = <String>{
  'common_voice',
  'fleurs',
};

class SwTtsInputEmpty implements Exception {
  @override
  String toString() => 'SwTtsInputEmpty';
}

class SwAsrRoundTripFailure implements Exception {
  SwAsrRoundTripFailure(this.code);

  final String code;

  @override
  String toString() => 'SwAsrRoundTripFailure:$code';
}

class SwListenCheckFailure implements Exception {
  SwListenCheckFailure(this.code);

  final String code;

  @override
  String toString() => 'SwListenCheckFailure:$code';
}

class SwLicensedClipMismatch implements Exception {
  SwLicensedClipMismatch(this.code);

  final String code;

  @override
  String toString() => 'SwLicensedClipMismatch:$code';
}

class SwTtsSynthesis {
  const SwTtsSynthesis({
    required this.bytes,
    required this.provider,
  });

  final Uint8List bytes;
  final String provider;
}

typedef SwTtsHttpPost = Future<SwTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

typedef SwTtsHttpGet = Future<SwTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
});

class SwTtsHttpResponse {
  const SwTtsHttpResponse({
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

void assertSwTtsInput(String text) {
  if (nfc(text.trim()).isEmpty) {
    throw SwTtsInputEmpty();
  }
}

String _normalizeAsrMatchText(String text) {
  return nfc(text).split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');
}

/// Intron ASR transcript must match the source phrase (NFC, collapsed whitespace).
void assertSwAsrRoundTrip({
  required String sourceText,
  required String transcript,
}) {
  final ref = _normalizeAsrMatchText(sourceText);
  final hyp = _normalizeAsrMatchText(transcript);
  if (ref.isEmpty) {
    throw SwAsrRoundTripFailure('SOURCE_TEXT_EMPTY');
  }
  if (ref != hyp) {
    throw SwAsrRoundTripFailure('ASR_TEXT_MISMATCH');
  }
}

class SwListenSample {
  const SwListenSample({
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

bool swListenBatchApproved(
  List<SwListenSample> samples, {
  int required = swRequiredListenSamples,
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

void assertSwListenBatchApproved(
  List<SwListenSample> samples, {
  int required = swRequiredListenSamples,
}) {
  if (samples.length < required) {
    throw SwListenCheckFailure('SAMPLE_SHORTFALL');
  }
  final reviewed = samples.where((s) => s.linguistPass != null).toList();
  if (reviewed.length < required) {
    throw SwListenCheckFailure('REVIEW_SHORTFALL');
  }
  for (var i = 0; i < required; i++) {
    if (reviewed[i].linguistPass != true) {
      throw SwListenCheckFailure('LISTEN_CHECK_FAILED');
    }
  }
}

/// Parses `routing_for_p5_066` from [sw_tts_decision.json].
({String primary, List<String> fallbackOrder, List<String> synthesisOrder})
    parseSwTtsRouting(Map<String, dynamic> decision) {
  final routing = decision['routing_for_p5_066'];
  if (routing is! Map) {
    throw StateError('routing_for_p5_066 missing');
  }
  final primary = routing['primary_provider'];
  final fallback = routing['fallback_order'];
  if (primary is! String || primary.isEmpty) {
    throw StateError('primary_provider missing');
  }
  if (fallback is! List || fallback.isEmpty) {
    throw StateError('fallback_order missing');
  }
  final fallbacks = fallback.map((e) => e.toString()).toList();
  return (
    primary: primary,
    fallbackOrder: fallbacks,
    synthesisOrder: [primary, ...fallbacks],
  );
}

List<Map<String, dynamic>> swLicensedHumanPoolsFromRegistry(
  Map<String, dynamic> registry,
) {
  final status = registry['languages'];
  if (status is! Map) {
    return const [];
  }
  final sw = status['sw'];
  if (sw is! List) {
    return const [];
  }
  return sw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// CP-§7-sw-03: Common Voice and FLEURS clips may only back their own sentence.
void assertSwLicensedClipOwnSentence({
  required Map<String, dynamic> pool,
  required String clipTranscript,
  required String requestedText,
}) {
  final provider = pool['provider'];
  if (provider is! String || !_licensedCommunityProviders.contains(provider)) {
    throw SwLicensedClipMismatch('PROVIDER_NOT_COMMUNITY');
  }
  final scope = pool['text_scope'];
  if (scope != _ownSentencesScope) {
    throw SwLicensedClipMismatch('TEXT_SCOPE_NOT_OWN_SENTENCES');
  }
  final lang = pool['language'];
  if (lang != 'sw') {
    throw SwLicensedClipMismatch('LANGUAGE_NOT_SW');
  }
  final ref = _normalizeAsrMatchText(clipTranscript);
  final req = _normalizeAsrMatchText(requestedText);
  if (ref.isEmpty || req.isEmpty) {
    throw SwLicensedClipMismatch('TEXT_EMPTY');
  }
  if (ref != req) {
    throw SwLicensedClipMismatch('OWN_SENTENCE_MISMATCH');
  }
}

/// Server routes (keys stay on backend; Doppler).
class SwTtsPaths {
  static const intronGenerate = '/api/voice/intron/tts/generate';
  static const synthesize = '/api/voice/tts/synthesize';
}

/// Licensed Swahili TTS wired from P5-065 routing artefact (EXT-01).
class SwTtsService {
  SwTtsService({
    required this.baseUrl,
    this.authToken,
    SwTtsHttpPost? post,
    SwTtsHttpGet? get,
    List<String>? providerOrder,
  })  : _post = post ?? _unimplementedPost,
        _get = get ?? _unimplementedGet,
        _providerOrder = providerOrder ?? swTtsSynthesisProviderOrder;

  final String baseUrl;
  final String? authToken;
  final SwTtsHttpPost _post;
  final SwTtsHttpGet _get;
  final List<String> _providerOrder;

  static Future<SwTtsHttpResponse> _unimplementedPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw StateError('SwTtsHttpPost not configured');
  }

  static Future<SwTtsHttpResponse> _unimplementedGet(
    Uri url, {
    Map<String, String>? headers,
  }) {
    throw StateError('SwTtsHttpGet not configured');
  }

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  Future<SwTtsSynthesis> synthesize({
    required String text,
    String language = 'sw',
  }) async {
    final clipped =
        text.length > 500 ? text.substring(0, 500) : text.trim();
    assertSwTtsInput(clipped);

    Object? lastFailure;
    for (final provider in _providerOrder) {
      try {
        final bytes = await _synthesizeProvider(
          clipped,
          language,
          provider,
        );
        return SwTtsSynthesis(bytes: bytes, provider: provider);
      } on IntronTtsFailure catch (e) {
        lastFailure = e;
      }
    }
    if (lastFailure is IntronTtsFailure) {
      throw lastFailure;
    }
    throw IntronTtsFailure('audio_unavailable');
  }

  Future<Uint8List> _synthesizeProvider(
    String text,
    String language,
    String provider,
  ) async {
    if (provider == 'intron') {
      return _synthesizeIntron(text, language);
    }
    return _synthesizeCloud(text, language, provider);
  }

  Future<Uint8List> _synthesizeIntron(String text, String language) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${SwTtsPaths.intronGenerate}'),
      headers: _jsonHeaders(),
      body: jsonEncode({'text': text, 'language': language, 'locale': swTtsLocale}),
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

  Future<Uint8List> _synthesizeCloud(
    String text,
    String language,
    String provider,
  ) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${SwTtsPaths.synthesize}'),
      headers: {
        ..._jsonHeaders(),
        'X-Tts-Provider': provider,
      },
      body: jsonEncode({
        'text': text,
        'language': language,
        'locale': swTtsLocale,
        'provider': provider,
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
