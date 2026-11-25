/// isiZulu TTS: Azure zu-ZA Thando/Themba (P5-067, EXT-01 §3.3).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:lingafriq/services/quiz/diacritic_grader.dart';
import 'package:lingafriq/services/tts/ig_tts.dart';

const String zuTtsCardId = 'P5-067';

const zuTtsLocale = 'zu-ZA';

/// Azure neural voice names per LINGAFRIQ_AI_MODEL_STACK §3.3.
const zuAzureVoiceThandoNeural = 'zu-ZA-ThandoNeural';
const zuAzureVoiceThembaNeural = 'zu-ZA-ThembaNeural';

const zuTtsProviderThando = 'azure_zu_za_thando';
const zuTtsProviderThemba = 'azure_zu_za_themba';

const zuTtsSynthesisProviderOrder = <String>[
  zuTtsProviderThando,
  zuTtsProviderThemba,
];

const zuRequiredListenSamples = 100;

const _ownSentencesScope = 'own_sentences_only';

const _licensedCommunityProviders = <String>{
  'fleurs',
  'waxal',
};

const _allowedAsrProviders = <String>{
  'intron',
  'lelapa',
};

/// PanSALB-style click letters in learner-facing Zulu orthography (c, q, x).
final RegExp _zuClickLetter = RegExp(r'[cqx]', caseSensitive: false);

enum ZuAzureVoice {
  thando(zuAzureVoiceThandoNeural, zuTtsProviderThando),
  themba(zuAzureVoiceThembaNeural, zuTtsProviderThemba);

  const ZuAzureVoice(this.voiceName, this.providerId);

  final String voiceName;
  final String providerId;

  ZuAzureVoice alternate() =>
      this == ZuAzureVoice.thando ? ZuAzureVoice.themba : ZuAzureVoice.thando;
}

class ZuTtsInputEmpty implements Exception {
  @override
  String toString() => 'ZuTtsInputEmpty';
}

class ZuAsrRoundTripFailure implements Exception {
  ZuAsrRoundTripFailure(this.code);

  final String code;

  @override
  String toString() => 'ZuAsrRoundTripFailure:$code';
}

class ZuListenCheckFailure implements Exception {
  ZuListenCheckFailure(this.code);

  final String code;

  @override
  String toString() => 'ZuListenCheckFailure:$code';
}

class ZuLicensedClipMismatch implements Exception {
  ZuLicensedClipMismatch(this.code);

  final String code;

  @override
  String toString() => 'ZuLicensedClipMismatch:$code';
}

class ZuClickCheckFailure implements Exception {
  ZuClickCheckFailure(this.code);

  final String code;

  @override
  String toString() => 'ZuClickCheckFailure:$code';
}

class ZuTtsSynthesis {
  const ZuTtsSynthesis({
    required this.bytes,
    required this.provider,
    required this.voiceName,
  });

  final Uint8List bytes;
  final String provider;
  final String voiceName;
}

typedef ZuTtsHttpPost = Future<ZuTtsHttpResponse> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

