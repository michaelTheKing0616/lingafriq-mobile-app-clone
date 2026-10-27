import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Visual + light haptic drum hits from a normalised contour (P8-920 AC1).
class DrumTimbreSynth {
  DrumTimbreSynth({Random? random}) : _rng = random ?? Random();

  final Random _rng;
  int _playToken = 0;

  Future<void> playContour(
    List<double> contour, {
    Duration step = const Duration(milliseconds: 280),
    bool reducedMotion = false,
  }) async {
    if (contour.isEmpty) return;
    final token = ++_playToken;
    if (reducedMotion) {
      await _hitOnce(contour.first);
      return;
    }
    for (var i = 0; i < contour.length; i++) {
      if (token != _playToken) return;
      await _hitOnce(contour[i]);
      if (i < contour.length - 1) {
        await Future<void>.delayed(step);
      }
    }
  }

  void cancel() => _playToken++;

  Future<void> _hitOnce(double height) async {
    if (height >= 0.66) {
      await HapticFeedback.heavyImpact();
    } else if (height >= 0.33) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
    if (!kIsWeb) {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
