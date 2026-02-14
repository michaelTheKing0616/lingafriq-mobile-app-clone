// Enhanced Historical Personality Service
// Provides world-class personality simulation with memory, knowledge base, and educational features
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/historical_personality_enhanced_model.dart';
import '../providers/user_provider.dart';
import '../providers/backend_sync_provider.dart';
import 'ai/historical_personality_service.dart' as base_service;

final enhancedHistoricalPersonalityServiceProvider = Provider<EnhancedHistoricalPersonalityService>((ref) {
  return EnhancedHistoricalPersonalityService(ref);
});

class EnhancedHistoricalPersonalityService {
  final Ref _ref;

  EnhancedHistoricalPersonalityService(this._ref);

  /// Get base service
  base_service.HistoricalPersonalityService get _baseService {
    return _ref.read(base_service.historicalPersonalityServiceProvider);
  }

  /// Get enhanced personality with full knowledge base
  Future<EnhancedHistoricalPersonality?> getEnhancedPersonality(String personalityId) async {
    try {
      // Get base personality
      final baseService = _baseService;
      final base = await baseService.getPersonality(personalityId);
      if (base == null) return null;

      // Load enhanced data from cache or generate
      final enhanced = await _loadEnhancedData(personalityId);
      
      return EnhancedHistoricalPersonality(
        id: base.id,
        name: base.name,
        birthDate: base.birthDate,
        deathDate: base.deathDate,
        country: base.country,
        language: base.language,
        biography: base.biography,
        achievements: base.achievements,
        traits: base.traits,
        speechPatterns: base.speechPatterns,
        knowledgeTopics: base.knowledgeTopics,
        imageUrl: base.imageUrl,
        culturalContext: base.culturalContext,
        knowledgeBase: enhanced['knowledge_base'] ?? {},
        famousQuotes: enhanced['famous_quotes'] ?? [],
        timelineEvents: (enhanced['timeline_events'] as List?)
                ?.map((e) => HistoricalEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        regionalVariations: enhanced['regional_variations'] ?? {},
        relatedPersonalities: enhanced['related_personalities'] ?? [],
        educationalContent: enhanced['educational_content'] ?? {},
        audioVoiceUrl: enhanced['audio_voice_url'],
        visualAssets: enhanced['visual_assets'],
      );
    } catch (e) {
      debugPrint('Error getting enhanced personality: $e');
      return null;
    }
  }

  /// Load enhanced data from cache
  Future<Map<String, dynamic>> _loadEnhancedData(String personalityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enhancedJson = prefs.getString('personality_enhanced_$personalityId');
      
      if (enhancedJson != null && enhancedJson.isNotEmpty) {
        return jsonDecode(enhancedJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading enhanced personality data: $e');
    }

    // Return default enhanced data structure
    return {
      'knowledge_base': {},
      'famous_quotes': [],
      'timeline_events': [],
      'regional_variations': {},
      'related_personalities': [],
      'educational_content': {},
    };
  }

  /// Get or create personality memory
  Future<PersonalityChatMemory> getPersonalityMemory(String personalityId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryKey = 'personality_memory_${personalityId}_$userId';
      final memoryJson = prefs.getString(memoryKey);
      
      if (memoryJson != null && memoryJson.isNotEmpty) {
        return PersonalityChatMemory.fromJson(jsonDecode(memoryJson) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading personality memory: $e');
    }

    return PersonalityChatMemory(
      personalityId: personalityId,
      userId: userId,
    );
  }

  /// Save personality memory
  Future<void> savePersonalityMemory(PersonalityChatMemory memory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryKey = 'personality_memory_${memory.personalityId}_${memory.userId}';
      await prefs.setString(memoryKey, jsonEncode(memory.toJson()));
      
      // Sync to backend
      await _syncToBackend(memory);
    } catch (e) {
      debugPrint('Error saving personality memory: $e');
    }
  }

  /// Add conversation context to memory
  Future<void> addConversationContext(
    String personalityId,
    String userId,
    ConversationContext context,
  ) async {
    final memory = await getPersonalityMemory(personalityId, userId);
    
    final updatedHistory = [context, ...memory.conversationHistory].take(20).toList();
    final updatedTopics = {...memory.topicsDiscussed, context.topic};
    
    // Update user interests based on topic
    final updatedInterests = Map<String, int>.from(memory.userInterests);
    updatedInterests[context.topic] = (updatedInterests[context.topic] ?? 0) + 1;

    final updatedMemory = memory.copyWith(
      conversationHistory: updatedHistory,
      topicsDiscussed: updatedTopics,
      userInterests: updatedInterests,
      lastConversation: DateTime.now(),
    );

    await savePersonalityMemory(updatedMemory);
  }

  /// Get conversation suggestions based on memory
  Future<List<String>> getConversationSuggestions(String personalityId, String userId) async {
    final memory = await getPersonalityMemory(personalityId, userId);
    final personality = await getEnhancedPersonality(personalityId);
    
    if (personality == null) return [];

    final suggestions = <String>[];
    
    // Suggest topics from knowledge base that haven't been discussed
    for (final topic in personality.knowledgeTopics) {
      if (!memory.topicsDiscussed.contains(topic)) {
        suggestions.add('Tell me about $topic');
      }
    }

    // Suggest based on user interests
    final topInterests = memory.userInterests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final interest in topInterests.take(3)) {
      suggestions.add('Can we discuss more about ${interest.key}?');
    }

    // Suggest timeline events
    if (personality.timelineEvents.isNotEmpty) {
      suggestions.add('What was happening in ${personality.timelineEvents.first.year}?');
    }

    // Suggest quotes
    if (personality.famousQuotes.isNotEmpty) {
      suggestions.add('What is your most famous quote?');
    }

    return suggestions.take(5).toList();
  }

  /// Get educational content (quiz, facts, etc.)
  Future<Map<String, dynamic>> getEducationalContent(String personalityId, String contentType) async {
    final personality = await getEnhancedPersonality(personalityId);
    if (personality == null) return {};

    final content = personality.educationalContent[contentType];
    if (content != null) {
      return content as Map<String, dynamic>;
    }

    // Generate educational content based on personality data
    switch (contentType) {
      case 'quiz':
        return _generateQuiz(personality);
      case 'facts':
        return _generateFacts(personality);
      case 'timeline':
        return {'events': personality.timelineEvents.map((e) => e.toJson()).toList()};
      default:
        return {};
    }
  }

  Map<String, dynamic> _generateQuiz(EnhancedHistoricalPersonality personality) {
    return {
      'questions': [
        {
          'question': 'When was ${personality.name} born?',
          'options': [personality.birthDate ?? 'Unknown', 'Other dates...'],
          'correct': 0,
        },
        {
          'question': 'What is ${personality.name} known for?',
          'options': personality.achievements.take(4).toList(),
          'correct': 0,
        },
      ],
    };
  }

  Map<String, dynamic> _generateFacts(EnhancedHistoricalPersonality personality) {
    return {
      'facts': [
        ...personality.achievements,
        ...personality.famousQuotes.take(3),
      ],
    };
  }

  /// Sync memory to backend
  Future<void> _syncToBackend(PersonalityChatMemory memory) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;

      final syncProvider = _ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.progress,
        data: {
          'user_id': user.id.toString(),
          'type': 'personality_memory',
          'personality_id': memory.personalityId,
          'memory': memory.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error syncing personality memory: $e');
    }
  }
}

