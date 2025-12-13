import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/curriculum_model.dart';
import '../services/polie_content_generator.dart';
import '../services/polie_cache_service.dart';
import '../providers/ai_chat_provider_groq.dart';

/// Comprehensive Curriculum Service
/// Loads curriculum from bundle folders and integrates with Polie for dynamic content
class CurriculumService {
  final Ref _ref;

  CurriculumService(this._ref);

  /// Load curriculum from FINAL_curriculum folder
  Future<Map<String, dynamic>?> loadFinalCurriculum(String language) async {
    try {
      final path = 'lingafriq_FINAL_curriculum/languages/$language.json';
      final file = File(path);
      
      if (!await file.exists()) {
        debugPrint('Final curriculum file not found: $path');
        return null;
      }

      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading final curriculum: $e');
      return null;
    }
  }

  /// Load curriculum from expanded bundle
  Future<Map<String, dynamic>?> loadExpandedCurriculum(String language, String level) async {
    try {
      final path = 'lingafriq_full_curriculum_bundle/curriculum_expanded_bundle/curriculum_expanded/$language/${language}_${level}_expanded.json';
      final file = File(path);
      
      if (!await file.exists()) {
        debugPrint('Expanded curriculum file not found: $path');
        return null;
      }

      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading expanded curriculum: $e');
      return null;
    }
  }

  /// Load curriculum from compact bundle
  Future<Map<String, dynamic>?> loadCompactCurriculum(String language, String level) async {
    try {
      final path = 'lingafriq_full_curriculum_bundle/curriculum_bundle/curriculum/$language/${language}_$level.json';
      final file = File(path);
      
      if (!await file.exists()) {
        debugPrint('Compact curriculum file not found: $path');
        return null;
      }

      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading compact curriculum: $e');
      return null;
    }
  }

  /// Load master index
  Future<Map<String, dynamic>?> loadMasterIndex() async {
    try {
      final path = 'lingafriq_FINAL_curriculum/master_index.json';
      final file = File(path);
      
      if (!await file.exists()) {
        debugPrint('Master index not found: $path');
        return null;
      }

      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading master index: $e');
      return null;
    }
  }

