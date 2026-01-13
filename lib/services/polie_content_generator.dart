import 'dart:convert';

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

  /// Generate greeting phrases grouped by formality.
  ///
  /// Returns:
  /// `{ "formal": [{ "native": "...", "translation": "..." }], "informal": [...] }`
  Future<Map<String, dynamic>> generateGreetings(String language) async {
    try {
      final content = await generateGameContent(
        gameType: 'greetings',
        language: language,
        additionalContext: '''Return JSON object with keys "formal" and "informal".
Each is an array of objects: {"native": "...", "translation": "..."}.
Use correct diacritics for $language.''',
      );
      final raw = content['content'];
      if (raw is String) {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) return parsed;
      }
    } catch (e) {
      debugPrint('Error generating greetings: $e');
    }

    // Fallback (keeps the recording workflow functional offline)
    return <String, dynamic>{
      'formal': [
        {'native': 'Hello', 'translation': 'Hello'},
      ],
      'informal': [
        {'native': 'Hi', 'translation': 'Hi'},
      ],
    };
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

  /// Generate a short, contextual hint for a specific game situation.
  /// This is used by game modes (e.g. WordMatch+Audio) as an in-game
  /// Polie coach when learners struggle.
  Future<String> generateGameHint({
    required String gameType,
    required String language,
    required String context,
  }) async {
    try {
      final groqChatNotifier = _ref.read(groqChatProvider.notifier);

      final systemPrompt = '''You are Polie, a kind, concise language coach.
Game: $gameType
Language: $language

The learner just made a mistake in this situation:
$context

Give a SHORT hint (1–2 sentences max) that:
- Focuses on one clear idea.
- Uses simple language.
- Encourages the learner.
Do NOT reveal the full answer outright unless the learner is truly stuck.''';

      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();

      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        'Give the learner a short, friendly hint.',
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }

      return fullResponse.trim();
    } catch (e) {
      debugPrint('Error generating game hint: $e');
      return 'Think about how this word is used in everyday conversation, especially its tone and context.';
    }
  }

  /// Generate a short loading-screen micro-tip based on the current
  /// greeting/fact and learner language. This is meant to be a single,
  /// motivating nugget of learning that feels personal.
  Future<String> generateLoadingScreenTip({
    required String language,
    required String greeting,
    required String fact,
  }) async {
    try {
      final groqChatNotifier = _ref.read(groqChatProvider.notifier);

      final systemPrompt = '''You are Polie, an inspiring African language tutor.
The app is showing this loading-screen content:
- Language: $language
- Greeting: "$greeting"
- Fact: "$fact"

Write ONE short, friendly learning tip (1–2 sentences) that:
- Connects to the greeting or fact.
- Either teaches a tiny piece of language or motivates the learner.
- Is easy to read quickly while a screen is loading.
Do NOT repeat the raw fact verbatim; build on it.''';

      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();

      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        'Give one short loading-screen learning tip.',
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }

      return fullResponse.trim();
    } catch (e) {
      debugPrint('Error generating loading-screen tip: $e');
      return 'Use this moment to say today’s greeting out loud and notice its rhythm and tone.';
    }
  }

  /// Generate classroom activity ideas for a specific class profile.
  /// Used by ClassroomDashboardScreen to give teachers concrete, level-aware
  /// warm‑ups and practice ideas powered by Polie.
  Future<String> generateClassroomActivities({
    required String language,
    required String classSummary,
  }) async {
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);

    final systemPrompt = '''
You are Polie, an expert African language teacher and lesson designer.

You are helping a teacher plan a SHORT in‑class activity for today based on
this classroom profile:

$classSummary

Generate 3 concrete activity ideas for the next 15–20 minutes:

For EACH activity, include:
1. A short title.
2. Step‑by‑step instructions for the teacher.
3. Example target‑language phrases students should use (in $language, with English glosses).
4. Optional variation or extension for stronger students.

The activities should:
- Be doable in a regular classroom (phones optional).
- Encourage speaking, listening, and interaction.
- Be culturally appropriate and motivating for African learners.

Return your answer as clear Markdown-style text with numbered activities.''';

    try {
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();

      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        'Suggest classroom activities for this class.',
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }

      return fullResponse.trim();
    } catch (e) {
      debugPrint('Error generating classroom activities: $e');
      // Fallback: generic but still helpful suggestion.
      return '''
1. Warm‑up circle: In a circle, each learner greets the next person in $language and asks a simple question (name, how they feel, favourite food). Then switch directions and change the question.

2. Mini role‑plays: In pairs, students act out a short scene (at the market, greeting an elder, meeting a friend). Give them 3–4 key phrases to use and invite 2 pairs to perform for the class.

3. Quick review game: Write 8–10 key words/phrases on the board. Call out the English meaning and have teams race to say the $language phrase correctly. Award small points or XP for correct answers.''';
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

  /// Generate a Polie-style recap of a village voice session, based on
  /// STT summary + optional transcripts from the voice-service.
  Future<String> generateVillageRecap({
    required String language,
    required String summary,
    List<String>? transcriptSnippets,
  }) async {
    final groqChatNotifier = _ref.read(groqChatProvider.notifier);

    final systemPrompt = '''
You are Polie, a warm, insightful African language tutor and community host.
You just listened to a set of short voice messages from a village voice room
for the language "$language". You received the following automatic summary and
snippets from a speech‑to‑text service:

Summary of the session:
$summary

${(transcriptSnippets != null && transcriptSnippets.isNotEmpty)
        ? 'Representative snippets:\n- ${transcriptSnippets.join('\n- ')}\n'
        : ''}

Your task:
- Write a short, human‑friendly recap of what the class or village talked about.
- Highlight interesting words, phrases, or cultural points that appeared.
- Encourage learners with 1–2 specific suggestions for what to try next time.
- Keep it concise (4–6 sentences), warm, and motivating.

Do NOT invent facts that contradict the summary. If the summary is very short
or generic, acknowledge that and still give helpful suggestions.''';

    try {
      await groqChatNotifier.setMode(PolieMode.tutor);
      await groqChatNotifier.setLanguageDirection('English', language);
      await groqChatNotifier.clearChat();

      String fullResponse = '';
      await for (final chunk in groqChatNotifier.sendMessageStream(
        'Please write a recap of this village voice session.',
        systemPromptOverride: systemPrompt,
      )) {
        fullResponse += chunk;
      }

      return fullResponse.trim();
    } catch (e) {
      debugPrint('Error generating village recap: $e');
      return 'Polie listened in on your village session. Keep greeting others, trying new phrases, and don’t worry about mistakes—every voice note grows your confidence.';
    }
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

