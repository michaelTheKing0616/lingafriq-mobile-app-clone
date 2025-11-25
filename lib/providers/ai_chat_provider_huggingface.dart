import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';

/// Alternative AI Chat Provider using Hugging Face Inference API
/// This is FREE and doesn't require a credit card (initially)
/// 
/// To use this instead of OpenAI:
/// 1. Get a free Hugging Face token: https://huggingface.co/settings/tokens
/// 2. Replace HuggingFaceChatProvider with this in your code
/// 3. Update the API key below

final huggingFaceChatProvider = NotifierProvider<HuggingFaceChatProvider, BaseProviderState>(() {
  return HuggingFaceChatProvider();
});

class HuggingFaceChatProvider extends BaseProvider {
  final List<ChatMessage> _messages = [];
  final Dio _dio = Dio();
  
  // Hugging Face Configuration
  // Get your FREE token at: https://huggingface.co/settings/tokens
  static const String _apiKey = 'YOUR_HUGGINGFACE_TOKEN_HERE'; // Replace with your token from GitHub Secrets or environment
  static const String _modelName = 'meta-llama/Llama-2-7b-chat-hf'; // Free model
  
  String get _apiUrl => 'https://router.huggingface.co/models/$_modelName';
  
  String _selectedLanguage = 'English';
  String? _systemPrompt;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String get selectedLanguage => _selectedLanguage;
  bool get hasMessages => _messages.isNotEmpty;
  bool get isBusy => state.isLoading;

  HuggingFaceChatProvider() {
    _loadChatHistory();
    _initializeSystemPrompt();
  }

  void _initializeSystemPrompt() {
    _systemPrompt = '''You are a helpful AI language learning assistant specializing in African languages. 
You help users learn and practice various African languages including:
- Swahili (Kiswahili)
- Yoruba
- Igbo
- Hausa
- Zulu
- Xhosa
- Amharic
- Pidgin English (Nigerian Pidgin)
- Twi
- Afrikaans
- And many other African languages

You can:
- Help users practice conversations
- Explain grammar and vocabulary
- Provide translations
- Create learning exercises
- Answer questions about African cultures and languages
- Engage in natural conversations in the selected language

Always be encouraging, patient, and culturally sensitive. Respond naturally in the language the user is learning, or in the language they're using to communicate with you.''';
  }

  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    _initializeSystemPrompt();
    state = state.copyWith();
  }

  Future<String> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    // Add user message to chat
    final userMsg = ChatMessage(
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    state = state.copyWith();
    await _saveChatHistory();

    setBusy();

    try {
      // Format conversation for Hugging Face
      // Build the full conversation context
      String conversationContext = _systemPrompt ?? '';
      conversationContext += '\n\nConversation:\n';
      
      for (var msg in _messages) {
        conversationContext += '${msg.role == 'user' ? 'User' : 'Assistant'}: ${msg.content}\n';
      }
      conversationContext += 'Assistant:';

      // Call Hugging Face Inference API
      final response = await _dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          validateStatus: (status) => status! < 500,
        ),
        data: {
          'inputs': conversationContext,
          'parameters': {
            'max_new_tokens': 500,
            'temperature': 0.7,
            'return_full_text': false,
          },
        },
      );

      setIdle();

      if (response.statusCode == 200) {
        // Hugging Face returns array of generated text
        final generatedText = response.data is List
            ? response.data[0]['generated_text'] as String
            : response.data['generated_text'] as String?;
        
        if (generatedText == null || generatedText.isEmpty) {
          throw Exception('Empty response from AI');
        }
        
        // Clean up the response (remove context if included)
        String assistantMessage = generatedText.trim();
        
        // Add assistant response to chat
        final assistantMsg = ChatMessage(
          role: 'assistant',
          content: assistantMessage,
          timestamp: DateTime.now(),
        );
        _messages.add(assistantMsg);
        state = state.copyWith();
        await _saveChatHistory();

        return assistantMessage;
      } else if (response.statusCode == 503) {
        // Model is loading (Hugging Face free tier)
        throw Exception('Model is loading. Please wait 10-20 seconds and try again.');
      } else {
        final errorMessage = response.data?['error'] ?? 
            'Failed to get response from AI';
        throw Exception(errorMessage.toString());
      }
    } catch (e) {
      setIdle();
      
      // Remove the user message if API call failed
      if (_messages.isNotEmpty && _messages.last.role == 'user') {
        _messages.removeLast();
        state = state.copyWith();
      }
      
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Invalid API token. Please check your Hugging Face token.');
        } else if (e.response?.statusCode == 429) {
          throw Exception('Rate limit exceeded. Free tier allows 1,000 requests/month.');
        } else if (e.response?.statusCode == 503) {
          throw Exception('Model is loading. Please wait 10-20 seconds and try again.');
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Connection timeout. Please check your internet connection.');
        }
      }
      
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> clearChat() async {
    _messages.clear();
    state = state.copyWith();
    await _saveChatHistory();
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((msg) => msg.toJson()).toList();
      await prefs.setString('ai_chat_history_hf', jsonEncode(messagesJson));
    } catch (e) {
      // Silently fail - chat history is not critical
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('ai_chat_history_hf');
      if (historyJson != null) {
        final List<dynamic> messagesList = jsonDecode(historyJson);
        _messages.clear();
        _messages.addAll(
          messagesList.map((json) => ChatMessage.fromJson(json)),
        );
        state = state.copyWith();
      }
    } catch (e) {
      // Silently fail - start with empty chat
    }
  }
}

// Re-export ChatMessage class
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

