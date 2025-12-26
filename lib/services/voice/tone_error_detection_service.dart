/// Tone Error Detection Service
/// Detects tone errors in tonal languages (Yoruba, Igbo, Twi) and generates targeted drills
/// 
/// Features:
/// - Pitch contour extraction and analysis
/// - Tone pattern comparison
/// - Syllable-level error detection
/// - Automatic minimal-pair drill generation
/// - Visual feedback with pitch visualization

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'pitch_visualization_service.dart';
import '../../models/lesson_item_model.dart';
import '../../widgets/pronunciation/visual_pitch_feedback_widget.dart';

/// Tone error detection result
class ToneErrorResult {
  final bool hasError;
  final double overallAccuracy;
  final List<ToneError> errors;
  final List<PitchPoint> userPitchContour;
  final List<PitchPoint> expectedPitchContour;
  final ToneDrill? generatedDrill;

  ToneErrorResult({
    required this.hasError,
    required this.overallAccuracy,
    required this.errors,
    required this.userPitchContour,
    required this.expectedPitchContour,
    this.generatedDrill,
  });
}

/// Individual tone error
class ToneError {
  final int syllableIndex;
  final String expectedTone;
  final String actualTone;
  final double startTime;
  final double endTime;
  final double severity; // 0.0 - 1.0
  final String syllableText;

  ToneError({
    required this.syllableIndex,
    required this.expectedTone,
    required this.actualTone,
    required this.startTime,
    required this.endTime,
    required this.severity,
    required this.syllableText,
  });
}

/// Generated tone drill
class ToneDrill {
  final String type; // 'minimal_pair', 'repetition', 'contrast'
  final List<DrillItem> items;
  final String focusSyllable;
  final List<String> targetTones;

  ToneDrill({
    required this.type,
    required this.items,
    required this.focusSyllable,
    required this.targetTones,
  });
}

/// Drill item (minimal pair or contrast)
class DrillItem {
  final String text;
  final String ipa;
  final List<String> tonePattern;
  final String translation;
  final String? audioUrl;

  DrillItem({
    required this.text,
    required this.ipa,
    required this.tonePattern,
    required this.translation,
    this.audioUrl,
  });
}

/// Tone Error Detection Service
class ToneErrorDetectionService {
  final PitchVisualizationService _pitchService = PitchVisualizationService();

  /// Tone mapping for different languages
  static const Map<String, Map<String, double>> tonePitchRanges = {
    'yo': { // Yoruba
      'low': 100.0,   // Hz
      'mid': 150.0,
      'high': 200.0,
    },
    'ig': { // Igbo
      'low': 100.0,
      'high': 200.0,
    },
    'tw': { // Twi
      'low': 100.0,
      'mid': 150.0,
      'high': 200.0,
    },
  };

