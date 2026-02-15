import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/grammar_progress_provider.dart'
    show grammarProgressProvider, GrammarMastery, kGrammarProgressSkipBackendSync;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GrammarMastery', () {
    test('should create GrammarMastery with default values', () {
      final mastery = GrammarMastery(
        topicId: 'topic1',
        masteryPercentage: 0,
      );

      expect(mastery.topicId, 'topic1');
      expect(mastery.masteryPercentage, 0);
      expect(mastery.exercisesCompleted, 0);
      expect(mastery.averageScore, 0);
      expect(mastery.lastPracticed, isNotNull);
    });

    test('should serialize and deserialize correctly', () {
      final mastery = GrammarMastery(
        topicId: 'topic1',
        masteryPercentage: 85.5,
        exercisesCompleted: 20,
        averageScore: 82.3,
        lastPracticed: DateTime(2024, 1, 15),
      );

      final json = mastery.toJson();
      final restored = GrammarMastery.fromJson(json);

      expect(restored.topicId, mastery.topicId);
      expect(restored.masteryPercentage, mastery.masteryPercentage);
      expect(restored.exercisesCompleted, mastery.exercisesCompleted);
      expect(restored.averageScore, mastery.averageScore);
      expect(restored.lastPracticed, mastery.lastPracticed);
    });

    test('should handle null values in JSON', () {
      final json = {
        'topicId': 'topic1',
        'masteryPercentage': null,
        'exercisesCompleted': null,
        'averageScore': null,
        'lastPracticed': null,
      };

      final mastery = GrammarMastery.fromJson(json);

      expect(mastery.topicId, 'topic1');
      expect(mastery.masteryPercentage, 0);
      expect(mastery.exercisesCompleted, 0);
      expect(mastery.averageScore, 0);
      expect(mastery.lastPracticed, isNotNull);
    });
  });

  group('GrammarProgressNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      kGrammarProgressSkipBackendSync = true;
      container = ProviderContainer();
    });

    tearDown(() {
      kGrammarProgressSkipBackendSync = false;
      container.dispose();
    });

    test('should initialize with empty state', () {
      final state = container.read(grammarProgressProvider);
      expect(state, isEmpty);
    });

    test('should calculate mastery percentage correctly', () async {
      final notifier = container.read(grammarProgressProvider.notifier);

      await notifier.updateMastery('topic1', 8, 10);

      final state = container.read(grammarProgressProvider);
      final mastery = state['topic1'];

      expect(mastery, isNotNull);
      expect(mastery!.masteryPercentage, 80.0);
    });

    test('should clamp mastery percentage to 0-100', () async {
      final notifier = container.read(grammarProgressProvider.notifier);

      // Test negative score
      await notifier.updateMastery('topic1', -5, 10);
      var state = container.read(grammarProgressProvider);
      expect(state['topic1']!.masteryPercentage, 0);

      // Test score exceeding total
      await notifier.updateMastery('topic2', 15, 10);
      state = container.read(grammarProgressProvider);
      expect(state['topic2']!.masteryPercentage, 100);
    });

    test('should track exercises completed', () async {
      final notifier = container.read(grammarProgressProvider.notifier);

      await notifier.updateMastery('topic1', 5, 10);
      await notifier.updateMastery('topic1', 7, 10);

      final state = container.read(grammarProgressProvider);
      final mastery = state['topic1'];

      expect(mastery!.exercisesCompleted, 20); // 10 + 10
    });

    test('should calculate average score correctly', () async {
      final notifier = container.read(grammarProgressProvider.notifier);

      // First attempt: 5/10 → averageScore stored as ratio 0.5
      await notifier.updateMastery('topic1', 5, 10);
      var state = container.read(grammarProgressProvider);
      expect(state['topic1']!.averageScore, 0.5);

      // Second attempt: 8/10 → average: (0.5*10 + 8)/20 = 0.65
      await notifier.updateMastery('topic1', 8, 10);
      state = container.read(grammarProgressProvider);
      expect(state['topic1']!.averageScore, closeTo(0.65, 0.01));
    });

    test('should update lastPracticed timestamp', () async {
      // Let initial async _loadFromLocal() from build() complete so it does not overwrite state after updateMastery.
      container.read(grammarProgressProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(grammarProgressProvider.notifier);
      final before = DateTime.now();

      await notifier.updateMastery('topic1', 5, 10);

      final state = container.read(grammarProgressProvider);
      final mastery = state['topic1'];
      final after = DateTime.now();

      expect(mastery!.lastPracticed.isAfter(before) || mastery.lastPracticed.isAtSameMomentAs(before), true);
      expect(mastery.lastPracticed.isBefore(after) || mastery.lastPracticed.isAtSameMomentAs(after), true);
    });

    test('should get mastery for topic', () async {
      final notifier = container.read(grammarProgressProvider.notifier);

      await notifier.updateMastery('topic1', 8, 10);

      final mastery = notifier.getMastery('topic1');
      expect(mastery, isNotNull);
      expect(mastery!.topicId, 'topic1');
      expect(mastery.masteryPercentage, 80);

      final nonExistent = notifier.getMastery('nonexistent');
      expect(nonExistent, isNull);
    });
  });

  group('Spaced Repetition Scheduling', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      kGrammarProgressSkipBackendSync = true;
      container = ProviderContainer();
    });

    tearDown(() {
      kGrammarProgressSkipBackendSync = false;
      container.dispose();
    });

    test('should return topics for review when mastery < 80%', () async {
      final notifier = container.read(grammarProgressProvider.notifier);

      await notifier.updateMastery('topic1', 6, 10); // 60%
      await notifier.updateMastery('topic2', 9, 10); // 90%

      final topicsForReview = notifier.getTopicsForReview();

      expect(topicsForReview, contains('topic1'));
      expect(topicsForReview, isNot(contains('topic2')));
    });

    test('should return topics for review based on review interval', () async {
      final notifier = container.read(grammarProgressProvider.notifier);

      // Create mastery with 85% (should review every 14 days)
      await notifier.updateMastery('topic1', 8, 10);
      
      // Manually set lastPracticed to 15 days ago
      final state = container.read(grammarProgressProvider);
      final mastery = state['topic1']!;
      final updatedMastery = GrammarMastery(
        topicId: mastery.topicId,
        masteryPercentage: mastery.masteryPercentage,
        exercisesCompleted: mastery.exercisesCompleted,
        lastPracticed: DateTime.now().subtract(const Duration(days: 15)),
        averageScore: mastery.averageScore,
      );
      container.read(grammarProgressProvider.notifier).state = {
        'topic1': updatedMastery,
      };

      final topicsForReview = notifier.getTopicsForReview();
      expect(topicsForReview, contains('topic1'));
    });

    test('should not return recently practiced topics', () async {
      final notifier = container.read(grammarProgressProvider.notifier);

      // Create mastery with 90% (should review every 30 days)
      await notifier.updateMastery('topic1', 9, 10);

      // Topic was just practiced, so shouldn't be in review list
      final topicsForReview = notifier.getTopicsForReview();
      expect(topicsForReview, isNot(contains('topic1')));
    });

    test('should use correct review intervals', () {
      final notifier = container.read(grammarProgressProvider.notifier);

      // Test review interval calculation
      // This tests the private _getReviewInterval method indirectly
      // by checking behavior with different mastery levels

      // 90%+ mastery should have 30-day interval
      final highMastery = GrammarMastery(
        topicId: 'high',
        masteryPercentage: 95,
        lastPracticed: DateTime.now().subtract(const Duration(days: 29)),
      );
      container.read(grammarProgressProvider.notifier).state = {'high': highMastery};
      expect(notifier.getTopicsForReview(), isNot(contains('high')));

      // 80-89% mastery should have 14-day interval
      final mediumMastery = GrammarMastery(
        topicId: 'medium',
        masteryPercentage: 85,
        lastPracticed: DateTime.now().subtract(const Duration(days: 15)),
      );
      container.read(grammarProgressProvider.notifier).state = {
        'high': highMastery,
        'medium': mediumMastery,
      };
      expect(notifier.getTopicsForReview(), contains('medium'));

      // 60-79% mastery should have 7-day interval
      final lowMastery = GrammarMastery(
        topicId: 'low',
        masteryPercentage: 70,
        lastPracticed: DateTime.now().subtract(const Duration(days: 8)),
      );
      container.read(grammarProgressProvider.notifier).state = {
        'high': highMastery,
        'medium': mediumMastery,
        'low': lowMastery,
      };
      expect(notifier.getTopicsForReview(), contains('low'));

      // <60% mastery should have 3-day interval
      final veryLowMastery = GrammarMastery(
        topicId: 'verylow',
        masteryPercentage: 50,
        lastPracticed: DateTime.now().subtract(const Duration(days: 4)),
      );
      container.read(grammarProgressProvider.notifier).state = {
        'high': highMastery,
        'medium': mediumMastery,
        'low': lowMastery,
        'verylow': veryLowMastery,
      };
      expect(notifier.getTopicsForReview(), contains('verylow'));
    });
  });
}
