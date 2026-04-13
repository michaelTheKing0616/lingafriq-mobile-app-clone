import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Fetches GET `/api/games/catalog` (Polie router) for the Games hub.
class GameCatalogService {
  GameCatalogService(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchCatalogRows() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiContract.url(ApiContract.games.catalog),
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: data?['error']?.toString() ?? 'Invalid games catalog response',
      );
    }
    final raw = data['data'];
    if (raw is! List) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'games catalog data is not a list',
      );
    }
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(e);
      } else if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }
}
