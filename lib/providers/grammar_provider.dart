import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_provider.dart';
import 'dio_provider.dart';
import '../utils/api.dart';

/// Provider for enhanced grammar explanations with backend integration
class GrammarNotifier extends Notifier<GrammarState> {
  final Map<String, Map<String, GrammarExplanation>> _cache = {}; // language -> grammarPoint -> explanation
  
  @override
  GrammarState build() {
    return GrammarState();
  }

  /// Get grammar explanation with backend integration and local caching
  Future<GrammarExplanation> getExplanation(String grammarPoint, String language) async {
    // Check cache first
    if (_cache[language]?.containsKey(grammarPoint) == true) {
      return _cache[language]![grammarPoint]!;
    }
    
    // Try to fetch from backend
    try {
      final response = await ref.read(client).get(
        '${Api.baseurl}api/grammar/explanations',
        queryParameters: {
          'language': language.toLowerCase(),
          'grammar_point': grammarPoint,
        },
      );
      
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final explanation = _parseGrammarExplanation(data);
        
        // Cache the explanation
        if (!_cache.containsKey(language)) {
          _cache[language] = {};
        }
        _cache[language]![grammarPoint] = explanation;
        
        // Save to local storage for offline access
        await _saveToLocalCache(language, grammarPoint, explanation);
        
        return explanation;
      }
    } catch (e) {
      debugPrint('Error fetching grammar explanation from backend: $e');
      // Fall back to local cache or default
    }
    
    // Try to load from local cache
    final cached = await _loadFromLocalCache(language, grammarPoint);
    if (cached != null) {
      // Add to memory cache
      if (!_cache.containsKey(language)) {
        _cache[language] = {};
      }
      _cache[language]![grammarPoint] = cached;
      return cached;
    }
    
    // Fall back to hardcoded database
    final explanations = _getGrammarDatabase(language);
    final explanation = explanations[grammarPoint] ?? GrammarExplanation(
      title: grammarPoint,
      description: 'Grammar explanation not available',
      examples: [],
      rules: [],
    );
    
    // Cache the fallback
    if (!_cache.containsKey(language)) {
      _cache[language] = {};
    }
    _cache[language]![grammarPoint] = explanation;
    
    return explanation;
  }
  
  /// Parse grammar explanation from API response
  GrammarExplanation _parseGrammarExplanation(Map<String, dynamic> data) {
    final examples = (data['examples'] as List<dynamic>?)
        ?.map((e) {
          if (e is Map) {
            return GrammarExample(
              yoruba: e['target_language'] ?? e['text'] ?? '',
              english: e['english'] ?? e['translation'] ?? '',
              explanation: e['explanation'] ?? '',
            );
          }
          return null;
        })
        .whereType<GrammarExample>()
        .toList() ?? [];
    
    return GrammarExplanation(
      title: data['title'] ?? data['grammar_point'] ?? '',
      description: data['description'] ?? '',
      examples: examples,
      rules: (data['rules'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [],
      commonMistakes: (data['common_mistakes'] as List<dynamic>?)?.map((m) => m.toString()).toList() ?? [],
      culturalNote: data['cultural_note']?.toString(),
    );
  }
  
  /// Save grammar explanation to local cache
  Future<void> _saveToLocalCache(String language, String grammarPoint, GrammarExplanation explanation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'grammar_${language}_$grammarPoint';
      await prefs.setString(cacheKey, jsonEncode({
        'title': explanation.title,
        'description': explanation.description,
        'examples': explanation.examples.map((e) => {
          'target_language': e.yoruba,
          'english': e.english,
          'explanation': e.explanation,
        }).toList(),
        'rules': explanation.rules,
        'common_mistakes': explanation.commonMistakes,
        'cultural_note': explanation.culturalNote,
      }));
    } catch (e) {
      debugPrint('Error saving grammar explanation to cache: $e');
    }
  }
  
  /// Load grammar explanation from local cache
  Future<GrammarExplanation?> _loadFromLocalCache(String language, String grammarPoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'grammar_${language}_$grammarPoint';
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        final data = jsonDecode(cachedJson) as Map<String, dynamic>;
        return _parseGrammarExplanation(data);
      }
    } catch (e) {
      debugPrint('Error loading grammar explanation from cache: $e');
    }
    return null;
  }

  Map<String, GrammarExplanation> _getGrammarDatabase(String language) {
    // Comprehensive local fallback database for offline support
    
    // Import SupportedLanguages to ensure we support all languages
    final supportedLanguages = [
      'yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'xhosa',
      'amharic', 'twi', 'afrikaans', 'pidgin', 'wolof', 'somali'
    ];
    
    if (!supportedLanguages.contains(language.toLowerCase())) {
      return {}; // Return empty for unsupported languages
    }
    
    if (language.toLowerCase() == 'yoruba') {
      return {
        'tone_marks': GrammarExplanation(
          title: 'Tone Marks in Yoruba',
          description: 'Yoruba is a tonal language with three tones: high (á), mid (a), and low (à).',
          examples: [
            GrammarExample(
              yoruba: 'bàtà',
              english: 'shoe',
              explanation: 'Low-low tone',
            ),
            GrammarExample(
              yoruba: 'bátà',
              english: 'to be better',
              explanation: 'High-low tone',
            ),
            GrammarExample(
              yoruba: 'batà',
              english: 'to be flat',
              explanation: 'Mid-low tone',
            ),
          ],
          rules: [
            'High tone (á) is marked with an acute accent',
            'Low tone (à) is marked with a grave accent',
            'Mid tone (a) has no mark',
            'Tone can change meaning completely',
          ],
          commonMistakes: [
            'Forgetting tone marks changes word meaning',
            'Using wrong tone in greetings is impolite',
          ],
        ),
        'verb_conjugation': GrammarExplanation(
          title: 'Verb Conjugation',
          description: 'Yoruba verbs are conjugated based on tense and aspect.',
          examples: [
            GrammarExample(
              yoruba: 'Mo lọ',
              english: 'I go',
              explanation: 'Present tense',
            ),
            GrammarExample(
              yoruba: 'Mo ti lọ',
              english: 'I have gone',
              explanation: 'Perfect aspect',
            ),
            GrammarExample(
              yoruba: 'Mo máa lọ',
              english: 'I will go',
              explanation: 'Future tense',
            ),
          ],
          rules: [
            'Subject pronouns: Mo (I), O (you), Ó (he/she)',
            'Tense markers: ti (past), máa (future)',
            'Aspect markers: ti (perfect), ń (progressive)',
          ],
          commonMistakes: [
            'Confusing tense and aspect markers',
            'Omitting subject pronouns',
          ],
        ),
      };
    }
    
    // Add more languages as needed
    return {};
  }
}

final grammarProvider = NotifierProvider<GrammarNotifier, GrammarState>(() {
  return GrammarNotifier();
});

class GrammarState {
  GrammarState();
}

class GrammarExplanation {
  final String title;
  final String description;
  final List<GrammarExample> examples;
  final List<String> rules;
  final List<String> commonMistakes;
  final String? culturalNote;

  GrammarExplanation({
    required this.title,
    required this.description,
    required this.examples,
    required this.rules,
    this.commonMistakes = const [],
    this.culturalNote,
  });
}

class GrammarExample {
  final String yoruba;
  final String english;
  final String explanation;

  GrammarExample({
    required this.yoruba,
    required this.english,
    required this.explanation,
  });
}

