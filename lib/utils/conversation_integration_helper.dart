import 'package:flutter/material.dart';
import 'package:lingafriq/services/ai/conversation_context_manager.dart';
import 'package:lingafriq/services/ai/conversation_practice_enhancer.dart';
import 'package:lingafriq/services/error/error_recovery_service.dart';
import 'package:lingafriq/utils/integration_helpers.dart';

/// Helper class for integrating conversation enhancements
/// Simplifies integration of context management and practice enhancement
class ConversationIntegrationHelper {
  static final ConversationContextManager _contextManager = ConversationContextManager();
  static final ConversationPracticeEnhancer _practiceEnhancer = ConversationPracticeEnhancer();
  static final ErrorRecoveryService _errorRecovery = ErrorRecoveryService();

  /// Get enhanced conversation context with intelligent management
  static Future<List<Map<String, dynamic>>> getEnhancedContext({
    required String conversationId,
    required List<Map<String, dynamic>> currentMessages,
    required String systemPrompt,
    int? maxTokens,
  }) async {
    return await safeAsync(
      operation: () => _contextManager.getConversationContext(
        conversationId: conversationId,
        currentMessages: currentMessages,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
      ),
      defaultValue: [
        if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
        ...currentMessages,
      ],
    );
  }

  /// Get enhanced prompt with conversation practice features
  static String getEnhancedPrompt({
    required String conversationId,
    required ConversationPracticeEnhancer.ConversationFlow flowState,
    required String basePrompt,
    String? currentTopic,
    String? userLevel,
    Map<String, dynamic>? previousContext,
  }) {
    return _practiceEnhancer.getEnhancedPrompt(
      conversationId: conversationId,
      flowState: flowState,
      basePrompt: basePrompt,
      currentTopic: currentTopic,
      userLevel: userLevel,
      previousContext: previousContext,
    );
  }

  /// Analyze conversation flow
  static ConversationPracticeEnhancer.ConversationFlow analyzeFlow({
    required List<Map<String, dynamic>> messages,
    required String currentMessage,
  }) {
    return _practiceEnhancer.analyzeConversationFlow(
      messages: messages,
      currentMessage: currentMessage,
    );
  }

  /// Get conversation suggestions
  static List<String> getSuggestions({
    required String conversationId,
    required ConversationPracticeEnhancer.ConversationFlow flowState,
    String? currentTopic,
    String? userLevel,
  }) {
    return _practiceEnhancer.generateConversationSuggestions(
      conversationId: conversationId,
      flowState: flowState,
      currentTopic: currentTopic,
      userLevel: userLevel,
    );
  }

  /// Execute operation with error recovery
  static Future<T> executeWithRecovery<T>({
    required Future<T> Function() operation,
    int? maxRetries,
    T? fallbackValue,
    String? operationName,
  }) async {
    return await _errorRecovery.executeWithRecovery(
      operation: operation,
      maxRetries: maxRetries,
      fallbackValue: fallbackValue,
      operationName: operationName,
    );
  }

  /// Save conversation context
  static Future<void> saveContext({
    required String conversationId,
    required List<Map<String, dynamic>> messages,
  }) async {
    await safeAsync(
      operation: () => _contextManager.saveConversationContext(
        conversationId: conversationId,
        messages: messages,
      ),
    );
  }

  /// Clear conversation context
  static Future<void> clearContext(String conversationId) async {
    await safeAsync(
      operation: () => _contextManager.clearConversationContext(conversationId),
    );
  }

  /// Get conversation insights
  static Map<String, dynamic> getInsights(String conversationId) {
    return _contextManager.getConversationInsights(conversationId);
  }
}

