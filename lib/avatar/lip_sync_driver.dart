import 'package:lingafriq/avatars/cast/phoneme_viseme.dart';
import 'package:lingafriq/avatars/lip_sync_engine.dart';

/// Drives avatar mouth state from gateway lip-sync payloads (P6-081).
class LipSyncDriver {
  LipSyncDriver({LipSyncEngine? engine}) : _engine = engine ?? LipSyncEngine();

  final LipSyncEngine _engine;
  LipSyncTrack? _track;
  bool _neutralTalking = true;
  List<RmsSample> _rms = const [];

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
      return;
    }

    final sidecar = LipSyncTimingSidecar.fromGatewayPayload(payload);
    final phonemes = sidecar.phonemes;

    _neutralTalking = phonemes.isEmpty;
    _track = _engine.track(
      language: language,
      phonemes: phonemes,
      rms: rms,
    );
  }

  void clear() {
    _track = null;
    _neutralTalking = true;
  }

  LipSyncSample sampleAt(
    Duration position, {
    Duration delta = const Duration(milliseconds: 16),
  }) {
    final track = _track;
    if (track == null) {
      return const LipSyncSample(viseme: 'sil', jawOpen: 0);
    }
    if (_neutralTalking) {
      final level = _rmsAt(position);
      final jaw = (level * 0.15).clamp(0.0, 0.2);
      return LipSyncSample(viseme: 'sil', jawOpen: jaw);
    }
    return track.at(position, delta: delta);
  }

  double _rmsAt(Duration position) {
    if (_rms.isEmpty) return 0;
    var chosen = _rms.first.level;
    for (final sample in _rms) {
      if (sample.at > position) break;
      chosen = sample.level;
    }
    return chosen.clamp(0, 1);
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
