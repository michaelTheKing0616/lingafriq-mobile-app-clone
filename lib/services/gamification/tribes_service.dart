import 'package:dio/dio.dart';
import 'package:lingafriq/utils/api.dart';

class TribesService {
  final Dio _dio;

  TribesService(this._dio);

  /// Create a new tribe
  Future<Map<String, dynamic>> createTribe({
    required String name,
    required String languageTag,
    String? description,
    String? emblemUrl,
  }) async {
    try {
      final response = await _dio.post(
        '${Api.baseurl}api/tribes',
        data: {
          'name': name,
          'language_tag': languageTag,
          'description': description,
          'emblem_url': emblemUrl,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all non-classroom tribes from backend (for dynamic catalog)
  Future<List<Map<String, dynamic>>> getTribes({String? languageTag}) async {
    try {
      final queryParams = <String, dynamic>{
        if (languageTag != null && languageTag.isNotEmpty)
          'language_tag': languageTag,
      };
      final response = await _dio.get(
        '${Api.baseurl}api/tribes',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new classroom tribe (teacher-owned class)
  Future<Map<String, dynamic>> createClassroom({
    required String name,
    required String languageTag,
    String? description,
    String? emblemUrl,
    bool allowStudentPosts = true,
  }) async {
    try {
      final response = await _dio.post(
        '${Api.baseurl}api/tribes/classrooms',
        data: {
          'name': name,
          'language_tag': languageTag,
          'description': description,
          'emblem_url': emblemUrl,
          'allow_student_posts': allowStudentPosts,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get tribe details
  Future<Map<String, dynamic>> getTribe(String tribeId) async {
    try {
      final response = await _dio.get('${Api.baseurl}api/tribes/$tribeId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// List classroom tribes owned by the current user (teacher)
  Future<List<Map<String, dynamic>>> getMyClassrooms() async {
    try {
      final response =
          await _dio.get('${Api.baseurl}api/tribes/classrooms/mine');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return List<Map<String, dynamic>>.from(data['classrooms'] ?? []);
    } catch (e) {
      rethrow;
    }
  }

  /// Join a classroom by join code
  Future<Map<String, dynamic>> joinClassroomByCode(String code) async {
    try {
      final response = await _dio.post(
        '${Api.baseurl}api/tribes/classrooms/join',
        data: {'code': code},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Join a tribe
  Future<void> joinTribe(String tribeId) async {
    try {
      await _dio.post('${Api.baseurl}api/tribes/$tribeId/join');
    } catch (e) {
      rethrow;
    }
  }

  /// Leave a tribe
  Future<void> leaveTribe(String tribeId) async {
    try {
      await _dio.post('${Api.baseurl}api/tribes/$tribeId/leave');
    } catch (e) {
      rethrow;
    }
  }

  /// Get tribe activity
  Future<List<dynamic>> getTribeActivity(String tribeId) async {
    try {
      final response = await _dio.get('${Api.baseurl}api/tribes/$tribeId/activity');
      return response.data['activities'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get classroom progress dashboard for a classroom tribe
  Future<Map<String, dynamic>> getClassroomProgress(String tribeId) async {
    try {
      final response =
          await _dio.get('${Api.baseurl}api/tribes/$tribeId/progress');
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// Create a simple classroom post (announcement or activity prompt)
  Future<Map<String, dynamic>> createClassPost({
    required String tribeId,
    required String text,
    String kind = 'announcement',
  }) async {
    try {
      final response = await _dio.post(
        '${Api.baseurl}api/tribes/$tribeId/posts',
        data: {
          'text': text,
          'kind': kind,
        },
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// Deposit XP to tribe
  Future<void> depositXP(String tribeId, int amount) async {
    try {
      await _dio.post(
        '${Api.baseurl}api/tribes/$tribeId/deposit-xp',
        data: {'amount': amount},
      );
    } catch (e) {
      rethrow;
    }
  }
}

