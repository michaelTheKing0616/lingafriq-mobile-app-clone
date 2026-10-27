import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Client-side AI traffic goes through the backend gateway.
/// Never attach a provider API key; the server owns credentials.
class AiGatewayClient {
  AiGatewayClient(this._dio);

  final Dio _dio;

  static const String chatCompletionStreamPath =
      '/api/ai/chat/completion/stream';

  /// Maps legacy Polie mode names to public gateway modes (P6-002).
  static String gatewayModeForPolie(String polieModeName) {
    switch (polieModeName) {
      case 'translation':
        return 'translate';
      case 'tutor':
        return 'tutor_explain';
      case 'roleplay':
        return 'roleplay';
      case 'conversation':
        return 'conversation';
      case 'vocab':
      case 'review':
      case 'grammar':
        return 'tutor_explain';
      case 'pronunciation':
        return 'shadowing';
      default:
        return 'conversation';
    }
  }

  /// User-visible copy for gateway failures (AC4: no fake replies).
  static String userMessageFor(
    AiGatewayException error, {
    Map<String, dynamic>? body,
  }) {
    final code = body?['error']?.toString() ?? '';
    if (code == 'quota_exceeded') {
      return 'Daily AI limit reached. Try again after the reset time.';
    }
    if (code == 'mode_disabled' || code == 'mode_budget_exhausted') {
      return 'This AI feature is temporarily unavailable. Please try again later.';
    }
    if (code == 'mode_unknown' || code == 'prompt_version_unknown') {
      return 'This chat mode is not available right now.';
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Sign in again to use Polie.';
    }
    if (error.statusCode != null && error.statusCode! >= 500) {
      return 'Polie is having trouble right now. Please try again.';
    }
    return error.message.isNotEmpty
        ? error.message
        : 'Polie could not respond. Please try again.';
  }

  static AiGatewayException fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error']?.toString();
      final msg = data['message']?.toString();
      return AiGatewayException(
        msg ?? err ?? e.message ?? 'Gateway request failed',
        statusCode: status,
        errorCode: err,
        body: data,
      );
    }
    return AiGatewayException(
      e.message ?? 'Gateway request failed',
      statusCode: status,
    );
  }

  static AiGatewayException fromHttpStatus(
    int? statusCode,
    Map<String, dynamic>? data,
  ) {
    final err = data?['error']?.toString();
    final msg = data?['message']?.toString();
    return AiGatewayException(
      msg ?? err ?? 'AI gateway returned ${statusCode ?? 'unknown'}',
      statusCode: statusCode,
      errorCode: err,
      body: data,
    );
  }

  Map<String, dynamic> _poliePayload({
    required String mode,
    required List<Map<String, String>> messages,
    double temperature = 0.35,
    int maxTokens = 500,
    String? language,
    String? languageCode,
    String? sourceLanguage,
    String? targetLanguage,
    String? cefr,
  }) {
    return {
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'mode': mode,
      if (language != null) 'language': language,
      if (languageCode != null) 'languageCode': languageCode,
      if (sourceLanguage != null) 'sourceLanguage': sourceLanguage,
      if (targetLanguage != null) 'targetLanguage': targetLanguage,
      if (cefr != null) 'cefr': cefr,
    };
  }

  /// POST [ApiContract.ai.chatCompletion]. Throws on any non-200 response.
  Future<Map<String, dynamic>> completeChat({
    required List<Map<String, String>> messages,
    required String mode,
    double temperature = 0.35,
    int maxTokens = 500,
    String? model,
    String? language,
    String? languageCode,
    String? sourceLanguage,
    String? targetLanguage,
    String? cefr,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiContract.ai.chatCompletion,
        data: {
          ..._poliePayload(
            mode: mode,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            language: language,
            languageCode: languageCode,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            cefr: cefr,
          ),
          if (model != null) 'model': model,
          'response_format': {'type': 'json_object'},
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode != 200) {
        throw fromHttpStatus(response.statusCode, response.data);
      }

      final data = response.data;
      if (data == null) {
        throw const AiGatewayException('AI gateway returned an empty body');
      }
      return data;
    } on DioException catch (e) {
      throw fromDio(e);
    }
  }

  /// JSON-shaped Polie workspace calls (server template + user schema in message).
  Future<String> completePolieJson({
    required String polieModeName,
    required String userMessage,
    double temperature = 0.3,
    int maxTokens = 2000,
    String? language,
    String? languageCode,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    final data = await completeChat(
      messages: [
        {'role': 'user', 'content': userMessage},
      ],
      mode: gatewayModeForPolie(polieModeName),
      temperature: temperature,
      maxTokens: maxTokens,
      language: language,
      languageCode: languageCode,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    return extractContent(data);
  }

  /// SSE token stream from the gateway (P6-017).
  Stream<String> streamChatTokens({
    required List<Map<String, String>> messages,
    required String mode,
    double temperature = 0.35,
    int maxTokens = 2000,
    String? language,
    String? languageCode,
    String? sourceLanguage,
    String? targetLanguage,
    String? cefr,
    CancelToken? cancelToken,
  }) async* {
    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        chatCompletionStreamPath,
        data: _poliePayload(
          mode: mode,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          language: language,
          languageCode: languageCode,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          cefr: cefr,
        ),
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw fromDio(e);
    }

    if (response.statusCode != 200) {
      throw fromHttpStatus(response.statusCode, null);
    }

    final body = response.data;
    if (body == null) {
      throw const AiGatewayException('AI gateway stream missing body');
    }

    var eventName = '';
    final dataLines = <String>[];

    await for (final chunk in body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.isEmpty) {
          if (dataLines.isNotEmpty) {
            final raw = dataLines.join('\n');
            dataLines.clear();
            if (eventName == 'error') {
              Map<String, dynamic>? parsed;
              try {
                parsed = jsonDecode(raw) as Map<String, dynamic>;
              } catch (_) {}
              throw AiGatewayException(
                parsed?['message']?.toString() ?? 'Stream failed',
                errorCode: parsed?['code']?.toString(),
                body: parsed,
              );
            }
            if (eventName == 'token') {
              try {
                final parsed = jsonDecode(raw) as Map<String, dynamic>;
                final text = parsed['text']?.toString() ?? '';
                if (text.isNotEmpty) yield text;
              } catch (_) {}
            }
          }
          eventName = '';
          continue;
        }
        if (line.startsWith(':')) continue;
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          dataLines.add(line.substring(5).trim());
        }
      }
    }
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
  const AiGatewayException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.body,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? body;

  @override
  String toString() => message;
}
