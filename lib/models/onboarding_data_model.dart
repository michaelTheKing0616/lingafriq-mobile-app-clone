import 'dart:convert';

class OnboardingData {
  // User Profile
  String? ageCategory; // 'child', 'teen', 'adult'
  List<String> learningReasons; // ['heritage', 'travel', 'school', 'business', 'curiosity']
  
  // Language Profile
  String? selectedLanguage;
  String? selectedDialect;
  String? proficiencyLevel; // 'beginner', 'intermediate', 'advanced'
  bool? literacyPreference; // true = spoken + written, false = spoken only
  
  // Learning Preferences
  String? learningStyle; // 'audio', 'visual', 'stories', 'drills', 'conversation'
  String? pacePreference; // 'slow', 'steady', 'fast', 'surprise'
  String? appTone; // 'playful', 'encouraging', 'serious'
  String? gamificationLevel; // 'high', 'medium', 'minimal'
  bool? culturalContentEnabled;
  
  // Goals & Motivation
  String? primaryGoal; // 'travel', 'heritage', 'business', 'academic', 'confidence', 'brain_training'
  List<String> secondaryGoals;
  List<String> motivationTriggers; // ['streaks', 'xp', 'storytelling', 'cultural_content', 'difficulty_breaks']
  
  // Schedule
  int? dailyDurationMinutes; // 5-25
  String? preferredTimeOfDay; // 'sunrise', 'midday', 'sunset', 'night'
  bool? remindersEnabled;
  
  // Accessibility
  bool? largeTextEnabled;
  bool? highContrastEnabled;
  bool? dyslexiaModeEnabled;
  bool? soundOffModeEnabled;
  bool? motionReductionEnabled;
  
  // Social Preferences
  String? socialPreference; // 'solo', 'buddies', 'community', 'teacher_guided'
  bool? competitionEnabled;
  String? speakingComfortLevel; // 'comfortable', 'moderate', 'uncomfortable'
  
  // Profile
  String? username;
  String? avatarPath;
  String? location; // optional
  
  // Placement Test Results
  Map<String, dynamic>? placementTestResults;
  
  OnboardingData({
    this.ageCategory,
    this.learningReasons = const [],
    this.selectedLanguage,
    this.selectedDialect,
    this.proficiencyLevel,
    this.literacyPreference,
    this.learningStyle,
    this.pacePreference,
    this.appTone,
    this.gamificationLevel,
    this.culturalContentEnabled,
    this.primaryGoal,
    this.secondaryGoals = const [],
    this.motivationTriggers = const [],
    this.dailyDurationMinutes,
    this.preferredTimeOfDay,
    this.remindersEnabled,
    this.largeTextEnabled,
    this.highContrastEnabled,
    this.dyslexiaModeEnabled,
    this.soundOffModeEnabled,
    this.motionReductionEnabled,
    this.socialPreference,
    this.competitionEnabled,
    this.speakingComfortLevel,
    this.username,
    this.avatarPath,
    this.location,
    this.placementTestResults,
  });
  
  Map<String, dynamic> toMap() => {
    'ageCategory': ageCategory,
    'learningReasons': learningReasons,
    'selectedLanguage': selectedLanguage,
    'selectedDialect': selectedDialect,
    'proficiencyLevel': proficiencyLevel,
    'literacyPreference': literacyPreference,
    'learningStyle': learningStyle,
    'pacePreference': pacePreference,
    'appTone': appTone,
    'gamificationLevel': gamificationLevel,
    'culturalContentEnabled': culturalContentEnabled,
    'primaryGoal': primaryGoal,
    'secondaryGoals': secondaryGoals,
    'motivationTriggers': motivationTriggers,
    'dailyDurationMinutes': dailyDurationMinutes,
    'preferredTimeOfDay': preferredTimeOfDay,
    'remindersEnabled': remindersEnabled,
    'largeTextEnabled': largeTextEnabled,
    'highContrastEnabled': highContrastEnabled,
    'dyslexiaModeEnabled': dyslexiaModeEnabled,
    'soundOffModeEnabled': soundOffModeEnabled,
    'motionReductionEnabled': motionReductionEnabled,
    'socialPreference': socialPreference,
    'competitionEnabled': competitionEnabled,
    'speakingComfortLevel': speakingComfortLevel,
    'username': username,
    'avatarPath': avatarPath,
    'location': location,
    'placementTestResults': placementTestResults,
  };
  
  factory OnboardingData.fromMap(Map<String, dynamic> map) => OnboardingData(
    ageCategory: map['ageCategory'],
    learningReasons: List<String>.from(map['learningReasons'] ?? []),
    selectedLanguage: map['selectedLanguage'],
    selectedDialect: map['selectedDialect'],
    proficiencyLevel: map['proficiencyLevel'],
    literacyPreference: map['literacyPreference'],
    learningStyle: map['learningStyle'],
    pacePreference: map['pacePreference'],
    appTone: map['appTone'],
    gamificationLevel: map['gamificationLevel'],
    culturalContentEnabled: map['culturalContentEnabled'],
    primaryGoal: map['primaryGoal'],
    secondaryGoals: List<String>.from(map['secondaryGoals'] ?? []),
    motivationTriggers: List<String>.from(map['motivationTriggers'] ?? []),
    dailyDurationMinutes: map['dailyDurationMinutes'],
    preferredTimeOfDay: map['preferredTimeOfDay'],
    remindersEnabled: map['remindersEnabled'],
    largeTextEnabled: map['largeTextEnabled'],
    highContrastEnabled: map['highContrastEnabled'],
    dyslexiaModeEnabled: map['dyslexiaModeEnabled'],
    soundOffModeEnabled: map['soundOffModeEnabled'],
    motionReductionEnabled: map['motionReductionEnabled'],
    socialPreference: map['socialPreference'],
    competitionEnabled: map['competitionEnabled'],
    speakingComfortLevel: map['speakingComfortLevel'],
    username: map['username'],
    avatarPath: map['avatarPath'],
    location: map['location'],
    placementTestResults: map['placementTestResults'],
  );
  
  String toJson() => jsonEncode(toMap());
  factory OnboardingData.fromJson(String json) => OnboardingData.fromMap(jsonDecode(json));
  
  bool get isComplete {
    return ageCategory != null &&
           learningReasons.isNotEmpty &&
           selectedLanguage != null &&
           proficiencyLevel != null &&
           learningStyle != null &&
           pacePreference != null &&
           appTone != null &&
           primaryGoal != null &&
           dailyDurationMinutes != null &&
           preferredTimeOfDay != null &&
           username != null &&
           username!.isNotEmpty;
  }
}

