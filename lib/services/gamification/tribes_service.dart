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

  /// Get tribe details
  Future<Map<String, dynamic>> getTribe(String tribeId) async {
    try {
      final response = await _dio.get('${Api.baseurl}api/tribes/$tribeId');
      return response.data;
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

  /// Get all available tribes
  Future<List<Map<String, dynamic>>> getAllTribes({String? languageTag}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (languageTag != null) {
        queryParams['language_tag'] = languageTag;
      }
      
      final response = await _dio.get(
        '${Api.baseurl}api/tribes',
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
      // Get all tribes and filter by membership
      // Note: In production, this should be a dedicated endpoint like /api/tribes/user/:userId
      // For now, we'll get all tribes and the client will need to check membership separately
      // This is a placeholder - backend should provide /api/tribes/user/:userId endpoint
      final allTribes = await getAllTribes();
      // Without a dedicated endpoint, we can't efficiently get user's tribes
      // Return empty list - this should be implemented on backend
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

