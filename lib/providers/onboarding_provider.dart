import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/models/onboarding_data_model.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  final SharedPreferencesProvider _prefs;
  
  OnboardingNotifier(this._prefs) : super(OnboardingData());
  
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
  }
  
  Future<void> loadOnboardingData() async {
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

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier(ref.read(sharedPreferencesProvider));
});

