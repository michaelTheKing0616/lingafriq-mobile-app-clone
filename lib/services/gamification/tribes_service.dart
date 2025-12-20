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
}

