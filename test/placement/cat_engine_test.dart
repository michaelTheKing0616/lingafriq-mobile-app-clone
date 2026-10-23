import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/placement_question.dart';
import 'package:lingafriq/services/placement/cat_engine.dart';
import 'package:lingafriq/services/placement_test_service.dart';

void main() {
  const engine = CatEngine();

  List<CatItem> bank() {
    return [
      for (var index = 0; index < 12; index++)
        CatItem(
          id: 'item-${index.toString().padLeft(2, '0')}',
          a: 1.2,
          b: -2 + 4 * index / 11,
          calibrated: true,
        ),
      const CatItem(id: 'lure', a: 8, b: 0, calibrated: false),
    ];
  }

  CatPlacement run(bool Function(CatItem item) respond) {
    return engine.run(bank: bank(), respond: respond);
  }

  test('a short calibrated bank is provisional and has no ability', () {
    final placement = engine.run(
      bank: [
        for (var index = 0; index < 7; index++)
          CatItem(id: 'short-$index', a: 1, b: 0, calibrated: true),
      ],
      respond: (_) => throw StateError('a provisional test must not ask an item'),
    );
    expect(placement.provisional, isTrue);
    expect(placement.label, 'unsure');
    expect(placement.ability, isNull);
    expect(placement.intervalLow, isNull);
    expect(placement.intervalHigh, isNull);
    expect(placement.administered, 0);
  });

  test('an uncalibrated lure is never administered', () {
    final placement = run((_) => true);
    expect(placement.itemIds, isNot(contains('lure')));
    expect(placement.provisional, isFalse);
    expect(placement.ability, isNotNull);
    expect(placement.intervalLow!, lessThan(placement.ability!));
    expect(placement.intervalHigh!, greaterThan(placement.ability!));
    expect(placement.administered, inInclusiveRange(CatEngine.minimumLength, CatEngine.maximumLength));
  });

  test('the same responses always select the same items', () {
    final first = run((_) => true);
    final second = run((_) => true);
    expect(second.itemIds, first.itemIds);
    expect(second.ability, closeTo(first.ability!, 1e-9));
  });

  test('the next item changes when the first answer changes', () {
    String secondItem(bool firstCorrect) {
      var asked = 0;
      final placement = run((item) {
        asked += 1;
        if (asked == 1) return firstCorrect;
        return item.b < 0;
      });
      return placement.itemIds[1];
    }

    expect(secondItem(true), isNot(secondItem(false)));
  });

  test('static questions stay unsure because they are not calibrated', () {
    final questions = PlacementTestService.questionsForLanguage('yoruba');
    PlacementResult score(List<int?> answers) {
      return PlacementTestService.evaluate(
        languageCode: 'yoruba',
        questions: questions,
        selectedIndices: answers,
      );
    }

    final allCorrect = [for (final question in questions) question.correctIndex];
    final allWrong = [for (final question in questions) question.correctIndex == 0 ? 1 : 0];
    final correct = score(allCorrect);
    final wrong = score(allWrong);
    expect(correct.level, 'unsure');
    expect(correct.provisional, isTrue);
    expect(correct.ability, isNull);
    expect(wrong.level, 'unsure');
    expect(wrong.ability, isNull);
    expect(correct.correct, questions.length);
    expect(wrong.correct, 0);
  });
}
