/// Interactive Exercises & Story-Based Learning Service
/// World-class interactive learning experiences
/// 
/// Features:
/// - Story-based learning with branching narratives
/// - Interactive exercises (fill-in-blank, multiple choice, etc.)
/// - Adaptive difficulty
/// - Immediate feedback
/// - Progress tracking
/// - Cultural context integration
/// 
/// Production-ready implementation (December 2025)

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Exercise Type
enum ExerciseType {
  fillInBlank,
  multipleChoice,
  matching,
  ordering,
  pronunciation,
  conversation,
  story,
  cultural,
}

/// Exercise
class Exercise {
  final String id;
  final ExerciseType type;
  final String language;
  final String title;
  final String? description;
  final Map<String, dynamic> content;
  final int difficulty; // 1-5
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.type,
    required this.language,
    required this.title,
    this.description,
    required this.content,
    required this.difficulty,
    this.tags,
    this.metadata,
    required this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      type: ExerciseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExerciseType.multipleChoice,
      ),
      language: json['language'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      content: Map<String, dynamic>.from(json['content'] ?? {}),
      difficulty: json['difficulty'] ?? 1,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Story
class Story {
  final String id;
  final String language;
  final String title;
  final String? description;
  final List<StoryChapter> chapters;
  final Map<String, dynamic> metadata;
  final int difficulty;
  final List<String>? tags;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.language,
    required this.title,
    this.description,
    required this.chapters,
    required this.metadata,
    required this.difficulty,
    this.tags,
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? '',
      language: json['language'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      chapters: (json['chapters'] as List?)
          ?.map((c) => StoryChapter.fromJson(c))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      difficulty: json['difficulty'] ?? 1,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Story Chapter
class StoryChapter {
  final String id;
  final int chapterNumber;
  final String title;
  final String content;
  final List<StoryChoice>? choices;
  final Map<String, dynamic>? exercises;
  final Map<String, dynamic>? metadata;

  StoryChapter({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.content,
    this.choices,
    this.exercises,
    this.metadata,
  });

  factory StoryChapter.fromJson(Map<String, dynamic> json) {
    return StoryChapter(
      id: json['id'] ?? '',
      chapterNumber: json['chapter_number'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      choices: json['choices'] != null
          ? (json['choices'] as List)
              .map((c) => StoryChoice.fromJson(c))
              .toList()
          : null,
      exercises: json['exercises'] != null
          ? Map<String, dynamic>.from(json['exercises'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

/// Story Choice (for branching narratives)
class StoryChoice {
  final String id;
  final String text;
  final String nextChapterId;
  final Map<String, dynamic>? consequences;

  StoryChoice({
    required this.id,
    required this.text,
    required this.nextChapterId,
    this.consequences,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      nextChapterId: json['next_chapter_id'] ?? '',
      consequences: json['consequences'] != null
          ? Map<String, dynamic>.from(json['consequences'])
          : null,
    );
  }
}

/// Exercise Result
class ExerciseResult {
  final String exerciseId;
  final bool correct;
  final double score; // 0.0 - 1.0
  final String? feedback;
  final Map<String, dynamic>? details;
  final DateTime completedAt;

  ExerciseResult({
    required this.exerciseId,
    required this.correct,
    required this.score,
    this.feedback,
    this.details,
    required this.completedAt,
  });

  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      exerciseId: json['exercise_id'] ?? '',
      correct: json['correct'] ?? false,
      score: (json['score'] ?? 0.0).toDouble(),
      feedback: json['feedback'],
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'])
          : null,
      completedAt: DateTime.parse(json['completed_at']),
    );
  }
}

/// Interactive Exercises Service Provider
final interactiveExercisesServiceProvider = Provider<InteractiveExercisesService>((ref) {
  return InteractiveExercisesService(ref);
});

/// Interactive Exercises Service
class InteractiveExercisesService {
  final Ref _ref;
  final Dio _dio;

  InteractiveExercisesService(this._ref) : _dio = _ref.read(client);

  /// Get exercises for a language
  Future<List<Exercise>> getExercises({
    required String language,
    ExerciseType? type,
    int? difficulty,
    List<String>? tags,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'language': language,
        if (type != null) 'type': type.name,
        if (difficulty != null) 'difficulty': difficulty,
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
        if (limit != null) 'limit': limit,
      };

      final response = await _dio.get(
        ApiContract.url(ApiContract.interactive.exercises),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final exercises = data['exercises'] as List?;
        if (exercises != null) {
          return exercises
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get exercises error: $e');
      return [];
    }
  }

  /// Get specific exercise
  Future<Exercise?> getExercise(String exerciseId) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.interactive.exercise(exerciseId)),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return Exercise.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Get exercise error: $e');
      return null;
    }
  }

  /// Submit exercise answer
  Future<ExerciseResult> submitExercise({
    required String exerciseId,
    required Map<String, dynamic> answer,
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.interactive.exerciseSubmit(exerciseId)),
        data: {
          'answer': answer,
          if (userId != null) 'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return ExerciseResult.fromJson(data);
      }

      throw Exception('Failed to submit exercise');
    } catch (e) {
      debugPrint('Submit exercise error: $e');
      rethrow;
    }
  }

  /// Get stories for a language
  Future<List<Story>> getStories({
    required String language,
    int? difficulty,
    List<String>? tags,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'language': language,
        if (difficulty != null) 'difficulty': difficulty,
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
        if (limit != null) 'limit': limit,
      };

      final response = await _dio.get(
        ApiContract.url(ApiContract.interactive.stories),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final stories = data['stories'] as List?;
        if (stories != null) {
          return stories
              .map((s) => Story.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get stories error: $e');
      return [];
    }
  }

  /// Get specific story
  Future<Story?> getStory(String storyId) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.interactive.story(storyId)),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return Story.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Get story error: $e');
      return null;
    }
  }

  /// Get story chapter
  Future<StoryChapter?> getStoryChapter({
    required String storyId,
    required String chapterId,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(
          ApiContract.interactive.storyChapter(storyId, chapterId),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return StoryChapter.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Get story chapter error: $e');
      return null;
    }
  }

  /// Submit story choice
  Future<StoryChapter?> submitStoryChoice({
    required String storyId,
    required String chapterId,
    required String choiceId,
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(
          ApiContract.interactive.storyChapterChoice(storyId, chapterId),
        ),
        data: {
          'choice_id': choiceId,
          if (userId != null) 'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return StoryChapter.fromJson(data['next_chapter']);
      }

      return null;
    } catch (e) {
      debugPrint('Submit story choice error: $e');
      return null;
    }
  }

  /// Get user's story progress
  Future<Map<String, dynamic>> getStoryProgress({
    required String userId,
    required String storyId,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(
          ApiContract.interactive.storyProgress(storyId, userId),
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }

      return {};
    } catch (e) {
      debugPrint('Get story progress error: $e');
      return {};
    }
  }

  /// Get adaptive exercise recommendations
  Future<List<Exercise>> getAdaptiveExercises({
    required String userId,
    required String language,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.interactive.exercisesAdaptive),
        queryParameters: {
          'user_id': userId,
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final exercises = data['exercises'] as List?;
        if (exercises != null) {
          return exercises
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get adaptive exercises error: $e');
      return [];
    }
  }
}

