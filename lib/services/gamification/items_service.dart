import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';

class ItemsService {
  final Dio _dio;

  ItemsService(this._dio);

  /// Get all magic items
  Future<List<dynamic>> getAllItems() async {
    try {
      final response =
          await _dio.get(ApiContract.url(ApiContract.items.list));
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user inventory
  Future<List<dynamic>> getUserInventory(String userId) async {
    try {
      final response = await _dio
          .get(ApiContract.url(ApiContract.items.userInventory(userId)));
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Claim item
  Future<void> claimItem(String userId, String itemCode, {int qty = 1}) async {
    try {
      await _dio.post(
        ApiContract.url(ApiContract.items.userClaim(userId)),
        data: {'item_code': itemCode, 'qty': qty},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Use item
  Future<Map<String, dynamic>> useItem(String userId, String itemId) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.items.userUse(userId)),
        data: {'item_id': itemId},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

