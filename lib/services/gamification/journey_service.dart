import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';
class JourneyService {
  final Dio _dio;

  JourneyService(this._dio);

  /// Get all nodes for a campaign
  Future<List<dynamic>> getCampaignNodes(String campaign) async {
    try {
      final response =
          await _dio.get(ApiContract.url(ApiContract.journey.nodes(campaign)));
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get node detail
  Future<Map<String, dynamic>> getNode(String campaign, String nodeId) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.journey.node(campaign, nodeId)),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Start a journey node
  Future<Map<String, dynamic>> startNode(String campaign, String nodeId) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.journey.nodeStart(campaign, nodeId)),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Complete a journey node
  Future<Map<String, dynamic>> completeNode(
    String campaign,
    String nodeId, {
    Map<String, dynamic>? evidence,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.journey.nodeComplete(campaign, nodeId)),
        data: evidence,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user progress
  Future<List<dynamic>> getUserProgress(String userId, {String? campaign}) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.journey.userProgress(userId)),
        queryParameters: campaign != null ? {'campaign': campaign} : null,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

