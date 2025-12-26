/// Smart Recommendations Service
/// Provides personalized content recommendations based on user behavior

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'dart:convert';
import 'dart:math';

/// Recommendation types
enum RecommendationType {
  lesson,
  game,
  article,
  word,
  story,
  quiz,
}

/// Recommendation model
class Recommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final String? imageUrl;
  final double score; // 0.0 - 1.0
  final Map<String, dynamic> metadata;

  Recommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.score,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'score': score,
        'metadata': metadata,
      };

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        id: json['id'] as String,
        type: RecommendationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RecommendationType.lesson,
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String?,
        score: (json['score'] ?? 0.0).toDouble(),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
}

/// Smart recommendations service
class SmartRecommendationsService {
  static final SmartRecommendationsService _instance =
      SmartRecommendationsService._internal();
  factory SmartRecommendationsService() => _instance;
  SmartRecommendationsService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Track user interaction
  Future<void> trackInteraction({
    required String itemId,
    required RecommendationType type,
    required String action, // 'view', 'complete', 'skip', 'favorite'
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    final history = await getUserHistory();
    history.add({
      'itemId': itemId,
      'type': type.name,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    });

    // Keep only last 100 interactions
    if (history.length > 100) {
      history.removeRange(0, history.length - 100);
    }

    await _prefs!.setStringList(
      'recommendation_history',
      history.map((e) => jsonEncode(e)).toList(),
    );
  }

  /// Get user interaction history
  Future<List<Map<String, dynamic>>> getUserHistory() async {
    await initialize();
    final historyJson = _prefs!.getStringList('recommendation_history') ?? [];
    return historyJson.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    await initialize();
    final history = await getUserHistory();

    // Analyze history to determine preferences
    final typeCounts = <RecommendationType, int>{};
    final actionCounts = <String, int>{};
    final languageCounts = <String, int>{};

    for (final interaction in history) {
      final type = RecommendationType.values.firstWhere(
        (e) => e.name == interaction['type'],
        orElse: () => RecommendationType.lesson,
      );
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;

      final action = interaction['action'] as String;
      actionCounts[action] = (actionCounts[action] ?? 0) + 1;

      final language = interaction['metadata']?['language'] as String?;
      if (language != null) {
        languageCounts[language] = (languageCounts[language] ?? 0) + 1;
      }
    }

    // Find preferred type
    RecommendationType? preferredType;
    int maxCount = 0;
    typeCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        preferredType = type;
      }
    });

    // Find preferred language
    String? preferredLanguage;
    int maxLangCount = 0;
    languageCounts.forEach((lang, count) {
      if (count > maxLangCount) {
        maxLangCount = count;
        preferredLanguage = lang;
      }
    });

    return {
      'preferredType': preferredType?.name,
      'preferredLanguage': preferredLanguage,
      'totalInteractions': history.length,
      'completionRate': (actionCounts['complete'] ?? 0) / history.length,
    };
  }

  /// Generate recommendations
  Future<List<Recommendation>> generateRecommendations({
    int limit = 10,
    String? language,
    RecommendationType? preferredType,
  }) async {
    await initialize();

    final preferences = await getUserPreferences();
    final history = await getUserHistory();
    final completedIds = history
        .where((e) => e['action'] == 'complete')
        .map((e) => e['itemId'] as String)
        .toSet();

    // Get all available content (this would come from your API/database)
    final allContent = await _getAllContent(language: language);

    // Score each item
    final scored = allContent.map((item) {
      double score = 0.5; // Base score

      // Boost if matches preferred type
      if (preferredType != null && item['type'] == preferredType.name) {
        score += 0.2;
      }

      // Boost if matches preferred language
      final prefLang = preferences['preferredLanguage'] as String?;
      if (prefLang != null && item['language'] == prefLang) {
        score += 0.15;
      }

      // Penalize if already completed
      if (completedIds.contains(item['id'])) {
        score -= 0.3;
      }

      // Add randomness for variety
      score += Random().nextDouble() * 0.1;

      return Recommendation(
        id: item['id'] as String,
        type: RecommendationType.values.firstWhere(
          (e) => e.name == item['type'],
          orElse: () => RecommendationType.lesson,
        ),
        title: item['title'] as String,
        description: item['description'] as String,
        imageUrl: item['imageUrl'] as String?,
        score: score.clamp(0.0, 1.0),
        metadata: Map<String, dynamic>.from(item['metadata'] ?? {}),
      );
    }).toList();

    // Sort by score and return top N
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).toList();
  }

  /// Get all available content from API
  Future<List<Map<String, dynamic>>> _getAllContent({String? language}) async {
    try {
      final List<Map<String, dynamic>> allContent = [];

      // Fetch lessons
      try {
        final lessonsResponse = await ApiService.get(
          '/lessons',
          queryParameters: language != null ? {'language': language} : null,
          requireAuth: true,
        );
        if (lessonsResponse.statusCode == 200 && lessonsResponse.data['data'] != null) {
          final lessons = List<Map<String, dynamic>>.from(lessonsResponse.data['data']);
          allContent.addAll(lessons.map((lesson) => {
                'id': lesson['_id'] ?? lesson['id'],
                'type': 'lesson',
                'title': lesson['title'] ?? lesson['name'] ?? 'Untitled Lesson',
                'description': lesson['description'] ?? lesson['summary'] ?? '',
                'language': lesson['language'] ?? language ?? 'yoruba',
                'imageUrl': lesson['imageUrl'] ?? lesson['thumbnail'],
                'metadata': {
                  'level': lesson['level'],
                  'difficulty': lesson['difficulty'],
                  'duration': lesson['duration'],
                },
              }));
        }
      } catch (e) {
        // Continue if lessons endpoint fails - error is logged but doesn't stop other fetches
        // In production, you might want to log this: ErrorHandler.logError(e);
      }

      // Fetch games
      try {
        final gamesResponse = await ApiService.get(Api.games);
        if (gamesResponse.statusCode == 200 && gamesResponse.data['data'] != null) {
          final games = List<Map<String, dynamic>>.from(gamesResponse.data['data']);
          allContent.addAll(games.map((game) => {
                'id': game['_id'] ?? game['id'],
                'type': 'game',
                'title': game['title'] ?? game['name'] ?? 'Untitled Game',
                'description': game['description'] ?? game['summary'] ?? '',
                'language': game['language'] ?? language ?? 'yoruba',
                'imageUrl': game['imageUrl'] ?? game['thumbnail'],
                'metadata': {
                  'category': game['category'],
                  'difficulty': game['difficulty'],
                },
              }));
        }
      } catch (e) {
        // Continue if games endpoint fails
      }

      // Fetch culture articles
      try {
        final articlesResponse = await ApiService.get(
          Api.cultureArticles(published: true),
          queryParameters: {
            'published': true,
            if (language != null) 'country': language,
          },
        );
        if (articlesResponse.statusCode == 200 && articlesResponse.data['data'] != null) {
          final articles = List<Map<String, dynamic>>.from(articlesResponse.data['data']);
          allContent.addAll(articles.map((article) => {
                'id': article['_id'] ?? article['id'],
                'type': 'article',
                'title': article['title'] ?? 'Untitled Article',
                'description': article['excerpt'] ?? article['summary'] ?? '',
                'language': article['country'] ?? language ?? 'yoruba',
                'imageUrl': article['imageUrl'] ?? article['thumbnail'],
                'metadata': {
                  'category': article['category'],
                  'author': article['author'],
                },
              }));
        }
      } catch (e) {
        // Continue if articles endpoint fails
      }

      // Fetch stories
      try {
        final storiesResponse = await ApiService.get(
          '/stories',
          queryParameters: language != null ? {'language': language} : null,
        );
        if (storiesResponse.statusCode == 200 && storiesResponse.data['data'] != null) {
          final stories = List<Map<String, dynamic>>.from(storiesResponse.data['data']);
          allContent.addAll(stories.map((story) => {
                'id': story['_id'] ?? story['id'],
                'type': 'story',
                'title': story['title'] ?? story['name'] ?? 'Untitled Story',
                'description': story['description'] ?? story['summary'] ?? '',
                'language': story['language'] ?? language ?? 'yoruba',
                'imageUrl': story['imageUrl'] ?? story['thumbnail'],
                'metadata': {
                  'level': story['level'],
                  'genre': story['genre'],
                },
              }));
        }
      } catch (e) {
        // Continue if stories endpoint fails
      }

      // Fetch quizzes
      try {
        final quizzesResponse = await ApiService.get(
          '/quizzes',
          queryParameters: language != null ? {'language': language} : null,
        );
        if (quizzesResponse.statusCode == 200 && quizzesResponse.data['data'] != null) {
          final quizzes = List<Map<String, dynamic>>.from(quizzesResponse.data['data']);
          allContent.addAll(quizzes.map((quiz) => {
                'id': quiz['_id'] ?? quiz['id'],
                'type': 'quiz',
                'title': quiz['title'] ?? quiz['name'] ?? 'Untitled Quiz',
                'description': quiz['description'] ?? quiz['summary'] ?? '',
                'language': quiz['language'] ?? language ?? 'yoruba',
                'imageUrl': quiz['imageUrl'] ?? quiz['thumbnail'],
                'metadata': {
                  'level': quiz['level'],
                  'questionCount': quiz['questionCount'] ?? quiz['questions']?.length,
                },
              }));
        }
      } catch (e) {
        // Continue if quizzes endpoint fails
      }

      // If no content fetched, return empty list
      return allContent;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Clear recommendation history
  Future<void> clearHistory() async {
    await initialize();
    await _prefs!.remove('recommendation_history');
  }
}

/// Provider for smart recommendations
final smartRecommendationsProvider =
    FutureProvider.autoDispose<List<Recommendation>>((ref) async {
  final service = SmartRecommendationsService();
  await service.initialize();
  final preferences = await service.getUserPreferences();
  
  return service.generateRecommendations(
    preferredType: preferences['preferredType'] != null
        ? RecommendationType.values.firstWhere(
            (e) => e.name == preferences['preferredType'],
          )
        : null,
    language: preferences['preferredLanguage'] as String?,
  );
});

