import 'package:dio/dio.dart';
import 'package:lingafriq/utils/api.dart';

class LeaderboardsService {
  final Dio _dio;

  LeaderboardsService(this._dio);

  /// Get global leaderboard (tries api/leaderboards/global then gamification league)
  Future<Map<String, dynamic>> getGlobalLeaderboard({
    String period = 'weekly',
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        'api/leaderboards/global',
        queryParameters: {'period': period, 'limit': limit},
      );
      return response.data is Map ? response.data as Map<String, dynamic> : {'entries': <dynamic>[]};
    } catch (_) {
      try {
        final fallback = await _dio.get(Api.leagueLeaderboard, queryParameters: {'limit': limit});
        return fallback.data is Map ? fallback.data as Map<String, dynamic> : {'entries': <dynamic>[]};
      } catch (__) {
        rethrow;
      }
    }
  }

  /// Get tribe leaderboard
  Future<Map<String, dynamic>> getTribeLeaderboard(
    String tribeId, {
    String period = 'season',
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        'api/leaderboards/tribe/$tribeId',
        queryParameters: {'period': period, 'limit': limit},
      );
      return response.data is Map ? response.data as Map<String, dynamic> : {'entries': <dynamic>[]};
    } catch (e) {
      rethrow;
    }
  }

  /// Get village leaderboard
  Future<Map<String, dynamic>> getVillageLeaderboard(
    String lang, {
    String period = 'monthly',
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        'api/leaderboards/village/$lang',
        queryParameters: {'period': period, 'limit': limit},
      );
      return response.data is Map ? response.data as Map<String, dynamic> : {'entries': <dynamic>[]};
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

