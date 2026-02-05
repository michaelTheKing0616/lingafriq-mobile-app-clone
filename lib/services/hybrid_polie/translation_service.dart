/// Translation Service using NLLB-200
/// Handles high-quality translation between English and African languages
/// Uses backend API with fallback to HuggingFace Inference API
/// Includes rate limiting with exponential backoff and offline support

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/url_constants.dart';
import '../../utils/api.dart';
import '../../utils/supported_languages.dart';
import '../../utils/structured_logger.dart';
import '../env_config.dart';
import '../api_rate_limiter.dart';
import '../translation/offline_translation_service.dart';
import 'cache_service.dart';

class TranslationService {
  final Dio _dio = Dio();
  final ApiRateLimiter _rateLimiter = ApiRateLimiter();
  final OfflineTranslationService _offlineService = OfflineTranslationService();
  bool _initialized = false;

  /// Hugging Face model: NLLB-200 for translation.
  static String get _hfNllbUrl =>
      UrlConstants.huggingFaceModel('facebook/nllb-200-distilled-600M');
  
  /// Initialize the service
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _rateLimiter.initialize();
    await _offlineService.initialize();
    _initialized = true;
  }
  
  /// Translate text using NLLB-200 (with caching and rate limiting)
  /// Priority: 1. Cache → 2. Backend API → 3. HuggingFace API → 4. Offline → 5. Fallback
  /// When [includePhraseBreakdown] is true, backend may return phraseBreakdowns for tap-to-highlight UI.
  Future<TranslationResult> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
    String? hfToken,
    bool useCache = true,
    bool includePhraseBreakdown = true,
    bool allowOffline = true,
  }) async {
    await _ensureInitialized();
    
    // Validate input
    if (text.trim().isEmpty) {
      return TranslationResult(
        translation: '',
        sourceText: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        model: 'validation',
        confidence: 1.0,
      );
    }
    
    // Truncate excessively long text
    final truncatedText = text.length > 5000 ? text.substring(0, 5000) : text;
    
    // Check cache first
    if (useCache) {
      final cached = await HybridPolieCache.getCachedTranslation(
        text: truncatedText,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );
      if (cached != null) {
        return TranslationResult(
          translation: cached,
          sourceText: truncatedText,
          sourceLang: sourceLang,
          targetLang: targetLang,
          model: 'NLLB-200-cached',
          confidence: 0.9,
        );
      }
    }
    
    // Try backend API with rate limiting
    final backendResult = await _rateLimiter.execute<TranslationResult?>(
      endpoint: 'backend-translate',
      config: RateLimiterConfig.translation,
      operation: () => _translateViaBackend(
        text: truncatedText,
        sourceLang: sourceLang,
        targetLang: targetLang,
        includePhraseBreakdown: includePhraseBreakdown,
      ),
    );
    
    if (backendResult.success && backendResult.data != null) {
      // Cache successful result
      if (useCache && backendResult.data!.translation.isNotEmpty) {
        await HybridPolieCache.cacheTranslation(
          text: truncatedText,
          sourceLang: sourceLang,
          targetLang: targetLang,
          result: backendResult.data!.translation,
        );
      }
      return backendResult.data!;
    }
    
    if (backendResult.rateLimited) {
      logger.warn('Backend rate limited, trying HuggingFace', tag: 'translation');
    }
    
    // Try HuggingFace API with rate limiting
    final hfResult = await _rateLimiter.execute<TranslationResult>(
      endpoint: 'huggingface-translate',
      config: RateLimiterConfig.translation,
      operation: () => _translateViaHuggingFace(
        text: truncatedText,
        sourceLang: sourceLang,
        targetLang: targetLang,
        hfToken: hfToken,
      ),
    );
    
    if (hfResult.success && hfResult.data != null && hfResult.data!.confidence > 0.5) {
      // Cache successful result
      if (useCache && hfResult.data!.translation.isNotEmpty) {
        await HybridPolieCache.cacheTranslation(
          text: truncatedText,
          sourceLang: sourceLang,
          targetLang: targetLang,
          result: hfResult.data!.translation,
        );
      }
      return hfResult.data!;
    }
    
    // Try offline translation as last resort
    if (allowOffline) {
      try {
        final offlineResult = await _offlineService.translate(
          text: truncatedText,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );
        
        if (offlineResult.confidence >= 0.5) {
          return TranslationResult(
            translation: offlineResult.translatedText,
            sourceText: truncatedText,
            sourceLang: sourceLang,
            targetLang: targetLang,
            model: 'offline-${offlineResult.model}',
            confidence: offlineResult.confidence,
          );
        }
      } catch (e) {
        logger.warn('Offline translation failed', tag: 'translation', error: e);
      }
    }
    
    return _fallbackResult(truncatedText, sourceLang, targetLang);
  }
  
  /// Translate via HuggingFace API
  Future<TranslationResult> _translateViaHuggingFace({
    required String text,
    required String sourceLang,
    required String targetLang,
    String? hfToken,
  }) async {
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
      
      return TranslationResult(
        translation: translation.isNotEmpty ? translation : text,
        sourceText: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        model: 'NLLB-200-HF',
        confidence: 0.9,
      );
    }
    
    return _fallbackResult(text, sourceLang, targetLang);
  }
  
  /// Batch translate multiple texts efficiently
  Future<List<TranslationResult>> translateBatch({
    required List<String> texts,
    required String sourceLang,
    required String targetLang,
    bool useCache = true,
  }) async {
    await _ensureInitialized();
    
    final results = <TranslationResult>[];
    final uncachedTexts = <String>[];
    final uncachedIndices = <int>[];
    
    // Check cache for all texts
    for (int i = 0; i < texts.length; i++) {
      final text = texts[i];
      if (useCache) {
        final cached = await HybridPolieCache.getCachedTranslation(
          text: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
        );
        if (cached != null) {
          results.add(TranslationResult(
            translation: cached,
            sourceText: text,
            sourceLang: sourceLang,
            targetLang: targetLang,
            model: 'NLLB-200-cached',
            confidence: 0.9,
          ));
          continue;
        }
      }
      uncachedTexts.add(text);
      uncachedIndices.add(i);
      results.add(TranslationResult(
        translation: '',
        sourceText: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        model: 'pending',
        confidence: 0.0,
      ));
    }
    
    // Translate uncached texts with rate limiting
    for (int i = 0; i < uncachedTexts.length; i++) {
      final text = uncachedTexts[i];
      final originalIndex = uncachedIndices[i];
      
      // Small delay between requests to avoid rate limiting
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      final result = await translate(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        useCache: useCache,
      );
      
      results[originalIndex] = result;
    }
    
    return results;
  }
  
  /// Invalidate cache for a specific language pair
  Future<void> invalidateCacheForLanguage(String language) async {
    await HybridPolieCache.clearByLanguage(language);
    debugPrint('Invalidated cache for language: $language');
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
      logger.error('Backend translation error', tag: 'translation', error: e);
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
