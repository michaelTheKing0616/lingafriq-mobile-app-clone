import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Blueprint §42 — historical persona missions with user-selectable setting/plot.
class PersonaMission {
  final String id;
  final String language;
  final String personaTitle;
  final String historicalSetting;
  final List<String> userSettingOptions;
  final List<PersonaMissionStep> steps;
  final List<String> culturalFocus;

  const PersonaMission({
    required this.id,
    required this.language,
    required this.personaTitle,
    required this.historicalSetting,
    required this.userSettingOptions,
    required this.steps,
    required this.culturalFocus,
  });

  factory PersonaMission.fromJson(Map<String, dynamic> json) => PersonaMission(
        id: json['id'] as String,
        language: json['language'] as String,
        personaTitle: json['persona_title'] as String,
        historicalSetting: json['historical_setting'] as String,
        userSettingOptions: (json['user_setting_options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        steps: (json['steps'] as List<dynamic>?)
                ?.map((e) => PersonaMissionStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        culturalFocus: (json['cultural_focus'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

class PersonaMissionStep {
  final int step;
  final String title;
  final List<String> vocab;
  final String poliePrompt;

  const PersonaMissionStep({
    required this.step,
    required this.title,
    required this.vocab,
    required this.poliePrompt,
  });

  factory PersonaMissionStep.fromJson(Map<String, dynamic> json) =>
      PersonaMissionStep(
        step: json['step'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        vocab: (json['vocab'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        poliePrompt: json['polie_prompt'] as String? ?? '',
      );
}

class PersonaMissionSession {
  final PersonaMission mission;
  final String selectedSetting;
  final String? customPlot;
  int currentStepIndex;

  PersonaMissionSession({
    required this.mission,
    required this.selectedSetting,
    this.customPlot,
    this.currentStepIndex = 0,
  });

  PersonaMissionStep? get currentStep {
    if (currentStepIndex < 0 || currentStepIndex >= mission.steps.length) {
      return null;
    }
    return mission.steps[currentStepIndex];
  }

  bool get isComplete => currentStepIndex >= mission.steps.length;

  String buildPolieSystemContext() {
    final step = currentStep;
    final plot = customPlot?.trim().isNotEmpty == true
        ? customPlot!.trim()
        : selectedSetting;
    return '''
You are Polie embodying "${mission.personaTitle}" in ${mission.language}.
Historical setting: ${mission.historicalSetting}.
User-selected scene: $plot
Cultural focus: ${mission.culturalFocus.join(', ')}
Current step (${step?.step ?? 0}): ${step?.title ?? 'Complete'}
Vocabulary for this beat: ${step?.vocab.join(', ') ?? ''}
Director prompt: ${step?.poliePrompt ?? 'Close the mission with respect.'}
Stay in character. Correct gently using tier correct/close/incorrect.
''';
  }
}

class PersonaMissionService {
  static const _assetPath = 'assets/data/persona_missions.json';

  List<PersonaMission>? _missions;

  Future<List<PersonaMission>> loadMissions() async {
    if (_missions != null) return _missions!;
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _missions = (data['missions'] as List<dynamic>?)
            ?.map((e) => PersonaMission.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return _missions!;
  }

  Future<List<PersonaMission>> missionsForLanguage(String language) async {
    final all = await loadMissions();
    final key = language.toLowerCase();
    return all.where((m) => m.language.toLowerCase() == key).toList();
  }

  Future<void> saveMissionProgress(String missionId, int stepIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('persona_mission_$missionId', stepIndex);
  }

  Future<int> loadMissionProgress(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('persona_mission_$missionId') ?? 0;
  }
}

final personaMissionServiceProvider = Provider<PersonaMissionService>((ref) {
  return PersonaMissionService();
});

final personaMissionsForLanguageProvider =
    FutureProvider.family<List<PersonaMission>, String>((ref, language) async {
  return ref.read(personaMissionServiceProvider).missionsForLanguage(language);
});
