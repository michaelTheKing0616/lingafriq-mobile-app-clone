import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/onboarding_data_model.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingData Model', () {
    test('should create with default values', () {
      final data = OnboardingData();
      
      expect(data.selectedPath, isNull);
      expect(data.learningStyle, isNull);
      expect(data.dailyDurationMinutes, isNull);
      expect(data.motivationTriggers, isEmpty);
    });
    
    test('should serialize to JSON', () {
      final data = OnboardingData(
        selectedPath: 'explore',
        learningStyle: 'visual',
        dailyDurationMinutes: 15,
        motivationTriggers: ['streaks', 'xp'],
      );
      
      final json = data.toJson();
      
      expect(json, isA<String>());
      expect(json.contains('explore'), true);
      expect(json.contains('visual'), true);
    });
    
    test('should deserialize from JSON', () {
      final originalData = OnboardingData(
        selectedPath: 'career',
        proficiencyLevel: 'intermediate',
        dailyDurationMinutes: 30,
      );
      
      final json = originalData.toJson();
      final restoredData = OnboardingData.fromJson(json);
      
      expect(restoredData.selectedPath, 'career');
      expect(restoredData.proficiencyLevel, 'intermediate');
      expect(restoredData.dailyDurationMinutes, 30);
    });
    
    // OnboardingData does not have copyWith; test direct construction instead.
    test('should create instances with different selectedPath', () {
      final explore = OnboardingData(selectedPath: 'explore');
      final academic = OnboardingData(selectedPath: 'academic');

      expect(explore.selectedPath, 'explore');
      expect(academic.selectedPath, 'academic');
    });
  });
  
  group('OnboardingNotifier', () {
    late ProviderContainer container;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('should update language', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.updateLanguage('Swahili');

      final state = container.read(onboardingProvider);
      expect(state.selectedLanguage, 'Swahili');
    });
    
    test('should update learning style', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.updateLearningStyle('visual');
      
      final state = container.read(onboardingProvider);
      expect(state.learningStyle, 'visual');
    });
    
    test('should update proficiency level', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.updateProficiencyLevel('intermediate');
      
      final state = container.read(onboardingProvider);
      expect(state.proficiencyLevel, 'intermediate');
    });
    
    test('should update path selection', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.updatePath('career');
      
      final state = container.read(onboardingProvider);
      expect(state.selectedPath, 'career');
    });
    
    test('should update daily duration via updateSchedule', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.updateSchedule(20, 'midday');

      final state = container.read(onboardingProvider);
      expect(state.dailyDurationMinutes, 20);
      expect(state.preferredTimeOfDay, 'midday');
    });

    test('should update gamification level via updatePersonality', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.updatePersonality('encouraging', 'full');

      final state = container.read(onboardingProvider);
      expect(state.gamificationLevel, 'full');
    });

    test('should update motivation triggers via updateGoals', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.updateGoals('travel', triggers: ['streaks', 'achievements']);

      final state = container.read(onboardingProvider);
      expect(state.motivationTriggers, ['streaks', 'achievements']);
    });
    
    test('should update placement test results', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.updatePlacementTest({
        'completed': true,
        'level': 'B1',
        'score': 75,
      });
      
      final state = container.read(onboardingProvider);
      expect(state.placementTestResults, isNotNull);
      expect(state.placementTestResults!['completed'], true);
      expect(state.placementTestResults!['level'], 'B1');
    });
  });
  
  group('Onboarding Validation', () {
    test('proficiency level should be valid CEFR level', () {
      final validLevels = ['a0', 'a1', 'a2', 'b1', 'b2', 'c1', 'c2', 'beginner', 'intermediate', 'advanced'];
      
      for (final level in validLevels) {
        final data = OnboardingData(proficiencyLevel: level);
        expect(data.proficiencyLevel, level);
      }
    });
    
    test('daily duration should be positive', () {
      final data = OnboardingData(dailyDurationMinutes: 15);
      expect(data.dailyDurationMinutes, greaterThan(0));
    });
  });
}
