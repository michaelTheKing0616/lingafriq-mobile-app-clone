import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_animation_bridge.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/games/proverb_unlocker/proverb_unlocker_catalog.dart';
import 'package:lingafriq/games/proverb_unlocker/proverb_unlocker_game.dart';
import 'package:lingafriq/games/proverb_unlocker/proverb_unlocker_models.dart';
import 'package:lingafriq/services/polie_game_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const harvestedOriginals = [
    'Agbara eniyan ju ti eranko lo',
    'Haraka haraka haina baraka',
    'Umuntu ngumuntu ngabantu',
    'Onye aghana nwanne ya',
    'Umntu ngumntu ngabantu',
    'Sew besew yinoralal',
  ];

  group('P3-069 harvested proverb catalog', () {
    test('keeps the six live fallback proverbs', () {
      expect(
        kHarvestedProverbUnlockerCatalog.map((proverb) => proverb.original),
        harvestedOriginals,
      );
      expect(
        kHarvestedProverbUnlockerCatalog.map((proverb) => proverb.translation),
        [
          'Human strength surpasses that of animals',
          'Hurry hurry has no blessing',
          'A person is a person through people',
          "Be your brother's keeper",
          'I am because we are',
          'People live through people',
        ],
      );
      expect(
        kHarvestedProverbUnlockerCatalog.map((proverb) => proverb.meaning),
        [
          'Unity and intelligence overcome brute force',
          'Patience leads to better outcomes',
          'Humanity is defined by community',
          'Look after each other always',
          'Individual identity is rooted in collective belonging',
          'Community support sustains life',
        ],
      );
    });

    test('meaning choices and tokens stay inside the harvested text', () {
      final originals = kHarvestedProverbUnlockerCatalog
          .expand((proverb) => proverb.original.split(' '))
          .toSet();
      final meanings = kHarvestedProverbUnlockerCatalog
          .map(harvestedProverbMeaning)
          .toSet();
      for (var seed = 1; seed <= 12; seed++) {
        final deal = dealProverbUnlocker(seed: seed);
        expect(meanings, contains(deal.correctAnswer));
        expect(deal.options, contains(deal.correctAnswer));
        for (final option in deal.options) {
          expect(meanings, contains(option));
        }
        for (final token in deal.tokenOptions) {
          expect(originals, contains(token));
        }
        for (final index in deal.blankIndices) {
          expect(deal.tokenOptions, contains(deal.words[index]));
        }
      }
    });
  });

  group('P3-069 seeded outcomes', () {
    test('the same seed returns the same proverb and outcome', () {
      for (var seed = 1; seed <= 12; seed++) {
        final first = dealProverbUnlocker(seed: seed);
        final second = dealProverbUnlocker(seed: seed);
        expect(second.proverb.original, first.proverb.original);
        expect(second.options, first.options);
        expect(second.blankIndices, first.blankIndices);
        expect(second.tokenOptions, first.tokenOptions);

        final correct = resolveProverbUnlockerOutcome(
          proverb: first.proverb.original,
          correctAnswer: first.correctAnswer,
          blankIndices: first.blankIndices,
          words: first.words,
          selectedAnswer: first.correctAnswer,
        );
        final correctAgain = resolveProverbUnlockerOutcome(
          proverb: second.proverb.original,
          correctAnswer: second.correctAnswer,
          blankIndices: second.blankIndices,
          words: second.words,
          selectedAnswer: second.correctAnswer,
        );
        expect(correct.correct, isTrue);
        expect(correctAgain.correct, isTrue);
        expect(correctAgain.proverb, correct.proverb);

        final wrongAnswer =
            first.options.firstWhere((option) => option != first.correctAnswer);
        final wrong = resolveProverbUnlockerOutcome(
          proverb: first.proverb.original,
          correctAnswer: first.correctAnswer,
          blankIndices: first.blankIndices,
          words: first.words,
          selectedAnswer: wrongAnswer,
        );
        final wrongAgain = resolveProverbUnlockerOutcome(
          proverb: second.proverb.original,
          correctAnswer: second.correctAnswer,
          blankIndices: second.blankIndices,
          words: second.words,
          selectedAnswer: wrongAnswer,
        );
        expect(wrong.correct, isFalse);
        expect(wrongAgain.correct, isFalse);

        final fills = {
          for (final index in first.blankIndices) index: first.words[index],
        };
        expect(proverbFillsAreCorrect(first, fills), isTrue);
        expect(proverbFillsAreCorrect(second, fills), isTrue);
        final missed = Map<int, String>.from(fills);
        missed[first.blankIndices.first] = 'not-a-harvested-token';
        expect(proverbFillsAreCorrect(first, missed), isFalse);
        expect(proverbFillsAreCorrect(second, missed), isFalse);
      }
    });

    test('a different seed can return a different proverb', () {
      final seen = <String>{
        for (var seed = 1; seed <= 12; seed++)
          dealProverbUnlocker(seed: seed).proverb.original,
      };
      expect(seen.length, greaterThan(1));
    });

    test('each harvested language keeps its own proverb', () {
      for (final proverb in kHarvestedProverbUnlockerCatalog) {
        final upper = dealProverbUnlocker(
          seed: 3,
          language: proverb.language,
        );
        final lower = dealProverbUnlocker(
          seed: 8,
          language: proverb.language.toLowerCase(),
        );
        expect(upper.proverb.original, proverb.original);
        expect(lower.proverb.original, proverb.original);
      }
    });
  });

  group('P3-069 GameKit play path', () {
    late ProverbUnlockerGame game;

    setUp(() {
      game = ProverbUnlockerGameFactory.create(
        polieClient: PolieGameClient(baseUrl: 'https://127.0.0.1'),
        animationBridge: GameAnimationBridge(),
      );
    });

    GameSession session({required int seed, String language = 'Yoruba'}) {
      return GameSession(
        sessionId: 'proverb-session',
        userId: 'learner',
        gameId: 'proverb_unlocker',
        language: language,
        level: 'A1',
        startTime: DateTime.utc(2026, 1, 1),
        metadata: {'seed': seed},
      );
    }

    test('loadContent and playTurn follow the seed', () async {
      final firstSession = session(seed: 4);
      final secondSession = session(seed: 4);
      final first = await game.loadContent(firstSession);
      final second = await game.loadContent(secondSession);
      expect(first.proverb, second.proverb);
      expect(first.proverb, 'Agbara eniyan ju ti eranko lo');
      expect(first.options, second.options);
      expect(first.contentId, second.contentId);

      final right = await game.playTurn(
        first,
        ProverbUnlockerInput(selectedAnswer: first.correctAnswer),
        firstSession,
      );
      final rightAgain = await game.playTurn(
        second,
        ProverbUnlockerInput(selectedAnswer: second.correctAnswer),
        secondSession,
      );
      expect(right.score.isCorrect, isTrue);
      expect(right.score.accuracy, 1.0);
      expect(rightAgain.score.accuracy, right.score.accuracy);
      expect(
        right.feedback.message,
        'Excellent! You understand the wisdom of this proverb.',
      );
      expect(rightAgain.feedback.message, right.feedback.message);

      final wrongAnswer =
          first.options.firstWhere((option) => option != first.correctAnswer);
      final wrong = await game.playTurn(
        first,
        ProverbUnlockerInput(selectedAnswer: wrongAnswer),
        firstSession,
      );
      expect(wrong.score.isCorrect, isFalse);
      expect(wrong.score.accuracy, 0.0);
      expect(
        wrong.feedback.message,
        'Not quite right. This proverb means: ${first.correctAnswer}',
      );

      final fills = {
        for (final index in first.blankIndices) index: first.words[index],
      };
      final unlocked = await game.playTurn(
        first,
        ProverbUnlockerInput(selectedAnswer: wrongAnswer, fills: fills),
        firstSession,
      );
      expect(unlocked.score.isCorrect, isTrue);
    });

    test('two seeds on the full catalog can differ inside the engine rule', () {
      final seen = <String>{
        for (var seed = 1; seed <= 12; seed++)
          dealProverbUnlocker(seed: seed, language: 'not-a-catalog-language')
              .proverb
              .original,
      };
      expect(seen.length, greaterThan(1));
    });
  });

  group('P3-069 route', () {
    test('the arcade route builds the GameKit screen and the old file is gone', () {
      final router = File('lib/screens/games/game_router.dart').readAsStringSync();
      expect(router.contains('ProverbUnlockerScreen'), isTrue);
      expect(router.contains('ProverbUnlockerLegacyTablet'), isFalse);
      expect(router.contains('ProverbUnlockerGame('), isFalse);
      expect(
        File('lib/screens/games/cultural/proverb_unlocker_game.dart').existsSync(),
        isFalse,
      );
      final barrel = File('lib/screens/games/cultural_games.dart').readAsStringSync();
      expect(barrel.contains('proverb_unlocker_game.dart'), isFalse);
    });

    test('the played proverb files do not construct an unseeded Random', () {
      final dir = Directory('lib/games/proverb_unlocker');
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      expect(files, isNotEmpty);
      for (final file in files) {
        final text = file.readAsStringSync();
        expect(RegExp(r'\bRandom\(\s*\)').hasMatch(text), isFalse, reason: file.path);
        expect(text.contains('Wisdom comes from experience'), isFalse, reason: file.path);
        expect(text.contains('DateTime.now'), isFalse, reason: file.path);
      }
    });
  });
}
