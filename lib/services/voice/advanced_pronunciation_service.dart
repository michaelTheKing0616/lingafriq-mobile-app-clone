/// Advanced Pronunciation Service with Wav2Vec2 Integration
/// World-class pronunciation assessment with real-time feedback and phoneme-level analysis
/// 
/// Features:
/// - Wav2Vec2-based pronunciation scoring
/// - Real-time feedback during recording
/// - Phoneme-level accuracy analysis
/// - Tone/intonation analysis for tonal languages
/// - Fluency metrics
/// - Detailed improvement suggestions
/// 
/// Uses state-of-the-art ML models for African languages (December 2025)

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/dio_provider.dart';
import '../../utils/api.dart';

/// Advanced Pronunciation Analysis Result
class AdvancedPronunciationResult {
  /// Overall pronunciation score (0.0 - 1.0)
  final double overallScore;
  
  /// Phoneme-level accuracy (0.0 - 1.0)
  final double phonemeAccuracy;
  
  /// Tone/intonation accuracy for tonal languages (0.0 - 1.0)
  final double toneAccuracy;
  
  /// Fluency score (pace, rhythm, naturalness)
  final double fluencyScore;
  
  /// System confidence in the analysis (0.0 - 1.0)
  final double confidence;
  
  /// Detailed feedback text
  final String feedback;
  
  /// Improvement suggestions
  final List<String> suggestions;
  
  /// Phoneme-level errors with timestamps
  final List<PhonemeError> phonemeErrors;
  
  /// Word-level errors
  final List<WordError> wordErrors;
  
  /// Pitch contour data for visualization
  final List<PitchPoint>? pitchContour;
  
  /// Word timing information
  final List<WordTiming>? wordTimings;
  
  /// Model used for analysis
  final String model;
  
  /// Processing time in milliseconds
  final int processingTimeMs;
  
  /// Real-time feedback during recording
  final List<RealTimeFeedback>? realTimeFeedback;

  AdvancedPronunciationResult({
    required this.overallScore,
    required this.phonemeAccuracy,
    required this.toneAccuracy,
    required this.fluencyScore,
    required this.confidence,
    required this.feedback,
    required this.suggestions,
    required this.phonemeErrors,
    required this.wordErrors,
    this.pitchContour,
    this.wordTimings,
    required this.model,
    required this.processingTimeMs,
    this.realTimeFeedback,
  });