class ZuTtsHttpResponse {
  const ZuTtsHttpResponse({
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

void assertZuTtsInput(String text) {
  if (nfc(text.trim()).isEmpty) {
    throw ZuTtsInputEmpty();
  }
}

String _normalizeAsrMatchText(String text) {
  return nfc(text).split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');
}

void assertZuAsrProvider(String provider) {
  if (!_allowedAsrProviders.contains(provider)) {
    throw ZuAsrRoundTripFailure('ASR_PROVIDER_FORBIDDEN');
  }
}

/// CP-§7-zu-03: Intron or Lelapa ASR transcript must match source (NFC).
void assertZuAsrRoundTrip({
  required String sourceText,
  required String transcript,
  required String asrProvider,
}) {
  assertZuAsrProvider(asrProvider);
  final ref = _normalizeAsrMatchText(sourceText);
  final hyp = _normalizeAsrMatchText(transcript);
  if (ref.isEmpty) {
    throw ZuAsrRoundTripFailure('SOURCE_TEXT_EMPTY');
  }
  if (ref != hyp) {
    throw ZuAsrRoundTripFailure('ASR_TEXT_MISMATCH');
  }
  assertZuClickInventoryMatches(sourceText: sourceText, transcript: transcript);
}

List<String> zuClickInventory(String text) {
  final lower = nfc(text).toLowerCase();
  final letters = <String>{};
  for (final match in _zuClickLetter.allMatches(lower)) {
    letters.add(match.group(0)!);
  }
  final sorted = letters.toList();
  sorted.sort();
  return sorted;
}

bool zuTextContainsClicks(String text) => zuClickInventory(text).isNotEmpty;

void assertZuClickInventoryMatches({
  required String sourceText,
  required String transcript,
}) {
  final src = zuClickInventory(sourceText);
  if (src.isEmpty) {
    return;
  }
  final hyp = zuClickInventory(transcript);
  if (src.length != hyp.length || !_listEq(src, hyp)) {
    throw ZuClickCheckFailure('CLICK_INVENTORY_MISMATCH');
  }
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

class ZuListenSample {
  const ZuListenSample({
    required this.sampleId,
    required this.sourceText,
    required this.audioRef,
    this.linguistPass,
    this.asrTranscript,
    this.asrProvider = 'intron',
  });

  final String sampleId;
  final String sourceText;
  final String audioRef;
  final bool? linguistPass;
  final String? asrTranscript;
  final String asrProvider;
}

bool zuListenBatchApproved(
  List<ZuListenSample> samples, {
  int required = zuRequiredListenSamples,
}) {
  try {
    assertZuListenBatchApproved(samples, required: required);
    return true;
  } on ZuListenCheckFailure {
    return false;
  } on ZuAsrRoundTripFailure {
    return false;
  } on ZuClickCheckFailure {
    return false;
  }
}

void assertZuListenBatchApproved(
  List<ZuListenSample> samples, {
  int required = zuRequiredListenSamples,
}) {
  if (samples.length < required) {
    throw ZuListenCheckFailure('SAMPLE_SHORTFALL');
  }
  final reviewed = samples.where((s) => s.linguistPass != null).toList();
  if (reviewed.length < required) {
    throw ZuListenCheckFailure('REVIEW_SHORTFALL');
  }
  for (var i = 0; i < required; i++) {
    final sample = reviewed[i];
    if (sample.linguistPass != true) {
      throw ZuListenCheckFailure('LISTEN_CHECK_FAILED');
    }
    final transcript = sample.asrTranscript;
    if (transcript != null && transcript.isNotEmpty) {
      assertZuAsrRoundTrip(
        sourceText: sample.sourceText,
        transcript: transcript,
        asrProvider: sample.asrProvider,
      );
    } else if (zuTextContainsClicks(sample.sourceText)) {
      throw ZuClickCheckFailure('CLICK_ASR_MISSING');
    }
  }
}

List<Map<String, dynamic>> zuLicensedHumanPoolsFromRegistry(
  Map<String, dynamic> registry,
) {
  final status = registry['languages'];
  if (status is! Map) {
    return const [];
  }
  final zu = status['zu'];
  if (zu is! List) {
    return const [];
  }
  return zu
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// CP-§7-zu-02: FLEURS/WAXAL clips only for their own sentence; WAXAL subset licence.
void assertZuLicensedClipOwnSentence({
  required Map<String, dynamic> pool,
  required String clipTranscript,
  required String requestedText,
}) {
  final provider = pool['provider'];
  if (provider is! String || !_licensedCommunityProviders.contains(provider)) {
    throw ZuLicensedClipMismatch('PROVIDER_NOT_COMMUNITY');
  }
  final scope = pool['text_scope'];
  if (scope != _ownSentencesScope) {
    throw ZuLicensedClipMismatch('TEXT_SCOPE_NOT_OWN_SENTENCES');
  }
  final lang = pool['language'];
  if (lang != 'zu') {
    throw ZuLicensedClipMismatch('LANGUAGE_NOT_ZU');
  }
  if (provider == 'waxal') {
    final registerId = pool['register_id'] ?? pool['waxal_register_id'];
    if (registerId != 'waxal-other') {
      throw ZuLicensedClipMismatch('WAXAL_SUBSET_LICENCE');
    }
    final verified = pool['subset_licence_verified'];
    if (verified != true) {
      throw ZuLicensedClipMismatch('SUBSET_LICENCE_UNVERIFIED');
    }
  }
  if (provider == 'fleurs') {
    final licenceId = pool['licence_id'];
    if (licenceId != 'fleurs') {
      throw ZuLicensedClipMismatch('FLEURS_LICENCE_ID');
    }
  }
  final ref = _normalizeAsrMatchText(clipTranscript);
  final req = _normalizeAsrMatchText(requestedText);
  if (ref.isEmpty || req.isEmpty) {
    throw ZuLicensedClipMismatch('TEXT_EMPTY');
  }
  if (ref != req) {
    throw ZuLicensedClipMismatch('OWN_SENTENCE_MISMATCH');
  }
}

/// Server routes (keys stay on backend; Doppler).
class ZuTtsPaths {
  static const synthesize = '/api/voice/tts/synthesize';
}

/// Licensed isiZulu TTS via Azure zu-ZA Thando/Themba per EXT-01.
class ZuTtsService {
  ZuTtsService({
    required this.baseUrl,
    this.authToken,
    ZuTtsHttpPost? post,
    ZuAzureVoice preferredVoice = ZuAzureVoice.thando,
  })  : _post = post ?? _unimplementedPost,
        _preferredVoice = preferredVoice;

  final String baseUrl;
  final String? authToken;
  final ZuTtsHttpPost _post;
  final ZuAzureVoice _preferredVoice;

  static Future<ZuTtsHttpResponse> _unimplementedPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw StateError('ZuTtsHttpPost not configured');
  }

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  Future<ZuTtsSynthesis> synthesize({
    required String text,
    String language = 'zu',
    ZuAzureVoice? voice,
  }) async {
    final clipped =
        text.length > 500 ? text.substring(0, 500) : text.trim();
    assertZuTtsInput(clipped);

    final primary = voice ?? _preferredVoice;
    final order = <ZuAzureVoice>[primary, primary.alternate()];

    Object? lastFailure;
    for (final v in order) {
      try {
        final bytes = await _synthesizeAzure(clipped, language, v);
        return ZuTtsSynthesis(
          bytes: bytes,
          provider: v.providerId,
          voiceName: v.voiceName,
        );
      } on IntronTtsFailure catch (e) {
        lastFailure = e;
      }
    }
    if (lastFailure is IntronTtsFailure) {
      throw lastFailure;
    }
    throw IntronTtsFailure('audio_unavailable');
  }

  Future<Uint8List> _synthesizeAzure(
    String text,
    String language,
    ZuAzureVoice voice,
  ) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final resp = await _post(
      Uri.parse('$root${ZuTtsPaths.synthesize}'),
      headers: {
        ..._jsonHeaders(),
        'X-Tts-Provider': voice.providerId,
      },
      body: jsonEncode({
        'text': text,
        'language': language,
        'locale': zuTtsLocale,
        'provider': voice.providerId,
        'voice': voice.voiceName,
        'voiceName': voice.voiceName,
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
