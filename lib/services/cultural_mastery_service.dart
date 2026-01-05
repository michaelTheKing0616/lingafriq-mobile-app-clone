import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cultural_mastery_profile.dart';
import '../models/game_streak.dart';

/// Service to manage cultural mastery profiles and streaks
class CulturalMasteryService {
  static const String _masteryPrefix = 'cultural_mastery_';
  static const String _streakPrefix = 'game_streak_';

  /// Get mastery profile for user and language
  Future<CulturalMasteryProfile?> getMasteryProfile({
    required String userId,
    required String language,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_masteryPrefix${userId}_$language';
      final jsonString = prefs.getString(key);
      
      if (jsonString == null) {
        // Create new profile
        return CulturalMasteryProfile(
          userId: userId,
          language: language,
        );
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CulturalMasteryProfile.fromJson(json);
    } catch (e) {
      return CulturalMasteryProfile(
        userId: userId,
        language: language,
      );
    }
  }

  /// Save mastery profile
  Future<void> saveMasteryProfile(CulturalMasteryProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_masteryPrefix${profile.userId}_${profile.language}';
      await prefs.setString(key, jsonEncode(profile.toJson()));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Update mastery from game result
  Future<CulturalMasteryProfile> updateMastery({
    required String userId,
    required String language,
    required String gameId,
    required double accuracy,
    required double learningSignal,
  }) async {
    final profile = await getMasteryProfile(
      userId: userId,
      language: language,
    ) ?? CulturalMasteryProfile(
      userId: userId,
      language: language,
    );

    final updated = profile.updateFromGame(
      gameId: gameId,
      accuracy: accuracy,
      learningSignal: learningSignal,
    );

    await saveMasteryProfile(updated);
    return updated;
  }

  /// Get streak for user and language
  Future<GameStreak> getStreak({
    required String userId,
    String? language,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = language != null
          ? '$_streakPrefix${userId}_$language'
          : '$_streakPrefix${userId}_global';
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        return GameStreak(userId: userId, language: language);
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final streak = GameStreak.fromJson(json);

      // Check if streak is broken
      if (streak.isBroken) {
        return streak.reset();
      }

      return streak;
    } catch (e) {
      return GameStreak(userId: userId, language: language);
    }
  }

  /// Increment streak
  Future<GameStreak> incrementStreak({
    required String userId,
    String? language,
  }) async {
    final streak = await getStreak(userId: userId, language: language);
    final updated = streak.increment();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = language != null
          ? '$_streakPrefix${userId}_$language'
          : '$_streakPrefix${userId}_global';
      await prefs.setString(key, jsonEncode(updated.toJson()));
    } catch (e) {
      // Handle error silently
    }

    return updated;
  }

  /// Reset streak
  Future<GameStreak> resetStreak({
    required String userId,
    String? language,
  }) async {
    final streak = await getStreak(userId: userId, language: language);
    final updated = streak.reset();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = language != null
          ? '$_streakPrefix${userId}_$language'
          : '$_streakPrefix${userId}_global';
      await prefs.setString(key, jsonEncode(updated.toJson()));
    } catch (e) {
      // Handle error silently
    }

    return updated;
  }
}

