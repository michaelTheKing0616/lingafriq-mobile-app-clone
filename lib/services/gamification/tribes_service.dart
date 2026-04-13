import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';

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
        ApiContract.url(ApiContract.tribes.list),
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

  /// Get tribe details
  Future<Map<String, dynamic>> getTribe(String tribeId) async {
    try {
      final response = await _dio
          .get(ApiContract.url(ApiContract.tribes.details(tribeId)));
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Join a tribe
  Future<void> joinTribe(String tribeId) async {
    try {
      await _dio.post(ApiContract.url(ApiContract.tribes.join(tribeId)));
    } catch (e) {
      rethrow;
    }
  }

  /// Leave a tribe
  Future<void> leaveTribe(String tribeId) async {
    try {
      await _dio.post(ApiContract.url(ApiContract.tribes.leave(tribeId)));
    } catch (e) {
      rethrow;
    }
  }

  /// Get tribe activity
  Future<List<dynamic>> getTribeActivity(String tribeId) async {
    try {
      final response = await _dio
          .get(ApiContract.url(ApiContract.tribes.activity(tribeId)));
      return response.data['activities'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Deposit XP to tribe
  Future<void> depositXP(String tribeId, int amount) async {
    try {
      await _dio.post(
        ApiContract.url(ApiContract.tribes.depositXp(tribeId)),
        data: {'amount': amount},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get all available tribes. Set [includeClassrooms] to list classroom tribes (Stitch lobby).
  Future<List<Map<String, dynamic>>> getAllTribes({
    String? languageTag,
    bool includeClassrooms = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (languageTag != null) {
        queryParams['language_tag'] = languageTag;
      }
      if (includeClassrooms) {
        queryParams['include_classrooms'] = 'true';
      }

      final response = await _dio.get(
        ApiContract.url(ApiContract.tribes.list),
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      if (response.data['success'] == true && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's tribes (tribes the user is a member of)
  Future<List<Map<String, dynamic>>> getUserTribes(String userId) async {
    try {
      // Preferred: fetch memberships for the authenticated user (server derives user id from JWT).
      final response = await _dio.get(ApiContract.url(ApiContract.tribes.me));
      if (response.data is Map &&
          (response.data['success'] == true || response.statusCode == 200) &&
          response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      // Backward compatible: if server returns a raw list.
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get classroom progress for a tribe
  Future<Map<String, dynamic>> getClassroomProgress(String tribeId) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.tribes.classroomProgress(tribeId)),
      );
      return response.data is Map ? Map<String, dynamic>.from(response.data) : {};
    } catch (e) {
      rethrow;
    }
  }
}

