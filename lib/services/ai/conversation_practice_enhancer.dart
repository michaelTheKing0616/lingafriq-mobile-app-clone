import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';

/// Conversation flow states
enum ConversationFlow {
  greeting,
  introduction,
  topicDiscussion,
  questionAnswer,
  roleplay,
  wrapUp,
}

/// World-class conversation practice enhancer
/// Provides natural dialogue flows, context retention, personality consistency
/// Comparable to Duolingo Max conversation practice
class ConversationPracticeEnhancer {

  /// Conversation context tracker
  final Map<String, ConversationContext> _conversationContexts = {};

  /// Get enhanced conversation prompt based on flow state
  String getEnhancedPrompt({
    required String conversationId,
    required ConversationFlow flowState,
    required String basePrompt,
    String? currentTopic,
    String? userLevel,
    Map<String, dynamic>? previousContext,
  }) {
    try {
      // Get or create context
      final context = _conversationContexts[conversationId] ?? ConversationContext();
      _conversationContexts[conversationId] = context;

      // Build enhanced prompt based on flow state
      final enhancedPrompt = StringBuffer(basePrompt);
      enhancedPrompt.writeln('\n\n--- Conversation Context ---');

      // Add flow-specific instructions
      switch (flowState) {
        case ConversationFlow.greeting:
          enhancedPrompt.writeln(
            'You are engaging in a natural greeting exchange. '
            'Use culturally appropriate greetings for the target language. '
            'Be warm and welcoming. After greeting, naturally transition to asking how the user is doing.',
          );
          break;

        case ConversationFlow.introduction:
          enhancedPrompt.writeln(
            'You are helping the user introduce themselves. '
            'Ask about their name, where they are from, and what they do. '
            'Respond naturally and show interest. Use appropriate honorifics if the language has them.',
          );
          break;

        case ConversationFlow.topicDiscussion:
          if (currentTopic != null) {
            enhancedPrompt.writeln(
              'You are discussing: $currentTopic. '
              'Engage naturally, ask follow-up questions, and share relevant information. '
              'Encourage the user to express their thoughts and opinions.',
            );
          }
          break;

        case ConversationFlow.questionAnswer:
          enhancedPrompt.writeln(
            'You are in a Q&A format. '
            'Answer questions clearly and concisely. '
            'If the user asks something you don\'t know, say so politely and suggest an alternative topic.',
          );
          break;

        case ConversationFlow.roleplay:
          enhancedPrompt.writeln(
            'You are in a roleplay scenario. '
            'Stay in character and respond as the scenario requires. '
            'Make it engaging and educational while being natural.',
          );
          break;

        case ConversationFlow.wrapUp:
          enhancedPrompt.writeln(
            'You are wrapping up the conversation. '
            'Summarize what was discussed, acknowledge the user\'s progress, '
            'and suggest topics for future conversations.',
          );
          break;
      }

      // Add context retention instructions
      if (previousContext != null) {
        enhancedPrompt.writeln('\n--- Previous Context ---');
        if (previousContext['topics'] != null) {
          enhancedPrompt.writeln(
            'Previously discussed: ${previousContext['topics']?.join(', ') ?? 'N/A'}',
          );
        }
        if (previousContext['user_level'] != null) {
          enhancedPrompt.writeln(
            'User level: ${previousContext['user_level']}',
          );
        }
        enhancedPrompt.writeln(
          'Remember and reference previous conversation points naturally.',
        );
      }

      // Add personality consistency instructions
      enhancedPrompt.writeln('\n--- Personality Consistency ---');
      enhancedPrompt.writeln(
        'Maintain a consistent personality throughout the conversation. '
        'If you started formal, stay formal. If casual, stay casual. '
        'Be culturally aware and sensitive to the target language\'s communication style.',
      );

      // Add multi-turn conversation instructions
      enhancedPrompt.writeln('\n--- Multi-Turn Conversation ---');
      enhancedPrompt.writeln(
        'Engage in natural multi-turn conversations. '
        'Ask follow-up questions, build on previous statements, '
        'and create a flowing dialogue that feels natural and engaging.',
      );

      return enhancedPrompt.toString();
    } catch (e, stackTrace) {
      debugPrint('Error in getEnhancedPrompt: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
      return basePrompt; // Fallback to base prompt
    }
  }

  /// Analyze conversation flow and suggest next state
  ConversationFlow analyzeConversationFlow({
    required List<Map<String, dynamic>> messages,
    required String currentMessage,
  }) {
    try {
      if (messages.isEmpty) {
        return ConversationFlow.greeting;
      }

      final lastUserMessage = messages.lastWhere(
        (m) => m['role'] == 'user',
        orElse: () => {'content': ''},
      )['content'] as String;

      final lowerMessage = currentMessage.toLowerCase();

      // Analyze message content to determine flow
      if (_isGreeting(lowerMessage)) {
        return ConversationFlow.greeting;
      } else if (_isIntroduction(lowerMessage)) {
        return ConversationFlow.introduction;
      } else if (_isQuestion(lowerMessage)) {
        return ConversationFlow.questionAnswer;
      } else if (_isRoleplayRequest(lowerMessage)) {
        return ConversationFlow.roleplay;
      } else if (_isWrapUp(lowerMessage)) {
        return ConversationFlow.wrapUp;
      } else {
        return ConversationFlow.topicDiscussion;
      }
    } catch (e, stackTrace) {
      debugPrint('Error analyzing conversation flow: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
      return ConversationFlow.topicDiscussion; // Default
    }
  }

  /// Generate conversation suggestions based on context
  List<String> generateConversationSuggestions({
    required String conversationId,
    required ConversationFlow flowState,
    String? currentTopic,
    String? userLevel,
  }) {
    try {
      final suggestions = <String>[];

      switch (flowState) {
        case ConversationFlow.greeting:
          suggestions.addAll([
            'Hello! How are you?',
            'Good morning!',
            'Nice to meet you!',
          ]);
          break;

        case ConversationFlow.introduction:
          suggestions.addAll([
            'My name is...',
            'I am from...',
            'I work as...',
          ]);
          break;

        case ConversationFlow.topicDiscussion:
          if (currentTopic != null) {
            suggestions.addAll([
              'Tell me more about $currentTopic',
              'What do you think about $currentTopic?',
              'I find $currentTopic interesting because...',
            ]);
          } else {
            suggestions.addAll([
              'What is your favorite food?',
              'Tell me about your culture',
              'What do you like to do for fun?',
            ]);
          }
          break;

        case ConversationFlow.questionAnswer:
          suggestions.addAll([
            'Can you explain...?',
            'What does... mean?',
            'How do you say...?',
          ]);
          break;

        case ConversationFlow.roleplay:
          suggestions.addAll([
            'Let\'s practice ordering food',
            'Can we roleplay a job interview?',
            'Let\'s practice asking for directions',
          ]);
          break;

        case ConversationFlow.wrapUp:
          suggestions.addAll([
            'Thank you for the conversation',
            'I learned a lot today',
            'Let\'s talk again soon',
          ]);
          break;
      }

      // Add level-appropriate suggestions
      if (userLevel == 'beginner') {
        suggestions.addAll([
          'Can you speak slower?',
          'Can you repeat that?',
          'I don\'t understand',
        ]);
      } else if (userLevel == 'advanced') {
        suggestions.addAll([
          'Let\'s discuss more complex topics',
          'Can you use more advanced vocabulary?',
          'I want to practice formal language',
        ]);
      }

      return suggestions.take(5).toList(); // Return top 5 suggestions
    } catch (e, stackTrace) {
      debugPrint('Error generating suggestions: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Track conversation context
  void updateConversationContext({
    required String conversationId,
    required Map<String, dynamic> context,
  }) {
    final conversationContext = _conversationContexts[conversationId] ?? ConversationContext();
    conversationContext.update(context);
    _conversationContexts[conversationId] = conversationContext;
  }

  /// Get conversation context
  ConversationContext? getConversationContext(String conversationId) {
    return _conversationContexts[conversationId];
  }

  /// Clear conversation context
  void clearConversationContext(String conversationId) {
    _conversationContexts.remove(conversationId);
  }

  // Helper methods for flow analysis
  bool _isGreeting(String message) {
    final greetings = ['hello', 'hi', 'greetings', 'good morning', 'good evening', 'hey'];
    return greetings.any((g) => message.contains(g));
  }

  bool _isIntroduction(String message) {
    final introKeywords = ['name', 'introduce', 'who are you', 'tell me about yourself'];
    return introKeywords.any((k) => message.contains(k));
  }

  bool _isQuestion(String message) {
    return message.contains('?') ||
        message.startsWith('what') ||
        message.startsWith('how') ||
        message.startsWith('why') ||
        message.startsWith('when') ||
        message.startsWith('where') ||
        message.startsWith('who');
  }

  bool _isRoleplayRequest(String message) {
    final roleplayKeywords = ['roleplay', 'role play', 'practice', 'scenario', 'pretend'];
    return roleplayKeywords.any((k) => message.contains(k));
  }

  bool _isWrapUp(String message) {
    final wrapUpKeywords = ['goodbye', 'bye', 'thank you', 'thanks', 'see you', 'later'];
    return wrapUpKeywords.any((k) => message.contains(k));
  }
}

/// Conversation context model
class ConversationContext {
  String? currentTopic;
  String? userLevel;
  List<String> topics = [];
  Map<String, dynamic> metadata = {};
  DateTime? lastUpdated;

  void update(Map<String, dynamic> context) {
    if (context['topic'] != null) currentTopic = context['topic'] as String;
    if (context['user_level'] != null) userLevel = context['user_level'] as String;
    if (context['topics'] != null) {
      topics = List<String>.from(context['topics'] ?? []);
    }
    if (context['metadata'] != null) {
      metadata = Map<String, dynamic>.from(context['metadata'] ?? {});
    }
    lastUpdated = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'current_topic': currentTopic,
      'user_level': userLevel,
      'topics': topics,
      'metadata': metadata,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

