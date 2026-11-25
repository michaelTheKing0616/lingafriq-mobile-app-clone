import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/screens/vocabulary/lexicon_entry_screen.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
VerifiedLexeme _baseLexeme(Map<String, dynamic> entryOverrides) {
  final fixturePath =
      File('test/content/fixtures/lexeme_yo_oko.json').absolute.path;
  final fixture =
      jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
  final entry = {...fixture, ...entryOverrides};
  return VerifiedLexeme.fromApiJson({
    'lexeme_id': entry['id'],
    'language': 'yo',
    'verification_status': entry['label'] ?? 'expert_reviewed',
    'entry': entry,
  });
}

Widget _host(Widget child) => MaterialApp(home: child);

void main() {
  group('parseLexiconProverbs', () {
    test('empty when field missing', () {
      expect(parseLexiconProverbs({}), isEmpty);
    });

    test('reads string and list forms', () {
      expect(
        parseLexiconProverbs({'proverbs': 'Ìwà lẹwà'}),
        [isA<LexiconProverbLine>()],
      );
      final lines = parseLexiconProverbs({
        'proverbs': [
          {'text': 'Ọwọ́ ọ̀rẹ́', 'gloss_en': 'Friendship'},
        ],
      });
      expect(lines, hasLength(1));
      expect(lines.first.text, 'Ọwọ́ ọ̀rẹ́');
      expect(lines.first.gloss, 'Friendship');
    });
  });

  group('parseLexiconCultureNotes', () {
    test('empty when field missing', () {
      expect(parseLexiconCultureNotes({}), isEmpty);
    });

    test('reads culture_notes string', () {
      expect(
        parseLexiconCultureNotes({'culture_notes': 'Greeting culture matters.'}),
        ['Greeting culture matters.'],
      );
    });
  });

  group('parseSameIdeaInOtherLanguages', () {
    test('empty when field missing', () {
      expect(parseSameIdeaInOtherLanguages({}), isEmpty);
    });

    test('parses verified rows', () {
      final rows = parseSameIdeaInOtherLanguages({
        'same_idea_in_other_languages': [
          {'language': 'ig', 'lemma': 'mmiri'},
          {'language': 'ha', 'lemma': 'ruwa', 'verified': true},
        ],
      });
      expect(rows, hasLength(2));
      expect(rows.first.languageLabel, 'Igbo');
      expect(rows.first.lemma, 'mmiri');
    });
  });

  group('LexiconEntryScreen', () {
    testWidgets('hides empty proverbs culture and same-idea sections', (tester) async {
      await tester.pumpWidget(
        _host(LexiconEntryScreen(lexeme: _baseLexeme({}))),
      );
      expect(find.text(kLexiconEntryProverbsTitle), findsNothing);
      expect(find.text(kLexiconEntryCultureTitle), findsNothing);
      expect(find.text(kLexiconEntrySameIdeaTitle), findsNothing);
      expect(find.text('ọkọ̀'), findsWidgets);
    });

    testWidgets('shows proverbs culture and same-idea when present', (tester) async {
      await tester.pumpWidget(
        _host(
          LexiconEntryScreen(
            lexeme: _baseLexeme({
              'proverbs': [
                {'text': 'Ìwà lẹwà', 'gloss_en': 'Character is beauty'},
              ],
              'culture_notes': 'Vehicles are common in Lagos traffic.',
              'same_idea_in_other_languages': [
                {'language': 'ig', 'lemma': 'ụgbọala'},
                {'language': 'sw', 'lemma': 'gari', 'verified': false},
              ],
            }),
          ),
        ),
      );
      expect(find.text(kLexiconEntryProverbsTitle), findsOneWidget);
      expect(find.text('Ìwà lẹwà'), findsOneWidget);
      expect(find.text(kLexiconEntryCultureTitle), findsOneWidget);
      expect(
        find.text('Vehicles are common in Lagos traffic.'),
        findsOneWidget,
      );
      expect(find.text(kLexiconEntrySameIdeaTitle), findsOneWidget);
      expect(find.textContaining('Igbo'), findsOneWidget);
      expect(find.textContaining(kLexiconEntrySameIdeaUnavailable), findsOneWidget);
    });

    testWidgets('ai draft badge uses honest copy', (tester) async {
      await tester.pumpWidget(
        _host(
          LexiconEntryScreen(
            lexeme: _baseLexeme({
              'label': 'beta',
              'provenance': {'ai_assisted': true},
            }),
          ),
        ),
      );
      expect(find.text(lensAiDraftHonestLabel), findsOneWidget);
    });

    testWidgets('loading and error states', (tester) async {
      await tester.pumpWidget(_host(const LexiconEntryScreen(isLoading: true)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(
        _host(const LexiconEntryScreen(errorMessage: 'Network down')),
      );
      expect(find.text('Network down'), findsOneWidget);
    });
  });
}
