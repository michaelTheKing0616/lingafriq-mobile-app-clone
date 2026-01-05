/// Pronunciation Analysis Service
/// Analyzes pronunciation with detailed feedback
/// Extends VoiceApiService.analyzePronunciation() with tone analysis and LessonItem integration
/// 
/// Features:
/// - Phoneme-level analysis
/// - Tone accuracy for tonal languages
/// - Fluency metrics
/// - Improvement suggestions
/// - Integration with VoiceApiService for core analysis

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../providers/dio_provider.dart';
import '../../utils/api.dart';
import '../../core/network/api_client_with_recovery.dart';
import '../../models/lesson_item_model.dart';
import 'tone_error_detection_service.dart';
import 'pitch_visualization_service.dart';
import 'voice_api_service.dart';

/// Pronunciation analysis result
class PronunciationAnalysisResult {
  final double overallScore;
  final double phonemeAccuracy;
  final double toneAccuracy;
  final double fluencyScore;
  final String feedback;
  final List<String> suggestions;
  final List<PhonemeError> phonemeErrors;
  final ToneErrorResult? toneErrors;
  final Map<String, dynamic>? metadata;

  PronunciationAnalysisResult({
    required this.overallScore,
    required this.phonemeAccuracy,
    required this.toneAccuracy,
    required this.fluencyScore,
    required this.feedback,
    required this.suggestions,
    required this.phonemeErrors,
    this.toneErrors,
    this.metadata,
  });
}

/// Phoneme error
class PhonemeError {
  final String phoneme;
  final String expected;
  final String actual;
  final double startTime;
  final double endTime;
  final double severity;

  PhonemeError({
    required this.phoneme,
    required this.expected,
    required this.actual,
    required this.startTime,
    required this.endTime,
    required this.severity,
  });
}

/// Pronunciation Analysis Service
/// Wraps VoiceApiService.analyzePronunciation() with additional tone analysis
class PronunciationAnalysisService {
  final Dio _dio;
  final ToneErrorDetectionService _toneErrorService = ToneErrorDetectionService();
  final PitchVisualizationService _pitchService = PitchVisualizationService();

  PronunciationAnalysisService(this._dio);

  /// Convert VoiceApiService PronunciationScore to PronunciationAnalysisResult
  PronunciationAnalysisResult _convertFromPronunciationScore(
    Map<String, dynamic> scoreData,
    ToneErrorResult? toneErrors,
  ) {
    final score = _parsePronunciationScore(scoreData);
    return PronunciationAnalysisResult(
      overallScore: score['overall'] ?? 0.0,
      phonemeAccuracy: score['phoneme_accuracy'] ?? 0.0,
      toneAccuracy: toneErrors?.overallAccuracy ?? (score['tone_accuracy'] ?? 0.0),
      fluencyScore: score['fluency'] ?? 0.0,
      feedback: score['feedback_text'] ?? '',
      suggestions: List<String>.from(score['improvement_tips'] ?? []),
      phonemeErrors: (score['problem_segments'] as List?)?.map((segment) {
        return PhonemeError(
          phoneme: segment['phoneme'] ?? '',
          expected: segment['expected'] ?? '',
          actual: segment['actual'] ?? '',
          startTime: (segment['start_time'] ?? 0.0).toDouble(),
          endTime: (segment['end_time'] ?? 0.0).toDouble(),
          severity: (segment['severity'] ?? 0.5).toDouble(),
        );
      }).toList() ?? [],
      toneErrors: toneErrors,
      metadata: {
        'confidence': score['confidence'],
        'grade': _calculateGrade(score['overall'] ?? 0.0),
        'passed': (score['overall'] ?? 0.0) >= 0.6,
      },
    );
  }

