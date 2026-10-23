import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/item.dart';

void main() {
  test('a parsed item keeps the answer rule, IRT, and skill tags', () {
    final item = ContentItem.parse(_item());
    expect(item.diacriticInsensitive, isTrue);
    expect(item.irtA, 1.2);
    expect(item.irtB, -0.4);
    expect(item.answerLink(), {
      'itemId': 'yo.item.tone.aar',
      'nodeIds': ['yo.lex.aaro.morning'],
    });
    expect(item.isServable, isTrue);
  });

  test('a multiple-choice distractor without a rationale fails', () {
    final json = _item();
    json['distractors'] = [
      {'text': 'ọkọ̀'},
    ];
    expect(() => ContentItem.parse(json), throwsArgumentError);
  });

  test('a draft item is not servable', () {
    final json = _item();
    json['review'] = {'status': 'draft'};
    expect(ContentItem.parse(json).isServable, isFalse);
  });
}

Map<String, Object?> _item() => {
      'id': 'yo.item.tone.aar',
      'language': 'yo',
      'type': 'multiple_choice',
      'stimulus': {
        'refs': ['audio/yo/aar.ogg'],
        'text': 'àárọ̀',
      },
      'answer': {
        'correct': 'àárọ̀',
        'variants': ['aaro'],
        'matching': {'diacritic_insensitive': true},
      },
      'distractors': [
        {'text': 'ọkọ̀', 'rationale': 'That word is a vehicle, not morning.'},
      ],
      'irt': {'a': 1.2, 'b': -0.4},
      'skill_tags': ['yo.lex.aaro.morning'],
      'review': {'status': 'approved'},
    };