  /// Detect tone errors in user audio
  Future<ToneErrorResult> detectToneErrors({
    required Uint8List audioData,
    required int sampleRate,
    required LessonItem lessonItem,
    List<PitchPoint>? userPitchContour,
  }) async {
    if (lessonItem.tonePattern == null || lessonItem.tonePattern!.isEmpty) {
      return ToneErrorResult(
        hasError: false,
        overallAccuracy: 1.0,
        errors: [],
        userPitchContour: userPitchContour ?? [],
        expectedPitchContour: [],
      );
    }

    // Extract pitch contour if not provided
    List<PitchPoint> pitchContour = userPitchContour ?? [];
    if (pitchContour.isEmpty) {
      // Convert Uint8List to List<double> for pitch extraction
      final audioSamples = _convertToAudioSamples(audioData);
      pitchContour = await _pitchService.extractPitchContour(
        audioSamples: audioSamples,
        sampleRate: sampleRate.toDouble(),
      );
    }

    // Generate expected pitch contour from tone pattern
    final expectedContour = _generateExpectedPitchContour(
      lessonItem.text,
      lessonItem.tonePattern!,
      lessonItem.languageCode,
      pitchContour.length,
    );

    // Segment text into syllables
    final syllables = _segmentIntoSyllables(lessonItem.text, lessonItem.languageCode);
    
    // Compare pitch contours syllable by syllable
    final errors = <ToneError>[];
    double totalAccuracy = 0.0;

    for (int i = 0; i < syllables.length && i < lessonItem.tonePattern!.length; i++) {
      final expectedTone = lessonItem.tonePattern![i];
      final syllable = syllables[i];
      
      // Get pitch for this syllable's time range
      final syllablePitch = _getSyllablePitch(
        pitchContour,
        i,
        syllables.length,
        pitchContour.length,
      );

      // Determine actual tone from pitch
      final actualTone = _pitchToTone(syllablePitch, lessonItem.languageCode);

      // Calculate accuracy
      final isCorrect = actualTone == expectedTone;
      final accuracy = isCorrect ? 1.0 : _calculateToneSimilarity(expectedTone, actualTone, lessonItem.languageCode);
      totalAccuracy += accuracy;

      if (!isCorrect) {
        final severity = 1.0 - accuracy;
        errors.add(ToneError(
          syllableIndex: i,
          expectedTone: expectedTone,
          actualTone: actualTone,
          startTime: (i / syllables.length) * _estimateDuration(pitchContour),
          endTime: ((i + 1) / syllables.length) * _estimateDuration(pitchContour),
          severity: severity,
          syllableText: syllable,
        ));
      }
    }

    final overallAccuracy = syllables.isEmpty ? 1.0 : totalAccuracy / syllables.length;

    // Generate drill if errors found
    ToneDrill? drill;
    if (errors.isNotEmpty) {
      drill = _generateToneDrill(lessonItem, errors);
    }

    return ToneErrorResult(
      hasError: errors.isNotEmpty,
      overallAccuracy: overallAccuracy,
      errors: errors,
      userPitchContour: pitchContour,
      expectedPitchContour: expectedContour,
      generatedDrill: drill,
    );
  }

  /// Generate expected pitch contour from tone pattern
  List<PitchPoint> _generateExpectedPitchContour(
    String text,
    List<String> tonePattern,
    String languageCode,
    int contourLength,
  ) {
    final ranges = tonePitchRanges[languageCode] ?? tonePitchRanges['yo']!;
    final contour = <PitchPoint>[];
    final syllables = _segmentIntoSyllables(text, languageCode);

    for (int i = 0; i < contourLength; i++) {
      final syllableIndex = (i / contourLength * syllables.length).floor();
      if (syllableIndex < tonePattern.length) {
        final tone = tonePattern[syllableIndex];
        final pitch = ranges[tone] ?? ranges['mid']!;
        
        contour.add(PitchPoint(
          time: (i / contourLength) * 2.0, // Estimate 2 seconds
          pitch: pitch,
          confidence: 1.0,
        ));
      }
    }

    return contour;
  }

  /// Segment text into syllables
  List<String> _segmentIntoSyllables(String text, String languageCode) {
    // Simple syllable segmentation (in production, use proper linguistic tools)
    final syllables = <String>[];
    final chars = text.split('');
    
    String currentSyllable = '';
    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      currentSyllable += char;
      
      // Simple heuristic: vowel indicates syllable boundary
      if (_isVowel(char) && i < chars.length - 1 && !_isVowel(chars[i + 1])) {
        syllables.add(currentSyllable.trim());
        currentSyllable = '';
      }
    }
    
    if (currentSyllable.isNotEmpty) {
      syllables.add(currentSyllable.trim());
    }

