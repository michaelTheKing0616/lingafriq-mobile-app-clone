// Historical African Personalities AI Chat Service
// World-class personality simulation with complete knowledge base
// 
// Features:
// - Complete knowledge of historical personalities
// - Authentic dialogue simulation
// - Cultural and historical context
// - Memory system for conversations
// - Personality-consistent responses
// - Integrated with Polie architecture
// 
// Production-ready implementation (December 2025)

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Historical Personality
class HistoricalPersonality {
  /// Unique identifier
  final String id;
  
  /// Name
  final String name;
  
  /// Birth and death dates
  final String? birthDate;
  final String? deathDate;
  
  /// Country/region
  final String country;
  
  /// Primary language
  final String language;
  
  /// Biography
  final String biography;
  
  /// Key achievements
  final List<String> achievements;
  
  /// Personality traits
  final List<String> traits;
  
  /// Speech patterns/characteristics
  final Map<String, dynamic> speechPatterns;
  
  /// Knowledge base topics
  final List<String> knowledgeTopics;
  
  /// Image URL
  final String? imageUrl;
  
  /// Cultural context
  final Map<String, dynamic> culturalContext;

  HistoricalPersonality({
    required this.id,
    required this.name,
    this.birthDate,
    this.deathDate,
    required this.country,
    required this.language,
    required this.biography,
    required this.achievements,
    required this.traits,
    required this.speechPatterns,
    required this.knowledgeTopics,
    this.imageUrl,
    required this.culturalContext,
  });

