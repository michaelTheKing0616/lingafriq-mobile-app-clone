import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../monitoring/sentry_service.dart';
import '../../widgets/pronunciation/visual_pitch_feedback_widget.dart';

/// Pitch Visualization Service
/// Extracts and processes pitch contours for visualization
/// Compares native vs user pitch with error detection
class PitchVisualizationService {
  /// Extract pitch contour from audio data
  /// Uses simple pitch detection algorithm (in production, use librosa/parselmouth)
  Future<List<PitchPoint>> extractPitchContour({
    required List<double> audioSamples,
    required double sampleRate,
    double minPitch = 50.0,
    double maxPitch = 400.0,
  }) async {
    try {
      // Simple autocorrelation-based pitch detection
      // In production, use librosa.pyin or parselmouth
      final pitchPoints = <PitchPoint>[];
      final windowSize = (sampleRate * 0.03).round(); // 30ms windows
      final hopSize = (sampleRate * 0.01).round(); // 10ms hop

      for (int i = 0; i < audioSamples.length - windowSize; i += hopSize) {
        final window = audioSamples.sublist(i, i + windowSize);
        final pitch = _estimatePitch(window, sampleRate, minPitch, maxPitch);
        
        if (pitch > 0) {
          pitchPoints.add(
            PitchPoint(
              time: i / sampleRate,
              pitch: pitch,
              confidence: 0.8, // Simplified - in production, calculate actual confidence
            ),
          );
        }
      }

      return pitchPoints;
    } catch (e, stackTrace) {
      debugPrint('Error extracting pitch contour: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Estimate pitch using autocorrelation
  double _estimatePitch(
    List<double> samples,
    double sampleRate,
    double minPitch,
    double maxPitch,
  ) {
    // Autocorrelation
    final autocorr = <double>[];
    final n = samples.length;
    
    for (int lag = 0; lag < n ~/ 2; lag++) {
      double sum = 0;
      for (int i = 0; i < n - lag; i++) {
        sum += samples[i] * samples[i + lag];
      }
      autocorr.add(sum / (n - lag));
    }

    // Find peak in pitch range
    final minPeriod = (sampleRate / maxPitch).round();
    final maxPeriod = (sampleRate / minPitch).round();
    
    double maxCorr = 0;
    int bestLag = 0;
    
    for (int lag = minPeriod; lag < math.min(maxPeriod, autocorr.length); lag++) {
      if (autocorr[lag] > maxCorr) {
        maxCorr = autocorr[lag];
        bestLag = lag;
      }
    }

    if (bestLag > 0 && maxCorr > 0.3) {
      return sampleRate / bestLag;
    }
    
    return 0; // No pitch detected
  }

  /// Compare native and user pitch contours
  /// Returns error regions and similarity score
  Future<PitchComparisonResult> comparePitchContours({
    required List<PitchPoint> nativePitch,
    required List<PitchPoint> userPitch,
    required List<double> timePoints,
    double errorThreshold = 0.2, // 20% pitch difference
  }) async {
    try {
      final errorRegions = <ErrorRegion>[];
      double totalSimilarity = 0;
      int validComparisons = 0;

      // Align contours by time
      for (int i = 0; i < math.min(nativePitch.length, userPitch.length); i++) {
        final nativePoint = nativePitch[i];
        final userPoint = userPitch[i];
        
        if (nativePoint.time == userPoint.time) {
          final pitchDiff = (nativePoint.pitch - userPoint.pitch).abs() / nativePoint.pitch;
          final similarity = 1.0 - math.min(pitchDiff, 1.0);
          totalSimilarity += similarity;
          validComparisons++;

          // Detect error regions
          if (pitchDiff > errorThreshold) {
            // Check if this is part of an existing error region
            bool addedToRegion = false;
            for (final region in errorRegions) {
              if (nativePoint.time >= region.startTime && 
                  nativePoint.time <= region.endTime) {
                addedToRegion = true;
                break;
              }
            }

            if (!addedToRegion) {
              // Create new error region
              final errorType = _classifyError(nativePoint, userPoint);
              errorRegions.add(
                ErrorRegion(
                  startTime: nativePoint.time,
                  endTime: nativePoint.time + 0.1, // 100ms window
                  type: errorType,
                  message: _generateErrorMessage(errorType, nativePoint, userPoint),
                ),
              );
            }
          }
        }
      }

      final averageSimilarity = validComparisons > 0 
          ? totalSimilarity / validComparisons 
          : 0.0;

      return PitchComparisonResult(
        toneAccuracy: averageSimilarity,
        errorRegions: errorRegions,
        feedback: _generateFeedback(averageSimilarity, errorRegions),
      );
    } catch (e, stackTrace) {
      debugPrint('Error comparing pitch contours: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
      return PitchComparisonResult(
        toneAccuracy: 0.0,
        errorRegions: [],
        feedback: 'Unable to compare pitch contours.',
      );
    }
  }

  String _classifyError(PitchPoint native, PitchPoint user) {
    final diff = user.pitch - native.pitch;
    if (diff > 0) {
      return 'pitch'; // Too high
    } else {
      return 'tone'; // Too low or wrong tone
    }
  }

  String _generateErrorMessage(String type, PitchPoint native, PitchPoint user) {
    final diff = ((user.pitch - native.pitch) / native.pitch * 100).abs();
    if (type == 'pitch') {
      return 'Pitch too high by ${diff.toStringAsFixed(0)}%';
    } else {
      return 'Pitch too low by ${diff.toStringAsFixed(0)}%';
    }
  }

  String _generateFeedback(double accuracy, List<ErrorRegion> errors) {
    if (accuracy >= 0.9) {
      return 'Excellent tone accuracy! Your pitch matches the native speaker very well.';
    } else if (accuracy >= 0.7) {
      return 'Good tone accuracy. Focus on the highlighted areas to improve further.';
    } else if (accuracy >= 0.5) {
      return 'Your tone needs improvement. Pay attention to the pitch contour and try to match the native speaker.';
    } else {
      return 'Significant tone differences detected. Practice the highlighted sections and listen carefully to the native pronunciation.';
    }
  }
}

/// Pitch comparison result
class PitchComparisonResult {
  final double toneAccuracy;
  final List<ErrorRegion> errorRegions;
  final String feedback;

  PitchComparisonResult({
    required this.toneAccuracy,
    required this.errorRegions,
    required this.feedback,
  });
}

