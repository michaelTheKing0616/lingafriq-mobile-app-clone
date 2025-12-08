import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/onboarding_data_model.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';

/// Provider that personalizes the app experience based on onboarding data
class PersonalizationNotifier extends Notifier<PersonalizationConfig> {
  @override
  PersonalizationConfig build() {
    final onboardingData = ref.watch(onboardingProvider);
    return _buildConfigFromOnboarding(onboardingData);
  }

  PersonalizationConfig _buildConfigFromOnboarding(OnboardingData data) {
    // Path-based personalization
    String? dashboardFocus;
    List<String> recommendedFeatures = [];
    String? contentTheme;
    
    switch (data.selectedPath) {
      case 'explore':
        dashboardFocus = 'cultural_content';
        recommendedFeatures = ['Culture Magazine', 'Language Villages', 'Cultural Games'];
        contentTheme = 'heritage';
        break;
      case 'career':
        dashboardFocus = 'professional_content';
        recommendedFeatures = ['Business Roleplays', 'Professional Vocabulary', 'Career Quests'];
        contentTheme = 'business';
        break;
      case 'academic':
        dashboardFocus = 'structured_learning';
        recommendedFeatures = ['Lessons', 'Grammar Detective', 'CEFR Progress'];
        contentTheme = 'academic';
        break;
    }

    // Learning style personalization
    String? primaryActivity;
    if (data.learningStyle == 'audio') {
      primaryActivity = 'listening';
    } else if (data.learningStyle == 'visual') {
      primaryActivity = 'games';
    } else if (data.learningStyle == 'stories') {
      primaryActivity = 'story_builder';
    } else if (data.learningStyle == 'conversation') {
      primaryActivity = 'ai_chat';
    }

    // Gamification level
    bool showGamification = data.gamificationLevel != 'minimal';
    bool emphasizeStreaks = data.motivationTriggers.contains('streaks');
    bool emphasizeXP = data.motivationTriggers.contains('xp');

    // Pace preference
    int? dailyGoalMinutes = data.dailyDurationMinutes;
    if (data.pacePreference == 'slow') {
      dailyGoalMinutes = (dailyGoalMinutes ?? 15) - 5;
    } else if (data.pacePreference == 'fast') {
      dailyGoalMinutes = (dailyGoalMinutes ?? 15) + 10;
    }

    // Social preferences
    bool showSocialFeatures = data.socialPreference != 'solo';
    bool showLeaderboards = data.competitionEnabled ?? false;

    return PersonalizationConfig(
      path: data.selectedPath,
      dashboardFocus: dashboardFocus,
      recommendedFeatures: recommendedFeatures,
      contentTheme: contentTheme,
      primaryActivity: primaryActivity,
      showGamification: showGamification,
      emphasizeStreaks: emphasizeStreaks,
      emphasizeXP: emphasizeXP,
      dailyGoalMinutes: dailyGoalMinutes ?? 20,
      showSocialFeatures: showSocialFeatures,
      showLeaderboards: showLeaderboards,
      appTone: data.appTone ?? 'encouraging',
      culturalContentEnabled: data.culturalContentEnabled ?? true,
      preferredTimeOfDay: data.preferredTimeOfDay,
      remindersEnabled: data.remindersEnabled ?? true,
    );
  }

  void refresh() {
    state = _buildConfigFromOnboarding(ref.read(onboardingProvider));
  }
}

final personalizationProvider = NotifierProvider<PersonalizationNotifier, PersonalizationConfig>(() {
  return PersonalizationNotifier();
});

class PersonalizationConfig {
  final String? path; // 'explore', 'career', 'academic'
  final String? dashboardFocus;
  final List<String> recommendedFeatures;
  final String? contentTheme;
  final String? primaryActivity;
  final bool showGamification;
  final bool emphasizeStreaks;
  final bool emphasizeXP;
  final int dailyGoalMinutes;
  final bool showSocialFeatures;
  final bool showLeaderboards;
  final String appTone;
  final bool culturalContentEnabled;
  final String? preferredTimeOfDay;
  final bool remindersEnabled;

  PersonalizationConfig({
    this.path,
    this.dashboardFocus,
    this.recommendedFeatures = const [],
    this.contentTheme,
    this.primaryActivity,
    this.showGamification = true,
    this.emphasizeStreaks = true,
    this.emphasizeXP = true,
    this.dailyGoalMinutes = 20,
    this.showSocialFeatures = true,
    this.showLeaderboards = true,
    this.appTone = 'encouraging',
    this.culturalContentEnabled = true,
    this.preferredTimeOfDay,
    this.remindersEnabled = true,
  });
}

