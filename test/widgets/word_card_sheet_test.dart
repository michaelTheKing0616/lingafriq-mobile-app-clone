import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/widgets/dialect_chips.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';

VerifiedLexeme _yoOkoVerified() {
  final fixturePath = File('test/content/fixtures/lexeme_yo_oko.json').absolute.path;
  final fixture =
      jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
  return VerifiedLexeme.fromApiJson({
    'lexeme_id': fixture['id'],
    'language': 'yo',
    'verification_status': 'expert_reviewed',
    'entry': fixture,
  });
}

VerifiedLexeme _aiDraftLexeme() {
  return VerifiedLexeme.fromApiJson({
    'lexeme_id': 'yo.lex.draft.sample',
    'language': 'yo',
    'verification_status': 'beta',
    'entry': {
      'id': 'yo.lex.draft.sample',
      'lemma': 'ọkọ̀',
      'orthography': {'standard': 'ọkọ̀'},
      'tone_pattern': ['M', 'L'],
      'syllables': ['ọ', 'kọ̀'],
      'senses': [
        {'gloss_en': 'vehicle', 'example_target': 'Mo ní ọkọ̀.'},
      ],
      'provenance': {'ai_assisted': true},
      'audio': [],
    },
  });
}

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('wordCardSheetShowsAiDraft', () {
    test('expert reviewed fixture is not ai draft', () {
      expect(
        wordCardSheetShowsAiDraft(lexeme: _yoOkoVerified()),
        isFalse,
      );
    });

    test('beta with ai_assisted is ai draft', () {
      expect(
        wordCardSheetShowsAiDraft(lexeme: _aiDraftLexeme()),
        isTrue,
      );
    });
  });

  group('wordCardSpeakerClipsFromEntry', () {
    test('reads human clips from fixture', () {
      final lexeme = _yoOkoVerified();
      final clips = wordCardSpeakerClipsFromEntry(lexeme.raw);
      expect(clips.length, 2);
      expect(clips.first.voiceId, 'yo_f_lagos_01');
    });
  });

  group('wordCardSurfaceForDialect', () {
    test('switches surface when dialect selected', () {
      const variants = [
        LensDialectVariant(text: 'ọkọ̀ (Ìbàdàn)', dialectTag: 'ibadan'),
      ];
      expect(
        wordCardSurfaceForDialect(
          standardWord: 'ọkọ̀',
          variants: variants,
          selectedTag: 'ibadan',
        ),
        'ọkọ̀ (Ìbàdàn)',
      );
    });
  });

  group('WordCardSheet', () {
    testWidgets('shows lemma, speakers, save and practise', (tester) async {
      final model = WordCardSheetModel.fromLexeme(_yoOkoVerified());
      await tester.pumpWidget(
        _host(
          WordCardSheet(
            model: model,
            onSave: () {},
            onPractise: () {},
          ),
        ),
      );

      expect(find.text('ọkọ̀'), findsOneWidget);
      expect(find.text('vehicle'), findsOneWidget);
      expect(find.text('yo_f_lagos_01'), findsOneWidget);
      expect(find.text(kWordCardSaveLabel), findsOneWidget);
      expect(find.text(kWordCardPractiseLabel), findsOneWidget);
      expect(find.text(kWordCardAiDraftCopy), findsNothing);
    });

    testWidgets('shows ai draft badge copy', (tester) async {
      final model = WordCardSheetModel.fromLexeme(
        _aiDraftLexeme(),
        showsAiDraftBadge: true,
      );
      await tester.pumpWidget(_host(WordCardSheet(model: model)));

      expect(find.text(kWordCardAiDraftCopy), findsOneWidget);
      expect(find.text(lensAiDraftHonestLabel), findsOneWidget);
    });

    testWidgets('large text scale still renders lemma', (tester) async {
      final model = WordCardSheetModel.fromLexeme(_yoOkoVerified());
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: WordCardSheet(model: model)),
          ),
        ),
      );
      expect(find.text('ọkọ̀'), findsOneWidget);
    });
  });
}
