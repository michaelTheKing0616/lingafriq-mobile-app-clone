import 'package:lingafriq/features/api/providers/api_provider_helpers.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/structured_logger.dart';

import 'package:lingafriq/features/api/providers/api_provider_mixin_4.dart';

mixin ApiProviderMixin5 on ApiProviderMixin4 {
  Future<List<Map<String, dynamic>>> getLeaderboard({String? category}) async {
    try {
      final url = category != null 
          ? '${ApiContract.url(ApiContract.gamification.leagueLeaderboard)}?category=$category'
          : ApiContract.url(ApiContract.gamification.leagueLeaderboard);
      final res = await ref.read(client).get(url);
      if (res.statusCode == 200) {
        if (res.data is List) {
          return List<Map<String, dynamic>>.from(res.data);
        } else if (res.data is Map && res.data['results'] is List) {
          return List<Map<String, dynamic>>.from(res.data['results']);
        } else if (res.data is Map && res.data['leaderboard'] is List) {
          return List<Map<String, dynamic>>.from(res.data['leaderboard']);
        }
      }
      return [];
    } catch (e) {
      logger.error('Error getting leaderboard', error: e);
      return [];
    }
  }

  /// Send telemetry events (batch). Hybrid Polie events go to /api/telemetry/events.
  Future<bool> sendTelemetry(List<Map<String, dynamic>> events) async {
    try {
      if (events.isEmpty) return true;

      final payload = events.map(_normalizeTelemetryEvent).toList();
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.telemetry.events),
        data: {'events': payload},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error sending telemetry', error: e);
      return false;
    }
  }

  Map<String, dynamic> _normalizeTelemetryEvent(Map<String, dynamic> event) {
    final metadata = Map<String, dynamic>.from(
      (event['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    if (event['feature'] != null) {
      metadata['feature'] = event['feature'];
    }
    return {
      'eventType': event['event_type'] ?? event['eventType'] ?? event['event'],
      'timestamp': event['timestamp'] ?? DateTime.now().toIso8601String(),
      'language': metadata['language'],
      'metadata': metadata,
      if (metadata['model_used'] != null) 'model': metadata['model_used'],
    };
  }

  /// Family subscription: aggregated progress dashboard
  /// Backend: GET /api/progress/family/dashboard
  Future<Map<String, dynamic>> getFamilyProgressDashboard() async {
    final res = await ref.read(client).get('/api/progress/family/dashboard');
    if (res.statusCode != 200) {
      throw Exception(res.data);
    }
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  /// Fetch ancestry graph for the current user.
  ///
  /// Backend: GET /api/ancestry/me
  /// Backward-compatible: requires only auth (user id is derived from JWT server-side).
  Future<Map<String, dynamic>> getAncestryMe() async {
    final res = await ref.read(client).get('/api/ancestry/me');
    if (res.statusCode != 200) {
      throw Exception(res.data);
    }
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  /// Generic POST helper method for flexibility
  Future<Response?> post(String path, {dynamic data}) async {
    try {
      return await ref.read(client).post(path, data: data);
    } catch (e) {
      logger.error('Error in POST request', error: e, context: {'path': path});
      return null;
    }
  }

  /// Sync game session to backend
  Future<bool> syncGameSession(Map<String, dynamic> data) async {
    try {
      // Canonical backend route: POST /api/games/session/start/
      // Backend upserts by `session.session_id` and is tolerant to being called
      // for start/turn/complete via the same handler.
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.games.sessionStart),
        data: {
          'session': data['session'],
          if (data['timestamp'] != null) 'timestamp': data['timestamp'],
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing game session', error: e);
      return false;
    }
  }

  /// Sync game SRS (Spaced Repetition System) data to backend
  Future<bool> syncGameSRS(Map<String, dynamic> data) async {
    try {
      final userId = data['user_id']?.toString();
      if (userId == null || userId.trim().isEmpty) {
        throw Exception('syncGameSRS requires user_id');
      }

      // Canonical backend route: PUT /api/games/srs/user/:userId
      final res = await ref.read(client).put(
        ApiContract.url(ApiContract.games.srsUser(userId)),
        data: {
          'srs': data['srs'],
          if (data['timestamp'] != null) 'timestamp': data['timestamp'],
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing game SRS', error: e);
      return false;
    }
  }

  /// Create user-generated lesson
  Future<Map<String, dynamic>> createUgcLesson(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url('$apiUserContentBase/lessons'),
        data: data,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : {'id': res.data};
      }
      throw Exception('Failed to create lesson: ${res.statusCode}');
    } catch (e) {
      logger.error('Error creating UGC lesson', error: e);
      rethrow;
    }
  }

  /// Create user-generated quiz
  Future<Map<String, dynamic>> createUgcQuiz(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url('$apiUserContentBase/quizzes'),
        data: data,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : {'id': res.data};
      }
      throw Exception('Failed to create quiz: ${res.statusCode}');
    } catch (e) {
      logger.error('Error creating UGC quiz', error: e);
      rethrow;
    }
  }

  /// Create user-generated story
  Future<Map<String, dynamic>> createUgcStory(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url('$apiUserContentBase/stories'),
        data: data,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : {'id': res.data};
      }
      throw Exception('Failed to create story: ${res.statusCode}');
    } catch (e) {
      logger.error('Error creating UGC story', error: e);
      rethrow;
    }
  }

  /// Share user-generated content
  Future<bool> shareUgcContent({
    required String contentId,
    required String contentType,
    List<String>? userIds,
  }) async {
    try {
      final data = {
        'content_id': contentId,
        'content_type': contentType,
        if (userIds != null && userIds.isNotEmpty) 'user_ids': userIds,
      };
      final res = await ref.read(client).post(
        ApiContract.url('$apiUserContentBase/share'),
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error sharing UGC content', error: e);
      return false;
    }
  }

  /// Get user-generated content
  Future<List<Map<String, dynamic>>> getUserContent({
    String? language,
    String? contentType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (language != null) queryParams['language'] = language;
      if (contentType != null) queryParams['type'] = contentType;
      
      final queryString = queryParams.isEmpty 
          ? '' 
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      
      final res = await ref.read(client).get(
        ApiContract.url('$apiUserContentBase$queryString'),
      );
      if (res.statusCode == 200) {
        if (res.data is List) {
          return List<Map<String, dynamic>>.from(res.data);
        } else if (res.data is Map && res.data['results'] is List) {
          return List<Map<String, dynamic>>.from(res.data['results']);
        } else if (res.data is Map && res.data['content'] is List) {
          return List<Map<String, dynamic>>.from(res.data['content']);
        }
      }
      return [];
    } catch (e) {
      logger.error('Error getting user content', error: e);
      return [];
    }
  }

  /// Rate user-generated content
  Future<bool> rateUgcContent({
    required String contentId,
    required int rating,
    String? review,
  }) async {
    try {
      final data = {
        'content_id': contentId,
        'rating': rating,
        if (review != null && review.isNotEmpty) 'review': review,
      };
      final res = await ref.read(client).post(
        ApiContract.url('$apiUserContentBase/rate'),
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error rating UGC content', error: e);
      return false;
    }
  }

  /// Sync AI chat history to backend
  Future<bool> syncAIChatHistory(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.ai.chatHistorySync),
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing AI chat history', error: e);
      return false;
    }
  }

  /// Sync AI chat SRS data to backend
  Future<bool> syncAIChatSRS(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.ai.chatSrsSync),
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing AI chat SRS', error: e);
      return false;
    }
  }

  /// Sync progress metrics to backend
  Future<bool> syncProgress(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.gamification.progressSync),
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing progress', error: e);
      return false;
    }
  }

  /// Sync onboarding data to backend
  /// Backend expects: { onboarding_data: {...}, timestamp: "..." }
  Future<bool> syncOnboarding(Map<String, dynamic> data) async {
    try {
      // Backend expects the data wrapped in 'onboarding_data' field
      final requestBody = {
        'onboarding_data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.onboarding.save),
        data: requestBody,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing onboarding', error: e);
      return false;
    }
  }

  /// Sync telemetry events to backend
  Future<bool> syncTelemetry(Map<String, dynamic> data) async {
    try {
      // Canonical backend route: POST /api/games/telemetry/
      // Support both single event and `{ events: [...] }` payloads.
      if (data['events'] is List) {
        final events = (data['events'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return await sendTelemetry(events);
      }

      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.games.telemetry),
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing telemetry', error: e);
      return false;
    }
  }

  /// Check if username is available
  /// Queries backend to check against all registered usernames (case-insensitive)
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final res = await ref.read(client).get(
        ApiContract.url(ApiContract.onboarding.checkUsername),
        queryParameters: {'username': username.trim()},
      );
      
      if (res.statusCode == 200 && res.data != null) {
        // Backend returns: { success: true, data: { username: "...", available: true/false } }
        final payload = res.data is Map ? res.data as Map : <String, dynamic>{};
        final data = payload['data'] is Map ? payload['data'] as Map : payload;
        return data['available'] == true;
      }
      // If endpoint doesn't exist or fails, assume available (allow user to continue)
      logger.warn('Username check endpoint returned unexpected response', context: {
        'statusCode': res.statusCode,
        'data': res.data,
      });
      return true; // Default to available if check fails
    } catch (e) {
      // If check fails, allow user to continue (they can change it later if needed)
      logger.warn('Error checking username availability', error: e);
      return true; // Default to available if check fails
    }
  }

  /// Search chat messages
  Future<List<Map<String, dynamic>>> searchChatMessages({
    required String query,
    String? room,
    String type = 'all',
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'type': type,
        'limit': limit,
      };
      if (room != null) {
        queryParams['room'] = room;
      }
      
      final res = await ref.read(client).get(
        ApiContract.url(ApiContract.chat.search),
        queryParameters: queryParams,
      );
      
      if (res.statusCode == 200 && res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      } else if (res.statusCode == 200 && res.data is Map && res.data['results'] is List) {
        return List<Map<String, dynamic>>.from(res.data['results']);
      }
      return [];
    } catch (e) {
      logger.error('Error searching chat messages', error: e);
      return [];
    }
  }

  /// Submit voice contribution
  Future<bool> submitVoiceContribution({
    required String userId,
    required String promptId,
    required String language,
    required String category,
    required String promptText,
    required String audioPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'prompt_id': promptId,
        'language': language,
        'category': category,
        'prompt_text': promptText,
        'audio': await MultipartFile.fromFile(audioPath),
      });
      
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.socialAudio.voiceContributions),
        data: formData,
      );
      
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error submitting voice contribution', error: e);
      return false;
    }
  }

  // ========== SOCIAL AUDIO API METHODS ==========

  /// Get social audio rooms
}
