import 'package:dio/dio.dart';
import 'package:lingafriq/utils/api.dart';

class BadgesService {
  final Dio _dio;

  BadgesService(this._dio);

  /// Get all available badges
  Future<List<dynamic>> getAllBadges() async {
    try {
      final response = await _dio.get('${Api.baseurl}api/badges');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user badges
  Future<List<dynamic>> getUserBadges(String userId) async {
    try {
      final response = await _dio.get('${Api.baseurl}api/badges/users/$userId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