  Map<String, dynamic> _parsePronunciationScore(Map<String, dynamic> data) {
    return {
      'overall': (data['overall'] ?? data['overall_score'] ?? 0.0).toDouble(),
      'phoneme_accuracy': (data['phoneme_accuracy'] ?? data['phonemeAccuracy'] ?? 0.0).toDouble(),
      'tone_accuracy': (data['tone_accuracy'] ?? data['toneAccuracy'] ?? 0.0).toDouble(),
      'fluency': (data['fluency'] ?? data['fluency_score'] ?? 0.0).toDouble(),
      'feedback_text': data['feedback_text'] ?? data['feedback'] ?? '',
      'improvement_tips': data['improvement_tips'] ?? data['suggestions'] ?? [],
      'problem_segments': data['problem_segments'] ?? data['phoneme_errors'] ?? [],
      'confidence': (data['confidence'] ?? 0.5).toDouble(),
    };
  }

  String _calculateGrade(double score) {
    if (score >= 0.9) return 'A+';
    if (score >= 0.8) return 'A';
    if (score >= 0.7) return 'B';
    if (score >= 0.6) return 'C';
    if (score >= 0.5) return 'D';
    return 'F';
  }

  /// Analyze pronunciation
  /// Uses VoiceApiService for core analysis, adds tone analysis for tonal languages
  Future<PronunciationAnalysisResult> analyzePronunciation({
    required Uint8List audioData,
    required int sampleRate,
    required LessonItem lessonItem,
    bool enableToneAnalysis = true,
    bool enablePhonemeAnalysis = true,
    bool useVoiceApiService = true,
  }) async {
    try {
      final tempFile = await _saveTempAudio(audioData);
      
      try {
        Map<String, dynamic>? coreScoreData;
        
        if (useVoiceApiService) {
          // Use direct API call (same as VoiceApiService does internally)
          coreScoreData = await _analyzeWithDirectAPI(
            audioPath: tempFile.path,
            expectedText: lessonItem.text,
            language: lessonItem.languageCode,
          );
        }

        ToneErrorResult? toneErrors;
        if (enableToneAnalysis && lessonItem.tonePattern != null && lessonItem.tonePattern!.isNotEmpty) {
          final audioSamples = _convertToAudioSamples(audioData);
          final pitchContour = await _pitchService.extractPitchContour(
            audioSamples: audioSamples,
            sampleRate: sampleRate.toDouble(),
          );

          toneErrors = await _toneErrorService.detectToneErrors(
            audioData: audioData,
            sampleRate: sampleRate,
            lessonItem: lessonItem,
            userPitchContour: pitchContour,
          );
        }

        if (coreScoreData != null) {
          return _convertFromPronunciationScore(coreScoreData, toneErrors);
        }

        // Fallback: use enhanced endpoint
        return await _analyzeWithEnhancedEndpointFallback(
          audioData: audioData,
          lessonItem: lessonItem,
          toneErrors: toneErrors,
          enablePhonemeAnalysis: enablePhonemeAnalysis,
        );
      } finally {
        await tempFile.delete();
      }
    } catch (e) {
      debugPrint('Pronunciation analysis error: $e');
      
      return PronunciationAnalysisResult(
        overallScore: 0.0,
        phonemeAccuracy: 0.0,
        toneAccuracy: 0.0,
        fluencyScore: 0.0,
        feedback: 'Analysis unavailable. Please try again.',
        suggestions: ['Check your internet connection', 'Ensure audio quality is good'],
        phonemeErrors: [],
      );
    }
  }

  Future<File> _saveTempAudio(Uint8List audioData) async {
    final tempDir = await Directory.systemTemp.createTemp('pronunciation_');
    final tempFile = File('${tempDir.path}/audio.wav');
    await tempFile.writeAsBytes(audioData);
    return tempFile;
  }

