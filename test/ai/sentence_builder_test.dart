import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/chapter3.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/sentence_builder.dart';

void main() {
  test('subtitle default on for A2, off for B1', () {
    expect(questSubtitlesDefaultOn('A2'), isTrue);
    expect(questSubtitlesDefaultOn('B1'), isFalse);
  });

  test('scaffold validates defend position', () {
    final scaffold = kYaaCouncilDefendScaffold;
    final filled = ['we', 'must', 'defend', 'stool', 'together'];
    expect(
      validateScaffoldSelection(scaffold: scaffold, filledTokenIds: filled),
      QuestBuilderValidation.complete,
    );
    expect(
      validateScaffoldSelection(
        scaffold: scaffold,
        filledTokenIds: ['we', 'must', 'negotiate', 'stool', 'together'],
      ),
      QuestBuilderValidation.wrongPosition,
    );
  });
}
