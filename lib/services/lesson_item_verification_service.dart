// Lesson Item Verification Service
// Handles native speaker verification of lesson items

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import '../providers/dio_provider.dart';

class LessonItemVerificationService {
  final Dio _dio;

  LessonItemVerificationService(this._dio);

  /// Submit verification for a lesson item.
  ///
  /// [confidenceScore] is sent only when the caller measured one.
  /// This method does not fill a score in.
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
      throw Exception(TransportErrorPolicy.toUserMessage(e));
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
      throw Exception(TransportErrorPolicy.toUserMessage(e));
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
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    }
  }

  /// Pending items, or an empty queue. A transport failure does not keep
  /// an older list: the caller drops whatever it had.
  Future<VerificationQueue> loadPending({
    String? languageCode,
    int limit = 20,
  }) async {
    try {
      final Map<String, dynamic> queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (languageCode != null) {
        queryParams['language_code'] = languageCode;
      }
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/lesson-items/pending-verification',
        queryParameters: queryParams,
      );
      final Object? body = response.data;
      if (body is Map && body['success'] == true) {
        final Object? rows = body['data'];
        if (rows is List && rows.isNotEmpty) {
          final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
          for (final Object? row in rows) {
            if (row is Map) {
              items.add(Map<String, dynamic>.from(row));
            }
          }
          if (items.isNotEmpty) return VerificationQueue.ready(items);
        }
      }
      return const VerificationQueue.empty();
    } on DioException catch (e) {
      if (TransportErrorPolicy.isNetworkIssue(e)) {
        return const VerificationQueue.offline();
      }
      return const VerificationQueue.error();
    } catch (_) {
      return const VerificationQueue.error();
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
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    }
  }
}

/// What [LessonItemVerificationService.loadPending] returned.
enum VerificationQueueStatus { ready, empty, error, offline }

/// Pending lesson-item rows. [ready] is the only status that carries rows.
class VerificationQueue {
  const VerificationQueue._(this.status, this.items);

  const VerificationQueue.ready(List<Map<String, dynamic>> items)
    : this._(VerificationQueueStatus.ready, items);

  const VerificationQueue.empty()
    : this._(VerificationQueueStatus.empty, const <Map<String, dynamic>>[]);

  const VerificationQueue.error()
    : this._(VerificationQueueStatus.error, const <Map<String, dynamic>>[]);

  const VerificationQueue.offline()
    : this._(VerificationQueueStatus.offline, const <Map<String, dynamic>>[]);

  final VerificationQueueStatus status;
  final List<Map<String, dynamic>> items;
}

/// Provider that uses the app-wide authenticated Dio client.
final lessonItemVerificationServiceProvider = Provider<LessonItemVerificationService>((ref) {
  return LessonItemVerificationService(ref.read(client));
});
