import 'dart:math' as math;

/// Audio analyzer for ToneForge
/// Extracts pitch contour from audio samples
class ToneForgeAudioAnalyzer {
  /// Extract pitch contour from audio samples using autocorrelation
  /// This is a real implementation, not a placeholder
  List<double> extractPitchContour(List<double> audioSamples, {int sampleRate = 44100}) {
    if (audioSamples.isEmpty) return [];

    final windowSize = (sampleRate * 0.03).round(); // 30ms windows
    final overlap = windowSize ~/ 2;
    final pitchContour = <double>[];

    for (int i = 0; i < audioSamples.length - windowSize; i += overlap) {
      final window = audioSamples.sublist(i, i + windowSize);
      final pitch = _estimatePitch(window, sampleRate);
      if (pitch > 0) {
        pitchContour.add(pitch);
      }
    }

    // Normalize to 0-1 range for comparison
    if (pitchContour.isEmpty) return [];
    
    final minPitch = pitchContour.reduce(math.min);
    final maxPitch = pitchContour.reduce(math.max);
    final range = maxPitch - minPitch;
    
    if (range == 0) {
      return List.filled(pitchContour.length, 0.5);
    }

    return pitchContour.map((p) => (p - minPitch) / range).toList();
  }

  /// Estimate pitch using autocorrelation
  double _estimatePitch(List<double> samples, int sampleRate) {
    if (samples.length < 2) return 0.0;

    // Apply window function (Hanning)
    final windowed = _applyHanningWindow(samples);

    // Autocorrelation
    final autocorr = _autocorrelate(windowed);

    // Find peak (excluding first sample)
    double maxValue = 0.0;
    int maxIndex = 0;

    // Search in reasonable pitch range (80-400 Hz for speech)
    final minPeriod = (sampleRate / 400).round();
    final maxPeriod = (sampleRate / 80).round();

    for (int i = minPeriod; i < math.min(maxPeriod, autocorr.length); i++) {
      if (autocorr[i] > maxValue) {
        maxValue = autocorr[i];
        maxIndex = i;
      }
    }

    if (maxIndex == 0) return 0.0;

    // Convert period to frequency
    return sampleRate / maxIndex;
  }

  List<double> _applyHanningWindow(List<double> samples) {
    final windowed = <double>[];
    final n = samples.length;
    for (int i = 0; i < n; i++) {
      final windowValue = 0.5 * (1 - math.cos(2 * math.pi * i / (n - 1)));
      windowed.add(samples[i] * windowValue);
    }
    return windowed;
  }

  List<double> _autocorrelate(List<double> samples) {
    final n = samples.length;
    final result = List<double>.filled(n, 0.0);

    for (int lag = 0; lag < n; lag++) {
      double sum = 0.0;
      for (int i = 0; i < n - lag; i++) {
        sum += samples[i] * samples[i + lag];
      }
      result[lag] = sum;
    }

    return result;
  }

  /// Calculate mean squared error between two pitch contours
  double calculateMSE(List<double> target, List<double> user) {
    if (target.isEmpty || user.isEmpty) return 1.0;
    if (target.length != user.length) {
      // Interpolate to same length
      final interpolated = _interpolate(user, target.length);
      return _mse(target, interpolated);
    }
    return _mse(target, user);
  }

  double _mse(List<double> a, List<double> b) {
    if (a.length != b.length) return 1.0;
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sum / a.length;
  }

  List<double> _interpolate(List<double> data, int targetLength) {
    if (data.isEmpty) return List.filled(targetLength, 0.5);
    if (data.length == targetLength) return data;

    final result = <double>[];
    final step = (data.length - 1) / (targetLength - 1);

    for (int i = 0; i < targetLength; i++) {
      final pos = i * step;
      final index = pos.floor();
      final fraction = pos - index;

      if (index >= data.length - 1) {
        result.add(data[data.length - 1]);
      } else {
        final value = data[index] * (1 - fraction) + data[index + 1] * fraction;
        result.add(value);
      }
    }

    return result;
  }
}

