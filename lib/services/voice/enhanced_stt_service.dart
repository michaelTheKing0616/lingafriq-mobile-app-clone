/// Enhanced Speech-to-Text Service
/// Extends VoiceApiService with accent recognition and dialect support
/// 
/// Features:
/// - Language-specific models
/// - Accent recognition
/// - Dialect support
/// - Confidence scoring
/// - Word-level timestamps
/// - Falls back to basic STT when enhanced features unavailable

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:dio/dio.dart';

/// STT Recognition Result
class STTRecognitionResult {
  final String text;
  final double confidence;
  final String? language;
  final String? dialect;
  final List<WordTiming>? wordTimings;
  final Map<String, dynamic>? metadata;

  STTRecognitionResult({
    required this.text,
    required this.confidence,
    this.language,
    this.dialect,
    this.wordTimings,
    this.metadata,
  });

  factory STTRecognitionResult.fromJson(Map<String, dynamic> json) {
    return STTRecognitionResult(
      text: json['text'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      language: json['language'],
      dialect: json['dialect'],
      wordTimings: json['word_timings'] != null
          ? (json['word_timings'] as List)
              .map((w) => WordTiming.fromJson(w))
              .toList()
          : null,
      metadata: json['metadata'],
    );
  }

  factory STTRecognitionResult.fromBasicTranscription(Map<String, dynamic> basicResult) {
    return STTRecognitionResult(
      text: basicResult['text'] ?? '',
      confidence: (basicResult['confidence'] ?? 0.5).toDouble(),
      language: basicResult['language'],
      metadata: basicResult,
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

/// Enhanced Speech-to-Text Service
/// Extends basic STT with accent recognition and dialect support
/// Falls back to basic STT API call when enhanced endpoint unavailable
class EnhancedSTTService {
  final Dio _dio;

  EnhancedSTTService(this._dio);

  /// Transcribe audio with enhanced features
  /// Falls back to basic STT if enhanced endpoint unavailable
  Future<STTRecognitionResult> transcribe({
    required Uint8List audioData,
    required String languageCode,
    String? dialect,
    bool enableWordTimings = false,
    bool enableAccentDetection = true,
    bool allowFallback = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          audioData,
          filename: 'audio.wav',
        ),
        'language_code': languageCode,
        if (dialect != null) 'dialect': dialect,
        'enable_word_timings': enableWordTimings.toString(),
        'enable_accent_detection': enableAccentDetection.toString(),
      });

      final response = await _dio.post(
        ApiContract.url(ApiContract.voice.sttTranscribeEnhanced),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        return STTRecognitionResult.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('STT transcription failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Enhanced STT error: $e');
      
      if (allowFallback) {
        return await _fallbackToBasicSTT(audioData, languageCode);
      }
      
      rethrow;
    }
  }

  /// Fallback to basic STT when enhanced features unavailable
  /// Uses direct API call (same endpoint as VoiceApiService.transcribeAudioBytes)
  Future<STTRecognitionResult> _fallbackToBasicSTT(Uint8List audioData, String languageCode) async {
    try {
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          audioData,
          filename: 'audio.wav',
        ),
        'language': languageCode,
      });

      final response = await _dio.post(
        ApiContract.url(ApiContract.voice.sttTranscribe),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final basicResult = response.data as Map<String, dynamic>;
        return STTRecognitionResult.fromBasicTranscription(basicResult);
      } else {
        throw Exception('Basic STT failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fallback STT error: $e');
      rethrow;
    }
  }

  /// Transcribe from file path (uses VoiceApiService internally)
  Future<STTRecognitionResult> transcribeFromFile({
    required String audioPath,
    required String languageCode,
    String? dialect,
    bool enableWordTimings = false,
    bool enableAccentDetection = true,
  }) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found: $audioPath');
    }

    final audioData = await file.readAsBytes();
    return transcribe(
      audioData: audioData,
      languageCode: languageCode,
      dialect: dialect,
      enableWordTimings: enableWordTimings,
      enableAccentDetection: enableAccentDetection,
    );
  }

  /// Detect language and accent from audio
  Future<Map<String, dynamic>> detectLanguageAndAccent({
    required Uint8List audioData,
    List<String>? candidateLanguages,
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          audioData,
          filename: 'audio.wav',
        ),
        if (candidateLanguages != null && candidateLanguages.isNotEmpty)
          'candidate_languages': candidateLanguages.join(','),
      });

      final response = await _dio.post(
        ApiContract.url(ApiContract.voice.detectLanguage),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Language detection failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Language detection error: $e');
      rethrow;
    }
  }

  /// Get supported dialects for a language
  Future<List<String>> getSupportedDialects(String languageCode) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.voice.dialects(languageCode)),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<String>.from(data['dialects'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error getting dialects: $e');
      return [];
    }
  }

  /// Batch transcribe multiple audio files
  Future<List<STTRecognitionResult>> transcribeBatch({
    required List<Uint8List> audioFiles,
    required String languageCode,
    String? dialect,
  }) async {
    final results = <STTRecognitionResult>[];

    for (final audioData in audioFiles) {
      try {
        final result = await transcribe(
          audioData: audioData,
          languageCode: languageCode,
          dialect: dialect,
        );
        results.add(result);
      } catch (e) {
        debugPrint('Error transcribing audio in batch: $e');
        // Continue with next item
      }
    }

    return results;
  }
}

