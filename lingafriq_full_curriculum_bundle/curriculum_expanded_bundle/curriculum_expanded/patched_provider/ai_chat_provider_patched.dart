import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';

final aiChatProvider = NotifierProvider<AiChatProvider, BaseProviderState>(() {
  return AiChatProvider();
});

class AiChatProvider extends BaseProvider {
  final List<ChatMessage> _messages = [];
  final Dio _dio = Dio();

  static const String _groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _modelName = 'aya-8b';

  AiChatProvider() {
    _loadChatHistory();
  }

  Future<Map<String, dynamic>> _callGrader(String promptJson, {int maxTokens = 400}) async {
    try {
      final resp = await _dio.post(
        _groqUrl,
        options: Options(headers: {'Authorization': 'Bearer $_groqApiKey', 'Content-Type': 'application/json'}),
        data: {
          'model': _modelName,
          'messages': [
            {'role':'system','content':'You are a JSON-output grader. Return valid JSON only.'},
            {'role':'user','content': promptJson}
          ],
          'temperature': 0.0,
          'max_tokens': maxTokens
        },
      );
      if (resp.statusCode == 200) {
        final text = resp.data['choices'][0]['message']['content']?.toString() ?? '';
        try {
          return jsonDecode(text) as Map<String, dynamic>;
        } catch (e) {
          // Try to extract JSON substring
          final start = text.indexOf('{');
          final end = text.lastIndexOf('}');
          if (start >=0 && end>start) {
            final sub = text.substring(start, end+1);
            return jsonDecode(sub) as Map<String,dynamic>;
          }
          throw Exception('Failed to parse grader JSON');
        }
      } else {
        throw Exception('Grader API error: ${resp.statusCode} ${resp.data}');
      }
    } on DioException catch (e) {
      debugPrint('Grader call failed: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> gradeTranslation(String sourceText, List<String> expected, String userTranslation, String language) async {
    final prompt = jsonEncode({
      'task':'translation_check',
      'source_text': sourceText,
      'expected_translations': expected,
      'user_translation': userTranslation,
      'language': language
    });
    return await _callGrader(prompt);
  }

  Future<Map<String, dynamic>> gradeGrammar(String userText, String language) async {
    final prompt = jsonEncode({'task':'grammar_correction','language':language,'user_text':userText});
    return await _callGrader(prompt, maxTokens:600);
  }

  Future<Map<String, dynamic>> gradePronunciation(String reference, String userTranscript, double asrConfidence, String language) async {
    final prompt = jsonEncode({'task':'pronunciation_score','language':language,'reference_text':reference,'user_transcript':userTranscript,'asr_confidence':asrConfidence});
    return await _callGrader(prompt, maxTokens:500);
  }

  // ... existing provider methods (load/save chat history, sendMessage, etc.) should be merged here in your app
}

// Simple ChatMessage model for provider
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  ChatMessage({required this.role, required this.content, required this.timestamp});
  Map<String,dynamic> toJson() => {'role':role,'content':content,'timestamp':timestamp.toIso8601String()};
}