  factory AdvancedPronunciationResult.fromJson(Map<String, dynamic> json) {
    return AdvancedPronunciationResult(
      overallScore: (json['overall_score'] ?? json['score'] ?? 0.0).toDouble(),
      phonemeAccuracy: (json['phoneme_accuracy'] ?? 0.0).toDouble(),
      toneAccuracy: (json['tone_accuracy'] ?? 0.0).toDouble(),
      fluencyScore: (json['fluency_score'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      feedback: json['feedback'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      phonemeErrors: (json['phoneme_errors'] as List?)
          ?.map((e) => PhonemeError.fromJson(e))
          .toList() ?? [],
      wordErrors: (json['word_errors'] as List?)
          ?.map((e) => WordError.fromJson(e))
          .toList() ?? [],
      pitchContour: json['pitch_contour'] != null
          ? (json['pitch_contour'] as List)
              .map((p) => PitchPoint.fromJson(p))
              .toList()
          : null,
      wordTimings: json['word_timings'] != null
          ? (json['word_timings'] as List)
              .map((w) => WordTiming.fromJson(w))
              .toList()
          : null,
      model: json['model'] ?? 'wav2vec2',
      processingTimeMs: json['processing_time_ms'] ?? 0,
      realTimeFeedback: json['real_time_feedback'] != null
          ? (json['real_time_feedback'] as List)
              .map((f) => RealTimeFeedback.fromJson(f))
              .toList()
          : null,
    );
  }

  /// Get grade (A+ to F)
  String get grade {
    if (overallScore >= 0.95) return 'A+';
    if (overallScore >= 0.85) return 'A';
    if (overallScore >= 0.75) return 'B+';
    if (overallScore >= 0.65) return 'B';
    if (overallScore >= 0.55) return 'C';
    if (overallScore >= 0.45) return 'D';
    return 'F';
  }

  /// Check if pronunciation is acceptable
  bool get isAcceptable => overallScore >= 0.7;

  /// Check if pronunciation is excellent
  bool get isExcellent => overallScore >= 0.9;

  /// Get score breakdown for UI
  Map<String, double> get scoreBreakdown => {
    'Overall': overallScore,
    'Pronunciation': phonemeAccuracy,
    'Tone': toneAccuracy,
    'Fluency': fluencyScore,
  };
}

/// Phoneme-level error information
class PhonemeError {
  final String phoneme;
  final String expectedPhoneme;
  final double startTime;
  final double endTime;
  final double severity; // 0.0 - 1.0
  final String suggestion;

  PhonemeError({
    required this.phoneme,
    required this.expectedPhoneme,
    required this.startTime,
    required this.endTime,
    required this.severity,
    required this.suggestion,
  });

  factory PhonemeError.fromJson(Map<String, dynamic> json) {
    return PhonemeError(
      phoneme: json['phoneme'] ?? '',
      expectedPhoneme: json['expected_phoneme'] ?? '',
      startTime: (json['start_time'] ?? 0.0).toDouble(),
      endTime: (json['end_time'] ?? 0.0).toDouble(),
      severity: (json['severity'] ?? 0.5).toDouble(),
      suggestion: json['suggestion'] ?? '',
    );
  }
}

/// Word-level error information
class WordError {
  final String word;
  final String expectedWord;
  final double startTime;
  final double endTime;
  final List<String> phonemeErrors;
  final String suggestion;

  WordError({
    required this.word,
    required this.expectedWord,
    required this.startTime,
    required this.endTime,
    required this.phonemeErrors,
    required this.suggestion,
  });

  factory WordError.fromJson(Map<String, dynamic> json) {
    return WordError(
      word: json['word'] ?? '',
      expectedWord: json['expected_word'] ?? '',
      startTime: (json['start_time'] ?? 0.0).toDouble(),
      endTime: (json['end_time'] ?? 0.0).toDouble(),
      phonemeErrors: List<String>.from(json['phoneme_errors'] ?? []),
      suggestion: json['suggestion'] ?? '',
    );
  }
}

/// Pitch point for contour visualization
class PitchPoint {
  final double time;
  final double pitch; // Hz
  final double confidence;

  PitchPoint({
    required this.time,
    required this.pitch,
    required this.confidence,
  });

  factory PitchPoint.fromJson(Map<String, dynamic> json) {
    return PitchPoint(
      time: (json['time'] ?? 0.0).toDouble(),
      pitch: (json['pitch'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

/// Word timing information
class WordTiming {
  final String word;
  final double startTime;
  final double endTime;
  final double confidence;

  WordTiming({
    required this.word,
    required this.startTime,
    required this.endTime,
    required this.confidence,
  });

  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      word: json['word'] ?? '',
      startTime: (json['start_time'] ?? 0.0).toDouble(),
      endTime: (json['end_time'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

/// Real-time feedback during recording
class RealTimeFeedback {
  final double timestamp;
  final String type; // 'pronunciation', 'tone', 'fluency', 'volume'
  final String message;
  final double severity; // 0.0 - 1.0

  RealTimeFeedback({
    required this.timestamp,
    required this.type,
    required this.message,
    required this.severity,
  });

  factory RealTimeFeedback.fromJson(Map<String, dynamic> json) {
    return RealTimeFeedback(
      timestamp: (json['timestamp'] ?? 0.0).toDouble(),
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      severity: (json['severity'] ?? 0.5).toDouble(),
    );
  }
}

/// Advanced Pronunciation Service Provider
final advancedPronunciationServiceProvider = Provider<AdvancedPronunciationService>((ref) {
  return AdvancedPronunciationService(ref);
});

/// Advanced Pronunciation Service
/// 
/// Provides world-class pronunciation assessment using:
/// - Wav2Vec2 for phoneme-level analysis
/// - Real-time feedback during recording
/// - Advanced tone analysis for tonal languages
/// - Fluency metrics
/// - Detailed improvement suggestions
class AdvancedPronunciationService {
  final Ref _ref;
  final Dio _dio;

  AdvancedPronunciationService(this._ref) : _dio = _ref.read(client);

  /// Analyze pronunciation with advanced ML models
  /// 
  /// [audioPath] - Path to recorded audio file
  /// [expectedText] - Expected text to compare against
  /// [language] - Language code (e.g., 'yoruba', 'swahili')
  /// [enableRealTime] - Enable real-time feedback (requires streaming)
  /// [includePhonemeDetails] - Include detailed phoneme-level analysis
  /// [includeToneAnalysis] - Include tone/intonation analysis
  /// [includeFluencyMetrics] - Include fluency metrics
  Future<AdvancedPronunciationResult> analyzePronunciation({
    required String audioPath,
    required String expectedText,
    required String language,
    bool enableRealTime = false,
    bool includePhonemeDetails = true,
    bool includeToneAnalysis = true,
    bool includeFluencyMetrics = true,
  }) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioPath');
      }

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioPath,
          filename: 'pronunciation_audio.wav',
        ),
        'expected_text': expectedText,
        'language': language,
        'enable_real_time': enableRealTime,
        'include_phoneme_details': includePhonemeDetails,
        'include_tone_analysis': includeToneAnalysis,
        'include_fluency_metrics': includeFluencyMetrics,
        'model': 'wav2vec2', // Use Wav2Vec2 model
        'version': '2.0', // API version
      });

      final response = await _dio.post(
        '${Api.baseurl}api/v1/pronunciation/advanced/analyze',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return AdvancedPronunciationResult.fromJson(data);
      }

      throw Exception('Pronunciation analysis failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('Advanced pronunciation analysis error: $e');
      // Return fallback result with error indication
      return AdvancedPronunciationResult(
        overallScore: 0.0,
        phonemeAccuracy: 0.0,
        toneAccuracy: 0.0,
        fluencyScore: 0.0,
        confidence: 0.0,
        feedback: 'Unable to analyze pronunciation. Please check your connection and try again.',
        suggestions: ['Check your internet connection', 'Ensure audio quality is good'],
        phonemeErrors: [],
        wordErrors: [],
        model: 'fallback',
        processingTimeMs: 0,
      );
    }
  }

  /// Analyze pronunciation from audio bytes
  Future<AdvancedPronunciationResult> analyzePronunciationFromBytes({
    required Uint8List audioBytes,
    required String expectedText,
    required String language,
    bool includePhonemeDetails = true,
    bool includeToneAnalysis = true,
    bool includeFluencyMetrics = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          audioBytes,
          filename: 'pronunciation_audio.wav',
        ),
        'expected_text': expectedText,
        'language': language,
        'include_phoneme_details': includePhonemeDetails,
        'include_tone_analysis': includeToneAnalysis,
        'include_fluency_metrics': includeFluencyMetrics,
        'model': 'wav2vec2',
        'version': '2.0',
      });

      final response = await _dio.post(
        '${Api.baseurl}api/v1/pronunciation/advanced/analyze',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return AdvancedPronunciationResult.fromJson(data);
      }

      throw Exception('Pronunciation analysis failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('Advanced pronunciation analysis error: $e');
      return AdvancedPronunciationResult(
        overallScore: 0.0,
        phonemeAccuracy: 0.0,
        toneAccuracy: 0.0,
        fluencyScore: 0.0,
        confidence: 0.0,
        feedback: 'Unable to analyze pronunciation. Please check your connection and try again.',
        suggestions: ['Check your internet connection', 'Ensure audio quality is good'],
        phonemeErrors: [],
        wordErrors: [],
        model: 'fallback',
        processingTimeMs: 0,
      );
    }
  }

  /// Get real-time pronunciation feedback during recording
  /// 
  /// This streams audio chunks and provides immediate feedback
  Stream<RealTimeFeedback> getRealTimeFeedback({
    required Stream<Uint8List> audioStream,
    required String expectedText,
    required String language,
  }) async* {
    // Implementation would stream audio chunks to backend
    // Backend would process and return real-time feedback
    // For now, return a placeholder that would be implemented with WebSocket/SSE
    
    yield RealTimeFeedback(
      timestamp: 0.0,
      type: 'info',
      message: 'Real-time feedback requires WebSocket connection',
      severity: 0.0,
    );
  }

  /// Quick pronunciation check (faster, less detailed)
  Future<AdvancedPronunciationResult> quickCheck({
    required String audioPath,
    required String expectedText,
    required String language,
  }) async {
    return analyzePronunciation(
      audioPath: audioPath,
      expectedText: expectedText,
      language: language,
      includePhonemeDetails: false,
      includeToneAnalysis: false,
      includeFluencyMetrics: false,
    );
  }

  /// Batch analyze multiple pronunciations
  Future<List<AdvancedPronunciationResult>> batchAnalyze({
    required List<Map<String, dynamic>> audioData, // [{audioPath, expectedText, language}, ...]
  }) async {
    final results = <AdvancedPronunciationResult>[];
    
    for (final data in audioData) {
      try {
        final result = await analyzePronunciation(
          audioPath: data['audioPath'] as String,
          expectedText: data['expectedText'] as String,
          language: data['language'] as String,
        );
        results.add(result);
      } catch (e) {
        debugPrint('Batch analysis error for ${data['audioPath']}: $e');
        // Continue with other items
      }
    }
    
    return results;
  }

  /// Get pronunciation statistics for a user
  Future<Map<String, dynamic>> getPronunciationStats({
    required String userId,
    required String language,
  }) async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}api/v1/pronunciation/stats/$userId/$language',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }

      return {};
    } catch (e) {
      debugPrint('Get pronunciation stats error: $e');
      return {};
    }
  }

  /// Get supported languages for advanced pronunciation
  Future<List<String>> getSupportedLanguages() async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}api/v1/pronunciation/languages',
      );

      if (response.statusCode == 200) {
        return List<String>.from(response.data['languages'] ?? []);
      }

      // Fallback to default supported languages
      return [
        'yoruba',
        'swahili',
        'hausa',
        'igbo',
        'zulu',
        'xhosa',
        'amharic',
        'twi',
        'afrikaans',
        'pidgin',
        'wolof',
        'somali',
        'english',
      ];
    } catch (e) {
      debugPrint('Get supported languages error: $e');
      return [
        'yoruba',
        'swahili',
        'hausa',
        'igbo',
        'english',
      ];
    }
  }
}

