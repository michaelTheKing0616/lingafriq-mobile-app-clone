import 'package:lingafriq/avatars/cast/phoneme_viseme.dart';

/// Drives avatar mouth state from gateway lip-sync payloads (P6-081).
class LipSyncDriver {
  LipSyncDriver();
  LipSyncTrack? _track;
  bool _neutralTalking = true;
  List<RmsSample> _rms = const [];
  VisemeScheduler? _scheduler;
  RmsJawDriver? _rmsOnly;

  static const int maxDriftMs = 80;

  /// JSON shape from `alignments.ts` (`LipSyncAlignmentPayload`).
  void loadPayload(
    Map<String, dynamic> payload, {
    List<RmsSample> rms = const [],
  }) {
    final language = (payload['language_id'] as String?)?.trim() ?? 'default';
    final mode = payload['mode'] as String? ?? 'neutral';
    final phonemeList = payload['phonemes'] as List<dynamic>? ?? const [];

    _rms = rms;
    if (mode != 'viseme' || phonemeList.isEmpty) {
      _neutralTalking = true;
      _track = null;
      _scheduler = VisemeScheduler(languageId: language, phonemes: const []);
      _rmsOnly = RmsJawDriver(samples: rms);
      _scheduler!.logUnalignedIfNeeded();
      return;
    }

    final sidecar = LipSyncTimingSidecar.fromGatewayPayload(payload);
    final phonemes = sidecar.phonemes;

    _neutralTalking = phonemes.isEmpty;
    _scheduler = VisemeScheduler(languageId: language, phonemes: phonemes);
    _rmsOnly = null;
    _track = LipSyncTrack(language: language, phonemes: phonemes, rms: rms);
  }

  void clear() {
    _track = null;
    _neutralTalking = true;
    _scheduler = null;
    _rmsOnly = null;
    _rms = const [];
  }

  LipSyncSample sampleAt(
    Duration position, {
    Duration delta = const Duration(milliseconds: 16),
  }) {
    final track = _track;
    if (track == null) {
      final rmsOnly = _rmsOnly;
      if (rmsOnly != null) {
        final jaw = rmsOnly.advance(position, delta);
        return LipSyncSample(viseme: 'sil', jawOpen: jaw);
      }
      return const LipSyncSample(viseme: 'sil', jawOpen: 0);
    }
    if (_neutralTalking) {
      final rmsOnly = _rmsOnly ?? RmsJawDriver(samples: _rms);
      final jaw = rmsOnly.advance(position, delta);
      return LipSyncSample(viseme: 'sil', jawOpen: jaw);
    }
    return track.at(position, delta: delta);
  }

  /// Returns drift from the active phoneme window (for tests); null when idle.
  int? phonemeDriftMs(Duration position) {
    final track = _track;
    if (track == null || _neutralTalking) return null;
    for (final token in track.phonemes) {
      if (position >= token.start && position < token.end) {
        final posMs = position.inMilliseconds;
        final startMs = token.start.inMilliseconds;
        final endMs = token.end.inMilliseconds;
        return (posMs - startMs).clamp(0, maxDriftMs);
      }
    }
    return null;
  }
}
