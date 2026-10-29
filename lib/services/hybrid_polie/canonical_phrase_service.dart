// Canonical Phrase Service using AfriTeVa/AfriT5
// Generates orthographically correct phrases with proper diacritics
// Uses backend API with fallback to HuggingFace Inference API

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'cache_service.dart';

class CanonicalPhraseService {
  final Dio _dio = Dio();

  /// Hugging Face model: AfriTeVa v2 for canonical phrase generation.

  /// Generate canonical phrase using AfriTeVa (with caching)
  /// Priority: 1. Cache → 2. Backend API → 3. Fallback
  Future<CanonicalPhraseResult> generateCanonical({
    required String phrase,
    required String language,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cached = await HybridPolieCache.getCachedCanonical(
        phrase: phrase,
        language: language,
      );
      if (cached != null) {
        return CanonicalPhraseResult(
          canonicalText: cached,
          originalText: phrase,
          language: language,
          model: 'AfriTeVa-cached',
          confidence: 0.85,
        );
      }
    }

    // Try backend API first
    try {
      final backendResult = await _generateViaBackend(
        phrase: phrase,
        language: language,
      );
      if (backendResult != null) {
        // Cache successful result
        if (useCache && backendResult.canonicalText.isNotEmpty) {
          await HybridPolieCache.cacheCanonical(
            phrase: phrase,
            language: language,
            result: backendResult.canonicalText,
          );
        }
        return backendResult;
      }
    } catch (e) {
      debugPrint('Backend canonical generation failed, using fallback: $e');
    }

    return _fallbackResult(phrase, language);
  }

  /// Generate canonical phrase via backend API
  Future<CanonicalPhraseResult?> _generateViaBackend({
    required String phrase,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.ai.hybridCanonical),
        data: {'phrase': phrase, 'language': language},
        options: Options(
          contentType: 'application/json',
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return CanonicalPhraseResult(
          canonicalText: data['canonicalText'] ?? phrase,
          originalText: phrase,
          language: language,
          model: data['model'] ?? 'AfriTeVa-backend',
          confidence: (data['confidence'] ?? 0.85).toDouble(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Backend canonical generation error: $e');
      return null;
    }
  }

  CanonicalPhraseResult _fallbackResult(
    String phrase,
    String language, {
    String? error,
  }) {
    return CanonicalPhraseResult(
      canonicalText: phrase,
      originalText: phrase,
      language: language,
      model: 'fallback',
      confidence: 0.5,
      error: error,
    );
  }

  /// Batch generate canonical phrases
  Future<List<CanonicalPhraseResult>> generateBatch({
    required List<String> phrases,
    required String language,
  }) async {
    final results = <CanonicalPhraseResult>[];

    for (final phrase in phrases) {
      final result = await generateCanonical(
        phrase: phrase,
        language: language,
      );
      results.add(result);

      // Rate limiting
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return results;
  }
}

class CanonicalPhraseResult {
  final String canonicalText;
  final String originalText;
  final String language;
  final String model;
  final double confidence;
  final String? error;

  CanonicalPhraseResult({
    required this.canonicalText,
    required this.originalText,
    required this.language,
    required this.model,
    required this.confidence,
    this.error,
  });
}
