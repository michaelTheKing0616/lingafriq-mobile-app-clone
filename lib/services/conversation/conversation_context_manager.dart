/// Conversation Context Manager
/// Manages conversation context, personality consistency, and natural dialogue flows
/// 
/// Features:
/// - Multi-turn conversation context retention
/// - Personality consistency tracking
/// - Natural dialogue flow generation
/// - Context-aware responses
/// - Conversation history management

import 'package:flutter/foundation.dart';

/// Conversation message
class ConversationMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Conversation context
class ConversationContext {
  final String conversationId;
  final String languageCode;
  final String? personality;
  final List<ConversationMessage> messages;
  final Map<String, dynamic> userProfile;
  final Map<String, dynamic> conversationState;
  final DateTime createdAt;
  DateTime updatedAt;

  ConversationContext({
    required this.conversationId,
    required this.languageCode,
    this.personality,
    required this.messages,
    required this.userProfile,
    required this.conversationState,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'language_code': languageCode,
      'personality': personality,
      'messages': messages.map((m) => m.toJson()).toList(),
      'user_profile': userProfile,
      'conversation_state': conversationState,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Conversation Context Manager
class ConversationContextManager {
  final Map<String, ConversationContext> _conversations = {};
  static const int maxContextMessages = 20; // Keep last 20 messages for context

  /// Get or create conversation context
  ConversationContext getOrCreateContext({
    required String conversationId,
    required String languageCode,
    String? personality,
    Map<String, dynamic>? userProfile,
  }) {
    if (_conversations.containsKey(conversationId)) {
      return _conversations[conversationId]!;
    }

    final context = ConversationContext(
      conversationId: conversationId,
      languageCode: languageCode,
      personality: personality,
      messages: [],
      userProfile: userProfile ?? {},
      conversationState: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _conversations[conversationId] = context;
    return context;
  }

  /// Add message to conversation
  void addMessage({
    required String conversationId,
    required String role,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    final context = _conversations[conversationId];
    if (context == null) {
      debugPrint('Warning: Conversation $conversationId not found');
      return;
    }

    final message = ConversationMessage(
      role: role,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    context.messages.add(message);

    // Trim to max context messages
    if (context.messages.length > maxContextMessages) {
      context.messages.removeRange(0, context.messages.length - maxContextMessages);
    }

    context.updatedAt = DateTime.now();
  }

  /// Get conversation history for context
  List<Map<String, dynamic>> getConversationHistory(String conversationId, {int? limit}) {
    final context = _conversations[conversationId];
    if (context == null) return [];

    final messages = limit != null
        ? context.messages.sublist(
            context.messages.length - limit,
            context.messages.length,
          )
        : context.messages;

    return messages.map((m) => {
      'role': m.role,
      'content': m.content,
    }).toList();
  }

  /// Build context-aware prompt
  String buildContextualPrompt({
    required String conversationId,
    required String userMessage,
    String? systemPrompt,
  }) {
    final context = _conversations[conversationId];
    if (context == null) {
      return userMessage;
    }

    final buffer = StringBuffer();

    // System prompt with personality
    if (systemPrompt != null) {
      buffer.writeln(systemPrompt);
    } else if (context.personality != null) {
      buffer.writeln('You are a ${context.personality} conversation partner.');
    }

    buffer.writeln('Language: ${context.languageCode}');
    buffer.writeln('');

    // Conversation history
    final history = getConversationHistory(conversationId, limit: 10);
    if (history.isNotEmpty) {
      buffer.writeln('Previous conversation:');
      for (final msg in history) {
        buffer.writeln('${msg['role']}: ${msg['content']}');
      }
      buffer.writeln('');
    }

    // Current message
    buffer.writeln('User: $userMessage');
    buffer.writeln('Assistant:');

    return buffer.toString();
  }

  /// Update conversation state
  void updateState({
    required String conversationId,
    required String key,
    required dynamic value,
  }) {
    final context = _conversations[conversationId];
    if (context == null) return;

    context.conversationState[key] = value;
    context.updatedAt = DateTime.now();
  }

  /// Get conversation state
  dynamic getState(String conversationId, String key) {
    final context = _conversations[conversationId];
    if (context == null) return null;

    return context.conversationState[key];
  }

  /// Check personality consistency
  bool checkPersonalityConsistency(String conversationId) {
    final context = _conversations[conversationId];
    if (context == null || context.personality == null) return true;

    // Analyze recent messages for personality consistency
    final recentMessages = context.messages
        .where((m) => m.role == 'assistant')
        .take(5)
        .toList();

    // Heuristic consistency check:
    // - Block common "AI disclaimer" / refusal patterns that break character.
    // - Ensure assistant stays aligned to the configured personality tone keywords (best-effort).
    final personality = context.personality!.toLowerCase().trim();
    if (personality.isEmpty) return true;

    final assistantText = recentMessages.map((m) => m.content).join('\n').toLowerCase();

    const disallowedPhrases = <String>[
      'as an ai',
      'as a language model',
      "i can't help with",
      "i cannot help with",
      "i can’t help with",
      'i am an ai',
      'i am a chatbot',
      'i do not have personal opinions',
      'i don\'t have personal opinions',
    ];
    if (disallowedPhrases.any(assistantText.contains)) {
      return false;
    }

    // Very lightweight personality cues (extendable).
    // If the personality string contains certain archetypes, expect matching markers sometimes.
    final cueMap = <String, List<String>>{
      'friendly': ['great', 'nice', 'let\'s', 'sure', 'happy to'],
      'strict': ['must', 'should', 'important', 'rule', 'focus'],
      'playful': ['fun', 'game', 'haha', 'play', 'challenge'],
      'formal': ['please', 'kindly', 'therefore', 'however'],
    };

    final matchedArchetypes = cueMap.keys.where((k) => personality.contains(k)).toList();
    if (matchedArchetypes.isEmpty) return true;

    // If we expect cues, require at least one cue hit across recent messages.
    final expectedCues = matchedArchetypes.expand((k) => cueMap[k] ?? const <String>[]).toList();
    final hasCue = expectedCues.any(assistantText.contains);
    return hasCue;
  }

  /// Clear conversation context
  void clearContext(String conversationId) {
    _conversations.remove(conversationId);
  }

  /// Get all conversations
  List<ConversationContext> getAllConversations() {
    return _conversations.values.toList();
  }
}

