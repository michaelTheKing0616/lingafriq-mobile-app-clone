/// Canonical Phrase Service using AfriTeVa/AfriT5
/// Generates orthographically correct phrases with proper diacritics

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../utils/supported_languages.dart';
import 'cache_service.dart';

class CanonicalPhraseService {
  final Dio _dio = Dio();
  static const String AFRITEVA_URL = "http://localhost:5050/afrit5"; // Local service
  static const String HF_AFRITEVA = "https://api-inference.huggingface.co/models/castorini/afriteva_v2_large";
  
  /// Generate canonical phrase using AfriTeVa (with caching)
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
    try {
      // Try local service first
      try {
        final response = await _dio.post(
          AFRITEVA_URL,
          data: jsonEncode({
            'text': phrase,
            'lang': language,
          }),
          options: Options(
            contentType: 'application/json',
            receiveTimeout: const Duration(seconds: 15),
          ),
        );
        
        if (response.statusCode == 200) {
          final output = response.data['output'] ?? phrase;
          final result = CanonicalPhraseResult(
            canonicalText: output,
            originalText: phrase,
            language: language,
            model: 'AfriTeVa-local',
            confidence: 0.85,
          );
          
          // Cache the result
          if (useCache && output.isNotEmpty) {
            await HybridPolieCache.cacheCanonical(
              phrase: phrase,
              language: language,
              result: output,
            );
          }
          
          return result;
        }
      } catch (e) {
        // Fall through to HF API
      }
      
      // Fallback to HuggingFace Inference API
      if (hfToken != null) {
        final headers = {
          'Authorization': 'Bearer $hfToken',
          'Content-Type': 'application/json',
        };
        
        final payload = {
          'inputs': 'Generate canonical form: $phrase',
          'parameters': {
            'lang': language,
          },
        };
        
        final response = await _dio.post(
          HF_AFRITEVA,
          data: jsonEncode(payload),
          options: Options(
            headers: headers,
            contentType: 'application/json',
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
          
          return CanonicalPhraseResult(
            canonicalText: canonical,
            originalText: phrase,
            language: language,
            model: 'AfriTeVa-HF',
            confidence: 0.8,
          );
        }
      }
      
      // Ultimate fallback: return original (will be corrected by diacritics module)
      return CanonicalPhraseResult(
        canonicalText: phrase,
        originalText: phrase,
        language: language,
        model: 'fallback',
        confidence: 0.5,
      );
    } catch (e) {
      return CanonicalPhraseResult(
        canonicalText: phrase,
        originalText: phrase,
        language: language,
        model: 'fallback',
        confidence: 0.3,
        error: e.toString(),
      );
    }
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

