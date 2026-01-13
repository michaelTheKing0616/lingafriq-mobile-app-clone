import 'package:shared_preferences/shared_preferences.dart';

/// Utility for tracking first-time access to features
/// Used to show preloader screens
class FeatureFirstAccess {
  static const String _keyPrefix = 'feature_first_access_';

  /// Check if user has seen a feature's preloader
  static Future<bool> hasSeenFeature(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix$featureName') ?? false;
  }

  /// Mark a feature as seen
  static Future<void> markFeatureSeen(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$featureName', true);
  }

  /// Reset a feature (for testing)
  static Future<void> resetFeature(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$featureName');
  }

  /// Feature names constants
  static const String gamification = 'gamification';
  static const String polie = 'polie';
  static const String games = 'games';
  static const String social = 'social';
  static const String progress = 'progress';
}

