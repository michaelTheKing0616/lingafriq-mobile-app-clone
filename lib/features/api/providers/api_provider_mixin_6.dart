import 'package:lingafriq/features/api/providers/api_provider_helpers.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, visibleForTesting;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/history/models/history_response.dart';
import 'package:lingafriq/history/models/section_history_model.dart';
import 'package:lingafriq/history_quiz/models/history_quiz_lesson_model.dart';
import 'package:lingafriq/mannerisms/models/mannerism_response.dart';
import 'package:lingafriq/mannerisms/models/mannerism_tutorial_model.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/models/profiles_response.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/random_quiz/models/random_quiz_lesson_model.dart';
import 'package:lingafriq/services/auth_token_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/history_quiz/models/history_quiz_response.dart';
import 'package:lingafriq/language_quiz/models/language_quiz_lesson_model.dart';
import 'package:lingafriq/language_quiz/models/language_quiz_response.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/models/user.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';

import 'package:lingafriq/features/api/providers/api_provider_mixin_5.dart';

mixin ApiProviderMixin6 on ApiProviderMixin5 {
  Future<Response?> getSocialAudioRooms({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await ref.read(client).get(
        ApiContract.url(ApiContract.socialAudio.rooms),
        queryParameters: queryParameters,
      );
    } catch (e) {
      logger.error('Error getting social audio rooms', error: e);
      return null;
    }
  }

  /// Get social audio room by ID
  Future<Response?> getSocialAudioRoom(String roomId) async {
    try {
      return await ref.read(client).get(
        ApiContract.url(ApiContract.socialAudio.room(roomId)),
      );
    } catch (e) {
      logger.error('Error getting social audio room', error: e);
      return null;
    }
  }

  /// Create social audio room
  Future<Response?> createSocialAudioRoom(Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        ApiContract.url(ApiContract.socialAudio.rooms),
        data: data,
      );
    } catch (e) {
      logger.error('Error creating social audio room', error: e);
      return null;
    }
  }

  /// Join social audio room
  Future<Response?> joinSocialAudioRoom(String roomId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        ApiContract.url(ApiContract.socialAudio.roomJoin(roomId)),
        data: data,
      );
    } catch (e) {
      logger.error('Error joining social audio room', error: e);
      return null;
    }
  }

  /// Leave social audio room
  Future<Response?> leaveSocialAudioRoom(String roomId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        ApiContract.url(ApiContract.socialAudio.roomLeave(roomId)),
        data: data,
      );
    } catch (e) {
      logger.error('Error leaving social audio room', error: e);
      return null;
    }
  }

  /// Update social audio room status
  Future<Response?> updateSocialAudioRoomStatus(String roomId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).patch(
        ApiContract.url(ApiContract.socialAudio.roomStatus(roomId)),
        data: data,
      );
    } catch (e) {
      logger.error('Error updating social audio room status', error: e);
      return null;
    }
  }

  /// Get social audio room participants
  Future<Response?> getSocialAudioRoomParticipants(String roomId) async {
    try {
      return await ref.read(client).get(
        ApiContract.url(ApiContract.socialAudio.roomParticipants(roomId)),
      );
    } catch (e) {
      logger.error('Error getting social audio room participants', error: e);
      return null;
    }
  }

  /// Moderate social audio room
  Future<Response?> moderateSocialAudioRoom(String roomId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        ApiContract.url(ApiContract.socialAudio.roomModerate(roomId)),
        data: data,
      );
    } catch (e) {
      logger.error('Error moderating social audio room', error: e);
      return null;
    }
  }

  /// Follow user for social audio
  Future<Response?> followSocialAudioUser(String userId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).post(
        ApiContract.url(ApiContract.socialAudio.followUser(userId)),
        data: data,
      );
    } catch (e) {
      logger.error('Error following social audio user', error: e);
      return null;
    }
  }

  /// Unfollow user for social audio
  Future<Response?> unfollowSocialAudioUser(String userId, Map<String, dynamic> data) async {
    try {
      return await ref.read(client).delete(
        ApiContract.url(ApiContract.socialAudio.followUser(userId)),
        data: data,
      );
    } catch (e) {
      logger.error('Error unfollowing social audio user', error: e);
      return null;
    }
  }

  /// Get following list for social audio
  Future<Response?> getSocialAudioFollowingList(Map<String, dynamic>? queryParameters) async {
    try {
      return await ref.read(client).get(
        ApiContract.url(ApiContract.socialAudio.followingList),
        queryParameters: queryParameters,
      );
    } catch (e) {
      logger.error('Error getting social audio following list', error: e);
      return null;
    }
  }

  /// Get followers list for social audio
  Future<Response?> getSocialAudioFollowersList(Map<String, dynamic>? queryParameters) async {
    try {
      return await ref.read(client).get(
        ApiContract.url(ApiContract.socialAudio.followers),
        queryParameters: queryParameters,
      );
    } catch (e) {
      logger.error('Error getting social audio followers list', error: e);
      return null;
    }
  }

  /// Upload media file
  Future<Map<String, dynamic>?> uploadMedia(File file, {String? type, Map<String, dynamic>? metadata}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        if (type != null) 'type': type,
        if (metadata != null) ...metadata,
      });
      
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.media.upload),
        data: formData,
      );
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : {'id': res.data.toString()};
      }
      return null;
    } catch (e) {
      logger.error('Error uploading media', error: e);
      return null;
    }
  }

  /// Report a chat message
  Future<bool> reportChatMessage({required String messageId, String? reason, String? description}) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.chat.report),
        data: {
          'messageId': messageId,
          if (reason != null) 'reason': reason,
          if (description != null) 'description': description,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error reporting chat message', error: e);
      return false;
    }
  }

  /// Block a user
  Future<bool> blockUser(String userId) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.social.connectionBlock),
        data: {'userId': userId},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error blocking user', error: e);
      return false;
    }
  }

  /// Quick pronunciation check
  Future<Map<String, dynamic>?> pronunciationQuick({
    required String text,
    required String language,
    String? audioUrl,
  }) async {
    try {
      final data = {
        'text': text,
        'language': language,
        if (audioUrl != null) 'audioUrl': audioUrl,
      };
      
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.games.pronunciationQuick),
        data: data,
      );
      
      if (res.statusCode == 200) {
        return res.data is Map ? Map<String, dynamic>.from(res.data) : null;
      }
      return null;
    } catch (e) {
      logger.error('Error checking pronunciation', error: e);
      return null;
    }
  }

  /// Submit game completion
  Future<bool> submitGameCompletion({
    required String gameType,
    required int languageId,
    required int points,
    required int score,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.games.complete),
        data: {
          'gameType': gameType,
          'languageId': languageId,
          'points': points,
          'score': score,
          if (metadata != null) ...metadata,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error submitting game completion', error: e);
      return false;
    }
  }

}
