import 'dart:math' as math;

import 'package:lingafriq/avatars/lipsync/phoneme_viseme_map.dart';
import 'package:lingafriq/avatars/lipsync/timing_sidecar.dart';

export 'package:lingafriq/avatars/lipsync/phoneme_viseme_map.dart';
export 'package:lingafriq/avatars/lipsync/timing_sidecar.dart'
    show AlignedPhoneme, LipSyncTimingSidecar, LipSyncSample, RmsSample;

const Map<String, double> visemeOpenness = visemeOpennessByWire;

const Duration lipSyncAttack = Duration(milliseconds: 30);
const Duration lipSyncRelease = Duration(milliseconds: 80);
const double rmsGate = 0.08;

/// Audio-clock lip sync. [at] is the playback position, not a letter index.
class LipSyncTrack {
  LipSyncTrack({
    required this.language,
    required List<AlignedPhoneme> phonemes,
    List<RmsSample> rms = const [],
  }) : phonemes = List<AlignedPhoneme>.unmodifiable(phonemes),
       rms = List<RmsSample>.unmodifiable(rms);

  final String language;
  final List<AlignedPhoneme> phonemes;
  final List<RmsSample> rms;

  double _jaw = 0;

  LipSyncSample at(
    Duration position, {
    Duration delta = const Duration(milliseconds: 16),
  }) {
    final raw = _rmsAt(position);
    final phoneme = _phonemeAt(position);
    final mapped =
        phoneme == null ? null : visemeWireForPhoneme(language, phoneme);
    final String viseme;
    final double target;
    if (phonemes.isEmpty) {
      viseme = raw >= rmsGate ? 'aa' : 'sil';
      target = _smooth(raw, delta);
    } else {
      viseme = mapped ?? 'sil';
      final openness = visemeOpenness[viseme] ?? 0;
      target = _smooth((raw * openness).clamp(0, 1), delta);
    }
    return LipSyncSample(viseme: viseme, jawOpen: target);
  }

  String? _phonemeAt(Duration position) {
    for (final token in phonemes) {
      if (position >= token.start && position < token.end) return token.phoneme;
    }
    return null;
  }

  double _rmsAt(Duration position) {
    if (rms.isEmpty) return 0;
    var chosen = rms.first.level;
    for (final sample in rms) {
      if (sample.at > position) break;
      chosen = sample.level;
    }
    return chosen.clamp(0, 1);
  }

  double _smooth(double target, Duration delta) {
    final tau = target >= _jaw ? lipSyncAttack : lipSyncRelease;
    final dt = delta.inMicroseconds / 1000000;
    final time = tau.inMicroseconds / 1000000;
    final alpha = time <= 0 ? 1.0 : 1 - math.exp(-dt / time);
    _jaw = (_jaw + (target - _jaw) * alpha).clamp(0, 1);
    return _jaw;
  }
}