  Future<Map<String, dynamic>?> _analyzeWithDirectAPI({
    required String audioPath,
    required String expectedText,
    required String language,
  }) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) return null;

      final formData = FormData.fromMap({
        'learner_audio': await MultipartFile.fromFile(audioPath, filename: 'audio.wav'),
        'expected_text': expectedText,
        'language': language,
      });

      final response = await _dio.post(
        '${Api.baseurl}api/voice/pronunciation/analyze',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Direct API analysis error: $e');
    }
    return null;
  }

  Future<PronunciationAnalysisResult> _analyzeWithEnhancedEndpointFallback({
    required Uint8List audioData,
    required LessonItem lessonItem,
    ToneErrorResult? toneErrors,
    bool enablePhonemeAnalysis = true,
  }) async {
    final client = ApiClientWithRecovery(_dio);

    final formData = FormData.fromBytes(audioData, filename: 'pronunciation.wav');
    formData.fields.addAll([
      MapEntry('lesson_item_id', lessonItem.id),
      MapEntry('text', lessonItem.text),
      MapEntry('language_code', lessonItem.languageCode),
      MapEntry('ipa', lessonItem.ipa ?? ''),
      MapEntry('enable_phoneme_analysis', enablePhonemeAnalysis.toString()),
    ]);

    if (lessonItem.tonePattern != null) {
      formData.fields.add(MapEntry('tone_pattern', lessonItem.tonePattern!.join(',')));
    }

    final response = await client.post<Map<String, dynamic>>(
      '${Api.baseurl}api/voice/pronunciation/analyze',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>;
      return PronunciationAnalysisResult(
        overallScore: (data['overall_score'] ?? 0.0).toDouble(),
        phonemeAccuracy: (data['phoneme_accuracy'] ?? 0.0).toDouble(),
        toneAccuracy: toneErrors?.overallAccuracy ?? (data['tone_accuracy'] ?? 0.0).toDouble(),
        fluencyScore: (data['fluency_score'] ?? 0.0).toDouble(),
        feedback: data['feedback'] ?? '',
        suggestions: List<String>.from(data['suggestions'] ?? []),
        phonemeErrors: (data['phoneme_errors'] as List?)
            ?.map((e) => PhonemeError(
                  phoneme: e['phoneme'] ?? '',
                  expected: e['expected'] ?? '',
                  actual: e['actual'] ?? '',
                  startTime: (e['start_time'] ?? 0.0).toDouble(),
                  endTime: (e['end_time'] ?? 0.0).toDouble(),
                  severity: (e['severity'] ?? 0.0).toDouble(),
                ))
            .toList() ?? [],
        toneErrors: toneErrors,
        metadata: data['metadata'],
      );
    }

    throw Exception('Failed to analyze pronunciation');
  }

  /// Get pronunciation history for a lesson item
  Future<List<PronunciationAnalysisResult>> getPronunciationHistory({
    required String userId,
    required String lessonItemId,
    int? limit,
  }) async {
    try {
      final client = ApiClientWithRecovery(_dio);
      final response = await client.get<Map<String, dynamic>>(
        '${Api.baseurl}api/voice/pronunciation/history',
        queryParameters: {
          'user_id': userId,
          'lesson_item_id': lessonItemId,
          if (limit != null) 'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as List;
        return data.map((item) {
          final itemData = item as Map<String, dynamic>;
          return PronunciationAnalysisResult(
            overallScore: (itemData['overall_score'] ?? 0.0).toDouble(),
            phonemeAccuracy: (itemData['phoneme_accuracy'] ?? 0.0).toDouble(),
            toneAccuracy: (itemData['tone_accuracy'] ?? 0.0).toDouble(),
            fluencyScore: (itemData['fluency_score'] ?? 0.0).toDouble(),
            feedback: itemData['feedback'] ?? '',
            suggestions: List<String>.from(itemData['suggestions'] ?? []),
            phonemeErrors: [],
            metadata: itemData,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching pronunciation history: $e');
      return [];
    }
  }

  List<double> _convertToAudioSamples(Uint8List audioData) {
    final samples = <double>[];
    for (int i = 0; i < audioData.length - 1; i += 2) {
      final sample = (audioData[i] | (audioData[i + 1] << 8));
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      samples.add(signedSample / 32768.0);
    }
    return samples;
  }
}

