import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Client-side AI traffic goes through the backend gateway.
/// Never attach a provider API key; the server owns credentials.
class AiGatewayClient {
  AiGatewayClient(this._dio);

  final Dio _dio;

  /// POST [ApiContract.ai.chatCompletion]. Throws on any non-200 response.
  Future<Map<String, dynamic>> completeChat({
    required List<Map<String, String>> messages,
    required String mode,
    double temperature = 0.35,
    int maxTokens = 500,
    String? model,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiContract.ai.chatCompletion,
      data: {
        if (model != null) 'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'response_format': {'type': 'json_object'},
        'mode': mode,
      },
      options: Options(contentType: Headers.jsonContentType),
    );

    if (response.statusCode != 200) {
      throw AiGatewayException(
        'AI gateway returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data == null) {
      throw const AiGatewayException('AI gateway returned an empty body');
    }
    return data;
  }

  /// Content from a gateway completion body (`content` or OpenAI-shaped choices).
  String extractContent(Map<String, dynamic> data) {
    final direct = data['content'];
    if (direct is String && direct.isNotEmpty) return direct;

    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          final nested = message['content'];
          if (nested is String && nested.isNotEmpty) return nested;
        }
      }
    }

    throw const AiGatewayException('AI gateway returned empty content');
  }
}

class AiGatewayException implements Exception {
  const AiGatewayException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
