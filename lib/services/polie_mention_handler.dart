// Polie Mention Handler Service
// Detects @Polie mentions in chat messages and triggers AI assistance
// 
// Features:
// - Case-insensitive @Polie detection
// - Extracts query text after mention
// - Provides inline AI responses in chat
// - Supports multiple mention patterns (@polie, @Polie, @POLIE)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/ai_chat_provider_groq.dart';
import 'hybrid_polie/translation_service.dart';

/// Provider for Polie mention handler
final polieMentionHandlerProvider = Provider<PolieMentionHandler>((ref) {
  return PolieMentionHandler(ref);
});

/// Result of processing a message for @Polie mentions
class PolieMentionResult {
  /// Whether the message contains a @Polie mention
  final bool hasMention;
  
  /// The extracted query after @Polie
  final String? query;
  
  /// The AI response (if processed)
  final String? response;
  
  /// The type of assistance requested
  final PolieAssistanceType assistanceType;
  
  /// Error message if processing failed
  final String? error;
  
  /// Processing time in milliseconds
  final int processingTimeMs;

  PolieMentionResult({
    required this.hasMention,
    this.query,
    this.response,
    this.assistanceType = PolieAssistanceType.general,
    this.error,
    this.processingTimeMs = 0,
  });

  bool get isSuccess => hasMention && response != null && error == null;
}

/// Types of assistance Polie can provide in chat
enum PolieAssistanceType {
  /// General question/conversation
  general,
  /// Translation request
  translation,
  /// Grammar explanation
  grammar,
  /// Vocabulary help
  vocabulary,
  /// Cultural context
  cultural,
  /// Pronunciation help
  pronunciation,
}

/// Handler for @Polie mentions in chat messages
class PolieMentionHandler {
  final Ref _ref;
  final TranslationService _translationService = TranslationService();
  
  /// Regex patterns for @Polie detection (case-insensitive)
  static final _mentionPatterns = [
    RegExp(r'@polie\b', caseSensitive: false),
    RegExp(r'@polié\b', caseSensitive: false), // With accent
    RegExp(r'@poli\b', caseSensitive: false),  // Common typo
  ];
  
  /// Keywords that indicate translation requests
  static const _translationKeywords = [
    'translate', 'translation', 'how do you say', 'what is', 'meaning of',
    'tumia', 'fasiri', 'itumọ', 'fassara', // African language keywords
  ];
  
  /// Keywords that indicate grammar help
  static const _grammarKeywords = [
    'grammar', 'sentence', 'structure', 'conjugate', 'tense',
    'plural', 'singular', 'verb', 'noun', 'adjective',
  ];
  
  /// Keywords that indicate cultural context
  static const _culturalKeywords = [
    'culture', 'cultural', 'tradition', 'custom', 'meaning behind',
    'when to use', 'appropriate', 'polite', 'formal', 'informal',
  ];

  PolieMentionHandler(this._ref);

  /// Check if a message contains @Polie mention
  bool hasMention(String message) {
    return _mentionPatterns.any((pattern) => pattern.hasMatch(message));
  }

