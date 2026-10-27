import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/vocabulary/lexicon_entry_screen.dart';
import 'package:lingafriq/services/multilingual_relay_lexicon.dart';
import 'package:lingafriq/widgets/same_idea_view.dart';

void main() {
  group('MultilingualRelayLexicon', () {
    test('resolves water equivalents from concept_id links', () {
      final index = MultilingualRelayLexicon.fromVerifiedEntries([
        {
          'id': 'yo.lex.omi.water',
          'concept_id': 'concept.water',
          'lemma': 'omi',
          'orthography': {'standard': 'omi'},
        },
        {
          'id': 'ig.lex.mmiri.water',
          'concept_id': 'concept.water',
          'lemma': 'mmiri',
          'orthography': {'standard': 'mmiri'},
        },
        {
          'id': 'ha.lex.ruwa.water',
          'concept_id': 'concept.water',
          'lemma': 'ruwa',
          'orthography': {'standard': 'ruwa'},
        },
      ]);

      final yoEntry = {
        'id': 'yo.lex.omi.water',
        'concept_id': 'concept.water',
        'orthography': {'standard': 'omi'},
      };
      final rows = index.sameIdeaRowsForEntry(yoEntry);
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.languageCode).toSet(), {'ig', 'ha'});
      expect(
        index.relayTargetLemma(sourceEntry: yoEntry, targetLanguage: 'ig'),
        'mmiri',
      );
    });

    test('does not invent verified lemma when concept missing in target language', () {
      final index = MultilingualRelayLexicon.fromVerifiedEntries([
        {
          'id': 'yo.lex.omi.water',
          'concept_id': 'concept.water',
          'orthography': {'standard': 'omi'},
        },
      ]);
      expect(
        index.relayTargetLemma(
          sourceEntry: {
            'id': 'yo.lex.omi.water',
            'concept_id': 'concept.water',
          },
          targetLanguage: 'sw',
        ),
        isNull,
      );
    });

    test('falls back to embedded same_idea list without concept_id', () {
      final index = MultilingualRelayLexicon.fromVerifiedEntries(const []);
      final rows = index.sameIdeaRowsForEntry({
        'same_idea_in_other_languages': [
          {'language': 'ig', 'lemma': 'mmiri', 'lexeme_id': 'ig.lex.mmiri.water'},
        ],
      });
      expect(rows, hasLength(1));
      expect(rows.first.lemma, 'mmiri');
    });
  });

  group('SameIdeaView', () {
    testWidgets('renders verified chips and unavailable copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SameIdeaView(
              rows: const [
                LexiconSameIdeaRow(
                  languageCode: 'ig',
                  languageLabel: 'Igbo',
                  lemma: 'mmiri',
                  lexemeId: 'ig.lex.mmiri.water',
                ),
                LexiconSameIdeaRow(
                  languageCode: 'sw',
                  languageLabel: 'Swahili',
                  lemma: '',
                  verified: false,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text(kSameIdeaTitle), findsOneWidget);
      expect(find.textContaining('Igbo · mmiri'), findsOneWidget);
      expect(find.textContaining(kSameIdeaUnavailable), findsOneWidget);
    });

    testWidgets('hides when rows empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SameIdeaView(rows: []))),
      );
      expect(find.text(kSameIdeaTitle), findsNothing);
    });
  });
}
