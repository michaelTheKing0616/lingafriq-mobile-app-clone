import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/word_of_the_day_service.dart';

VerifiedLexeme _lexeme({
  required String id,
  required String status,
  Map<String, dynamic>? rawExtra,
}) {
  final raw = <String, dynamic>{
    'id': id,
    'lemma': 'báwo',
    'orthography': {'standard': 'báwo'},
    if (rawExtra != null) ...rawExtra,
  };
  return VerifiedLexeme(
    lexemeId: id,
    language: 'yo',
    verificationStatus: status,
    lemma: 'báwo',
    standardOrthography: 'báwo',
    exampleSentence: null,
    audioUris: const [],
    raw: raw,
  );
}

void main() {
  group('extractWordStory', () {
    test('prefers word_story field', () {
      expect(
        extractWordStory({'word_story': 'A greeting story.'}),
        'A greeting story.',
      );
    });

    test('falls back to culture_notes string', () {
      expect(
        extractWordStory({'culture_notes': 'Used when meeting elders.'}),
        'Used when meeting elders.',
      );
    });
  });

  group('pickWordOfTheDay', () {
    final day = DateTime.utc(2026, 10, 27);

    test('same day and language pick the same lexeme for all learners', () {
      final catalog = [
        _lexeme(
          id: 'yo.lex.aa',
          status: 'expert_reviewed',
          rawExtra: {'word_story': 'Story A'},
        ),
        _lexeme(
          id: 'yo.lex.bb',
          status: 'expert_reviewed',
          rawExtra: {'word_story': 'Story B'},
        ),
        _lexeme(
          id: 'yo.lex.cc',
          status: 'beta',
          rawExtra: {'word_story': 'Hidden'},
        ),
      ];
      final first = pickWordOfTheDay(
        dayUtc: day,
        language: 'yo',
        catalog: catalog,
      );
      final second = pickWordOfTheDay(
        dayUtc: day,
        language: 'yo',
        catalog: List<VerifiedLexeme>.from(catalog.reversed),
      );
      expect(first, isNotNull);
      expect(second?.lexeme.lexemeId, first?.lexeme.lexemeId);
      expect(first?.calendarDayUtc, '2026-10-27');
    });

    test('returns null when no verified word has a story', () {
      final catalog = [
        _lexeme(id: 'yo.lex.aa', status: 'expert_reviewed'),
        _lexeme(
          id: 'yo.lex.bb',
          status: 'expert_reviewed',
          rawExtra: {'word_story': ''},
        ),
      ];
      expect(
        pickWordOfTheDay(dayUtc: day, language: 'yo', catalog: catalog),
        isNull,
      );
    });

    test('stableWotdIndex stays within range', () {
      final idx = stableWotdIndex(
        calendarDayUtc: '2026-10-27',
        language: 'yo',
        candidateCount: 5,
      );
      expect(idx, inInclusiveRange(0, 4));
    });
  });
}
