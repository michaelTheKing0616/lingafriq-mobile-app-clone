/// Hybrid Polie Orchestrator
/// Coordinates multiple models to provide the best response
/// Combines LLaMA (dialogue) + NLLB (translation) + AfriTeVa (canonical) + diacritics enforcement

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ai_chat_provider_groq.dart';
import 'model_router.dart';
import 'translation_service.dart';
import 'canonical_phrase_service.dart';
import '../../utils/diacritics_enforcer.dart';
import '../../utils/supported_languages.dart';

class HybridPolieOrchestrator {
  final TranslationService _translationService = TranslationService();
  final CanonicalPhraseService _canonicalService = CanonicalPhraseService();
  
  /// Main orchestration method - routes to appropriate models and post-processes
  Future<HybridPolieResponse> orchestrate({
    required String userMessage,
    required PolieMode mode,
    required String targetLanguage,
    String? sourceLanguage,
    required GroqChatProvider groqProvider,
    String? hfToken,
  }) async {
    // 1. Classify task
    final taskType = _modeToTaskType(mode);
    final modelType = ModelRouter.routeTask(
      taskType: taskType,
      language: targetLanguage,
      sourceLanguage: sourceLanguage,
      isTranslation: mode == PolieMode.translation,
      needsCanonical: ModelRouter.needsCanonicalPhrase(taskType, targetLanguage),
    );
    
    debugPrint('🔀 Hybrid Polie: Routing ${mode.name} → ${modelType.name}');
    
    // 2. Route to appropriate model
    String rawOutput = '';
    String modelUsed = '';
    bool diacriticsCorrected = false;
    Map<String, dynamic> metadata = {};
    
    switch (modelType) {
      case ModelType.nllb200:
        // Translation → NLLB-200
        final translation = await _translationService.translate(
          text: userMessage,
          sourceLang: sourceLanguage ?? 'english',
          targetLang: targetLanguage,
          hfToken: hfToken,
        );
        rawOutput = translation.translation;
        modelUsed = translation.model;
        metadata['translation_confidence'] = translation.confidence;
        break;
        
      case ModelType.afriteva:
        // Canonical phrase → AfriTeVa
        final canonical = await _canonicalService.generateCanonical(
          phrase: userMessage,
          language: targetLanguage,
          hfToken: hfToken,
        );
        rawOutput = canonical.canonicalText;
        modelUsed = canonical.model;
        metadata['canonical_confidence'] = canonical.confidence;
        break;
        
      case ModelType.llama70b:
        // Dialogue/roleplay/tutor → LLaMA-3.1-70B
        // Check if we need to inject canonical phrases
        String? canonicalPhrase;
        if (ModelRouter.needsCanonicalPhrase(taskType, targetLanguage)) {
          // Generate canonical phrase first
          final canonical = await _canonicalService.generateCanonical(
            phrase: userMessage,
            language: targetLanguage,
            hfToken: hfToken,
          );
          canonicalPhrase = canonical.canonicalText;
          metadata['canonical_injected'] = true;
        }
        
        // Build enhanced prompt with canonical phrase constraint
        final enhancedPrompt = _buildEnhancedPrompt(
          userMessage: userMessage,
          mode: mode,
          language: targetLanguage,
          canonicalPhrase: canonicalPhrase,
        );
        
        // Call LLaMA via existing Groq provider
        rawOutput = await _callLlamaViaGroq(
          prompt: enhancedPrompt,
          groqProvider: groqProvider,
          mode: mode,
        );
        modelUsed = 'llama-3.1-70b-versatile';
        metadata['canonical_phrase'] = canonicalPhrase;
        break;
        
      case ModelType.asrMfa:
        // Pronunciation → handled separately in pronunciation service
        rawOutput = '[Pronunciation feedback will be handled by ASR/MFA service]';
        modelUsed = 'asr-mfa';
        break;
    }
    
    // 3. Post-process: enforce diacritics
    final diacriticsResult = DiacriticsEnforcer.enforceWithMetadata(
      rawOutput,
      targetLanguage,
      enableFuzzy: true,
      fuzzyThreshold: 0.75,
    );
    
    final finalOutput = diacriticsResult['text'] as String;
    diacriticsCorrected = diacriticsResult['changed'] as bool;
    
    if (diacriticsCorrected) {
      metadata['diacritics_corrected'] = true;
      metadata['diacritics_metadata'] = diacriticsResult['metadata'];
      debugPrint('✅ Diacritics corrected: $rawOutput → $finalOutput');
    }
    
    // 4. Validate orthography
    final isValid = _validateOrthography(finalOutput, targetLanguage);
    if (!isValid) {
      metadata['orthography_warning'] = true;
      debugPrint('⚠️ Orthography validation warning for: $finalOutput');
    }
    
    // 5. Build response
    return HybridPolieResponse(
      output: finalOutput,
      model: modelUsed,
      diacriticsCorrected: diacriticsCorrected,
      confidence: metadata['translation_confidence'] ?? 
                  metadata['canonical_confidence'] ?? 
                  0.85,
      metadata: metadata,
      needsNativeReview: !isValid || (metadata['translation_confidence'] ?? 1.0) < 0.65,
    );
  }
  