  /// Generate dynamic lesson content using Polie
  Future<Map<String, dynamic>> generateLessonContent({
    required String language,
    required String level,
    required String lessonTitle,
    required List<Map<String, dynamic>> vocab,
    List<String>? grammar,
    String? topic,
  }) async {
    try {
      // Check cache first
      final cacheKey = '${language}_${level}_${lessonTitle}';
      final cached = await PolieCacheService.getCachedContent(
        'lesson_content',
        language,
        additional: cacheKey,
      );
      
      if (cached != null) {
        debugPrint('✅ Using cached lesson content for $language $level');
        return cached;
      }

      final polieGenerator = _ref.read(polieContentGeneratorProvider);
      
      // Generate comprehensive lesson content
      final systemPrompt = '''You are Polie, an expert language tutor for $language. Generate comprehensive lesson content for a $level level lesson titled "$lessonTitle".

Requirements:
1. **Grammar Explanations**: Clear, culturally-appropriate explanations for: ${grammar?.join(', ') ?? 'relevant grammar points'}
2. **Dialogue**: Natural conversation between two speakers using the vocabulary
3. **Examples**: Multiple example sentences for each vocabulary word
4. **Cultural Context**: Explain cultural nuances and appropriate usage
5. **Practice Exercises**: Create varied exercises (fill-in-blank, translation, comprehension)

Vocabulary to use: ${vocab.map((v) => '${v['word']} (${v['meaning']})').join(', ')}

${topic != null ? 'Topic focus: $topic' : ''}

Return structured JSON with: grammar_explanations, dialogue, examples, cultural_notes, exercises.''';

      final userMessage = 'Generate comprehensive lesson content for "$lessonTitle" in $language ($level level)';

      final groqChatNotifier = _ref.read(groqChatProvider.notifier);
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();

      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        userMessage,
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }

      // Parse response
      final content = _parseLessonContent(fullResponse, vocab, grammar);
      
      // Cache the result
      await PolieCacheService.cacheContent(
        'lesson_content',
        language,
        content,
        additional: cacheKey,
      );

      return content;
    } catch (e) {
      debugPrint('Error generating lesson content: $e');
      return _getFallbackLessonContent(vocab, grammar);
    }
  }

  /// Generate dialogue using Polie
  Future<Map<String, dynamic>> generateDialogue({
    required String language,
    required String level,
    required List<Map<String, dynamic>> vocab,
    String? context,
  }) async {
    try {
      final cacheKey = 'dialogue_${language}_${level}_${vocab.map((v) => v['word']).join('_')}';
      final cached = await PolieCacheService.getCachedContent(
        'dialogue',
        language,
        additional: cacheKey,
      );
      
      if (cached != null) {
        return cached;
      }

      final polieGenerator = _ref.read(polieContentGeneratorProvider);
      final groqChatNotifier = _ref.read(groqChatProvider.notifier);
      
      final systemPrompt = '''You are Polie, a native $language speaker. Generate a natural, culturally-appropriate dialogue between two speakers.

Requirements:
1. Use vocabulary: ${vocab.map((v) => '${v['word']} (${v['meaning']})').join(', ')}
2. Natural conversation flow
3. Culturally appropriate expressions
4. Suitable for $level level learners
${context != null ? '5. Context: $context' : ''}

Return JSON with: script (array of {speaker, text}), notes, cultural_context.''';

      await groqChatNotifier.setMode(PolieMode.roleplay);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();

      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        'Generate a dialogue using the vocabulary',
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }

      final dialogue = _parseDialogue(fullResponse);
      
      await PolieCacheService.cacheContent(
        'dialogue',
        language,
        dialogue,
        additional: cacheKey,
      );

      return dialogue;
    } catch (e) {
      debugPrint('Error generating dialogue: $e');
      return _getFallbackDialogue(vocab);
    }
  }

  /// Generate exercises using Polie
  Future<List<Map<String, dynamic>>> generateExercises({
    required String language,
    required String level,
    required List<Map<String, dynamic>> vocab,
    required List<String> grammar,
  }) async {
    try {
      final cacheKey = 'exercises_${language}_${level}';
      final cached = await PolieCacheService.getCachedContent(
        'exercises',
        language,
        additional: cacheKey,
      );
      
      if (cached != null && cached['exercises'] != null) {
        return List<Map<String, dynamic>>.from(cached['exercises']);
      }

      final groqChatNotifier = _ref.read(groqChatProvider.notifier);
      
      final systemPrompt = '''You are Polie, an expert language tutor. Generate varied exercises for $language ($level level).

Vocabulary: ${vocab.map((v) => '${v['word']} (${v['meaning']})').join(', ')}
Grammar: ${grammar.join(', ')}

Create exercises:
1. Fill-in-the-blank (using vocabulary)
2. Translation (English to $language)
3. Multiple choice (grammar)
4. Sentence construction
5. Comprehension questions

Return JSON array with: type, prompt, options (if applicable), answer, explanation.''';

      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();

      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        'Generate exercises',
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }

      final exercises = _parseExercises(fullResponse);
      
      await PolieCacheService.cacheContent(
        'exercises',
        language,
        {'exercises': exercises},
        additional: cacheKey,
      );

      return exercises;
    } catch (e) {
      debugPrint('Error generating exercises: $e');
      return _getFallbackExercises(vocab);
    }
  }

  Map<String, dynamic> _parseLessonContent(String response, List<Map<String, dynamic>> vocab, List<String>? grammar) {
    try {
      // Try to parse as JSON first
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error parsing JSON from Polie response: $e');
    }

    // Fallback: structure the response
    return {
      'grammar_explanations': grammar?.map((g) => {'point': g, 'explanation': response}).toList() ?? [],
      'dialogue': _getFallbackDialogue(vocab),
      'examples': vocab.map((v) => 'Example sentence with ${v['word']}').toList(),
      'cultural_notes': 'Cultural context and usage notes',
      'exercises': _getFallbackExercises(vocab),
    };
  }

  Map<String, dynamic> _parseDialogue(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error parsing dialogue JSON: $e');
    }

    return _getFallbackDialogue([]);
  }

  List<Map<String, dynamic>> _parseExercises(String response) {
    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(jsonMatch.group(0)!));
      }
    } catch (e) {
      debugPrint('Error parsing exercises JSON: $e');
    }

    return _getFallbackExercises([]);
  }

  Map<String, dynamic> _getFallbackLessonContent(List<Map<String, dynamic>> vocab, List<String>? grammar) {
    return {
      'grammar_explanations': grammar?.map((g) => {'point': g, 'explanation': 'Explanation for $g'}).toList() ?? [],
      'dialogue': _getFallbackDialogue(vocab),
      'examples': vocab.map((v) => 'Example: ${v['word']} means ${v['meaning']}').toList(),
      'cultural_notes': 'Cultural context will be available',
      'exercises': _getFallbackExercises(vocab),
    };
  }

  Map<String, dynamic> _getFallbackDialogue(List<Map<String, dynamic>> vocab) {
    return {
      'script': [
        {'speaker': 'A', 'text': vocab.isNotEmpty ? 'Hello in ${vocab[0]['word']}' : 'Hello'},
        {'speaker': 'B', 'text': 'Response'},
      ],
      'notes': 'Practice dialogue',
      'cultural_context': 'Cultural notes',
    };
  }

  List<Map<String, dynamic>> _getFallbackExercises(List<Map<String, dynamic>> vocab) {
    return [
      {
        'type': 'flashcards',
        'items': vocab.map((v) => '${v['word']} - ${v['meaning']}').toList(),
      },
      {
        'type': 'translation',
        'prompt': 'Translate a sentence',
        'answer': ['answer'],
      },
    ];
  }
}

final curriculumServiceProvider = Provider<CurriculumService>((ref) {
  return CurriculumService(ref);
});

