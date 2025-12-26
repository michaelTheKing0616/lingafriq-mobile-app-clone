import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';

/// World-class conversation context manager with intelligent summarization
/// Handles context window management, conversation memory, and context retention
/// Comparable to Duolingo Max's conversation system
class ConversationContextManager {
  static const String _conversationMemoryKey = 'conversation_memory';
  static const String _conversationSummariesKey = 'conversation_summaries';
  static const int _maxMessagesInContext = 15; // Keep last 15 messages in full context
  static const int _summaryThreshold = 30; // Summarize when conversation exceeds 30 messages
  static const int _maxSummaryLength = 500; // Max characters for summary

  /// Conversation summary model
  final Map<String, dynamic> _conversationSummaries = {};
  final Map<String, List<Map<String, dynamic>>> _conversationMemory = {};

  /// Get or create conversation context with intelligent management
  Future<List<Map<String, dynamic>>> getConversationContext({
    required String conversationId,
    required List<Map<String, dynamic>> currentMessages,
    required String systemPrompt,
    int? maxTokens,
  }) async {
    try {
      // Load conversation history and summaries
      await _loadConversationData(conversationId);

      // Get summary if exists
      final summary = _conversationSummaries[conversationId];
      
      // Calculate total message count
      final totalMessages = (summary != null ? 1 : 0) + currentMessages.length;

      // If conversation is getting long, create summary
      if (totalMessages > _summaryThreshold && summary == null) {
        await _createConversationSummary(conversationId, currentMessages);
      }

      // Build context-aware message list
      final contextMessages = <Map<String, dynamic>>[];

      // Add system prompt
      if (systemPrompt.isNotEmpty) {
        contextMessages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }

      // Add summary if exists (provides long-term memory)
      if (summary != null) {
        contextMessages.add({
          'role': 'system',
          'content': 'Previous conversation summary: ${summary['summary']}\n\n'
              'Key topics discussed: ${summary['topics']?.join(', ') ?? 'N/A'}\n'
              'User learning level: ${summary['user_level'] ?? 'intermediate'}\n'
              'Continue the conversation naturally, building on this context.',
        });
      }

      // Add recent messages (keep full context for recent exchanges)
      final recentMessages = currentMessages.length > _maxMessagesInContext
          ? currentMessages.sublist(currentMessages.length - _maxMessagesInContext)
          : currentMessages;

      contextMessages.addAll(recentMessages);

      // Estimate token count (rough approximation: 1 token ≈ 4 characters)
      final estimatedTokens = contextMessages
          .map((m) => (m['content'] as String? ?? '').length)
          .fold<int>(0, (sum, len) => sum + len) ~/ 4;

      // If exceeding token limit, further trim messages
      if (maxTokens != null && estimatedTokens > maxTokens) {
        final targetTokens = (maxTokens * 0.8).round(); // Use 80% of limit
        final trimmedMessages = _trimMessagesToTokenLimit(
          contextMessages,
          targetTokens,
          preserveSystem: true,
        );
        return trimmedMessages;
      }

      return contextMessages;
    } catch (e, stackTrace) {
      debugPrint('Error in getConversationContext: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
      // Fallback: return current messages with system prompt
      return [
        if (systemPrompt.isNotEmpty)
          {'role': 'system', 'content': systemPrompt},
        ...currentMessages,
      ];
    }
  }

  /// Create intelligent conversation summary
  Future<void> _createConversationSummary(
    String conversationId,
    List<Map<String, dynamic>> messages,
  ) async {
    try {
      // Extract key information from conversation
      final userMessages = messages
          .where((m) => m['role'] == 'user')
          .map((m) => m['content'] as String)
          .toList();

      final assistantMessages = messages
          .where((m) => m['role'] == 'assistant')
          .map((m) => m['content'] as String)
          .toList();

      // Identify topics discussed
      final topics = _extractTopics(userMessages, assistantMessages);

      // Determine user learning level based on conversation complexity
      final userLevel = _determineUserLevel(userMessages, assistantMessages);

      // Create summary
      final summary = {
        'summary': _generateSummary(messages),
        'topics': topics,
        'user_level': userLevel,
        'message_count': messages.length,
        'created_at': DateTime.now().toIso8601String(),
      };

      _conversationSummaries[conversationId] = summary;
      await _saveConversationData();
    } catch (e, stackTrace) {
      debugPrint('Error creating conversation summary: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Generate conversation summary
  String _generateSummary(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return 'No conversation history.';

    final summaryParts = <String>[];
    final userMessages = messages.where((m) => m['role'] == 'user').toList();
    final assistantMessages = messages.where((m) => m['role'] == 'assistant').toList();

    // Extract key themes
    if (userMessages.isNotEmpty && assistantMessages.isNotEmpty) {
      summaryParts.add(
        'User engaged in ${userMessages.length} exchanges, '
        'discussing various topics in the target language.',
      );
    }

    // Add language patterns observed
    final languagePatterns = _extractLanguagePatterns(messages);
    if (languagePatterns.isNotEmpty) {
      summaryParts.add('Language patterns: ${languagePatterns.join(', ')}');
    }

    // Limit summary length
    final summary = summaryParts.join(' ');
    return summary.length > _maxSummaryLength
        ? '${summary.substring(0, _maxSummaryLength)}...'
        : summary;
  }

  /// Extract topics from conversation
  List<String> _extractTopics(
    List<String> userMessages,
    List<String> assistantMessages,
  ) {
    final topics = <String>{};
    
    // Common topic keywords
    final topicKeywords = {
      'greeting': ['hello', 'hi', 'greetings', 'good morning', 'good evening'],
      'introduction': ['name', 'introduce', 'who are you', 'tell me about'],
      'family': ['family', 'mother', 'father', 'sister', 'brother', 'parent'],
      'food': ['food', 'eat', 'cooking', 'recipe', 'meal', 'hungry'],
      'travel': ['travel', 'visit', 'trip', 'journey', 'destination'],
      'culture': ['culture', 'tradition', 'custom', 'festival', 'celebration'],
      'work': ['work', 'job', 'career', 'profession', 'office'],
      'education': ['learn', 'study', 'school', 'university', 'education'],
      'health': ['health', 'sick', 'doctor', 'hospital', 'medicine'],
      'weather': ['weather', 'rain', 'sun', 'temperature', 'climate'],
    };

    final allMessages = [...userMessages, ...assistantMessages];
    final lowerMessages = allMessages.map((m) => m.toLowerCase()).join(' ');

    for (final entry in topicKeywords.entries) {
      if (entry.value.any((keyword) => lowerMessages.contains(keyword))) {
        topics.add(entry.key);
      }
    }

    return topics.toList();
  }

  /// Determine user learning level
  String _determineUserLevel(
    List<String> userMessages,
    List<String> assistantMessages,
  ) {
    if (userMessages.isEmpty) return 'beginner';

    // Analyze message complexity
    final avgLength = userMessages
        .map((m) => m.split(' ').length)
        .fold<int>(0, (sum, len) => sum + len) /
        userMessages.length;

    final hasComplexSentences = userMessages.any((m) => m.split(' ').length > 10);
    final hasQuestions = userMessages.any((m) => m.contains('?'));
    final hasMultipleTopics = _extractTopics(userMessages, assistantMessages).length > 2;

    if (avgLength > 8 && hasComplexSentences && hasMultipleTopics) {
      return 'advanced';
    } else if (avgLength > 5 && hasQuestions) {
      return 'intermediate';
    } else {
      return 'beginner';
    }
  }

  /// Extract language patterns
  List<String> _extractLanguagePatterns(List<Map<String, dynamic>> messages) {
    final patterns = <String>[];
    
    // Look for common grammatical patterns
    final allContent = messages
        .map((m) => m['content'] as String? ?? '')
        .join(' ')
        .toLowerCase();

    if (allContent.contains('question') || allContent.contains('?')) {
      patterns.add('question formation');
    }
    if (allContent.contains('past') || allContent.contains('yesterday')) {
      patterns.add('past tense');
    }
    if (allContent.contains('future') || allContent.contains('will') || allContent.contains('tomorrow')) {
      patterns.add('future tense');
    }
    if (allContent.contains('please') || allContent.contains('thank')) {
      patterns.add('politeness markers');
    }

    return patterns;
  }

  /// Trim messages to fit token limit
  List<Map<String, dynamic>> _trimMessagesToTokenLimit(
    List<Map<String, dynamic>> messages,
    int targetTokens, {
    bool preserveSystem = true,
  }) {
    final trimmed = <Map<String, dynamic>>[];
    int currentTokens = 0;

    // Always preserve system messages
    for (final message in messages) {
      if (message['role'] == 'system') {
        trimmed.add(message);
        currentTokens += ((message['content'] as String? ?? '').length ~/ 4);
      }
    }

    // Add user/assistant messages from most recent, up to token limit
    final nonSystemMessages = messages
        .where((m) => m['role'] != 'system')
        .toList()
        .reversed
        .toList();

    for (final message in nonSystemMessages) {
      final messageTokens = ((message['content'] as String? ?? '').length ~/ 4);
      if (currentTokens + messageTokens <= targetTokens) {
        trimmed.insert(trimmed.length - (preserveSystem ? 1 : 0), message);
        currentTokens += messageTokens;
      } else {
        break;
      }
    }

    return trimmed;
  }

  /// Save conversation context for persistence
  Future<void> saveConversationContext({
    required String conversationId,
    required List<Map<String, dynamic>> messages,
  }) async {
    try {
      _conversationMemory[conversationId] = messages;
      await _saveConversationData();
    } catch (e, stackTrace) {
      debugPrint('Error saving conversation context: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Get conversation history
  Future<List<Map<String, dynamic>>> getConversationHistory(String conversationId) async {
    await _loadConversationData(conversationId);
    return _conversationMemory[conversationId] ?? [];
  }

  /// Clear conversation context
  Future<void> clearConversationContext(String conversationId) async {
    try {
      _conversationMemory.remove(conversationId);
      _conversationSummaries.remove(conversationId);
      await _saveConversationData();
    } catch (e, stackTrace) {
      debugPrint('Error clearing conversation context: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Load conversation data from storage
  Future<void> _loadConversationData(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load summaries
      final summariesJson = prefs.getString(_conversationSummariesKey);
      if (summariesJson != null) {
        final decoded = jsonDecode(summariesJson) as Map<String, dynamic>;
        _conversationSummaries.addAll(
          decoded.map((key, value) => MapEntry(key, value as Map<String, dynamic>)),
        );
      }

      // Load memory
      final memoryJson = prefs.getString(_conversationMemoryKey);
      if (memoryJson != null) {
        final decoded = jsonDecode(memoryJson) as Map<String, dynamic>;
        _conversationMemory.addAll(
          decoded.map(
            (key, value) => MapEntry(
              key,
              (value as List).map((e) => e as Map<String, dynamic>).toList(),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading conversation data: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Save conversation data to storage
  Future<void> _saveConversationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save summaries
      final summariesJson = jsonEncode(_conversationSummaries);
      await prefs.setString(_conversationSummariesKey, summariesJson);

      // Save memory
      final memoryJson = jsonEncode(_conversationMemory);
      await prefs.setString(_conversationMemoryKey, memoryJson);
    } catch (e, stackTrace) {
      debugPrint('Error saving conversation data: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Get conversation insights for analytics
  Map<String, dynamic> getConversationInsights(String conversationId) {
    final summary = _conversationSummaries[conversationId];
    final messages = _conversationMemory[conversationId] ?? [];

    return {
      'conversation_id': conversationId,
      'message_count': messages.length,
      'has_summary': summary != null,
      'topics': summary?['topics'] ?? [],
      'user_level': summary?['user_level'] ?? 'unknown',
      'last_updated': summary?['created_at'] ?? DateTime.now().toIso8601String(),
    };
  }
}

