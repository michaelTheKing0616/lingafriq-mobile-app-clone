// One-off Groq completion for features that need a single AI response without
// mutating chat state (e.g. magazine cultural context, vocabulary extraction).
// Uses the same Groq pipeline as the main chat; does not call backend /polie/*.

import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:lingafriq/config/url_constants.dart';
import 'package:lingafriq/services/env_config.dart';

class GroqOneOffService {
  static final Dio _dio = Dio();

  static String get _groqApiKey => EnvConfig.groqApiKey;

  static const String _model = 'llama-3.3-70b-versatile';

  /// Single completion without touching chat provider state.
  /// Returns the assistant content string or empty string on failure/missing key.
  static Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.5,
    int maxTokens = 500,
  }) async {
    if (_groqApiKey.isEmpty || _groqApiKey == 'YOUR_GROQ_API_KEY') {
      return '';
    }
    try {
      final response = await _dio.post(
        UrlConstants.groqChatCompletions,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqApiKey',
          },
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final content = response.data['choices']?[0]?['message']?['content']?.toString();
        return content?.trim() ?? '';
      }
    } catch (_) {
      // Callers handle empty response
    }
    return '';
  }
}
