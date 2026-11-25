import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/chapter3.dart';

void main() {
  test('comprehension checkpoint requires three correct answers', () {
    final sentences = defaultYaaDemandKeySentences();
    expect(sentences.length, 3);

    final fail = evaluateComprehensionCheckpoint(
      sentences: sentences.sublist(0, 1),
      answersBySentenceId: {'ks1': 'coin'},
    );
    expect(fail.passed, isFalse);
    expect(fail.failedSentenceId, 'ks1');

    final pass = evaluateComprehensionCheckpoint(
      sentences: sentences,
      answersBySentenceId: {
        'ks1': 'soul',
        'ks2': 'outsiders',
        'ks3': 'queen_mother',
      },
    );
    expect(pass.passed, isTrue);
  });
}
