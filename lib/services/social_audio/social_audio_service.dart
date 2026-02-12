import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../providers/api_provider.dart';
import '../../providers/dio_provider.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import '../../models/social_audio/social_audio_room_model.dart';
import 'social_audio_cache.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Social Audio Service - Manages Spaces-like audio rooms
/// Full backend integration with no placeholders
class SocialAudioService {
  final ApiProvider _api;
  final Dio _dio;

  SocialAudioService(this._api, this._dio);

  /// Discover available rooms with caching
  Future<List<SocialAudioRoom>> discoverRooms({
    String? language,
    RoomType? type,
    RoomStatus? status,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
    bool useCache = true,
  }) async {
    // Try cache first if no search query and cache is valid
    if (useCache && searchQuery == null && await SocialAudioCache.isCacheValid()) {
      final cachedRooms = await SocialAudioCache.getDiscoveredRooms();
      if (cachedRooms.isNotEmpty) {
        // Filter cached rooms by language/type/status if needed
        var filtered = cachedRooms;
        if (language != null) {
          filtered = filtered.where((r) => r.language == language).toList();
        }
        if (type != null) {
          filtered = filtered.where((r) => r.type == type).toList();
        }
        if (status != null) {
          filtered = filtered.where((r) => r.status == status).toList();
        }
        if (filtered.isNotEmpty) {
          return filtered;
        }
      }
    }

    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (language != null && language.isNotEmpty) 'language': language,
        if (type != null) 'type': type.name,
        if (status != null) 'status': status.name,
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      };

