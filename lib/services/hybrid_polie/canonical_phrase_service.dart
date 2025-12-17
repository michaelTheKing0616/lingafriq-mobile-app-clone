/// Canonical Phrase Service using AfriTeVa/AfriT5
/// Generates orthographically correct phrases with proper diacritics
/// Uses backend API with fallback to HuggingFace Inference API

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../utils/api.dart';
import '../../utils/supported_languages.dart';
import '../env_config.dart';
import 'cache_service.dart';

class CanonicalPhraseService {
  final Dio _dio = Dio();
  
  // HuggingFace Inference API URL for AfriTeVa
  static const String _hfAfritevaUrl = "https://api-inference.huggingface.co/models/castorini/afriteva_v2_large";
  
  /// Generate canonical phrase using AfriTeVa (with caching)
  /// Priority: 1. Cache → 2. Backend API → 3. HuggingFace API → 4. Fallback
  Future<CanonicalPhraseResult> generateCanonical({
    required String phrase,
    required String language,
    String? hfToken,
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
      debugPrint('Backend canonical generation failed, trying HuggingFace: $e');
    }
    
    // Fallback to HuggingFace Inference API
    try {
      final effectiveToken = hfToken ?? EnvConfig.huggingFaceToken;
      
      if (effectiveToken.isEmpty) {
        debugPrint('⚠️ HuggingFace token not configured for canonical generation');
        return _fallbackResult(phrase, language);
      }
      
      final response = await _dio.post(
        _hfAfritevaUrl,
        data: jsonEncode({
          'inputs': 'Generate canonical form: $phrase',
          'parameters': {
            'lang': language,
          },
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $effectiveToken',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        String canonical = phrase;
        
        if (data is List && data.isNotEmpty) {
          canonical = data[0]['generated_text'] ?? phrase;
        } else if (data is Map && data.containsKey('generated_text')) {
          canonical = data['generated_text'];
        }
        
        final result = CanonicalPhraseResult(
          canonicalText: canonical,
          originalText: phrase,
          language: language,
          model: 'AfriTeVa-HF',
          confidence: 0.8,
        );
        
        // Cache the result
        if (useCache && canonical.isNotEmpty && canonical != phrase) {
          await HybridPolieCache.cacheCanonical(
            phrase: phrase,
            language: language,
            result: canonical,
          );
        }
        
        return result;
      }
      
      return _fallbackResult(phrase, language);
    } catch (e) {
      debugPrint('HuggingFace canonical generation failed: $e');
      return _fallbackResult(phrase, language, error: e.toString());
    }
  }
  
  /// Generate canonical phrase via backend API
  Future<CanonicalPhraseResult?> _generateViaBackend({
    required String phrase,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        '${Api.baseurl}hybrid-polie/canonical',
        data: {
          'phrase': phrase,
          'language': language,
        },
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
  
  CanonicalPhraseResult _fallbackResult(String phrase, String language, {String? error}) {
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
    String? hfToken,
  }) async {
    final results = <CanonicalPhraseResult>[];
    
    for (final phrase in phrases) {
      final result = await generateCanonical(
        phrase: phrase,
        language: language,
        hfToken: hfToken,
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
