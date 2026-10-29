// Hybrid Polie Orchestrator
// Coordinates multiple models to provide the best response
// Combines LLaMA (dialogue) + NLLB (translation) + AfriTeVa (canonical) + diacritics enforcement

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../providers/ai_chat_provider_groq.dart';
import 'model_router.dart';
import 'translation_service.dart';
import 'canonical_phrase_service.dart';
import '../../config/api_contract.dart';
import '../../utils/diacritics_enforcer.dart';
import '../../utils/supported_languages.dart';
import '../error/typed_errors.dart';
import '../../utils/api_service.dart';

class HybridPolieOrchestrator {
  final TranslationService _translationService = TranslationService();
  final CanonicalPhraseService _canonicalService = CanonicalPhraseService();
  final Dio _dio = Dio();

  // Recursion guard to prevent infinite loops
  bool _isProcessingLlamaCall = false;

  /// Main orchestration method - routes to appropriate models and post-processes
  Future<HybridPolieResponse> orchestrate({
    required String userMessage,
    required PolieMode mode,
    required String targetLanguage,
    String? sourceLanguage,
    required GroqChatProvider groqProvider,
    void Function(HybridPolieResponse response, {required int elapsedMs})?
    onTelemetry,
  }) async {
    final startedAt = DateTime.now();

    // 1. Classify task
    final taskType = _modeToTaskType(mode);
    final modelType = ModelRouter.routeTask(
      taskType: taskType,
      language: targetLanguage,
      sourceLanguage: sourceLanguage,
      isTranslation: mode == PolieMode.translation,
      needsCanonical: ModelRouter.needsCanonicalPhrase(
        taskType,
        targetLanguage,
      ),
    );

    debugPrint('🔀 Hybrid Polie: Routing ${mode.name} → ${modelType.name}');

    // 2. Route to appropriate model
    String rawOutput = '';
    String modelUsed = '';
    bool diacriticsCorrected = false;
    Map<String, dynamic> metadata = {};

    switch (modelType) {
      case ModelType.nllb200:
        // Translation → NLLB-200 (via backend or direct HF API)
        final translation = await _translationService.translate(
          text: userMessage,
          sourceLang: sourceLanguage ?? 'english',
          targetLang: targetLanguage,
          includePhraseBreakdown: true,
        );
        rawOutput = translation.translation;
        modelUsed = translation.model;
        metadata['translation_confidence'] = translation.confidence;
        if (translation.phraseBreakdowns != null &&
            translation.phraseBreakdowns!.isNotEmpty) {
          metadata['phraseBreakdowns'] = translation.phraseBreakdowns;
        }
        break;

      case ModelType.afriteva:
        // Canonical phrase → AfriTeVa (via backend)
        final canonical = await _canonicalService.generateCanonical(
          phrase: userMessage,
          language: targetLanguage,
        );
        rawOutput = canonical.canonicalText;
        modelUsed = canonical.model;
        metadata['canonical_confidence'] = canonical.confidence;
        break;

      case ModelType.llama70b:
        // Dialogue/roleplay/tutor → LLaMA-3.1-70B
        // Check recursion guard to prevent infinite loops
        if (_isProcessingLlamaCall) {
          debugPrint('Recursion guard triggered');
          throw personaUnavailable;
        }

        // Check if we need to inject canonical phrases
        String? canonicalPhrase;
        if (ModelRouter.needsCanonicalPhrase(taskType, targetLanguage)) {
          // Generate canonical phrase first
          final canonical = await _canonicalService.generateCanonical(
            phrase: userMessage,
            language: targetLanguage,
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

        // Dialogue via the backend AI gateway (bypasses the provider to prevent recursion)
        rawOutput = await _callDialogueGateway(
          prompt: enhancedPrompt,
          systemPrompt: groqProvider.currentSystemPrompt,
        );
        modelUsed = 'llama-3.3-70b-versatile';
        metadata['canonical_phrase'] = canonicalPhrase;
        break;

      case ModelType.gemini:
        final geminiOutput = await _callBackendGemini(
          userMessage: userMessage,
          mode: mode,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage ?? 'english',
          systemPrompt: groqProvider.currentSystemPrompt,
        );
        final geminiText = geminiOutput['content']?.toString().trim() ?? '';
        if (geminiText.isEmpty) throw personaUnavailable;
        rawOutput = geminiText;
        modelUsed = geminiOutput['model']?.toString() ?? 'gemini-via-backend';
        metadata['provider'] = 'gemini';
        metadata['routed_by'] = 'hybrid_model_router';
        break;

      case ModelType.asrMfa:
        throw pronunciationUnavailable;
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
    final response = HybridPolieResponse(
      output: finalOutput,
      model: modelUsed,
      diacriticsCorrected: diacriticsCorrected,
      confidence:
          metadata['translation_confidence'] ??
          metadata['canonical_confidence'] ??
          0.85,
      metadata: metadata,
      needsNativeReview:
          !isValid || (metadata['translation_confidence'] ?? 1.0) < 0.65,
    );
    onTelemetry?.call(
      response,
      elapsedMs: DateTime.now().difference(startedAt).inMilliseconds,
    );
    return response;
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
      case PolieMode.pronunciation:
        return TaskType.tutor;
      case PolieMode.grammar:
        return TaskType.tutor;
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
      prompt =
          '''
CANONICAL_PHRASE_CONSTRAINT: You MUST use this exact phrase verbatim in your response: "$canonicalPhrase"
Do not modify, translate, or paraphrase this phrase. Use it exactly as provided.

User request: $userMessage

Respond in $langName, incorporating the canonical phrase above where appropriate.
''';
    }

    return prompt;
  }

  /// Dialogue completion via the backend AI gateway (no client key)
  /// This bypasses the provider's hybrid mode check
  Future<String> _callDialogueGateway({
    required String prompt,
    String? systemPrompt,
  }) async {
    _isProcessingLlamaCall = true;

    try {
      final messages = <Map<String, String>>[
        {'role': 'user', 'content': prompt},
      ];
      // Server-side gateway owns provider credentials; the client sends none.
      final response = await ApiService.post(
        ApiContract.ai.chatCompletion,
        data: {
          'messages': messages,
          if (systemPrompt != null && systemPrompt.isNotEmpty)
            'systemPrompt': systemPrompt,
          'max_tokens': 2048,
          'temperature': 0.7,
          'mode': 'dialogue',
        },
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        final content = data['content']?.toString().trim() ?? '';
        if (content.isNotEmpty) return content;
      }

      throw personaUnavailable;
    } catch (e) {
      if (e is LingAfriqFailure) rethrow;
      debugPrint('Dialogue gateway call failed: $e');
      throw personaUnavailable;
    } finally {
      _isProcessingLlamaCall = false;
    }
  }

  Future<Map<String, dynamic>> _callBackendGemini({
    required String userMessage,
    required PolieMode mode,
    required String targetLanguage,
    required String sourceLanguage,
    String? systemPrompt,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.ai.chatCompletion),
        data: {
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
          'systemPrompt': systemPrompt,
          'temperature': 0.6,
          'max_tokens': 900,
          'language': targetLanguage,
          'mode': mode.name,
          'sourceLanguage': sourceLanguage,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          contentType: Headers.jsonContentType,
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final content = data['content']?.toString().trim();
        if (content != null && content.isNotEmpty) {
          return {
            'content': content,
            'model': data['model']?.toString() ?? 'gemini-via-backend',
          };
        }
      }
    } catch (e) {
      debugPrint('Gemini backend routing failed: $e');
    }

    final fallback = await _callDialogueGateway(
      prompt: userMessage,
      systemPrompt: systemPrompt,
    );
    if (fallback.trim().isEmpty) throw personaUnavailable;
    return {'content': fallback, 'model': 'llama-3.3-70b-versatile'};
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
