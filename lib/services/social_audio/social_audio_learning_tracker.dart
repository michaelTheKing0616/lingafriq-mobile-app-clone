import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../providers/api_provider.dart';
import '../../providers/dio_provider.dart';
import '../../utils/api.dart';
import '../../providers/user_provider.dart';
import '../../models/social_audio/social_audio_room_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Social Audio Learning Tracker - Tracks learning progress in social audio sessions
class SocialAudioLearningTracker {
  final ApiProvider _api;
  final Dio _dio;

  SocialAudioLearningTracker(this._api, this._dio);

  /// Track participation in a room session
  Future<bool> trackParticipation({
    required String userId,
    required String roomId,
    required String language,
    required DateTime joinedAt,
    DateTime? leftAt,
    int? durationMinutes,
    ParticipantRole? role,
    int? messagesSpoken,
    int? wordsLearned,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'room_id': roomId,
        'language': language,
        'joined_at': joinedAt.toIso8601String(),
        if (leftAt != null) 'left_at': leftAt.toIso8601String(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (role != null) 'role': role.name,
        if (messagesSpoken != null) 'messages_spoken': messagesSpoken,
        if (wordsLearned != null) 'words_learned': wordsLearned,
      };

      final response = await _dio.post(
        '${Api.baseurl}${Api.socialAudioLearningTrack}',
        data: data,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('Error tracking participation: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error tracking participation: $e');
      return false;
    }
  }

  /// Track word/phrase learned in a session
  Future<bool> trackWordLearned({
    required String userId,
    required String roomId,
    required String word,
    required String language,
    String? translation,
    String? context,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'room_id': roomId,
        'word': word,
        'language': language,
        if (translation != null) 'translation': translation,
        if (context != null) 'context': context,
      };

      final response = await _dio.post(
        '${Api.baseurl}${Api.socialAudioLearningWords}',
        data: data,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('Error tracking word learned: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error tracking word learned: $e');
      return false;
    }
  }

  /// Get learning statistics for user
  Future<Map<String, dynamic>?> getLearningStats({
    required String userId,
    String? language,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        if (language != null) 'language': language,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await _dio.get(
        '${Api.baseurl}${Api.socialAudioLearningStats}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['data'] ?? data;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Error getting learning stats: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error getting learning stats: $e');
      return null;
    }
  }

  /// Track pronunciation practice in room
  Future<bool> trackPronunciationPractice({
    required String userId,
    required String roomId,
    required String word,
    required String language,
    double? accuracyScore,
    List<String>? mistakes,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'room_id': roomId,
        'word': word,
        'language': language,
        if (accuracyScore != null) 'accuracy_score': accuracyScore,
        if (mistakes != null) 'mistakes': mistakes,
      };

      final response = await _dio.post(
        '${Api.baseurl}${Api.socialAudioLearningPronunciation}',
        data: data,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('Error tracking pronunciation practice: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error tracking pronunciation practice: $e');
      return false;
    }
  }

  /// Get room learning summary
  Future<Map<String, dynamic>?> getRoomLearningSummary(String roomId) async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}${Api.socialAudioRoomLearningSummary(roomId)}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['data'] ?? data;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Error getting room learning summary: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error getting room learning summary: $e');
      return null;
    }
  }
}

