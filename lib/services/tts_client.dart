import 'dart:convert';

/// Typed client helpers for gateway TTS/translate unavailable responses (P1-040).
enum TtsClientUnavailableKind {
  audio,
  translation,
}

class TtsClientUnavailable implements Exception {
  const TtsClientUnavailable(this.code, {this.retryable = false});

  final String code;
  final bool retryable;

  @override
  String toString() => 'TtsClientUnavailable($code)';
}

/// User-visible playback state when licensed audio cannot be produced.
enum TtsClientSurfaceState {
  ready,
  unavailable,
  voiceComing,
}

TtsClientSurfaceState ttsClientSurfaceForHttp({
  required int statusCode,
  required String body,
  String language = '',
}) {
  if (statusCode == 503) {
    final code = parseUnavailableCode(body);
    if (code == 'audio_unavailable') {
      return TtsClientSurfaceState.unavailable;
    }
    if (code == 'translation_unavailable') {
      return TtsClientSurfaceState.unavailable;
    }
    if (code == 'voice_coming' ||
        (language.toLowerCase() == 'xhosa' && code == null)) {
      return TtsClientSurfaceState.voiceComing;
    }
    return TtsClientSurfaceState.unavailable;
  }
  if (statusCode >= 200 && statusCode < 300) {
    return TtsClientSurfaceState.ready;
  }
  return TtsClientSurfaceState.unavailable;
}

String? parseUnavailableCode(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final code = decoded['code'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}

TtsClientUnavailable? ttsClientUnavailableFromResponse({
  required int statusCode,
  required String body,
}) {
  if (statusCode != 503) {
    return null;
  }
  final code = parseUnavailableCode(body);
  if (code == 'audio_unavailable') {
    return const TtsClientUnavailable('audio_unavailable', retryable: true);
  }
  if (code == 'translation_unavailable') {
    return const TtsClientUnavailable('translation_unavailable', retryable: false);
  }
  if (code != null) {
    return TtsClientUnavailable(code, retryable: false);
  }
  return const TtsClientUnavailable('audio_unavailable', retryable: true);
}
