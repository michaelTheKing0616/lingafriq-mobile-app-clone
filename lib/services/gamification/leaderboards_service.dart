import 'package:dio/dio.dart';
import 'package:lingafriq/utils/api.dart';

/// Page size for leaderboard API requests (backend supports offset pagination).
const int kLeaderboardPageSize = 100;

class LeaderboardsService {
  final Dio _dio;

  LeaderboardsService(this._dio);

  Map<String, dynamic> _queryParams({
    required String period,
    required int limit,
    required int offset,
  }) =>
      {
        'period': period,
        'limit': limit,
        'offset': offset,
      };

  /// Get global leaderboard (tries api/leaderboards/global then gamification league).
  Future<Map<String, dynamic>> getGlobalLeaderboard({
    String period = 'weekly',
    int limit = kLeaderboardPageSize,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        'api/leaderboards/global',
        queryParameters: _queryParams(
          period: period,
          limit: limit,
          offset: offset,
        ),
      );
      return response.data is Map
          ? response.data as Map<String, dynamic>
          : {'entries': <dynamic>[]};
    } catch (_) {
      try {
        final fallback = await _dio.get(
          Api.leagueLeaderboard,
          queryParameters: {'limit': limit},
        );
        return fallback.data is Map
            ? fallback.data as Map<String, dynamic>
            : {'entries': <dynamic>[]};
      } catch (__) {
        rethrow;
      }
    }
  }

  /// Get tribe leaderboard
  Future<Map<String, dynamic>> getTribeLeaderboard(
    String tribeId, {
    String period = 'season',
    int limit = kLeaderboardPageSize,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        'api/leaderboards/tribe/$tribeId',
        queryParameters: _queryParams(
          period: period,
          limit: limit,
          offset: offset,
        ),
      );
      return response.data is Map
          ? response.data as Map<String, dynamic>
          : {'entries': <dynamic>[]};
    } catch (e) {
      rethrow;
    }
  }

  /// Get village leaderboard
  Future<Map<String, dynamic>> getVillageLeaderboard(
    String lang, {
    String period = 'monthly',
    int limit = kLeaderboardPageSize,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        'api/leaderboards/village/$lang',
        queryParameters: _queryParams(
          period: period,
          limit: limit,
          offset: offset,
        ),
      );
      return response.data is Map
          ? response.data as Map<String, dynamic>
          : {'entries': <dynamic>[]};
    } catch (e) {
      rethrow;
    }
  }

  /// Get user ranks across all leaderboards
  Future<Map<String, dynamic>> getUserRanks(String userId) async {
    try {
      final response = await _dio.get('api/leaderboards/user/$userId/ranks');
      return response.data is Map ? response.data as Map<String, dynamic> : {};
    } catch (e) {
      rethrow;
    }
  }
}
