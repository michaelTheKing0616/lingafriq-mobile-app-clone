import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/onboarding_data_model.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/backend_sync_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class OnboardingNotifier extends Notifier<OnboardingData> {
  SharedPreferencesProvider get _prefs => ref.read(sharedPreferencesProvider);
  
  @override
  OnboardingData build() {
    // Load saved data asynchronously after initial build
    Future.microtask(() => _loadOnboardingData());
    return OnboardingData();
  }
  
  void updateAgeCategory(String category) {
    state = OnboardingData(
      ageCategory: category,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updateLearningReasons(List<String> reasons) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: reasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updateLanguage(String language, {String? dialect}) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: language,
      selectedDialect: dialect ?? state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updateProficiency(String level, {bool? literacyPreference}) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: level,
      literacyPreference: literacyPreference ?? state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }

  /// Alias for [updateProficiency] — some callers use this name.
  void updateProficiencyLevel(String level, {bool? literacyPreference}) {
    updateProficiency(level, literacyPreference: literacyPreference);
  }
  
  void updateLearningStyle(String style, {String? pace}) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: style,
      pacePreference: pace ?? state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updateSchedule(int duration, String timeOfDay, {bool? reminders}) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: duration,
      preferredTimeOfDay: timeOfDay,
      remindersEnabled: reminders ?? state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updateGoals(String primary, {List<String>? secondary, List<String>? triggers}) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: primary,
      secondaryGoals: secondary ?? state.secondaryGoals,
      motivationTriggers: triggers ?? state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updatePath(String path) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      selectedPath: path,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }

  void updatePersonality(String tone, String gamification, {bool? culturalContent}) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: tone,
      gamificationLevel: gamification,
      culturalContentEnabled: culturalContent ?? state.culturalContentEnabled,
      selectedPath: state.selectedPath,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updateAccessibility({
    bool? largeText,
    bool? highContrast,
    bool? dyslexia,
    bool? soundOff,
    bool? motionReduction,
  }) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: largeText ?? state.largeTextEnabled,
      highContrastEnabled: highContrast ?? state.highContrastEnabled,
      dyslexiaModeEnabled: dyslexia ?? state.dyslexiaModeEnabled,
      soundOffModeEnabled: soundOff ?? state.soundOffModeEnabled,
      motionReductionEnabled: motionReduction ?? state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updateSocial(String preference, {bool? competition, String? speakingComfort}) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: preference,
      competitionEnabled: competition ?? state.competitionEnabled,
      speakingComfortLevel: speakingComfort ?? state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updateProfile(String username, {String? avatarPath, String? location}) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: username,
      avatarPath: avatarPath ?? state.avatarPath,
      location: location ?? state.location,
      placementTestResults: state.placementTestResults,
    );
  }
  
  void updatePlacementTest(Map<String, dynamic> results) {
    state = OnboardingData(
      ageCategory: state.ageCategory,
      learningReasons: state.learningReasons,
      selectedLanguage: state.selectedLanguage,
      selectedDialect: state.selectedDialect,
      proficiencyLevel: state.proficiencyLevel,
      literacyPreference: state.literacyPreference,
      learningStyle: state.learningStyle,
      pacePreference: state.pacePreference,
      appTone: state.appTone,
      gamificationLevel: state.gamificationLevel,
      culturalContentEnabled: state.culturalContentEnabled,
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals,
      motivationTriggers: state.motivationTriggers,
      dailyDurationMinutes: state.dailyDurationMinutes,
      preferredTimeOfDay: state.preferredTimeOfDay,
      remindersEnabled: state.remindersEnabled,
      largeTextEnabled: state.largeTextEnabled,
      highContrastEnabled: state.highContrastEnabled,
      dyslexiaModeEnabled: state.dyslexiaModeEnabled,
      soundOffModeEnabled: state.soundOffModeEnabled,
      motionReductionEnabled: state.motionReductionEnabled,
      socialPreference: state.socialPreference,
      competitionEnabled: state.competitionEnabled,
      speakingComfortLevel: state.speakingComfortLevel,
      username: state.username,
      avatarPath: state.avatarPath,
      location: state.location,
      placementTestResults: results,
    );
  }
  
  Future<void> saveOnboardingData() async {
    await _prefs.prefs.setString('onboarding_data', state.toJson());
    
    // Sync to backend
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        final syncProvider = ref.read(backendSyncProvider.notifier);
        await syncProvider.queueSync(SyncTask(
          type: SyncType.onboarding,
          data: {
            'user_id': user.id.toString(),
            'onboarding_data': state.toJson(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
      }
    } catch (e) {
      logger.error('Error queuing onboarding sync', tag: 'onboarding', error: e);
    }
  }
  
  Future<void> _loadOnboardingData() async {
    final data = _prefs.prefs.getString('onboarding_data');
    if (data != null) {
      try {
        state = OnboardingData.fromJson(data);
      } catch (e) {
        // If parsing fails, start fresh
        state = OnboardingData();
      }
    }
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingData>(() {
  return OnboardingNotifier();
});
