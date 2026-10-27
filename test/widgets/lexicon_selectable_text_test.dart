import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/screens/chat/message_bubble.dart';
import 'package:lingafriq/screens/feed/feed_text.dart';
import 'package:lingafriq/screens/games/game_prompt_text.dart';
import 'package:lingafriq/screens/lesson/lesson_text.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';
import 'package:lingafriq/widgets/lexicon_selectable_text.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';

VerifiedLexeme _yoOkoVerified() {
  final fixturePath =
      File('test/content/fixtures/lexeme_yo_oko.json').absolute.path;
  final fixture =
      jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
  return VerifiedLexeme.fromApiJson({
    'lexeme_id': fixture['id'],
    'language': 'yo',
    'verification_status': 'expert_reviewed',
    'entry': fixture,
  });
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('lemma resolution', () {
    test('ascii fallback resolves to lemma', () {
      final lexeme = _yoOkoVerified();
      expect(lexemeEntryMatchesSurface(lexeme, 'oko'), isTrue);
      expect(resolveLemmaForSurface(lexeme, 'oko'), 'ọkọ̀');
    });

    test('inflected form list resolves to lemma', () {
      final lexeme = VerifiedLexeme.fromApiJson({
        'lexeme_id': 'yo.lex.sample',
        'language': 'yo',
        'verification_status': 'expert_reviewed',
        'entry': {
          'id': 'yo.lex.sample',
          'lemma': 'báwo',
          'orthography': {'standard': 'báwo'},
          'inflected_forms': ['báwo ni'],
        },
      });
      expect(lexemeEntryMatchesSurface(lexeme, 'báwo ni'), isTrue);
      expect(resolveLemmaForSurface(lexeme, 'báwo ni'), 'báwo');
    });
  });

  group('LexiconLookupService offline', () {
    late LexiconPackService pack;

    setUp(() async {
      pack = LexiconPackService();
      pack.resetForTests();
      final entries = [
        LexiconPackEntry(
          lexemeId: 'yo.lex.aa',
          lemma: 'ọkọ̀',
          standard: 'ọkọ̀',
          adjustedRank: 1,
          audioUris: const [],
        ),
      ];
      final manifest = LexiconPackManifest(
        language: 'yo',
        version: '1.0.0',
        entryCount: 1,
        entriesSha256: lexiconPackEntriesDigest(entries),
        audioBytesEstimate: 0,
      );
      await pack.installVerifiedPack(manifest: manifest, entries: entries);
    });

    test('hits installed pack lemma', () async {
      final service = LexiconLookupService(
        languageCode: 'yo',
        packService: pack,
        fetchLexemeById: (_) async => _yoOkoVerified(),
        assumeOffline: true,
      );
      final result = await service.lookupSurface('ọkọ̀');
      expect(result.kind, LexiconLookupKind.hit);
      expect(result.usedOfflinePack, isTrue);
      expect(result.lexeme?.lemma, 'ọkọ̀');
    });

    test('offline missing when absent from pack', () async {
      final service = LexiconLookupService(
        languageCode: 'yo',
        packService: pack,
        assumeOffline: true,
      );
      final result = await service.lookupSurface('missingword');
      expect(result.kind, LexiconLookupKind.offlineMissing);
    });
  });

  group('LexiconSelectableText', () {
    testWidgets('long-press opens Word Card sheet', (tester) async {
      final lexeme = _yoOkoVerified();
      await tester.pumpWidget(
        _host(
          LexiconSelectableText(
            text: 'Mo ní ọkọ̀.',
            languageCode: 'yo',
            lookup: (_) async => LexiconLookupResult(
              kind: LexiconLookupKind.hit,
              surface: 'ọkọ̀',
              lexeme: lexeme,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('ọkọ̀'));
      await tester.pumpAndSettle();

      expect(find.byType(WordCardSheet), findsOneWidget);
    });

    testWidgets('not found sheet offers suggest', (tester) async {
      var suggested = false;
      await tester.pumpWidget(
        _host(
          LexiconSelectableText(
            text: 'unknown',
            languageCode: 'yo',
            lookup: (_) async => const LexiconLookupResult(
              kind: LexiconLookupKind.notFound,
              surface: 'unknown',
            ),
            onSuggest: (_) => suggested = true,
          ),
        ),
      );

      await tester.longPress(find.text('unknown'));
      await tester.pumpAndSettle();

      expect(find.text(kWordCardNotFoundCopyKey), findsOneWidget);
      await tester.tap(find.text(kWordCardSuggestCopyKey));
      await tester.pumpAndSettle();
      expect(suggested, isTrue);
    });

    testWidgets('semantics exposes Word Card custom action', (tester) async {
      await tester.pumpWidget(
        _host(
          LexiconSelectableText(
            text: 'báwo',
            languageCode: 'yo',
            lookup: (_) async => const LexiconLookupResult(
              kind: LexiconLookupKind.notFound,
              surface: 'báwo',
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.customSemanticsActions?.keys.any(
                    (action) =>
                        action.label == kLexiconWordCardSemanticsAction,
                  ) ??
                  false),
        ),
        findsWidgets,
      );
    });
  });

  group('surface wrappers use LexiconSelectableText', () {
    Future<LexiconLookupResult> noopLookup(String _) async =>
        const LexiconLookupResult(
          kind: LexiconLookupKind.notFound,
          surface: '',
        );

    testWidgets('chat lesson feed game surfaces', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              ChatMessageBubble(
                messageText: 'Ẹ kú',
                languageCode: 'yo',
                lookup: noopLookup,
              ),
              LessonText(text: 'Ẹ kú', languageCode: 'yo', lookup: noopLookup),
              FeedText(text: 'Ẹ kú', languageCode: 'yo', lookup: noopLookup),
              GamePromptText(
                prompt: 'Ẹ kú',
                languageCode: 'yo',
                lookup: noopLookup,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(LexiconSelectableText), findsNWidgets(4));
    });
  });
}
