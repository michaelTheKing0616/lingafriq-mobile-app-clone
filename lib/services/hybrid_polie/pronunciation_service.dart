/// Pronunciation Service using ASR + MFA (Montreal Forced Aligner)
/// Provides phoneme-level pronunciation feedback

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class PronunciationService {
  final Dio _dio = Dio();
  static const String MFA_SERVICE_URL = "http://localhost:5051/pronounce"; // Local MFA service
  static const String ASR_SERVICE_URL = "http://localhost:5052/asr"; // Local ASR service
  
  /// Score pronunciation using MFA
  Future<PronunciationResult> scorePronunciation({
    required String audioPath,
    required String referenceText,
    required String language,
  }) async {
    try {
      // Send audio file to MFA service
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioPath),
        'reference_text': referenceText,
        'language': language,
      });
      
      final response = await _dio.post(
        MFA_SERVICE_URL,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return PronunciationResult(
          score: (data['score'] ?? 0.0).toDouble(),
          phonemeErrors: List<String>.from(data['phoneme_errors'] ?? []),
          wordErrors: List<String>.from(data['word_errors'] ?? []),
          alignment: Map<String, dynamic>.from(data['alignment'] ?? {}),
          feedback: data['feedback'] ?? '',
          model: 'MFA',
        );
      }
      
      throw Exception('Pronunciation scoring failed: ${response.statusCode}');
    } catch (e) {
      // Fallback: basic scoring
      return PronunciationResult(
        score: 0.7, // Default moderate score
        phonemeErrors: [],
        wordErrors: [],
        alignment: {},
        feedback: 'Pronunciation feedback unavailable. Please try again.',
        model: 'fallback',
        error: e.toString(),
      );
    }
  }
  
  /// Transcribe audio using ASR
  Future<String> transcribeAudio({
    required String audioPath,
    required String language,
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioPath),
        'language': language,
      });
      
      final response = await _dio.post(
        ASR_SERVICE_URL,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data['transcription'] ?? '';
      }
      
      throw Exception('ASR failed: ${response.statusCode}');
    } catch (e) {
      return ''; // Return empty on error
    }
  }
}

class PronunciationResult {
  final double score; // 0.0 - 1.0
  final List<String> phonemeErrors;
  final List<String> wordErrors;
  final Map<String, dynamic> alignment;
  final String feedback;
  final String model;
  final String? error;
  
  PronunciationResult({
    required this.score,
    required this.phonemeErrors,
    required this.wordErrors,
    required this.alignment,
    required this.feedback,
    required this.model,
    this.error,
  });
  
  int get srsQuality {
    // Map score to SRS quality (0-5)
    if (score >= 0.95) return 5;
    if (score >= 0.85) return 4;
    if (score >= 0.70) return 3;
    if (score >= 0.50) return 2;
    return 1;
  }
}