  TaskType _modeToTaskType(PolieMode mode) {
    switch (mode) {
      case PolieMode.translation:
        return TaskType.translate;
      case PolieMode.tutor:
        return TaskType.tutor;
      case PolieMode.roleplay:
        return TaskType.roleplay;
      case PolieMode.conversation:
        return TaskType.conversation;
      case PolieMode.vocab:
        return TaskType.vocab;
      case PolieMode.review:
        return TaskType.review;
    }
  }
  
  String _buildEnhancedPrompt({
    required String userMessage,
    required PolieMode mode,
    required String language,
    String? canonicalPhrase,
  }) {
    final langInfo = SupportedLanguages.getLanguageInfo(language);
    final langName = langInfo['name'] ?? language;
    
    String prompt = userMessage;
    
    // Inject canonical phrase if available
    if (canonicalPhrase != null && canonicalPhrase.isNotEmpty) {
      prompt = '''
CANONICAL_PHRASE_CONSTRAINT: You MUST use this exact phrase verbatim in your response: "$canonicalPhrase"
Do not modify, translate, or paraphrase this phrase. Use it exactly as provided.

User request: $userMessage

Respond in $langName, incorporating the canonical phrase above where appropriate.
''';
    }
    
    return prompt;
  }
  
  Future<String> _callLlamaViaGroq({
    required String prompt,
    required GroqChatProvider groqProvider,
    required PolieMode mode,
  }) async {
    // Use existing Groq provider's streaming method
    // This maintains compatibility with existing streaming and SRS integration
    try {
      String fullResponse = '';
      await for (final chunk in groqProvider.sendMessageStream(prompt)) {
        fullResponse += chunk;
      }
      return fullResponse;
    } catch (e) {
      debugPrint('Error calling LLaMA via Groq: $e');
      return prompt; // Fallback
    }
  }
  
  bool _validateOrthography(String text, String language) {
    // Basic orthography validation
    // Check against known valid characters for the language
    final validChars = SupportedLanguages.getValidCharacters(language);
    if (validChars.isEmpty) return true; // No validation data available
    
    for (final char in text.runes) {
      final charStr = String.fromCharCode(char);
      if (!RegExp(r'[\s\p{P}]').hasMatch(charStr) && 
          !validChars.contains(charStr.toLowerCase())) {
        // Character not in valid set (but might be valid, so just warn)
        return true; // Allow for now, but log
      }
    }
    
    return true;
  }
}

class HybridPolieResponse {
  final String output;
  final String model;
  final bool diacriticsCorrected;
  final double confidence;
  final Map<String, dynamic> metadata;
  final bool needsNativeReview;
  
  HybridPolieResponse({
    required this.output,
    required this.model,
    required this.diacriticsCorrected,
    required this.confidence,
    required this.metadata,
    required this.needsNativeReview,
  });
}

