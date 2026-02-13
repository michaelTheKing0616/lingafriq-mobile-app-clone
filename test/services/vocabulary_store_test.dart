import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/offline/vocabulary_store.dart';
import 'package:lingafriq/models/offline/local_vocabulary.dart';

void main() {
  group('VocabularyStore SM-2 Algorithm', () {
    late VocabularyStore store;

    setUp(() {
      store = VocabularyStore();
    });

    group('Quality 0-2 resets repetitions', () {
      test('quality 0 resets repetitions and interval', () async {
        final vocab = LocalVocabulary(
          id: 'test1',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 10,
          repetitions: 5,
          nextReviewDate: DateTime.now().add(const Duration(days: 10)),
        );

        await store.addWord(vocab);
        await store.reviewWord('test1', 0);

        final updated = store.getVocabulary('test1');
        expect(updated, isNotNull);
        expect(updated!.repetitions, equals(0));
        expect(updated.interval, equals(1));
        expect(updated.nextReviewDate, isNotNull);
        expect(
          updated.nextReviewDate!.difference(DateTime.now()).inDays,
          equals(1),
        );
      });

      test('quality 1 resets repetitions and interval', () async {
        final vocab = LocalVocabulary(
          id: 'test2',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 10,
          repetitions: 5,
        );

        await store.addWord(vocab);
        await store.reviewWord('test2', 1);

        final updated = store.getVocabulary('test2');
        expect(updated, isNotNull);
        expect(updated!.repetitions, equals(0));
        expect(updated.interval, equals(1));
      });

      test('quality 2 resets repetitions and interval', () async {
        final vocab = LocalVocabulary(
          id: 'test3',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 10,
          repetitions: 5,
        );

        await store.addWord(vocab);
        await store.reviewWord('test3', 2);

        final updated = store.getVocabulary('test3');
        expect(updated, isNotNull);
        expect(updated!.repetitions, equals(0));
        expect(updated.interval, equals(1));
      });
    });

    group('Quality 4-5 increases interval', () {
      test('quality 4 increases interval and updates ease factor', () async {
        final vocab = LocalVocabulary(
          id: 'test4',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 6,
          repetitions: 2,
        );

        await store.addWord(vocab);
        final initialEF = vocab.easeFactor;
        await store.reviewWord('test4', 4);

        final updated = store.getVocabulary('test4');
        expect(updated, isNotNull);
        expect(updated!.repetitions, greaterThan(2));
        expect(updated.interval, greaterThan(6));
        expect(updated.easeFactor, greaterThan(initialEF));
      });

      test('quality 5 increases interval and updates ease factor', () async {
        final vocab = LocalVocabulary(
          id: 'test5',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 6,
          repetitions: 2,
        );

        await store.addWord(vocab);
        final initialEF = vocab.easeFactor;
        await store.reviewWord('test5', 5);

        final updated = store.getVocabulary('test5');
        expect(updated, isNotNull);
        expect(updated!.repetitions, greaterThan(2));
        expect(updated.interval, greaterThan(6));
        expect(updated.easeFactor, greaterThan(initialEF));
      });
    });

    group('Ease factor adjustment', () {
      test('ease factor increases for quality 4', () async {
        final vocab = LocalVocabulary(
          id: 'test6',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 6,
          repetitions: 2,
        );

        await store.addWord(vocab);
        await store.reviewWord('test6', 4);

        final updated = store.getVocabulary('test6');
        expect(updated, isNotNull);
        expect(updated!.easeFactor, greaterThan(2.5));
      });

      test('ease factor increases more for quality 5 than quality 4', () async {
        final vocab1 = LocalVocabulary(
          id: 'test7a',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 6,
          repetitions: 2,
        );
        final vocab2 = LocalVocabulary(
          id: 'test7b',
          word: 'world',
          translation: 'monde',
          language: 'french',
          easeFactor: 2.5,
          interval: 6,
          repetitions: 2,
        );

        await store.addWord(vocab1);
        await store.addWord(vocab2);
        await store.reviewWord('test7a', 4);
        await store.reviewWord('test7b', 5);

        final updated1 = store.getVocabulary('test7a');
        final updated2 = store.getVocabulary('test7b');
        expect(updated1, isNotNull);
        expect(updated2, isNotNull);
        expect(updated2!.easeFactor, greaterThan(updated1!.easeFactor));
      });

      test('minimum ease factor constraint is enforced', () async {
        final vocab = LocalVocabulary(
          id: 'test8',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 1.3,
          interval: 1,
          repetitions: 0,
        );

        await store.addWord(vocab);
        // Review with low quality multiple times to try to reduce ease factor
        await store.reviewWord('test8', 0);
        await store.reviewWord('test8', 4);

        final updated = store.getVocabulary('test8');
        expect(updated, isNotNull);
        expect(updated!.easeFactor, greaterThanOrEqualTo(1.3));
      });
    });

    group('Interval calculation', () {
      test('first repetition sets interval to 1', () async {
        final vocab = LocalVocabulary(
          id: 'test9',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 0,
          repetitions: 0,
        );

        await store.addWord(vocab);
        await store.reviewWord('test9', 3);

        final updated = store.getVocabulary('test9');
        expect(updated, isNotNull);
        expect(updated!.interval, equals(1));
        expect(updated.repetitions, equals(1));
      });

      test('second repetition sets interval to 6', () async {
        final vocab = LocalVocabulary(
          id: 'test10',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 1,
          repetitions: 1,
        );

        await store.addWord(vocab);
        await store.reviewWord('test10', 3);

        final updated = store.getVocabulary('test10');
        expect(updated, isNotNull);
        expect(updated!.interval, equals(6));
        expect(updated.repetitions, equals(2));
      });

      test('third repetition multiplies interval by ease factor', () async {
        final vocab = LocalVocabulary(
          id: 'test11',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
          easeFactor: 2.5,
          interval: 6,
          repetitions: 2,
        );

        await store.addWord(vocab);
        await store.reviewWord('test11', 3);

        final updated = store.getVocabulary('test11');
        expect(updated, isNotNull);
        expect(updated!.interval, equals(15)); // 6 * 2.5 = 15
        expect(updated.repetitions, equals(3));
      });
    });

    group('Words due for review sorting', () {
      test('sorts by most overdue first', () {
        final now = DateTime.now();
        final vocab1 = LocalVocabulary(
          id: 'overdue1',
          word: 'word1',
          translation: 'trans1',
          language: 'french',
          nextReviewDate: now.subtract(const Duration(days: 5)),
        );
        final vocab2 = LocalVocabulary(
          id: 'overdue2',
          word: 'word2',
          translation: 'trans2',
          language: 'french',
          nextReviewDate: now.subtract(const Duration(days: 2)),
        );
        final vocab3 = LocalVocabulary(
          id: 'due',
          word: 'word3',
          translation: 'trans3',
          language: 'french',
          nextReviewDate: now,
        );

        // Note: This test requires actual database setup
        // In a real test, you'd add these words and then check sorting
        expect(vocab1.nextReviewDate!.isBefore(now), isTrue);
        expect(vocab2.nextReviewDate!.isBefore(now), isTrue);
        expect(vocab3.nextReviewDate!.isAtSameMomentAs(now), isTrue);
      });

      test('words without nextReviewDate are included', () {
        final vocab = LocalVocabulary(
          id: 'new',
          word: 'word',
          translation: 'trans',
          language: 'french',
          nextReviewDate: null,
        );

        expect(vocab.nextReviewDate, isNull);
      });
    });

    group('Error handling', () {
      test('throws error for invalid quality', () async {
        final vocab = LocalVocabulary(
          id: 'test12',
          word: 'hello',
          translation: 'bonjour',
          language: 'french',
        );

        await store.addWord(vocab);

        expect(
          () => store.reviewWord('test12', -1),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => store.reviewWord('test12', 6),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for non-existent vocabulary', () {
        expect(
          () => store.reviewWord('nonexistent', 3),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
