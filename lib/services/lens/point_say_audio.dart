/// Point-and-Say playback: human recording first, then licensed server TTS.
library;

import 'dart:typed_data';

import 'package:lingafriq/services/voice/tts_service.dart';

enum PointSayPlaybackKind {
  playingHuman,
  playingLicensed,
  voiceComing,
  audioUnavailable,
}

class PointSayDictionaryHit {
  const PointSayDictionaryHit({
    required this.word,
    required this.language,
    this.humanAudioUrl,
  });

  final String word;
  final String language;
  final String? humanAudioUrl;

  bool get hasHumanAudio =>
      humanAudioUrl != null && humanAudioUrl!.trim().isNotEmpty;
}

class PointSayPlaybackPlan {
  const PointSayPlaybackPlan({
    required this.kind,
    this.humanAudioUrl,
    this.licensedAudioBytes,
    this.unavailableCode,
    this.licensedTtsRequested = false,
  });

  final PointSayPlaybackKind kind;
  final String? humanAudioUrl;
  final Uint8List? licensedAudioBytes;
  final String? unavailableCode;

  /// True when [TtsService.synthesize] was invoked (human audio did not win).
  final bool licensedTtsRequested;
}

/// Resolves how a Point-and-Say hit should be played. Never uses device TTS.
class PointSayAudio {
  PointSayAudio({required TtsService ttsService}) : _tts = ttsService;

  final TtsService _tts;

  /// Semantics label for the play control (a11y).
  static String playButtonLabel(String word) => 'Play $word';

  Future<PointSayPlaybackPlan> resolve(PointSayDictionaryHit hit) async {
    if (hit.hasHumanAudio) {
      return PointSayPlaybackPlan(
        kind: PointSayPlaybackKind.playingHuman,
        humanAudioUrl: hit.humanAudioUrl!.trim(),
      );
    }

    try {
      final audio = await _tts.synthesize(
        language: hit.language,
        text: hit.word,
      );
      return PointSayPlaybackPlan(
        kind: PointSayPlaybackKind.playingLicensed,
        licensedAudioBytes: audio,
        licensedTtsRequested: true,
      );
    } on LicensedVoiceUnavailable catch (e) {
      final kind = e.code == 'voice_coming'
          ? PointSayPlaybackKind.voiceComing
          : PointSayPlaybackKind.audioUnavailable;
      return PointSayPlaybackPlan(
        kind: kind,
        unavailableCode: e.code,
        licensedTtsRequested: true,
      );
    }
  }
}
