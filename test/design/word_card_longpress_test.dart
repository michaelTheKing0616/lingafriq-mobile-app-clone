import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/tone_lens/tone_contour.dart';
import 'package:lingafriq/design/tone_lens/tone_lens.dart';
import 'package:lingafriq/design/word_card/word_card.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/word_card_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordCardService', () {
    test('uses the lexicon gloss and the first human clip', () {
      final Map<String, dynamic> raw =
          jsonDecode(
                File(
                  'test/content/fixtures/lexeme_yo_oko.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final String gloss =
          ((raw['senses'] as List<dynamic>).first
                  as Map<String, dynamic>)['gloss_en']
              as String;
      String? humanUri;
      for (final Object? clip in raw['audio'] as List<dynamic>) {
        final Map<String, dynamic> map = (clip as Map).cast<String, dynamic>();
        if (map['kind'] == 'human' && (map['uri'] as String).isNotEmpty) {
          humanUri = map['uri'] as String;
          break;
        }
      }
      final WordCardRecord record = wordCardFromLexeme(
        const WordCardQuery(
          word: 'ọkọ̀',
          host: WordCardHost.dictionary,
          languageCode: 'yo',
        ),
        VerifiedLexeme.fromApiJson(<String, dynamic>{
          'lexeme_id': raw['id'],
          'language': 'yo',
          'verification_status': 'expert_reviewed',
          'entry': raw,
        }),
      );

      expect(record.meaning, gloss);
      expect(record.audio.playable, isTrue);
      expect(record.audio.synthetic, isFalse);
      expect(record.audio.uri, humanUri);
      expect(record.tone.unverified, isFalse);
      expect(record.tone.validatedAudio, isFalse);
      expect(record.tone.contours, <ToneContourKind>[
        ToneContourKind.mid,
        ToneContourKind.low,
      ]);
    });

    test('a requested dialect with no clip is not playable', () {
      final WordCardRecord record = wordCardFromLexeme(
        const WordCardQuery(
          word: 'ọkọ̀',
          host: WordCardHost.lesson,
          languageCode: 'yo',
          dialect: 'ijebu',
        ),
        _lexeme(),
      );

      expect(record.audio.playable, isFalse);
      expect(record.audio.uri, isNull);
      expect(record.audio.synthetic, isFalse);
      expect(record.meaning, 'vehicle');
    });

    test('synthetic audio is dropped and is not played', () async {
      var plays = 0;
      final WordCardService service = WordCardService(
        playUri: (String uri) async {
          plays += 1;
        },
      );
      final WordCardRecord record = wordCardFromLexeme(
        const WordCardQuery(
          word: 'ọkọ̀',
          host: WordCardHost.chat,
          languageCode: 'yo',
        ),
        _lexeme(
          audio: const <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'tts_synthetic',
              'uri': 'tts/yo/synthetic.ogg',
            },
          ],
        ),
      );

      expect(record.audio.synthetic, isTrue);
      expect(record.audio.playable, isFalse);
      expect(record.audio.uri, isNull);
      expect(await service.play(record.audio), isFalse);
      expect(plays, 0);
      expect(await service.play(const WordCardAudio.missing()), isFalse);
      expect(plays, 0);
    });

    test('a human clip plays only through the given player', () async {
      final List<String> played = <String>[];
      final WordCardService service = WordCardService(
        playUri: (String uri) async {
          played.add(uri);
        },
      );
      const WordCardAudio audio = WordCardAudio.missing();
      expect(await service.play(audio), isFalse);
      final bool playedClip = await service.play(
        WordCardAudio.playable(uri: 'audio/yo/human.ogg', dialect: 'lagos'),
      );
      expect(playedClip, isTrue);
      expect(played, <String>['audio/yo/human.ogg']);
    });

    test('no gloss is not replaced with a meaning', () {
      final WordCardRecord record = wordCardFromLexeme(
        const WordCardQuery(
          word: 'ọkọ̀',
          host: WordCardHost.game,
          languageCode: 'yo',
        ),
        _lexeme(senses: const <Map<String, dynamic>>[]),
      );

      expect(record.hasMeaning, isFalse);
      expect(record.meaning, isNull);
    });

    test('an unknown tone token stays unverified', () {
      final WordCardTone tone = wordCardToneFromEntry(<String, dynamic>{
        'tone_pattern': <String>['M', 'not-a-tone'],
      });

      expect(tone.unverified, isTrue);
      expect(tone.contours, isEmpty);
    });

    test('save writes My Words and Review only when both succeed', () async {
      final List<String> myWords = <String>[];
      final List<String> review = <String>[];
      final WordCardService service = WordCardService(
        saveMyWords: (WordCardRecord record) async {
          myWords.add(record.word);
        },
        saveReview: (WordCardRecord record) async {
          review.add(record.word);
        },
      );
      final WordCardRecord record = _ready();

      final WordCardSaveResult result = await service.save(record);

      expect(result.saved, isTrue);
      expect(result.inMyWords, isTrue);
      expect(result.inReview, isTrue);
      expect(myWords, <String>[record.word]);
      expect(review, <String>[record.word]);
      expect(service.myWords.map((WordCardRecord item) => item.word), <String>[
        record.word,
      ]);
      expect(service.review.map((WordCardRecord item) => item.word), <String>[
        record.word,
      ]);
    });

    test('a failed save does not claim the word was stored', () async {
      final List<String> myWords = <String>[];
      final List<String> review = <String>[];
      var removed = 0;
      final WordCardService service = WordCardService(
        saveMyWords: (WordCardRecord record) async {
          throw StateError('my words down');
        },
        saveReview: (WordCardRecord record) async {
          review.add(record.word);
        },
        removeReview: (WordCardRecord record) async {
          removed += 1;
          review.remove(record.word);
        },
      );

      final WordCardSaveResult failed = await service.save(_ready());
      final WordCardSaveResult noMeaning = await service.save(
        _ready(meaning: null),
      );

      expect(failed.saved, isFalse);
      expect(failed.inMyWords, isFalse);
      expect(failed.inReview, isFalse);
      expect(noMeaning.saved, isFalse);
      expect(myWords, isEmpty);
      expect(review, isEmpty);
      expect(removed, 1);
      expect(service.myWords, isEmpty);
      expect(service.review, isEmpty);
    });
  });

  group('Word card long-press', () {
    testWidgets('each host opens meaning, dialect audio, and Tone Lens', (
      WidgetTester tester,
    ) async {
      final List<WordCardHost> seen = <WordCardHost>[];
      final WordCardService service = WordCardService(
        lookup: (WordCardQuery query) async {
          seen.add(query.host);
          return _ready(host: query.host);
        },
      );

      const ValueKey<String> hostKey = ValueKey<String>('host-word');
      for (final WordCardHost host in WordCardHost.values) {
        await tester.pumpWidget(
          _app(
            TargetText(
              key: hostKey,
              text: 'ọkọ̀',
              host: host,
              wordCardService: service,
            ),
          ),
        );
        await tester.longPress(find.byKey(hostKey));
        await tester.pumpAndSettle();

        expect(find.byKey(WordCard.sheetKey), findsOneWidget);
        expect(find.byKey(WordCard.meaningKey), findsOneWidget);
        expect(find.text('vehicle'), findsOneWidget);
        expect(find.byKey(WordCard.audioKey), findsOneWidget);
        expect(find.text('Listen'), findsOneWidget);
        expect(find.byType(ToneLens), findsOneWidget);
        expect(find.byKey(WordCard.toneKey), findsOneWidget);

        await tester.tap(find.byKey(WordCard.closeKey));
        await tester.pumpAndSettle();
        expect(find.byKey(WordCard.sheetKey), findsNothing);
      }

      expect(seen, WordCardHost.values);
    });

    testWidgets('long-press inside the card does not open a second card', (
      WidgetTester tester,
    ) async {
      final WordCardService service = WordCardService(
        lookup: (WordCardQuery query) async => _ready(),
      );
      await tester.pumpWidget(
        _app(TargetText(text: 'ọkọ̀', wordCardService: service)),
      );
      await tester.longPress(find.byType(TargetText));
      await tester.pumpAndSettle();

      await tester.longPress(
        find.descendant(
          of: find.byKey(WordCard.sheetKey),
          matching: find.byType(TargetText),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(WordCard.sheetKey), findsOneWidget);
    });

    testWidgets(
      'save shows Words and Review only after both stores accept it',
      (WidgetTester tester) async {
        final List<String> myWords = <String>[];
        final List<String> review = <String>[];
        final WordCardService service = WordCardService(
          lookup: (WordCardQuery query) async => _ready(),
          saveMyWords: (WordCardRecord record) async {
            myWords.add(record.word);
          },
          saveReview: (WordCardRecord record) async {
            review.add(record.word);
          },
        );
        await _open(tester, service);

        expect(find.byKey(WordCard.savedKey), findsNothing);
        await tester.tap(find.byKey(WordCard.saveKey));
        await tester.pumpAndSettle();

        expect(find.byKey(WordCard.savedKey), findsOneWidget);
        expect(find.text('Words and Review'), findsOneWidget);
        expect(find.byKey(WordCard.retryKey), findsNothing);
        expect(myWords, <String>['ọkọ̀']);
        expect(review, <String>['ọkọ̀']);
      },
    );

    testWidgets(
      'a failed save shows retry and does not claim the word was saved',
      (WidgetTester tester) async {
        var fail = true;
        final List<String> myWords = <String>[];
        final List<String> review = <String>[];
        final WordCardService service = WordCardService(
          lookup: (WordCardQuery query) async => _ready(),
          saveMyWords: (WordCardRecord record) async {
            if (fail) throw StateError('my words down');
            myWords.add(record.word);
          },
          saveReview: (WordCardRecord record) async {
            review.add(record.word);
          },
          removeReview: (WordCardRecord record) async {
            review.remove(record.word);
          },
        );
        await _open(tester, service);
        await tester.tap(find.byKey(WordCard.saveKey));
        await tester.pumpAndSettle();

        expect(find.byKey(WordCard.retryKey), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.byKey(WordCard.savedKey), findsNothing);
        expect(find.text('Words and Review'), findsNothing);
        expect(myWords, isEmpty);
        expect(review, isEmpty);
        expect(service.myWords, isEmpty);
        expect(service.review, isEmpty);

        fail = false;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(find.byKey(WordCard.retryKey), findsNothing);
        expect(find.byKey(WordCard.savedKey), findsOneWidget);
        expect(myWords, <String>['ọkọ̀']);
        expect(review, <String>['ọkọ̀']);
      },
    );

    testWidgets('missing dialect audio shows unavailable and does not play', (
      WidgetTester tester,
    ) async {
      var plays = 0;
      final WordCardService service = WordCardService(
        lookup: (WordCardQuery query) async =>
            _ready(audio: const WordCardAudio.missing(dialect: 'ijebu')),
        playUri: (String uri) async {
          plays += 1;
        },
      );
      await _open(tester, service);

      expect(find.byKey(WordCard.unavailableKey), findsOneWidget);
      expect(find.text('Unavailable'), findsWidgets);
      expect(find.text('Listen'), findsNothing);
      expect(plays, 0);
      expect(
        await service.play(const WordCardAudio.missing(dialect: 'ijebu')),
        isFalse,
      );
      expect(plays, 0);
    });

    testWidgets('synthetic audio shows unavailable and does not play', (
      WidgetTester tester,
    ) async {
      var plays = 0;
      final WordCardService service = WordCardService(
        lookup: (WordCardQuery query) async =>
            _ready(audio: const WordCardAudio.synthetic()),
        playUri: (String uri) async {
          plays += 1;
        },
      );
      await _open(tester, service);

      expect(find.byKey(WordCard.unavailableKey), findsOneWidget);
      expect(find.text('Listen'), findsNothing);
      expect(plays, 0);
    });

    testWidgets('no meaning shows the not-available state', (
      WidgetTester tester,
    ) async {
      final WordCardService service = WordCardService(
        lookup: (WordCardQuery query) async => _ready(meaning: null),
      );
      await _open(tester, service);

      expect(find.byKey(WordCard.notAvailableKey), findsOneWidget);
      expect(find.text('Not available yet'), findsOneWidget);
      expect(find.text('There is nothing to show.'), findsOneWidget);
      expect(find.byKey(WordCard.meaningKey), findsNothing);
      expect(find.text('vehicle'), findsNothing);
      expect(find.byKey(WordCard.saveKey), findsNothing);
      expect(find.byKey(WordCard.savedKey), findsNothing);
    });

    testWidgets('a plain Text long-press does not open the card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(const Text('ọkọ̀')));
      await tester.longPress(find.byType(Text));
      await tester.pumpAndSettle();

      expect(find.byKey(WordCard.sheetKey), findsNothing);
      expect(find.byType(ToneLens), findsNothing);
    });

    testWidgets('closed word card stays inside 200% text and reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final WordCardService service = WordCardService(
        lookup: (WordCardQuery query) async => _ready(),
      );
      await tester.pumpWidget(
        _app(
          TargetText(text: 'ọkọ̀', wordCardService: service),
          textScale: 2,
          reduced: true,
        ),
      );
      await tester.longPress(find.byType(TargetText));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('vehicle'), findsOneWidget);
      expect(find.byType(ToneLens), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  test('lint blocks plain Text for target words', () {
    final ProcessResult tree = Process.runSync('python3', <String>[
      'scripts/lint/target_text_only.py',
    ]);
    expect(tree.exitCode, 0, reason: '${tree.stdout}\n${tree.stderr}');

    final ProcessResult sample = Process.runSync('python3', <String>[
      '-c',
      r'''
import sys
sys.path.insert(0, "scripts/lint")
import target_text_only as lint
plain = "Widget build(BuildContext context) {\n  return Text('ọkọ̀');\n}\n"
named = "final word = 'ọkọ̀';\nWidget build(BuildContext context) {\n  return Text(word);\n}\n"
allowed = "Widget build(BuildContext context) {\n  return TargetText(text: 'ọkọ̀');\n}\n"
plain_lines = lint.offending_lines(plain, lint.assigned_names(plain))
named_lines = lint.offending_lines(named, lint.assigned_names(named))
allowed_lines = lint.offending_lines(allowed, lint.assigned_names(allowed))
sys.exit(0 if plain_lines and named_lines and not allowed_lines else 1)
''',
    ]);
    expect(sample.exitCode, 0, reason: '${sample.stdout}\n${sample.stderr}');
  });
}

VerifiedLexeme _lexeme({
  List<Map<String, dynamic>>? senses,
  List<Map<String, dynamic>>? audio,
}) {
  return VerifiedLexeme(
    lexemeId: 'yo.lex.ọkọ.vehicle',
    language: 'yo',
    verificationStatus: 'expert_reviewed',
    lemma: 'ọkọ̀',
    standardOrthography: 'ọkọ̀',
    exampleSentence: null,
    audioUris: const <String>[],
    raw: <String, dynamic>{
      'senses':
          senses ??
          const <Map<String, dynamic>>[
            <String, dynamic>{'gloss_en': 'vehicle'},
          ],
      'tone_pattern': const <String>['M', 'L'],
      'audio':
          audio ??
          const <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'human',
              'uri': 'audio/yo/9f2c1a4b5e6d7c8a.ogg',
            },
          ],
    },
  );
}

WordCardRecord _ready({
  WordCardHost host = WordCardHost.lesson,
  String? meaning = 'vehicle',
  WordCardAudio? audio,
}) {
  return WordCardRecord(
    word: 'ọkọ̀',
    host: host,
    meaning: meaning,
    audio:
        audio ?? WordCardAudio.playable(uri: 'audio/yo/9f2c1a4b5e6d7c8a.ogg'),
    tone: const WordCardTone.checked(
      contours: <ToneContourKind>[ToneContourKind.mid, ToneContourKind.low],
      validatedAudio: false,
    ),
    languageCode: 'yo',
    lexemeId: 'yo.lex.ọkọ.vehicle',
  );
}

Widget _app(Widget child, {double textScale = 1, bool reduced = false}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduced,
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(body: Center(child: child)),
  );
}

Future<void> _open(WidgetTester tester, WordCardService service) async {
  await tester.pumpWidget(
    _app(TargetText(text: 'ọkọ̀', wordCardService: service)),
  );
  await tester.longPress(find.byType(TargetText));
  await tester.pumpAndSettle();
  expect(find.byKey(WordCard.sheetKey), findsOneWidget);
}
