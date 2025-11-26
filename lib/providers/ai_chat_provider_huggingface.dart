import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

class HuggingFaceChatProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
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

  @override
  BaseProviderState build() {
    _loadChatHistory();
    _initializeSystemPrompt();
    return BaseProviderState();
  }

  HuggingFaceChatProvider() {
    // Initialization moved to build()
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

    state = state.copyWith(isLoading: true);

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

      state = state.copyWith(isLoading: false);

      if (response.statusCode == 200) {
        // Hugging Face API response format can vary:
        // 1. List of maps: [{"generated_text": "..."}]
        // 2. Single map: {"generated_text": "..."}
        // 3. Direct string in some cases
        // 4. Error response: {"error": "..."}
        String? generatedText;
        
        try {
          // Log response for debugging
          debugPrint('AI Response status: ${response.statusCode}');
          debugPrint('AI Response data type: ${response.data.runtimeType}');
          debugPrint('AI Response data: ${response.data}');
          
          // Handle different response formats
          dynamic responseData = response.data;
          
          // If responseData is null, throw error
          if (responseData == null) {
            throw Exception('Null response from AI API');
          }
          
          // Handle List response
          if (responseData is List) {
            if (responseData.isEmpty) {
              throw Exception('Empty list response from AI API');
            }
            final firstItem = responseData[0];
            if (firstItem is Map<String, dynamic>) {
              if (firstItem.containsKey('error')) {
                throw Exception(firstItem['error'].toString());
              }
              generatedText = firstItem['generated_text'] as String?;
            } else if (firstItem is String) {
              generatedText = firstItem;
            } else {
              // Try to convert to string
              generatedText = firstItem.toString();
            }
          }
          // Handle Map response
          else if (responseData is Map<String, dynamic>) {
            // Check for error first
            if (responseData.containsKey('error')) {
              final error = responseData['error'];
              throw Exception(error is String ? error : error.toString());
            }
            
            // Try different possible keys
            generatedText = responseData['generated_text'] as String?;
            
            if (generatedText == null) {
              generatedText = responseData['text'] as String?;
            }
            
            if (generatedText == null && responseData.containsKey('output')) {
              final output = responseData['output'];
              if (output is List && output.isNotEmpty) {
                final firstOutput = output[0];
                if (firstOutput is Map<String, dynamic>) {
                  generatedText = firstOutput['generated_text'] as String?;
                } else if (firstOutput is String) {
                  generatedText = firstOutput;
                }
              } else if (output is String) {
                generatedText = output;
              }
            }
          }
          // Handle String response
          else if (responseData is String) {
            generatedText = responseData;
          }
          // Try to convert to string as last resort
          else {
            generatedText = responseData.toString();
          }
          
          // Validate we got text
          if (generatedText == null || generatedText.trim().isEmpty) {
            debugPrint('Failed to extract text from response');
            throw Exception('Empty response from AI. Response format: ${responseData.runtimeType}');
          }
          
          debugPrint('Successfully extracted text: ${generatedText.substring(0, generatedText.length > 50 ? 50 : generatedText.length)}...');
        } catch (e) {
          debugPrint('Error parsing AI response: $e');
          // If it's already an Exception, rethrow it
          if (e is Exception) {
            rethrow;
          }
          // Otherwise wrap it
          throw Exception('Failed to parse AI response: ${e.toString()}');
        }
        
        // Clean up the response (remove context if included)
        String assistantMessage = generatedText.trim();
        
        // Remove the conversation context prefix if it was included
        if (assistantMessage.contains('Assistant:')) {
          final parts = assistantMessage.split('Assistant:');
          if (parts.length > 1) {
            assistantMessage = parts.last.trim();
          }
        }
        
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
      state = state.copyWith(isLoading: false);
      
      // Remove the user message if API call failed
      if (_messages.isNotEmpty && _messages.last.role == 'user') {
        _messages.removeLast();
        state = state.copyWith();
        await _saveChatHistory();
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
        } else if (e.response != null) {
          // Try to extract error message from response
          final errorData = e.response?.data;
          String errorMsg = 'Failed to send message';
          if (errorData is Map && errorData.containsKey('error')) {
            errorMsg = errorData['error'].toString();
          } else if (errorData is String) {
            errorMsg = errorData;
          }
          throw Exception('Failed to send message: $errorMsg');
        }
      }
      
      // Re-throw with more context
      final errorMessage = e.toString();
      if (errorMessage.contains('type') && errorMessage.contains('subtype')) {
        throw Exception('Failed to send message: API response format error. Please try again.');
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

