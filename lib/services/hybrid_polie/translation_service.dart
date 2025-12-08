/// Translation Service using NLLB-200
/// Handles high-quality translation between English and African languages

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../utils/supported_languages.dart';
import 'cache_service.dart';

class TranslationService {
  final Dio _dio = Dio();
  static const String NLLB_API_URL = "https://api-inference.huggingface.co/models/facebook/nllb-200-distilled-600M";
  static const String HF_TOKEN = ""; // Set via environment
  
  /// Translate text using NLLB-200 (with caching)
  Future<TranslationResult> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
    String? hfToken,
    bool useCache = true,
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
    try {
      final srcCode = _getLanguageCode(sourceLang);
      final tgtCode = _getLanguageCode(targetLang);
      
      final headers = {
        'Authorization': 'Bearer ${hfToken ?? HF_TOKEN}',
        'Content-Type': 'application/json',
      };
      
      final payload = {
        'inputs': text,
        'parameters': {
          'src_lang': srcCode,
          'tgt_lang': tgtCode,
        },
      };
      
      final response = await _dio.post(
        NLLB_API_URL,
        data: jsonEncode(payload),
        options: Options(
          headers: headers,
          contentType: 'application/json',
        ),
        options: Options(
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
          translation: translation,
          sourceText: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
          model: 'NLLB-200',
          confidence: 0.9, // NLLB typically high confidence
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
      
      throw Exception('Translation failed: ${response.statusCode}');
    } catch (e) {
      // Fallback to LLaMA if NLLB fails
      return TranslationResult(
        translation: text, // Fallback
        sourceText: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        model: 'fallback',
        confidence: 0.5,
        error: e.toString(),
      );
    }
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
  
  TranslationResult({
    required this.translation,
    required this.sourceText,
    required this.sourceLang,
    required this.targetLang,
    required this.model,
    required this.confidence,
    this.error,
  });
}

