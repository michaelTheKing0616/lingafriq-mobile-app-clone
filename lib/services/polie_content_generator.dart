import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/ai_chat_provider_groq.dart';
import '../models/quest_model.dart';
import 'polie_cache_service.dart';

/// Comprehensive Polie Content Generator
/// Powers the entire app with intelligent, culturally-accurate content generation
/// Similar to JARVIS - fully autonomous AI engine for African languages
/// Now with intelligent caching for improved performance
final polieContentGeneratorProvider = Provider<PolieContentGenerator>((ref) {
  return PolieContentGenerator(ref);
});

class PolieContentGenerator {
  final Ref _ref;

  PolieContentGenerator(this._ref);

  /// Generate actionable classroom / family learning activities based on a progress summary.
  ///
  /// This is used by Family subscription dashboards to turn raw metrics into:
  /// - a weekly plan
  /// - suggested activities by age/level
  /// - parent/guardian coaching tips
  /// - a short motivational message
  Future<String> generateClassroomActivities({
    required String language,
    required String classSummary,
  }) async {
    final additional = classSummary.hashCode.toString();
    final cached = await PolieCacheService.getCachedContent(
      'family_classroom_activities',
      language,
      additional: additional,
    );
    if (cached != null && cached['text'] is String && (cached['text'] as String).trim().isNotEmpty) {
      return cached['text'] as String;
    }

    final groqChatNotifier = _ref.read(groqChatProvider.notifier);
    final systemPrompt = '''
You are Polie, a world-class language learning coach and curriculum designer.
Your job: turn the provided learning summary into a practical, motivating plan that a family can follow.

Requirements:
- Output in clear, friendly English (unless requested otherwise).
- Be specific and actionable: concrete activities, duration, and example prompts.
- Tailor the plan to a family setting with multiple learners at different levels.
- Include: (1) Snapshot, (2) Weekly plan (Mon–Sun), (3) 5 activity ideas, (4) 5 quick coaching tips, (5) a short motivational note.
- Keep it concise: ~400–700 words.

Family learning summary:
${classSummary.trim()}
''';

    try {
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();

      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        'Create a family-friendly learning plan from the summary above.',
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }

      final cleaned = fullResponse.trim();
      if (cleaned.isEmpty) throw Exception('Empty AI response');

      await PolieCacheService.cacheContent(
        'family_classroom_activities',
        language,
        {'text': cleaned},
        additional: additional,
        ttl: const Duration(hours: 24),
      );

      return cleaned;
    } catch (e) {
      debugPrint('Error generating classroom activities: $e');
      // Provide a robust non-AI fallback that is still actionable.
      final fallback = [
        'Snapshot',
        '- Summary received, but Polie could not generate a tailored plan right now.',
        '',
        'Weekly plan (simple)',
        '- Mon/Wed/Fri: 15 min speaking practice (repeat + shadow simple phrases)',
        '- Tue/Thu: 15 min listening + 5 min recap',
        '- Sat: 20 min family game (flashcards / quiz / roleplay)',
        '- Sun: 10 min review + set next week goals',
        '',
        'Activity ideas',
        '- “Repeat & Record”: say 5 phrases, record, replay, improve',
        '- “Family roleplay”: market greetings + bargaining',
        '- “Story time”: read a short story and pick 5 new words',
        '- “Kitchen labels”: label 10 objects; quiz each other',
        '- “Mini-challenges”: fastest correct pronunciation wins',
        '',
        'Coaching tips',
        '- Keep sessions short and consistent',
        '- Celebrate effort, not perfection',
        '- Encourage full sentences, not single words',
        '- Review yesterday’s words before adding new ones',
        '- Rotate who “teaches” to boost confidence',
      ].join('\n');
      return fallback;
    }
  }

  /// Generate culturally-accurate proverb with explanation
  /// Uses caching to improve performance for common queries
  Future<Map<String, dynamic>> generateProverb(String language, {String? theme}) async {
    // Check cache first
    final cacheKey = theme != null ? 'proverb_$theme' : 'proverb';
    final cached = await PolieCacheService.getCachedContent('proverb', language, additional: theme);
    if (cached != null) {
      debugPrint('✅ Using cached proverb for $language${theme != null ? ' ($theme)' : ''}');
      return cached;
    }
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);
    
    final systemPrompt = '''You are Polie, an expert in African languages and cultures. Generate an authentic, culturally-accurate proverb in $language with:
1. The proverb in $language (with proper diacritics)
2. Literal English translation
3. Meaning/interpretation
4. Cultural context
5. Usage example

${theme != null ? 'Theme: $theme' : 'Choose a relevant theme for daily life, wisdom, or relationships.'}

Ensure the proverb is authentic to $language culture and uses proper orthography.''';

    final userMessage = theme != null 
        ? "Generate a $language proverb about $theme"
        : "Generate an authentic $language proverb";

    try {
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();
      
      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(userMessage, systemPromptOverride: systemPrompt)) {
        fullResponse += chunk;
      }
      
      // Parse response into structured format
      final result = _parseProverbResponse(fullResponse, language);
      
      // Cache the result
      await PolieCacheService.cacheContent('proverb', language, result, additional: theme);
      
      return result;
    } catch (e) {
      debugPrint('Error generating proverb: $e');
      return _getFallbackProverb(language);
    }
  }

  /// Generate drum rhythm pattern description
  Future<Map<String, dynamic>> generateDrumRhythm(String language) async {
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);
    
    final systemPrompt = '''You are Polie, an expert in African music and rhythm. Generate a traditional drum rhythm pattern for $language culture:
1. Rhythm pattern notation (e.g., "DUM da-da DUM")
2. Cultural context (when/where it's used)
3. Associated words/phrases in $language
4. How to practice matching tone patterns

Make it authentic and culturally relevant.''';

    try {
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();
      
      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        "Generate a traditional $language drum rhythm pattern",
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }
      
      return {
        'pattern': fullResponse,
        'language': language,
        'type': 'drum_rhythm',
      };
    } catch (e) {
      debugPrint('Error generating drum rhythm: $e');
      return _getFallbackRhythm(language);
    }
  }

  /// Generate cultural story/folktale
  Future<Map<String, dynamic>> generateCulturalStory(String language, {String? theme}) async {
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);
    
    final systemPrompt = '''You are Polie, a master African storyteller. Generate an engaging, culturally-authentic story in $language:
1. Story title in $language
2. Full story narrative (300-500 words)
3. Key vocabulary with translations
4. Cultural lessons/morals
5. Discussion questions

${theme != null ? 'Theme: $theme' : 'Use a traditional folktale theme relevant to $language culture.'}

The story should be appropriate for language learners and culturally enriching.''';

    try {
      await groqChatNotifier.setMode(PolieMode.roleplay);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();
      
      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        theme != null 
            ? "Generate a $language cultural story about $theme"
            : "Generate an authentic $language folktale",
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }
      
      return {
        'title': _extractTitle(fullResponse),
        'content': fullResponse,
        'language': language,
        'type': 'cultural_story',
        'vocabulary': _extractVocabulary(fullResponse),
      };
    } catch (e) {
      debugPrint('Error generating cultural story: $e');
      return _getFallbackStory(language);
    }
  }

  /// Generate market bargaining scenario
  Future<Map<String, dynamic>> generateMarketScenario(String language) async {
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);
    
    final systemPrompt = '''You are Polie, an expert in African market culture. Generate a realistic market bargaining scenario in $language:
1. Market setting description
2. Items for sale with prices
3. Buyer-seller dialogue in $language
4. Bargaining phrases and strategies
5. Cultural etiquette tips

Make it authentic and practical for learners.''';

    try {
      await groqChatNotifier.setMode(PolieMode.roleplay);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();
      
      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        "Generate a market bargaining scenario in $language",
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }
      
      return {
        'scenario': fullResponse,
        'language': language,
        'type': 'market_bargaining',
        'phrases': _extractPhrases(fullResponse),
      };
    } catch (e) {
      debugPrint('Error generating market scenario: $e');
      return _getFallbackMarketScenario(language);
    }
  }

  /// Generate cultural article for magazine
  Future<Map<String, dynamic>> generateCulturalArticle({
    required String language,
    required String type, // story, festival, music, food, etc.
    String? topic,
  }) async {
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);
    
    final systemPrompt = '''You are Polie, a cultural expert and journalist. Write a comprehensive, engaging article about $type in $language culture:
1. Compelling title
2. Introduction hook
3. Detailed content (500-800 words)
4. Cultural significance
5. Key vocabulary in $language
6. Related traditions

${topic != null ? 'Specific topic: $topic' : 'Choose a relevant, interesting topic.'}

Make it informative, culturally accurate, and engaging for language learners.''';

    try {
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();
      
      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        topic != null
            ? "Write an article about $topic ($type) in $language culture"
            : "Write a comprehensive article about $type in $language culture",
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }
      
      return {
        'title': _extractTitle(fullResponse),
        'description': _extractDescription(fullResponse),
        'content': fullResponse,
        'type': type,
        'language': language,
        'publishDate': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error generating cultural article: $e');
      return _getFallbackArticle(language, type);
    }
  }

  /// Generate game content (questions, scenarios, etc.)
  /// Uses caching for common game types to improve loading performance
  Future<Map<String, dynamic>> generateGameContent({
    required String gameType,
    required String language,
    String? difficulty,
    String? additionalContext,
  }) async {
    // Check cache first (cache common game types for better performance)
    final cacheableTypes = ['proverb', 'drum_rhythm', 'tongue_twister', 'blessing'];
    if (cacheableTypes.contains(gameType)) {
      final cached = await PolieCacheService.getCachedContent(
        gameType,
        language,
        additional: difficulty,
      );
      if (cached != null) {
        debugPrint('✅ Using cached game content for $gameType ($language)');
        return cached;
      }
    }
    
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);
    
    // Enhanced system prompt with better structure requirements
    final systemPrompt = '''You are Polie, an expert game designer for language learning. Generate engaging game content for $gameType in $language:
1. Game scenario/context
2. Questions or challenges
3. Correct answers
4. Explanations
5. Cultural context

${difficulty != null ? 'Difficulty level: $difficulty' : 'Use appropriate difficulty for language learners.'}
${additionalContext != null ? '\nAdditional context: $additionalContext' : ''}

IMPORTANT: Structure your response clearly with labels like "Sentence:", "Error:", "Explanation:", "Options:", etc.
Make it fun, educational, and culturally relevant.''';

    try {
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();
      
      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        "Generate $gameType game content for $language learners",
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }
      
      final result = {
        'content': fullResponse,
        'gameType': gameType,
        'language': language,
        'difficulty': difficulty ?? 'intermediate',
      };
      
      // Cache common game types
      if (cacheableTypes.contains(gameType)) {
        await PolieCacheService.cacheContent(
          gameType,
          language,
          result,
          additional: difficulty,
        );
      }
      
      return result;
    } catch (e) {
      debugPrint('Error generating game content: $e');
      return _getFallbackGameContent(gameType, language);
    }
  }

  /// Generate village quest scenario with NPC interaction
  Future<Map<String, dynamic>> generateVillageQuestScenario(String language) async {
    return generateGameContent(
      gameType: 'village_quest',
      language: language,
      additionalContext: 'Create an NPC conversation scenario with: NPC name, scenario description, NPC message, and 4 response options (first should be most culturally appropriate).',
    );
  }

  /// Generate accent decoding puzzle
  Future<Map<String, dynamic>> generateAccentPuzzle(String language) async {
    return generateGameContent(
      gameType: 'accent_puzzle',
      language: language,
      additionalContext: 'Create accent/regional variation matching: word/phrase, 4 regional variations, correct region match.',
    );
  }

  /// Generate tongue twister
  Future<Map<String, dynamic>> generateTongueTwister(String language) async {
    return generateGameContent(
      gameType: 'tongue_twister',
      language: language,
      additionalContext: 'Create a challenging tongue twister in $language with pronunciation guide and practice tips.',
    );
  }

  /// Generate emoji translation challenge
  Future<Map<String, dynamic>> generateEmojiTranslation(String language) async {
    return generateGameContent(
      gameType: 'emoji_translator',
      language: language,
      additionalContext: 'Create emoji sequence representing a sentence in $language, with 4 translation options.',
    );
  }

  /// Generate rhythm typing content
  Future<Map<String, dynamic>> generateRhythmTyping(String language) async {
    return generateGameContent(
      gameType: 'rhythm_typing',
      language: language,
      additionalContext: 'Create words/phrases to type with drum rhythm patterns, including rhythm notation and target text.',
    );
  }

  /// Generate elders' blessings content
  Future<Map<String, dynamic>> generateEldersBlessings(String language) async {
    return generateGameContent(
      gameType: 'elders_blessings',
      language: language,
      additionalContext: 'Create traditional blessing phrases in $language with meanings, contexts, and usage examples.',
    );
  }

  /// Generate multilingual relay content
  Future<Map<String, dynamic>> generateMultilingualRelay(String language) async {
    return generateGameContent(
      gameType: 'multilingual_relay',
      language: language,
      additionalContext: 'Create translation chain: English phrase, intermediate language, target $language phrase.',
    );
  }

  /// Generate cultural etiquette scenario
  Future<Map<String, dynamic>> generateCulturalEtiquette(String language) async {
    return generateGameContent(
      gameType: 'cultural_etiquette',
      language: language,
      additionalContext: 'Create cultural situation with: scenario description, 4 response options (first should be most appropriate), explanation.',
    );
  }

  /// Generate drum-to-word matching content
  Future<Map<String, dynamic>> generateDrumWordMatching(String language) async {
    return generateGameContent(
      gameType: 'drum_word_matching',
      language: language,
      additionalContext: 'Create drum rhythm pattern with associated word/phrase in $language, and 4 word options to match.',
    );
  }

  /// Generate greetings for voice contribution
  Future<Map<String, dynamic>> generateGreetings(String language) async {
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);
    
    final systemPrompt = '''You are Polie, an expert in African languages and cultures. Generate authentic greetings in $language:
1. Formal greetings (morning, afternoon, evening)
2. Informal greetings
3. Responses to greetings
4. Cultural context and usage

Provide at least 5 formal and 5 informal greetings with translations.''';

    try {
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();
      
      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        "Generate authentic greetings in $language",
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }
      
      // Parse response into structured format
      final lines = fullResponse.split('\n');
      final formal = <String>[];
      final informal = <String>[];
      
      bool inFormal = false;
      bool inInformal = false;
      
      for (var line in lines) {
        if (line.toLowerCase().contains('formal')) {
          inFormal = true;
          inInformal = false;
        } else if (line.toLowerCase().contains('informal')) {
          inInformal = true;
          inFormal = false;
        } else if (line.trim().isNotEmpty && !line.startsWith('#')) {
          if (inFormal && formal.length < 5) {
            formal.add(line.trim());
          } else if (inInformal && informal.length < 5) {
            informal.add(line.trim());
          }
        }
      }
      
      return {
        'formal': formal.isNotEmpty ? formal : ['Good morning', 'Good afternoon', 'Good evening', 'Hello', 'Greetings'],
        'informal': informal.isNotEmpty ? informal : ['Hi', 'Hey', 'What\'s up', 'How are you', 'Hey there'],
        'language': language,
      };
    } catch (e) {
      debugPrint('Error generating greetings: $e');
      return {
        'formal': ['Good morning', 'Good afternoon', 'Good evening', 'Hello', 'Greetings'],
        'informal': ['Hi', 'Hey', 'What\'s up', 'How are you', 'Hey there'],
        'language': language,
      };
    }
  }

  // Helper methods for parsing and fallbacks
  Map<String, dynamic> _parseProverbResponse(String response, String language) {
    // Try to extract structured data from response
    final lines = response.split('\n');
    String proverb = '';
    String translation = '';
    String meaning = '';
    
    for (var line in lines) {
      if (line.toLowerCase().contains('proverb:') || line.toLowerCase().contains('saying:')) {
        proverb = line.split(':').length > 1 ? line.split(':')[1].trim() : line;
      } else if (line.toLowerCase().contains('translation:')) {
        translation = line.split(':').length > 1 ? line.split(':')[1].trim() : line;
      } else if (line.toLowerCase().contains('meaning:') || line.toLowerCase().contains('interpretation:')) {
        meaning = line.split(':').length > 1 ? line.split(':')[1].trim() : line;
      }
    }
    
    return {
      'proverb': proverb.isNotEmpty ? proverb : response.split('\n').first,
      'translation': translation.isNotEmpty ? translation : '',
      'meaning': meaning.isNotEmpty ? meaning : response,
      'context': response,
      'language': language,
    };
  }

  String _extractTitle(String content) {
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.trim().isNotEmpty && line.length < 100) {
        if (line.contains('Title:') || line.contains('#')) {
          return line.replaceAll('Title:', '').replaceAll('#', '').trim();
        }
        return line.trim();
      }
    }
    return 'Cultural Content';
  }

  String _extractDescription(String content) {
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.length > 50 && line.length < 200) {
        return line.trim();
      }
    }
    return content.substring(0, content.length > 150 ? 150 : content.length);
  }

  List<String> _extractVocabulary(String content) {
    final vocab = <String>[];
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('vocabulary:') || 
          line.toLowerCase().contains('words:') ||
          (line.contains('-') && line.length < 100)) {
        vocab.add(line.trim());
      }
    }
    return vocab.take(10).toList();
  }

  List<String> _extractPhrases(String content) {
    final phrases = <String>[];
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.contains(':') && line.length < 150) {
        phrases.add(line.trim());
      }
    }
    return phrases.take(5).toList();
  }

  // Fallback methods
  Map<String, dynamic> _getFallbackProverb(String language) {
    return {
      'proverb': 'Wisdom comes from experience',
      'translation': 'Wisdom comes from experience',
      'meaning': 'Learning through practice and experience',
      'context': 'A common saying about the value of experience',
      'language': language,
    };
  }

  Map<String, dynamic> _getFallbackRhythm(String language) {
    return {
      'pattern': 'DUM da-da DUM da DUM',
      'language': language,
      'type': 'drum_rhythm',
      'context': 'Traditional rhythm pattern',
    };
  }

  Map<String, dynamic> _getFallbackStory(String language) {
    return {
      'title': 'Traditional Story',
      'content': 'Once upon a time, in a village far away...',
      'language': language,
      'type': 'cultural_story',
      'vocabulary': [],
    };
  }

  Map<String, dynamic> _getFallbackMarketScenario(String language) {
    return {
      'scenario': 'A typical market scene with bargaining',
      'language': language,
      'type': 'market_bargaining',
      'phrases': ['How much?', 'Can you reduce?', 'Thank you'],
    };
  }

  Map<String, dynamic> _getFallbackArticle(String language, String type) {
    return {
      'title': '$type in $language Culture',
      'description': 'An exploration of $type',
      'content': 'Content about $type in $language culture...',
      'type': type,
      'language': language,
      'publishDate': DateTime.now(),
    };
  }

  Map<String, dynamic> _getFallbackGameContent(String gameType, String language) {
    return {
      'content': 'Game content for $gameType',
      'gameType': gameType,
      'language': language,
      'difficulty': 'intermediate',
    };
  }
}

