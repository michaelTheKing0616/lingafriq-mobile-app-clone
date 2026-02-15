import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Curriculum Service Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('Curriculum service initialization', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(curriculumServiceProvider);
      
      expect(service, isNotNull);
    });

    test('Fallback lesson content generation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(curriculumServiceProvider);
      
      // Test fallback content (will work even if AI fails)
      final vocab = [
        {'word': 'test', 'meaning': 'test meaning'},
      ];
      
      final content = await service.generateLessonContent(
        language: 'yoruba',
        level: 'A1',
        lessonTitle: 'Test Lesson',
        vocab: vocab,
        grammar: ['test grammar'],
      );
      
      expect(content, isNotNull);
      expect(content['grammar_explanations'], isNotNull);
      expect(content['dialogue'], isNotNull);
      expect(content['exercises'], isNotNull);
    });

    test('Fallback dialogue generation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(curriculumServiceProvider);
      
      final vocab = [
        {'word': 'hello', 'meaning': 'greeting'},
      ];
      
      final dialogue = await service.generateDialogue(
        language: 'yoruba',
        level: 'A1',
        vocab: vocab,
      );
      
      expect(dialogue, isNotNull);
      expect(dialogue['script'], isNotNull);
    });

    test('Fallback exercise generation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(curriculumServiceProvider);
      
      final vocab = [
        {'word': 'test', 'meaning': 'test meaning'},
      ];
      
      final exercises = await service.generateExercises(
        language: 'yoruba',
        level: 'A1',
        vocab: vocab,
        grammar: ['test grammar'],
      );
      
      expect(exercises, isNotNull);
      expect(exercises, isNotEmpty);
    });
  });
}


