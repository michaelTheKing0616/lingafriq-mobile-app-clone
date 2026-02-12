/// Conversation Practice Service
/// Manages conversation practice sessions with context and personality
/// 
/// Features:
/// - Multi-turn conversations
/// - Context retention
/// - Personality consistency
/// - Dialogue flow generation

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../models/lesson_item_model.dart';
import '../../providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';
import '../../core/network/api_client_with_recovery.dart';
import 'conversation_context_manager.dart';
import 'dialogue_flow_generator.dart';

/// Conversation practice session
class ConversationSession {
  final String id;
  final String languageCode;
  final String level;
  final String? personality;
  final ConversationContext context;
  final DateTime startedAt;
  int messageCount;

  ConversationSession({
    required this.id,
    required this.languageCode,
    required this.level,
    this.personality,
    required this.context,
    required this.startedAt,
    this.messageCount = 0,
  });
}

/// Conversation Practice Service
class ConversationPracticeService {
  final Dio _dio;
  final ConversationContextManager _contextManager = ConversationContextManager();
  final DialogueFlowGenerator _dialogueGenerator = DialogueFlowGenerator();
  final Map<String, ConversationSession> _activeSessions = {};

  ConversationPracticeService(this._dio);

  /// Start a new conversation session
  Future<ConversationSession> startSession({
    required String languageCode,
    required String level,
    String? personality,
    Map<String, dynamic>? userProfile,
    DialogueFlowType? flowType,
  }) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final context = _contextManager.getOrCreateContext(
      conversationId: sessionId,
      languageCode: languageCode,
      personality: personality,
      userProfile: userProfile,
    );

    final session = ConversationSession(
      id: sessionId,
      languageCode: languageCode,
      level: level,
      personality: personality,
      context: context,
      startedAt: DateTime.now(),
    );

    _activeSessions[sessionId] = session;

    if (flowType != null) {
      final flow = await _dialogueGenerator.generateDialogueFlow(
        type: flowType,
        languageCode: languageCode,
        level: level,
      );

      for (final turn in flow.turns) {
        _contextManager.addMessage(
          conversationId: sessionId,
          role: turn.speaker,
          content: turn.text,
          metadata: {
            'translation': turn.translation,
            'ipa': turn.ipa,
            'tone_pattern': turn.tonePattern,
          },
        );
      }
    }

    return session;
  }

  /// Send a message in conversation
  Future<String> sendMessage({
    required String sessionId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw Exception('Session not found');
    }

    _contextManager.addMessage(
      conversationId: sessionId,
      role: 'user',
      content: message,
      metadata: metadata,
    );

    session.messageCount++;

    try {
      final client = ApiClientWithRecovery(_dio);
      final prompt = _contextManager.buildContextualPrompt(
        conversationId: sessionId,
        userMessage: message,
      );

      final response = await client.post<Map<String, dynamic>>(
        ApiContract.url(ApiContract.ai.aiChat),
        data: {
          'message': prompt,
          'language': session.languageCode,
          'level': session.level,
          'conversation_id': sessionId,
          'personality': session.personality,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final aiResponse = response.data!['response'] as String? ?? 
            response.data!['message'] as String? ?? '';

        _contextManager.addMessage(
          conversationId: sessionId,
          role: 'assistant',
          content: aiResponse,
        );

        return aiResponse;
      } else {
        throw Exception('Failed to get AI response');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      final fallbackResponse = _generateFallbackResponse(session, message);
      _contextManager.addMessage(
        conversationId: sessionId,
        role: 'assistant',
        content: fallbackResponse,
      );

      return fallbackResponse;
    }
  }

  /// Generate dialogue flow for practice
  Future<DialogueFlow> generateDialogueFlow({
    required String sessionId,
    required DialogueFlowType type,
    String? topic,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw Exception('Session not found');
    }

    final existingContext = session.context.conversationState;

    final flow = await _dialogueGenerator.generateDialogueFlow(
      type: type,
      languageCode: session.languageCode,
      level: session.level,
      topic: topic,
      existingContext: existingContext,
    );

    for (final turn in flow.turns) {
      _contextManager.addMessage(
        conversationId: sessionId,
        role: turn.speaker,
        content: turn.text,
        metadata: {
          'translation': turn.translation,
          'ipa': turn.ipa,
          'tone_pattern': turn.tonePattern,
          'cultural_note': turn.culturalNote,
        },
      );
    }

    return flow;
  }

  /// Get conversation history
  List<Map<String, dynamic>> getConversationHistory(String sessionId, {int? limit}) {
    return _contextManager.getConversationHistory(sessionId, limit: limit);
  }

  /// Update conversation state
  void updateState({
    required String sessionId,
    required String key,
    required dynamic value,
  }) {
    _contextManager.updateState(
      conversationId: sessionId,
      key: key,
      value: value,
    );
  }

  /// Check personality consistency
  bool checkPersonalityConsistency(String sessionId) {
    return _contextManager.checkPersonalityConsistency(sessionId);
  }

  /// End conversation session
  void endSession(String sessionId) {
    _activeSessions.remove(sessionId);
    _contextManager.clearContext(sessionId);
  }

  /// Get active session
  ConversationSession? getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  String _generateFallbackResponse(ConversationSession session, String userMessage) {
    final greetings = {
      'yo': 'Ẹ káàbọ̀! Báwo ni?',
      'ig': 'Nnọọ! Kedu ka ị mere?',
      'sw': 'Karibu! Habari yako?',
      'ha': 'Barka da zuwa! Yaya kake?',
      'am': 'እንኳን ደህና መጡ! እንዴት ነዎት?',
    };

    if (userMessage.toLowerCase().contains('hello') || 
        userMessage.toLowerCase().contains('hi')) {
      return greetings[session.languageCode] ?? 'Hello! How can I help you?';
    }

    return 'I understand. Please continue.';
  }
}