  factory HistoricalPersonality.fromJson(Map<String, dynamic> json) {
    return HistoricalPersonality(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      birthDate: json['birth_date'],
      deathDate: json['death_date'],
      country: json['country'] ?? '',
      language: json['language'] ?? '',
      biography: json['biography'] ?? '',
      achievements: List<String>.from(json['achievements'] ?? []),
      traits: List<String>.from(json['traits'] ?? []),
      speechPatterns: Map<String, dynamic>.from(json['speech_patterns'] ?? {}),
      knowledgeTopics: List<String>.from(json['knowledge_topics'] ?? []),
      imageUrl: json['image_url'],
      culturalContext: Map<String, dynamic>.from(json['cultural_context'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birth_date': birthDate,
    'death_date': deathDate,
    'country': country,
    'language': language,
    'biography': biography,
    'achievements': achievements,
    'traits': traits,
    'speech_patterns': speechPatterns,
    'knowledge_topics': knowledgeTopics,
    'image_url': imageUrl,
    'cultural_context': culturalContext,
  };
}

/// Personality Chat Message
class PersonalityMessage {
  final String role; // 'user' or 'personality'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PersonalityMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  factory PersonalityMessage.fromJson(Map<String, dynamic> json) {
    return PersonalityMessage(
      role: json['role'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Personality Chat Session
class PersonalityChatSession {
  final String sessionId;
  final String personalityId;
  final String userId;
  final List<PersonalityMessage> messages;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final Map<String, dynamic> context;

  PersonalityChatSession({
    required this.sessionId,
    required this.personalityId,
    required this.userId,
    required this.messages,
    required this.createdAt,
    this.lastActivity,
    required this.context,
  });

  factory PersonalityChatSession.fromJson(Map<String, dynamic> json) {
    return PersonalityChatSession(
      sessionId: json['session_id'] ?? '',
      personalityId: json['personality_id'] ?? '',
      userId: json['user_id'] ?? '',
      messages: (json['messages'] as List?)
          ?.map((m) => PersonalityMessage.fromJson(m))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }
}

/// Historical Personality Service Provider
final historicalPersonalityServiceProvider = Provider<HistoricalPersonalityService>((ref) {
  return HistoricalPersonalityService(ref);
});

/// Historical Personality Service
/// 
/// Provides world-class personality simulation with:
/// - Complete knowledge bases
/// - Authentic dialogue
/// - Cultural context
/// - Memory system
/// - Personality consistency
class HistoricalPersonalityService {
  // ignore: unused_field
  final Ref _ref;
  final Dio _dio;

  HistoricalPersonalityService(this._ref) : _dio = _ref.read(client);

  Future<Response<dynamic>> _getWithFallbackPaths(
    List<String> paths, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        final response = await _dio.get(path, queryParameters: queryParameters);
        if (response.statusCode != null && response.statusCode! < 500) {
          return response;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('No reachable historical personality endpoint');
  }

  Future<Response<dynamic>> _postWithFallbackPaths(
    List<String> paths, {
    required Map<String, dynamic> data,
  }) async {
    Object? lastError;
    for (final path in paths) {
      try {
        final response = await _dio.post(path, data: data);
        if (response.statusCode != null && response.statusCode! < 500) {
          return response;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('No reachable historical personality endpoint');
  }

  dynamic _extractPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw['data'] ?? raw['result'] ?? raw;
    }
    return raw;
  }

  List<Map<String, dynamic>> _extractPersonalityList(dynamic raw) {
    final payload = _extractPayload(raw);
    final dynamic list = payload is Map<String, dynamic>
        ? (payload['personalities'] ?? payload['items'] ?? payload['results'] ?? payload['data'])
        : payload;
    if (list is List) {
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  PersonalityMessage _parseAssistantMessage(dynamic raw) {
    final payload = _extractPayload(raw);
    if (payload is Map<String, dynamic>) {
      final direct = payload['response'] ?? payload['assistant'] ?? payload['reply'] ?? payload['message'];
      if (direct is Map<String, dynamic>) {
        return PersonalityMessage(
          role: (direct['role']?.toString().isNotEmpty ?? false)
              ? direct['role'].toString()
              : 'personality',
          content: (direct['content'] ?? direct['text'] ?? '').toString(),
          timestamp: DateTime.tryParse((direct['timestamp'] ?? '').toString()) ?? DateTime.now(),
          metadata: direct['metadata'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(direct['metadata'])
              : null,
        );
      }
      if (direct is String && direct.trim().isNotEmpty) {
        return PersonalityMessage(
          role: 'personality',
          content: direct.trim(),
          timestamp: DateTime.now(),
        );
      }

      final content = (payload['content'] ?? payload['text'] ?? '').toString().trim();
      if (content.isNotEmpty) {
        return PersonalityMessage(
          role: (payload['role'] ?? 'personality').toString(),
          content: content,
          timestamp: DateTime.now(),
          metadata: payload['metadata'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(payload['metadata'])
              : null,
        );
      }
    }

    throw Exception('Historical personality API returned an empty assistant response');
  }

  /// Get all available personalities
  Future<List<HistoricalPersonality>> getPersonalities({
    String? country,
    String? language,
    String? era,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (country != null) queryParams['country'] = country;
      if (language != null) queryParams['language'] = language;
      if (era != null) queryParams['era'] = era;

      final response = await _getWithFallbackPaths(
        [
          ApiContract.url(ApiContract.personalities.list),
          '/api/personalities',
          '/api/v1/personalities',
          '/api/v1/historical-personalities',
          '/api/historical-personalities',
          '/historical-personalities',
        ],
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final personalities = _extractPersonalityList(response.data);
        if (personalities.isNotEmpty) {
          return personalities
              .map((p) => HistoricalPersonality.fromJson(p))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get personalities error: $e');
      return [];
    }
  }

  /// Get specific personality
  Future<HistoricalPersonality?> getPersonality(String personalityId) async {
    try {
      final response = await _dio.get(
        ApiContract.url(
          ApiContract.personalities.details(personalityId),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return HistoricalPersonality.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Get personality error: $e');
      return null;
    }
  }

  /// Start a chat session with a personality
  Future<PersonalityChatSession> startChatSession({
    required String personalityId,
    required String userId,
    Map<String, dynamic>? initialContext,
  }) async {
    try {
      final response = await _postWithFallbackPaths(
        [
          ApiContract.url(ApiContract.personalities.chatStart(personalityId)),
          '/api/personalities/$personalityId/chat/start',
          '/api/v1/personalities/$personalityId/chat/start',
          '/api/v1/historical-personalities/$personalityId/chat/start',
          '/api/historical-personalities/$personalityId/chat/start',
          '/historical-personalities/$personalityId/chat/start',
        ],
        data: {
          'user_id': userId,
          'initial_context': initialContext ?? {},
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _extractPayload(response.data);
        final sessionPayload =
            data is Map<String, dynamic> && data['session'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(data['session'])
                : data;
        if (sessionPayload is! Map<String, dynamic>) {
          throw Exception('Unexpected chat session payload');
        }
        return PersonalityChatSession.fromJson(sessionPayload);
      }

      throw Exception('Failed to start chat session');
    } catch (e) {
      debugPrint('Start chat session error: $e');
      rethrow;
    }
  }

  /// Send message to personality
  Future<PersonalityMessage> sendMessage({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _postWithFallbackPaths(
        [
          ApiContract.url(ApiContract.personalities.chatMessage(sessionId)),
          '/api/personalities/chat/$sessionId/message',
          '/api/v1/personalities/chat/$sessionId/message',
          '/api/v1/historical-personalities/chat/$sessionId/message',
          '/api/historical-personalities/chat/$sessionId/message',
          '/historical-personalities/chat/$sessionId/message',
        ],
        data: {
          'message': message,
          'context': {
            ...(context ?? <String, dynamic>{}),
            'providerPolicy': 'gemini_first',
            'client': 'mobile',
            'feature': 'historical_personality_chat',
          },
        },
      );

      if (response.statusCode == 200) {
        return _parseAssistantMessage(response.data);
      }

      throw Exception('Failed to send message');
    } catch (e) {
      debugPrint('Send message error: $e');
      rethrow;
    }
  }

  /// Get chat session history
  Future<PersonalityChatSession?> getChatSession(String sessionId) async {
    try {
      final response = await _dio.get(
        ApiContract.url(
          ApiContract.personalities.chatSession(sessionId),
        ),
      );

      if (response.statusCode == 200) {
        final data = _extractPayload(response.data);
        final sessionPayload =
            data is Map<String, dynamic> && data['session'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(data['session'])
                : data;
        if (sessionPayload is! Map<String, dynamic>) return null;
        return PersonalityChatSession.fromJson(sessionPayload);
      }

      return null;
    } catch (e) {
      debugPrint('Get chat session error: $e');
      return null;
    }
  }

  /// Get user's chat sessions
  Future<List<PersonalityChatSession>> getUserChatSessions({
    required String userId,
    String? personalityId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (personalityId != null) queryParams['personality_id'] = personalityId;

      final response = await _dio.get(
        ApiContract.url(
          ApiContract.personalities.userChatSessions(userId),
        ),
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final sessions = data['sessions'] as List?;
        if (sessions != null) {
          return sessions
              .map((s) => PersonalityChatSession.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get user chat sessions error: $e');
      return [];
    }
  }

  /// Get personality knowledge on a topic
  Future<Map<String, dynamic>> getPersonalityKnowledge({
    required String personalityId,
    required String topic,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(
          ApiContract.personalities.knowledge(personalityId),
        ),
        queryParameters: {'topic': topic},
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }

      return {};
    } catch (e) {
      debugPrint('Get personality knowledge error: $e');
      return {};
    }
  }

  /// Get conversation suggestions
  Future<List<String>> getConversationSuggestions({
    required String personalityId,
    String? currentTopic,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (currentTopic != null) queryParams['current_topic'] = currentTopic;

      final response = await _dio.get(
        ApiContract.url(
          ApiContract.personalities.suggestions(personalityId),
        ),
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return List<String>.from(data['suggestions'] ?? []);
      }

      return [];
    } catch (e) {
      debugPrint('Get conversation suggestions error: $e');
      return [];
    }
  }
}

