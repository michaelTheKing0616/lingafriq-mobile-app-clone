import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';

class BadgesService {
  final Dio _dio;

  BadgesService(this._dio);

  /// Get all available badges
  Future<List<dynamic>> getAllBadges() async {
    try {
      final response =
          await _dio.get(ApiContract.url(ApiContract.badges.list));
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user badges
  Future<List<dynamic>> getUserBadges(String userId) async {
    try {
      final response = await _dio
          .get(ApiContract.url(ApiContract.badges.userBadges(userId)));
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

