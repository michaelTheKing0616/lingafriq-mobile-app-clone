// Social Learning Service
// Manages study groups and friend challenges
// 
// Production-ready implementation

import 'package:dio/dio.dart';
import 'package:lingafriq/models/social_group.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/services/env_config.dart';

class SocialLearningService {
  final Dio _dio;
  final String _baseUrl;

  SocialLearningService({Dio? dio})
      : _dio = dio ?? Dio(),
        _baseUrl = EnvConfig.backendBaseUrl;

  // ===== Study Groups =====

  Future<List<StudyGroup>> discoverGroups({
    String? language,
    int? level,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/study-groups/discover',
        queryParameters: {
          if (language != null) 'language': language,
          if (level != null) 'level': level,
          'limit': limit,
        },
      );

      return (response.data['groups'] as List)
          .map((e) => StudyGroup.fromJson(e))
          .toList();
    } catch (e) {
      logger.error('Failed to discover groups', error: e);
      return [];
    }
  }

  Future<StudyGroup?> createGroup(Map<String, dynamic> groupData) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/study-groups',
        data: groupData,
      );

      return StudyGroup.fromJson(response.data);
    } catch (e) {
      logger.error('Failed to create group', error: e);
      return null;
    }
  }

  Future<bool> joinGroup(String groupId) async {
    try {
      await _dio.post('$_baseUrl/api/study-groups/$groupId/join');
      return true;
    } catch (e) {
      logger.error('Failed to join group', error: e);
      return false;
    }
  }

  Future<List<StudyGroup>> getMyGroups() async {
    try {
      final response = await _dio.get('$_baseUrl/api/study-groups/my-groups');
      return (response.data['groups'] as List)
          .map((e) => StudyGroup.fromJson(e))
          .toList();
    } catch (e) {
      logger.error('Failed to get my groups', error: e);
      return [];
    }
  }

  // ===== Challenges =====

  Future<GroupChallenge?> createChallenge(
    String groupId,
    Map<String, dynamic> challengeData,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/study-groups/$groupId/challenges',
        data: challengeData,
      );

      return GroupChallenge.fromJson(response.data);
    } catch (e) {
      logger.error('Failed to create challenge', error: e);
      return null;
    }
  }

  Future<List<GroupChallenge>> getActiveChallenges(String groupId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/study-groups/$groupId/challenges/active',
      );

      return (response.data['challenges'] as List)
          .map((e) => GroupChallenge.fromJson(e))
          .toList();
    } catch (e) {
      logger.error('Failed to get challenges', error: e);
      return [];
    }
  }

  Future<List<ChallengeParticipant>> getChallengeLeaderboard(
    String challengeId,
  ) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/challenges/$challengeId/leaderboard',
      );

      return (response.data['participants'] as List)
          .map((e) => ChallengeParticipant.fromJson(e))
          .toList();
    } catch (e) {
      logger.error('Failed to get challenge leaderboard', error: e);
      return [];
    }
  }

  // ===== Friend Connections =====

  Future<bool> sendFriendRequest(String userId) async {
    try {
      await _dio.post('$_baseUrl/api/friends/request', data: {
        'target_user_id': userId,
      });
      return true;
    } catch (e) {
      logger.error('Failed to send friend request', error: e);
      return false;
    }
  }

  Future<List<FriendConnection>> getFriends() async {
    try {
      final response = await _dio.get('$_baseUrl/api/friends');
      return (response.data['friends'] as List)
          .map((e) => FriendConnection.fromJson(e))
          .toList();
    } catch (e) {
      logger.error('Failed to get friends', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getFriendStats(String friendId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/friends/$friendId/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.error('Failed to get friend stats', error: e);
      return {};
    }
  }
}

final socialLearningService = SocialLearningService();

