import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';

final aiChatProvider = NotifierProvider<AiChatProvider, BaseProviderState>(() {
  return AiChatProvider();
});

class ChatMessage {
  final String role; // 'user' or 'assistant'
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

class AiChatProvider extends BaseProvider {
  final List<ChatMessage> _messages = [];
  final Dio _dio = Dio();
  
  // OpenAI API Configuration
  // TODO: Move this to environment variables or secure storage
  static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // Replace with actual API key
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  
  String _selectedLanguage = 'English'; // Default language
  String? _systemPrompt;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String get selectedLanguage => _selectedLanguage;
  bool get hasMessages => _messages.isNotEmpty;
  bool get isBusy => state.isLoading;

  AiChatProvider() {
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
      // Prepare messages for API
      final apiMessages = [
        {
          'role': 'system',
          'content': _systemPrompt ?? 'You are a helpful AI assistant for learning African languages.',
        },
        ..._messages.map((msg) => {
              'role': msg.role,
              'content': msg.content,
            }),
      ];

      // Call OpenAI API
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
          'model': 'gpt-4', // Use gpt-4 for best multilingual support
          'messages': apiMessages,
          'temperature': 0.7,
          'max_tokens': 1000,
        },
      );

      setIdle();

      if (response.statusCode == 200) {
        final assistantMessage = response.data['choices'][0]['message']['content'] as String;
        
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
      } else {
        final errorMessage = response.data['error']?['message'] ?? 
            'Failed to get response from AI';
        throw Exception(errorMessage);
      }
    } catch (e) {
      setIdle();
      
      // Remove the user message if API call failed
      _messages.removeLast();
      state = state.copyWith();
      
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Invalid API key. Please check your OpenAI API configuration.');
        } else if (e.response?.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
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
      await prefs.setString('ai_chat_history', jsonEncode(messagesJson));
    } catch (e) {
      // Silently fail - chat history is not critical
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('ai_chat_history');
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

