import 'package:dio/dio.dart';
import 'package:lingafriq/utils/api.dart';

class CompetitionsService {
  final Dio _dio;

  CompetitionsService(this._dio);

  /// List competitions
  Future<List<dynamic>> getCompetitions({
    String? status,
    String? type,
  }) async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}api/competitions',
        queryParameters: {
          if (status != null) 'status': status,
          if (type != null) 'type': type,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get competition details
  Future<Map<String, dynamic>> getCompetition(String competitionId) async {
    try {
      final response = await _dio.get('${Api.baseurl}api/competitions/$competitionId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get competition results
  Future<Map<String, dynamic>> getCompetitionResults(String competitionId, {int limit = 50}) async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}api/competitions/$competitionId/results',
        queryParameters: {'limit': limit},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

