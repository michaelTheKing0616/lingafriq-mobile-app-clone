import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lingafriq/config/api_contract.dart';
import '../services/env_config.dart';

/// Service to persist Rive character state across sessions
class RiveStateService {
  final Dio _dio;
  final String _resolvedBaseUrl;

  RiveStateService({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _resolvedBaseUrl =
            (baseUrl ?? EnvConfig.backendBaseUrl).replaceAll(RegExp(r'/$'), '');

  String _url(String path) => '$_resolvedBaseUrl$path';

  /// Save Rive state to backend
  Future<bool> saveState({
    required String userId,
    required String emotion,
    required double confidence,
  }) async {
    try {
      final response = await _dio.post(
        _url(ApiContract.polieRiveState),
        data: {
          'user_id': userId,
          'emotion': emotion,
          'confidence': confidence,
          'last_interaction': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving Rive state: $e');
      return false;
    }
  }

  /// Get saved Rive state from backend
  Future<Map<String, dynamic>?> getState({required String userId}) async {
    try {
      final response = await _dio.get(
        _url(ApiContract.polieRiveState),
        queryParameters: {'user_id': userId},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error getting Rive state: $e');
    }
    return null;
  }
}