    return syllables.isEmpty ? [text] : syllables;
  }

  bool _isVowel(String char) {
    const vowels = 'aeiouáàéèíìóòúùẹẹ́ẹ̀ọọ́ọ̀';
    return vowels.contains(char.toLowerCase());
  }

  /// Get average pitch for a syllable
  double _getSyllablePitch(
    List<PitchPoint> contour,
    int syllableIndex,
    int totalSyllables,
    int contourLength,
  ) {
    final startIndex = (syllableIndex / totalSyllables * contourLength).floor();
    final endIndex = ((syllableIndex + 1) / totalSyllables * contourLength).floor();
    
    if (startIndex >= contour.length) return 0.0;
    final end = endIndex > contour.length ? contour.length : endIndex;
    
    double sum = 0.0;
    int count = 0;
    for (int i = startIndex; i < end; i++) {
      sum += contour[i].pitch;
      count++;
    }
    
    return count > 0 ? sum / count : 0.0;
  }

  /// Convert pitch to tone
  String _pitchToTone(double pitch, String languageCode) {
    final ranges = tonePitchRanges[languageCode] ?? tonePitchRanges['yo']!;
    
    // Find closest tone
    double minDiff = double.infinity;
    String closestTone = 'mid';
    
    ranges.forEach((tone, tonePitch) {
      final diff = (pitch - tonePitch).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestTone = tone;
      }
    });
    
    return closestTone;
  }

  /// Calculate similarity between tones
  double _calculateToneSimilarity(String expected, String actual, String languageCode) {
    if (expected == actual) return 1.0;
    
    final ranges = tonePitchRanges[languageCode] ?? tonePitchRanges['yo']!;
    final expectedPitch = ranges[expected] ?? 150.0;
    final actualPitch = ranges[actual] ?? 150.0;
    
    final diff = (expectedPitch - actualPitch).abs();
    final maxDiff = ranges.values.reduce((a, b) => a > b ? a : b) - ranges.values.reduce((a, b) => a < b ? a : b);
    
    return 1.0 - (diff / maxDiff).clamp(0.0, 1.0);
  }

  /// Estimate audio duration from pitch contour
  double _estimateDuration(List<PitchPoint> contour) {
    if (contour.isEmpty) return 1.0;
    return contour.last.time;
  }

  /// Generate tone drill based on errors
  ToneDrill _generateToneDrill(LessonItem lessonItem, List<ToneError> errors) {
    // Focus on the most severe error
    errors.sort((a, b) => b.severity.compareTo(a.severity));
    final primaryError = errors.first;
    
    final syllables = _segmentIntoSyllables(lessonItem.text, lessonItem.languageCode);
    final focusSyllable = primaryError.syllableIndex < syllables.length
        ? syllables[primaryError.syllableIndex]
        : '';

    // Generate minimal pairs
    final drillItems = <DrillItem>[];
    
    // Add the correct version
    drillItems.add(DrillItem(
      text: _applyToneToSyllable(focusSyllable, primaryError.expectedTone, lessonItem.languageCode),
      ipa: lessonItem.ipa ?? '',
      tonePattern: [primaryError.expectedTone],
      translation: 'Correct tone',
    ));

    // Add the incorrect version (what user said)
    drillItems.add(DrillItem(
      text: _applyToneToSyllable(focusSyllable, primaryError.actualTone, lessonItem.languageCode),
      ipa: lessonItem.ipa ?? '',
      tonePattern: [primaryError.actualTone],
      translation: 'Your pronunciation',
    ));

    // Add contrast pairs if available
    final allTones = tonePitchRanges[lessonItem.languageCode]?.keys.toList() ?? ['low', 'mid', 'high'];
    for (final tone in allTones) {
      if (tone != primaryError.expectedTone && tone != primaryError.actualTone) {
        drillItems.add(DrillItem(
          text: _applyToneToSyllable(focusSyllable, tone, lessonItem.languageCode),
          ipa: lessonItem.ipa ?? '',
          tonePattern: [tone],
          translation: 'Contrast: $tone tone',
        ));
      }
    }

    return ToneDrill(
      type: 'minimal_pair',
      items: drillItems,
      focusSyllable: focusSyllable,
      targetTones: [primaryError.expectedTone],
    );
  }

  /// Apply tone diacritics to syllable (simplified - in production use proper linguistic tools)
  String _applyToneToSyllable(String syllable, String tone, String languageCode) {
    // This is a simplified version - in production, use proper tone marking
    // For now, return the syllable with a note about the tone
    return syllable; // Placeholder - would need proper tone diacritic application
  }

  /// Convert Uint8List audio data to List<double> samples
  List<double> _convertToAudioSamples(Uint8List audioData) {
    // Convert 16-bit PCM to double samples
    final samples = <double>[];
    for (int i = 0; i < audioData.length - 1; i += 2) {
      final sample = (audioData[i] | (audioData[i + 1] << 8));
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      samples.add(signedSample / 32768.0);
    }
    return samples;
  }
}

