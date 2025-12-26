/// Lesson Item Verification Service
/// Handles native speaker verification of lesson items

import 'package:dio/dio.dart';
import '../providers/dio_provider.dart';

class LessonItemVerificationService {
  final Dio _dio;

  LessonItemVerificationService() : _dio = DioProvider.instance;

  /// Submit verification for a lesson item
  Future<Map<String, dynamic>> submitVerification({
    required String itemId,
    required String status, // 'approved', 'rejected', 'needs_revision'
    bool? toneCorrect,
    bool? pronunciationCorrect,
    bool? translationAccurate,
    bool? culturalAppropriate,
    String? comments,
    Map<String, dynamic>? corrections,
    double? confidenceScore,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/lesson-items/$itemId/verify',
        data: {
          'status': status,
          if (toneCorrect != null) 'tone_correct': toneCorrect,
          if (pronunciationCorrect != null) 'pronunciation_correct': pronunciationCorrect,
          if (translationAccurate != null) 'translation_accurate': translationAccurate,
          if (culturalAppropriate != null) 'cultural_appropriate': culturalAppropriate,
          if (comments != null && comments.isNotEmpty) 'comments': comments,
          if (corrections != null) 'corrections': corrections,
          if (confidenceScore != null) 'confidence_score': confidenceScore,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to submit verification: ${e.message}');
    }
  }

  /// Get verification status for a lesson item
  Future<Map<String, dynamic>> getVerifications(String itemId) async {
    try {
      final response = await _dio.get(
        '/api/v1/lesson-items/$itemId/verifications',
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch verifications: ${e.message}');
    }
  }

  /// Get items pending verification for user's language
  Future<List<Map<String, dynamic>>> getPendingVerification({
    String? languageCode,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (languageCode != null) {
        queryParams['language_code'] = languageCode;
      }

      final response = await _dio.get(
        '/api/v1/lesson-items/pending-verification',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to fetch pending verifications: ${e.message}');
    }
  }

  /// Apply corrections to a lesson item (admin only)
  Future<Map<String, dynamic>> applyCorrections(String itemId) async {
    try {
      final response = await _dio.post(
        '/api/v1/lesson-items/$itemId/apply-corrections',
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to apply corrections: ${e.message}');
    }
  }
}