      final response = await _dio.get(
        ApiContract.url(ApiContract.socialAudio.rooms),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Handle both {data: [...]} and direct array responses
        final roomsList = data['data'] ?? data['results'] ?? data;
        if (roomsList is List) {
          final rooms = roomsList
              .map((json) => SocialAudioRoom.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // Cache results if no search query
          if (searchQuery == null) {
            await SocialAudioCache.saveDiscoveredRooms(rooms);
          }
          
          return rooms;
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error discovering rooms: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      // Return cached data on error if available
      if (useCache && searchQuery == null) {
        final cachedRooms = await SocialAudioCache.getDiscoveredRooms();
        if (cachedRooms.isNotEmpty) {
          return cachedRooms;
        }
      }
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error discovering rooms: $e');
      // Return cached data on error if available
      if (useCache && searchQuery == null) {
        final cachedRooms = await SocialAudioCache.getDiscoveredRooms();
        if (cachedRooms.isNotEmpty) {
          return cachedRooms;
        }
      }
      rethrow;
    }
  }

  /// Get room details
  Future<SocialAudioRoom?> getRoom(String roomId) async {
    try {
      final response =
          await _dio.get(ApiContract.url(ApiContract.socialAudio.room(roomId)));

      if (response.statusCode == 200) {
        final data = response.data;
        final roomData = data['data'] ?? data;
        return SocialAudioRoom.fromJson(roomData as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('Room not found: $roomId');
        return null;
      }
      debugPrint('Error getting room: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error getting room: $e');
      rethrow;
    }
  }

  /// Create a new room - Invalidates cache
  Future<SocialAudioRoom> createRoom({
    required String name,
    required String description,
    required String language,
    RoomType type = RoomType.practice,
    int maxParticipants = 50,
    bool isPrivate = false,
    List<String> tags = const [],
    DateTime? scheduledStartTime,
    int? durationMinutes,
    String? coverImageUrl,
  }) async {
    try {
      final data = {
        'name': name.trim(),
        'description': description.trim(),
        'language': language,
        'type': type.name,
        'max_participants': maxParticipants,
        'is_private': isPrivate,
        'tags': tags,
        if (scheduledStartTime != null)
          'scheduled_start_time': scheduledStartTime.toIso8601String(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (coverImageUrl != null && coverImageUrl.isNotEmpty) 'cover_image_url': coverImageUrl,
      };

      final response = await _dio.post(
        ApiContract.url(ApiContract.socialAudio.rooms),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final roomData = responseData['data'] ?? responseData;
        final room = SocialAudioRoom.fromJson(roomData as Map<String, dynamic>);
        
        // Invalidate cache after creating room
        await SocialAudioCache.clearCache();
        
        return room;
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Failed to create room: ${response.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint('Error creating room: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error creating room: $e');
      rethrow;
    }
  }

  /// Join a room - Returns room data and LiveKit token
  Future<Map<String, dynamic>> joinRoom({
    required String roomId,
    required String userId,
    ParticipantRole role = ParticipantRole.listener,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.socialAudio.roomJoin(roomId)),
        data: {
          'user_id': userId,
          'role': role.name,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final data = responseData['data'] ?? responseData;
        
        // Parse room data
        final roomData = data['room'] ?? data;
        final room = SocialAudioRoom.fromJson(roomData as Map<String, dynamic>);
        
        // Get LiveKit credentials
        final livekitToken = data['livekit_token'] as String? ?? data['token'] as String?;
        final livekitUrl = data['livekit_url'] as String? ?? 
                          data['url'] as String? ?? 
                          'wss://lingafriq.livekit.cloud';
        
        if (livekitToken == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'LiveKit token not provided in response',
          );
        }
        
        return {
          'room': room,
          'livekit_token': livekitToken,
          'livekit_url': livekitUrl,
        };
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Failed to join room: ${response.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint('Error joining room: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error joining room: $e');
      rethrow;
    }
  }

  /// Leave a room
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.socialAudio.roomLeave(roomId)),
        data: {'user_id': userId},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Failed to leave room: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Error leaving room: ${e.message}');
      // Don't throw for 404 - user might already have left
      if (e.response?.statusCode != 404) {
        throw Exception(TransportErrorPolicy.toUserMessage(e));
      }
    } catch (e) {
      debugPrint('Error leaving room: $e');
      rethrow;
    }
  }

  /// Update room status
  Future<SocialAudioRoom> updateRoomStatus({
    required String roomId,
    required RoomStatus status,
  }) async {
    try {
      final response = await _dio.patch(
        ApiContract.url(ApiContract.socialAudio.roomStatus(roomId)),
        data: {'status': status.name},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final roomData = responseData['data'] ?? responseData;
        return SocialAudioRoom.fromJson(roomData as Map<String, dynamic>);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Failed to update room status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint('Error updating room status: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error updating room status: $e');
      rethrow;
    }
  }

  /// Promote user to speaker
  Future<void> promoteToSpeaker({
    required String roomId,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.socialAudio.roomSpeakers(roomId)),
        data: {'user_id': userId},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Failed to promote user: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Error promoting to speaker: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error promoting to speaker: $e');
      rethrow;
    }
  }

  /// Get scheduled rooms with caching
  Future<List<SocialAudioRoom>> getScheduledRooms({
    String? language,
    DateTime? after,
    int limit = 20,
    bool useCache = true,
  }) async {
    // Try cache first
    if (useCache) {
      final cachedRooms = await SocialAudioCache.getScheduledRooms();
      if (cachedRooms.isNotEmpty) {
        var filtered = cachedRooms;
        if (language != null) {
          filtered = filtered.where((r) => r.language == language).toList();
        }
        if (after != null) {
          filtered = filtered.where((r) => 
            r.scheduledStartTime != null && r.scheduledStartTime!.isAfter(after)
          ).toList();
        }
        if (filtered.isNotEmpty) {
          return filtered;
        }
      }
    }

    try {
      final queryParams = <String, dynamic>{
        'status': RoomStatus.scheduled.name,
        'limit': limit,
        if (language != null && language.isNotEmpty) 'language': language,
        if (after != null) 'after': after.toIso8601String(),
      };

      final response = await _dio.get(
        ApiContract.url(ApiContract.socialAudio.roomsScheduled),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final roomsList = data['data'] ?? data['results'] ?? data;
        if (roomsList is List) {
          final rooms = roomsList
              .map((json) => SocialAudioRoom.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // Cache results
          await SocialAudioCache.saveScheduledRooms(rooms);
          
          return rooms;
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error getting scheduled rooms: ${e.message}');
      // Return cached data on error
      if (useCache) {
        final cachedRooms = await SocialAudioCache.getScheduledRooms();
        if (cachedRooms.isNotEmpty) {
          return cachedRooms;
        }
      }
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error getting scheduled rooms: $e');
      // Return cached data on error
      if (useCache) {
        final cachedRooms = await SocialAudioCache.getScheduledRooms();
        if (cachedRooms.isNotEmpty) {
          return cachedRooms;
        }
      }
      rethrow;
    }
  }

  /// Get user's rooms (hosted or joined) with caching
  Future<List<SocialAudioRoom>> getUserRooms({
    required String userId,
    bool hostedOnly = false,
    bool useCache = true,
  }) async {
    // Try cache first
    if (useCache) {
      final cachedRooms = await SocialAudioCache.getMyRooms();
      if (cachedRooms.isNotEmpty) {
        var filtered = cachedRooms;
        if (hostedOnly) {
          filtered = filtered.where((r) => r.hostId == userId).toList();
        }
        if (filtered.isNotEmpty) {
          return filtered;
        }
      }
    }

    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        if (hostedOnly) 'hosted_only': true,
      };

      final response = await _dio.get(
        ApiContract.url(ApiContract.socialAudio.roomsUser),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final roomsList = data['data'] ?? data['results'] ?? data;
        if (roomsList is List) {
          final rooms = roomsList
              .map((json) => SocialAudioRoom.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // Cache results
          await SocialAudioCache.saveMyRooms(rooms);
          
          return rooms;
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error getting user rooms: ${e.message}');
      // Return cached data on error
      if (useCache) {
        final cachedRooms = await SocialAudioCache.getMyRooms();
        if (cachedRooms.isNotEmpty) {
          return cachedRooms;
        }
      }
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error getting user rooms: $e');
      // Return cached data on error
      if (useCache) {
        final cachedRooms = await SocialAudioCache.getMyRooms();
        if (cachedRooms.isNotEmpty) {
          return cachedRooms;
        }
      }
      rethrow;
    }
  }

  /// Search rooms
  Future<List<SocialAudioRoom>> searchRooms({
    required String query,
    String? language,
    int limit = 20,
  }) async {
    return discoverRooms(
      searchQuery: query,
      language: language,
      limit: limit,
    );
  }

  /// Get room participants
  Future<List<RoomParticipant>> getRoomParticipants(String roomId) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.socialAudio.roomParticipants(roomId)),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final participantsList = data['data'] ?? data['participants'] ?? data;
        if (participantsList is List) {
          return participantsList
              .map((json) => RoomParticipant.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error getting room participants: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error getting room participants: $e');
      rethrow;
    }
  }

  /// Moderate room (mute, remove, etc.)
  Future<void> moderateRoom({
    required String roomId,
    required String targetUserId,
    required String action, // 'mute', 'unmute', 'remove', 'promote', 'demote'
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.socialAudio.roomModerate(roomId)),
        data: {
          'target_user_id': targetUserId,
          'action': action,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Failed to moderate room: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Error moderating room: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error moderating room: $e');
      rethrow;
    }
  }

  /// Get room history
  Future<List<Map<String, dynamic>>> getRoomHistory({
    required String roomId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.socialAudio.roomHistory(roomId)),
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final historyList = data['data'] ?? data['history'] ?? data;
        if (historyList is List) {
          return historyList.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error getting room history: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error getting room history: $e');
      rethrow;
    }
  }

  /// Follow a user
  Future<void> followUser({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final response = await _dio.post(
        ApiContract.url(ApiContract.socialAudio.followUser(targetUserId)),
        data: {'user_id': userId},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Failed to follow user: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Error following user: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final response = await _dio.delete(
        ApiContract.url(ApiContract.socialAudio.followUser(targetUserId)),
        data: {'user_id': userId},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Failed to unfollow user: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Error unfollowing user: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Get following list
  Future<List<Map<String, dynamic>>> getFollowingList({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.socialAudio.followingList),
        queryParameters: {
          'user_id': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final followingList = data['data'] ?? data['following'] ?? data;
        if (followingList is List) {
          return followingList.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error getting following list: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error getting following list: $e');
      rethrow;
    }
  }

  /// Get followers list
  Future<List<Map<String, dynamic>>> getFollowersList({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        ApiContract.url(ApiContract.socialAudio.followers),
        queryParameters: {
          'user_id': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final followersList = data['data'] ?? data['followers'] ?? data;
        if (followersList is List) {
          return followersList.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error getting followers list: ${e.message}');
      throw Exception(TransportErrorPolicy.toUserMessage(e));
    } catch (e) {
      debugPrint('Error getting followers list: $e');
      rethrow;
    }
  }

  /// Check if user is following another user
  Future<bool> isFollowing({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final following = await getFollowingList(userId: userId);
      return following.any((user) => user['id'] == targetUserId || user['user_id'] == targetUserId);
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }
}

