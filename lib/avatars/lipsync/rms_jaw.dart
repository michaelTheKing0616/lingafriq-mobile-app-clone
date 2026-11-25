import 'dart:math' as math;

import 'package:lingafriq/avatars/lipsync/timing_sidecar.dart';

const Duration rmsJawAttack = Duration(milliseconds: 30);
const Duration rmsJawRelease = Duration(milliseconds: 80);
const double rmsJawGate = 0.08;

/// Smoothed jaw openness (0..1) from RMS samples on the audio clock.
class RmsJawDriver {
  RmsJawDriver({
    List<RmsSample> samples = const [],
    this.attack = rmsJawAttack,
    this.release = rmsJawRelease,
    this.gate = rmsJawGate,
  }) : _samples = List<RmsSample>.unmodifiable(samples);

  final List<RmsSample> _samples;
  final Duration attack;
  final Duration release;
  final double gate;

  double _smoothed = 0;

  List<RmsSample> get samples => _samples;

  double levelAt(Duration position) {
    if (_samples.isEmpty) return 0;
    var chosen = _samples.first.level;
    for (final sample in _samples) {
      if (sample.at > position) break;
      chosen = sample.level;
    }
    return chosen.clamp(0, 1);
  }

  /// Returns smoothed RMS jaw only (no viseme openness mixed in).
  double advance(Duration position, Duration delta) {
    final raw = levelAt(position);
    final target = raw >= gate ? raw : 0;
    final tau = target >= _smoothed ? attack : release;
    final dt = delta.inMicroseconds / 1000000;
    final time = tau.inMicroseconds / 1000000;
    final alpha = time <= 0 ? 1.0 : 1 - math.exp(-dt / time);
    _smoothed = (_smoothed + (target - _smoothed) * alpha).clamp(0, 1);
    return _smoothed;
  }

  void reset() => _smoothed = 0;
}

/// jawOpen = viseme pose openness plus smoothed RMS, capped at 1.
double combineJawOpen({
  required double visemeOpenness,
  required double smoothedRms,
  double rmsBlend = 0.35,
}) {
  return (visemeOpenness + smoothedRms * rmsBlend).clamp(0, 1);
}
