import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/api_provider.dart';
import '../providers/user_provider.dart';

/// User Generated Content Service
/// Allows users to create and share their own learning content
class UserGeneratedContentService {
  final Ref _ref;

  UserGeneratedContentService(this._ref);

  /// Create a user-generated lesson
  Future<Map<String, dynamic>?> createLesson({
    required String language,
    required String title,
    required String content,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) throw Exception('User not logged in');

      final api = _ref.read(apiProvider.notifier);
      final data = {
        'language': language,
        'title': title,
        'content': content,
        'description': description,
        'tags': tags ?? [],
        'author_id': user.id,
        'type': 'user_generated',
      };

      debugPrint('Creating user-generated lesson: $title');
      final result = await api.createUgcLesson(data);
      return result;
    } catch (e) {
      debugPrint('Error creating user-generated lesson: $e');
      return null;
    }
  }

  /// Create a user-generated quiz
  Future<Map<String, dynamic>?> createQuiz({
    required String language,
    required String title,
    required List<Map<String, dynamic>> questions,
    String? description,
  }) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) throw Exception('User not logged in');

      final api = _ref.read(apiProvider.notifier);
      final data = {
        'language': language,
        'title': title,
        'questions': questions,
        'description': description,
        'author_id': user.id,
        'type': 'user_generated',
      };

      debugPrint('Creating user-generated quiz: $title');
      final result = await api.createUgcQuiz(data);
      return result;
    } catch (e) {
      debugPrint('Error creating user-generated quiz: $e');
      return null;
    }
  }

  /// Create a user-generated story
  Future<Map<String, dynamic>?> createStory({
    required String language,
    required String title,
    required String story,
    String? theme,
    List<String>? vocabulary,
  }) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) throw Exception('User not logged in');

      final api = _ref.read(apiProvider.notifier);
      final data = {
        'language': language,
        'title': title,
        'story': story,
        'theme': theme,
        'vocabulary': vocabulary ?? [],
        'author_id': user.id,
        'type': 'user_generated',
      };

      debugPrint('Creating user-generated story: $title');
      final result = await api.createUgcStory(data);
      return result;
    } catch (e) {
      debugPrint('Error creating user-generated story: $e');
      return null;
    }
  }

  /// Share content with other users
  Future<bool> shareContent({
    required String contentId,
    required String contentType, // 'lesson', 'quiz', 'story'
    List<String>? userIds, // Specific users, or null for public
  }) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) throw Exception('User not logged in');

      final api = _ref.read(apiProvider.notifier);
      final success = await api.shareUgcContent(
        contentId: contentId,
        contentType: contentType,
        userIds: userIds,
      );

      debugPrint('Sharing content: $contentId - ${success ? "Success" : "Failed"}');
      return success;
    } catch (e) {
      debugPrint('Error sharing content: $e');
      return false;
    }
  }

  /// Get user-generated content
  Future<List<Map<String, dynamic>>> getUserContent({
    String? language,
    String? contentType,
    String? authorId,
  }) async {
    try {
      final api = _ref.read(apiProvider.notifier);
      debugPrint('Fetching user-generated content');
      
      final result = await api.getUserContent(
        language: language,
        contentType: contentType,
      );
      
      // Filter by authorId if provided (client-side filter)
      if (authorId != null) {
        return result.where((item) => item['author_id'] == authorId).toList();
      }
      
      return result;
    } catch (e) {
      debugPrint('Error fetching user-generated content: $e');
      return [];
    }
  }

  /// Rate user-generated content
  Future<bool> rateContent({
    required String contentId,
    required int rating, // 1-5
    String? review,
  }) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) throw Exception('User not logged in');

      final api = _ref.read(apiProvider.notifier);
      debugPrint('Rating content: $contentId with $rating stars');
      
      final success = await api.rateUgcContent(
        contentId: contentId,
        rating: rating,
        review: review,
      );
      
      return success;
    } catch (e) {
      debugPrint('Error rating content: $e');
      return false;
    }
  }
}

final userGeneratedContentServiceProvider = Provider<UserGeneratedContentService>((ref) {
  return UserGeneratedContentService(ref);
});
