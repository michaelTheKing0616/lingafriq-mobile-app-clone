import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingafriq/services/games_learning_language_preload.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';

import 'api_provider.dart';

final userProvider = NotifierProvider<UserProvider, ProfileModel?>(
  () => UserProvider(),
);

class UserProvider extends Notifier<ProfileModel?> {
  @override
  ProfileModel? build() {
    return null;
  }

  void overrideUser(ProfileModel? user) {
    state = user;
    if (user != null) {
      _syncLearningLanguagePrefsFromProfile(user);
    }
  }

  void resetUser() {
    state = null;
  }

  /// Add points to user's completed_point
  void addPoints(int points) {
    if (state != null) {
      // Note: completed_point is final in ProfileModel, so we need to create a new instance
      // This is a simplified implementation - in production, you'd update via API
      // The actual update should happen via API, this is just for local state
      // The API call should update the backend and then refresh the user profile
    }
  }

  /// Refresh user data from backend
  Future<void> refreshUser() async {
    try {
      final apiNotifier = ref.read(apiProvider.notifier);
      // Get user info first to get the user ID
      final userInfo = await apiNotifier.getUserInfo();
      // Then get the full profile
      final updatedProfile = await apiNotifier.getProfileUser(userInfo.id);
      state = updatedProfile;
      _syncLearningLanguagePrefsFromProfile(updatedProfile);
    } catch (e) {
      // Silently fail - user state remains unchanged
      // Error logging would be handled by the API provider
    }
  }

  /// Keeps `learning_language` prefs aligned with the server profile and warms
  /// game card cache when the stored value changes.
  Future<void> _syncLearningLanguagePrefsFromProfile(ProfileModel profile) async {
    final raw = profile.learningLanguage?.trim();
    if (raw == null || raw.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final prev = prefs.getString('learning_language')?.trim().toLowerCase();
      final next = raw.toLowerCase();
      if (prev == next) return;

      await prefs.setString('learning_language', raw);
      scheduleGamesPreloadWithLoader(ref.read(lazyGameLoaderProvider));
    } catch (e) {
      debugPrint('UserProvider._syncLearningLanguagePrefsFromProfile: $e');
    }
  }
}
