/// Translation Service using NLLB-200
/// Handles high-quality translation between English and African languages
/// Uses backend API with fallback to HuggingFace Inference API

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/url_constants.dart';
import '../../utils/api.dart';
import '../../utils/supported_languages.dart';
import '../env_config.dart';
import 'cache_service.dart';

class TranslationService {
  final Dio _dio = Dio();

  /// Hugging Face model: NLLB-200 for translation.
  static String get _hfNllbUrl =>
      UrlConstants.huggingFaceModel('facebook/nllb-200-distilled-600M');
  
  /// Translate text using NLLB-200 (with caching)
  /// Priority: 1. Cache → 2. Backend API → 3. HuggingFace API → 4. Fallback
  /// When [includePhraseBreakdown] is true, backend may return phraseBreakdowns for tap-to-highlight UI.
  Future<TranslationResult> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
    String? hfToken,
    bool useCache = true,
    bool includePhraseBreakdown = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cached = await HybridPolieCache.getCachedTranslation(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );
      if (cached != null) {
        return TranslationResult(
          translation: cached,
          sourceText: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
          model: 'NLLB-200-cached',
          confidence: 0.9,
        );
      }
    }
    
    // Try backend API first (more reliable, handles tokens server-side)
    try {
      final backendResult = await _translateViaBackend(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        includePhraseBreakdown: includePhraseBreakdown,
      );
      if (backendResult != null) {
        // Cache successful result
        if (useCache && backendResult.translation.isNotEmpty) {
          await HybridPolieCache.cacheTranslation(
            text: text,
            sourceLang: sourceLang,
            targetLang: targetLang,
            result: backendResult.translation,
          );
        }
        return backendResult;
      }
    } catch (e) {
      debugPrint('Backend translation failed, trying HuggingFace: $e');
    }
    
    // Fallback to direct HuggingFace API
    try {
      final effectiveToken = hfToken ?? EnvConfig.huggingFaceToken;
      
      if (effectiveToken.isEmpty) {
        debugPrint('⚠️ HuggingFace token not configured');
        return _fallbackResult(text, sourceLang, targetLang);
      }
      
      final srcCode = _getLanguageCode(sourceLang);
      final tgtCode = _getLanguageCode(targetLang);
      
      final response = await _dio.post(
        _hfNllbUrl,
        data: jsonEncode({
          'inputs': text,
          'parameters': {
            'src_lang': srcCode,
            'tgt_lang': tgtCode,
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
        String translation = '';
        
        if (data is List && data.isNotEmpty) {
          translation = data[0]['translation_text'] ?? '';
        } else if (data is Map && data.containsKey('translation_text')) {
          translation = data['translation_text'];
        }
        
        final result = TranslationResult(
          translation: translation.isNotEmpty ? translation : text,
          sourceText: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
          model: 'NLLB-200-HF',
          confidence: 0.9,
        );
        
        // Cache the result
        if (useCache && translation.isNotEmpty) {
          await HybridPolieCache.cacheTranslation(
            text: text,
            sourceLang: sourceLang,
            targetLang: targetLang,
            result: translation,
          );
        }
        
        return result;
      }
      
      return _fallbackResult(text, sourceLang, targetLang);
    } catch (e) {
      debugPrint('HuggingFace translation failed: $e');
      return _fallbackResult(text, sourceLang, targetLang, error: e.toString());
    }
  }
  
  /// Translate via backend API (sends auth token so backend accepts request)
  Future<TranslationResult?> _translateViaBackend({
    required String text,
    required String sourceLang,
    required String targetLang,
    bool includePhraseBreakdown = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('access_token');
      final response = await _dio.post(
        '${Api.baseurl}hybrid-polie/translate',
        data: {
          'text': text,
          'sourceLang': sourceLang,
          'targetLang': targetLang,
          if (includePhraseBreakdown) 'includePhraseBreakdown': true,
        },
        options: Options(
          contentType: 'application/json',
          receiveTimeout: const Duration(seconds: 30),
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        if (data == null) return null;
        List<Map<String, String>>? phraseBreakdowns;
        if (data['phraseBreakdowns'] is List) {
          phraseBreakdowns = (data['phraseBreakdowns'] as List)
              .map((e) => e is Map ? Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))) : null)
              .whereType<Map<String, String>>()
              .toList();
          if (phraseBreakdowns.isEmpty) phraseBreakdowns = null;
        }
        return TranslationResult(
          translation: data['translation']?.toString() ?? text,
          sourceText: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
          model: data['model']?.toString() ?? 'NLLB-200-backend',
          confidence: (data['confidence'] ?? 0.9).toDouble(),
          phraseBreakdowns: phraseBreakdowns,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Backend translation error: $e');
      return null;
    }
  }
  
  TranslationResult _fallbackResult(String text, String sourceLang, String targetLang, {String? error}) {
    return TranslationResult(
      translation: text,
      sourceText: text,
      sourceLang: sourceLang,
      targetLang: targetLang,
      model: 'fallback',
      confidence: 0.3,
      error: error,
      phraseBreakdowns: null,
    );
  }
  
  String _getLanguageCode(String language) {
    // Map to NLLB language codes
    final codeMap = {
      'yoruba': 'yor_Latn',
      'hausa': 'hau_Latn',
      'igbo': 'ibo_Latn',
      'swahili': 'swh_Latn',
      'zulu': 'zul_Latn',
      'xhosa': 'xho_Latn',
      'amharic': 'amh_Ethi',
      'twi': 'twi_Latn',
      'afrikaans': 'afr_Latn',
      'pidgin': 'pcm_Latn',
      'nigerian pidgin': 'pcm_Latn',
      'wolof': 'wol_Latn',
      'somali': 'som_Latn',
      'english': 'eng_Latn',
    };
    
    return codeMap[language.toLowerCase()] ?? 'eng_Latn';
  }
}

class TranslationResult {
  final String translation;
  final String sourceText;
  final String sourceLang;
  final String targetLang;
  final String model;
  final double confidence;
  final String? error;
  /// Phrase-level breakdown for tap-to-highlight UI: sourcePhrase, targetPhrase, note.
  final List<Map<String, String>>? phraseBreakdowns;
  
  TranslationResult({
    required this.translation,
    required this.sourceText,
    required this.sourceLang,
    required this.targetLang,
    required this.model,
    required this.confidence,
    this.error,
    this.phraseBreakdowns,
  });
}
