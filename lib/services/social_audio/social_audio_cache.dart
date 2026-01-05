import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/social_audio/social_audio_room_model.dart';

/// Social Audio Cache - Local persistence for rooms
class SocialAudioCache {
  static const String _roomsKey = 'social_audio_rooms';
  static const String _scheduledRoomsKey = 'social_audio_scheduled_rooms';
  static const String _myRoomsKey = 'social_audio_my_rooms';
  static const String _cacheTimestampKey = 'social_audio_cache_timestamp';
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Save discovered rooms to cache
  static Future<void> saveDiscoveredRooms(List<SocialAudioRoom> rooms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = rooms.map((room) => room.toJson()).toList();
      await prefs.setString(_roomsKey, jsonEncode(roomsJson));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving discovered rooms to cache: $e');
    }
  }

  /// Get discovered rooms from cache
  static Future<List<SocialAudioRoom>> getDiscoveredRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = prefs.getString(_roomsKey);
      if (roomsJson == null) return [];

      final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
        // Cache expired
        await prefs.remove(_roomsKey);
        return [];
      }

      final List<dynamic> decoded = jsonDecode(roomsJson);
      return decoded
          .map((json) => SocialAudioRoom.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting discovered rooms from cache: $e');
      return [];
    }
  }

  /// Save scheduled rooms to cache
  static Future<void> saveScheduledRooms(List<SocialAudioRoom> rooms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = rooms.map((room) => room.toJson()).toList();
      await prefs.setString(_scheduledRoomsKey, jsonEncode(roomsJson));
    } catch (e) {
      debugPrint('Error saving scheduled rooms to cache: $e');
    }
  }

  /// Get scheduled rooms from cache
  static Future<List<SocialAudioRoom>> getScheduledRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = prefs.getString(_scheduledRoomsKey);
      if (roomsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(roomsJson);
      return decoded
          .map((json) => SocialAudioRoom.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting scheduled rooms from cache: $e');
      return [];
    }
  }

  /// Save user's rooms to cache
  static Future<void> saveMyRooms(List<SocialAudioRoom> rooms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = rooms.map((room) => room.toJson()).toList();
      await prefs.setString(_myRoomsKey, jsonEncode(roomsJson));
    } catch (e) {
      debugPrint('Error saving my rooms to cache: $e');
    }
  }

  /// Get user's rooms from cache
  static Future<List<SocialAudioRoom>> getMyRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomsJson = prefs.getString(_myRoomsKey);
      if (roomsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(roomsJson);
      return decoded
          .map((json) => SocialAudioRoom.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting my rooms from cache: $e');
      return [];
    }
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roomsKey);
      await prefs.remove(_scheduledRoomsKey);
      await prefs.remove(_myRoomsKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Check if cache is valid
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      if (timestamp == 0) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheTime) < _cacheExpiry;
    } catch (e) {
      return false;
    }
  }
}