  /// Extract the query text after @Polie mention
  String? extractQuery(String message) {
    for (final pattern in _mentionPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        // Get text after the mention
        final afterMention = message.substring(match.end).trim();
        
        // Also get text before the mention (for context)
        final beforeMention = message.substring(0, match.start).trim();
        
        // Combine for full context, prioritizing after-mention text
        if (afterMention.isNotEmpty) {
          return afterMention;
        } else if (beforeMention.isNotEmpty) {
          return beforeMention;
        }
      }
    }
    return null;
  }

  /// Detect the type of assistance requested
  PolieAssistanceType detectAssistanceType(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Check for translation keywords
    if (_translationKeywords.any((kw) => lowerQuery.contains(kw))) {
      return PolieAssistanceType.translation;
    }
    
    // Check for grammar keywords
    if (_grammarKeywords.any((kw) => lowerQuery.contains(kw))) {
      return PolieAssistanceType.grammar;
    }
    
    // Check for cultural keywords
    if (_culturalKeywords.any((kw) => lowerQuery.contains(kw))) {
      return PolieAssistanceType.cultural;
    }
    
    // Check for vocabulary patterns
    if (lowerQuery.contains('word') || lowerQuery.contains('vocabulary') ||
        lowerQuery.contains('mean')) {
      return PolieAssistanceType.vocabulary;
    }
    
    // Check for pronunciation
    if (lowerQuery.contains('pronounce') || lowerQuery.contains('say') ||
        lowerQuery.contains('pronunciation')) {
      return PolieAssistanceType.pronunciation;
    }
    
    return PolieAssistanceType.general;
  }

  /// Process a message for @Polie mentions and generate response
  Future<PolieMentionResult> processMessage({
    required String message,
    String? userLanguage,
    String? chatContext,
  }) async {
    final startTime = DateTime.now();
    
    // Check for mention
    if (!hasMention(message)) {
      return PolieMentionResult(
        hasMention: false,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    }
    
    // Extract query
    final query = extractQuery(message);
    if (query == null || query.isEmpty) {
      return PolieMentionResult(
        hasMention: true,
        error: 'Please provide a question after @Polie',
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    }
    
    // Detect assistance type
    final assistanceType = detectAssistanceType(query);
    
    try {
      // Get AI response based on assistance type
      final response = await _getAIResponse(
        query: query,
        assistanceType: assistanceType,
        userLanguage: userLanguage ?? 'english',
        chatContext: chatContext,
      );
      
      return PolieMentionResult(
        hasMention: true,
        query: query,
        response: response,
        assistanceType: assistanceType,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    } catch (e) {
      debugPrint('Polie mention processing error: $e');
      return PolieMentionResult(
        hasMention: true,
        query: query,
        error: 'Sorry, I could not process your request. Please try again.',
        assistanceType: assistanceType,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    }
  }

  /// Get AI response based on assistance type
  Future<String> _getAIResponse({
    required String query,
    required PolieAssistanceType assistanceType,
    required String userLanguage,
    String? chatContext,
  }) async {
    final chatProvider = _ref.read(groqChatProvider.notifier);
    
    // Build appropriate prompt based on assistance type
    String systemContext;
    String prompt;
    
    switch (assistanceType) {
      case PolieAssistanceType.translation:
        systemContext = '''You are Polie, a helpful African language learning assistant.
The user is learning $userLanguage. Provide translations with:
- Primary translation
- Alternative ways to say it
- Brief pronunciation guide
- Usage context (formal/informal)
Keep responses concise for chat format (2-3 sentences max per point).''';
        prompt = query;
        
        // Try direct translation first for simple requests
        final translationMatch = RegExp(r'(?:translate|how do you say)\s+["\x27]?(.+?)["\x27]?\s+(?:to|in|into)\s+(\w+)', 
            caseSensitive: false).firstMatch(query);
        if (translationMatch != null) {
          final textToTranslate = translationMatch.group(1)?.trim() ?? query;
          final targetLang = translationMatch.group(2)?.trim() ?? userLanguage;
          
          try {
            final result = await _translationService.translate(
              text: textToTranslate,
              sourceLang: 'english',
              targetLang: targetLang.toLowerCase(),
            );
            
            if (result.translation.isNotEmpty && result.translation != textToTranslate) {
              return '**Translation:** ${result.translation}\n\n'
                  '_Model: ${result.model} (${(result.confidence * 100).toStringAsFixed(0)}% confidence)_';
            }
          } catch (e) {
            // Fall through to LLM
          }
        }
        break;
        
      case PolieAssistanceType.grammar:
        systemContext = '''You are Polie, an expert in African language grammar.
Explain grammar concepts clearly and simply. Use examples.
Keep responses brief (3-4 bullet points max) for chat format.
The user is learning $userLanguage.''';
        prompt = query;
        break;
        
      case PolieAssistanceType.cultural:
        systemContext = '''You are Polie, a cultural guide for African languages.
Explain cultural context, usage norms, and etiquette.
Be respectful and educational. Share interesting cultural insights.
Keep responses concise for chat (3-4 sentences max).
The user is learning $userLanguage.''';
        prompt = query;
        break;
        
      case PolieAssistanceType.vocabulary:
        systemContext = '''You are Polie, a vocabulary expert for African languages.
Help users understand words, their roots, and related vocabulary.
Include synonyms and example sentences when helpful.
Keep responses brief for chat format.
The user is learning $userLanguage.''';
        prompt = query;
        break;
        
      case PolieAssistanceType.pronunciation:
        systemContext = '''You are Polie, a pronunciation coach for African languages.
Provide clear pronunciation guides using simple phonetic descriptions.
Mention tone patterns where applicable (Yoruba, Igbo, etc.).
Keep responses concise for chat.
The user is learning $userLanguage.''';
        prompt = query;
        break;
        
      case PolieAssistanceType.general:
        systemContext = '''You are Polie, a friendly African language learning assistant.
Help with any language learning questions. Be encouraging and helpful.
If the question is about a specific language, provide relevant cultural context.
Keep responses brief and conversational for chat format.
The user is learning $userLanguage.''';
        prompt = query;
    }
    
    // Add chat context if available
    if (chatContext != null && chatContext.isNotEmpty) {
      prompt = 'Context: $chatContext\n\nUser question: $prompt';
    }
    
    // Get response from AI (use systemPromptOverride instead of setSystemPrompt)
    final response = await chatProvider.sendMessage(prompt, systemPromptOverride: systemContext);
    
    return response;
  }

  /// Format the AI response for display in chat
  String formatResponseForChat(PolieMentionResult result) {
    if (!result.hasMention) {
      return '';
    }
    
    if (result.error != null) {
      return '🤖 **Polie:** ${result.error}';
    }
    
    if (result.response == null) {
      return '🤖 **Polie:** I\'m thinking...';
    }
    
    // Add type-specific emoji
    String emoji;
    switch (result.assistanceType) {
      case PolieAssistanceType.translation:
        emoji = '🌍';
        break;
      case PolieAssistanceType.grammar:
        emoji = '📚';
        break;
      case PolieAssistanceType.cultural:
        emoji = '🎭';
        break;
      case PolieAssistanceType.vocabulary:
        emoji = '📖';
        break;
      case PolieAssistanceType.pronunciation:
        emoji = '🗣️';
        break;
      case PolieAssistanceType.general:
        emoji = '🤖';
    }
    
    return '$emoji **Polie:** ${result.response}';
  }

  /// Check if a response is from Polie (for filtering in chat display)
  bool isPolieResponse(String message) {
    return message.startsWith('🤖 **Polie:') ||
           message.startsWith('🌍 **Polie:') ||
           message.startsWith('📚 **Polie:') ||
           message.startsWith('🎭 **Polie:') ||
           message.startsWith('📖 **Polie:') ||
           message.startsWith('🗣️ **Polie:');
  }
}
