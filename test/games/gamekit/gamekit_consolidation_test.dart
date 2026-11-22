import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/harvested_frame.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('six harvested templates', () {
    test('slot names match the template constructors', () {
      expect(GameKitTemplateKind.values, hasLength(6));
      expect(kGameKitMissingTemplate, 'not present');
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.matchBoard).playSlot,
        'board',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.matchBoard).actionSlot,
        'controls',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.narrative).playSlot,
        'narrativeContent',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.narrative).actionSlot,
        'actions',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.pronunciation).playSlot,
        'content',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.pronunciation).actionSlot,
        'micControls',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.rhythm).playSlot,
        'rhythmArea',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.strategic).playSlot,
        'board',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.strategic).actionSlot,
        'controls',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.timedQuiz).playSlot,
        'questionArea',
      );
      expect(
        gameKitTemplateSlots(GameKitTemplateKind.timedQuiz).actionSlot,
        'actions',
      );
    });

    test('the templates directory names six template classes', () {
      final names =
          Directory('lib/screens/games/templates')
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .where((name) => name.startsWith('template_'))
              .toList()
            ..sort();
      expect(names, [
        'template_match_board.dart',
        'template_narrative.dart',
        'template_pronunciation.dart',
        'template_rhythm.dart',
        'template_strategic.dart',
        'template_timed_quiz.dart',
      ]);
      expect(
        File('lib/screens/games/universal_game_screen.dart').existsSync(),
        isFalse,
      );
      expect(File('lib/games/base_game_screen.dart').existsSync(), isFalse);
      expect(
        File('lib/games/gamekit/universal_game_screen.dart').existsSync(),
        isTrue,
      );
    });

    testWidgets('each template frame shows its play area and action', (
      tester,
    ) async {
      Future<void> pump(GameKitTemplateKind kind) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => MaterialApp(
              home: GameKitTemplateFrame(
                kind: kind,
                title: kind.name,
                play: Text('play-${kind.name}'),
                action: Text('action-${kind.name}'),
                progressLabel: '1/5',
                scoreLabel: '10',
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text(kind.name), findsOneWidget);
        expect(find.text('play-${kind.name}'), findsOneWidget);
        expect(find.text('action-${kind.name}'), findsOneWidget);
        final slots = gameKitTemplateSlots(kind);
        expect(find.byKey(ValueKey<String>(slots.playSlot)), findsOneWidget);
        expect(find.byKey(ValueKey<String>(slots.actionSlot)), findsOneWidget);
      }

      for (final kind in GameKitTemplateKind.values) {
        await pump(kind);
      }
    });
  });

  group('universal loading', () {
    test('a provided fact wins, and one seed returns one fact', () {
      expect(gameKitLoadingFact(factText: '', random: Random(1)), '');
      expect(
        gameKitLoadingFact(factText: 'A saved fact.', random: Random(1)),
        'A saved fact.',
      );
      for (var seed = 0; seed < 8; seed++) {
        final first = gameKitLoadingFact(random: Random(seed));
        final second = gameKitLoadingFact(random: Random(seed));
        expect(second, first);
        expect(kGameKitLoadingFacts, contains(first));
      }
      expect(kGameKitLoadingFacts, hasLength(5));
      for (final fact in kGameKitLoadingFacts) {
        expect(fact.contains('—'), isFalse);
      }
    });

    test('dot index, skip, and back follow the loading screen', () {
      expect(gameKitLoadingDotIndex(0), 0);
      expect(gameKitLoadingDotIndex(0.2), 0);
      expect(gameKitLoadingDotIndex(0.34), 1);
      expect(gameKitLoadingDotIndex(0.67), 2);
      expect(gameKitLoadingDotIndex(1), 2);
      expect(gameKitLoadingDotIndex(-0.2), 0);
      expect(kGameKitLoadingPulse, const Duration(milliseconds: 2400));
      expect(kGameKitLoadingProgress, const Duration(seconds: 8));
      expect(kGameKitLoadingDots, const Duration(milliseconds: 1800));
      expect(gameKitLoadingShowsSkip(false), isFalse);
      expect(gameKitLoadingShowsSkip(true), isTrue);
      expect(gameKitLoadingShowsBack(false), isFalse);
      expect(gameKitLoadingShowsBack(true), isTrue);
    });

    testWidgets('loading view shows the fact and skip only when it can skip', (
      tester,
    ) async {
      var skipped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameKitLoadingView(
              fact: kGameKitLoadingFacts.first,
              dotIndex: 1,
              onSkip: () => skipped++,
              canPop: true,
            ),
          ),
        ),
      );
      expect(find.text('LingAfriq'), findsOneWidget);
      expect(find.text('Did You Know?'), findsOneWidget);
      expect(find.text(kGameKitLoadingFacts.first), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      await tester.tap(find.text('Skip'));
      expect(skipped, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameKitLoadingView(fact: kGameKitLoadingFacts[1]),
          ),
        ),
      );
      expect(find.text('Skip'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });
  });

  group('start guide', () {
    test('only the first three steps are kept', () {
      expect(kGameKitStartGuideStepCap, 3);
      expect(
        gameKitStartGuideSteps(const ['one', 'two', 'three', 'four']),
        const ['one', 'two', 'three'],
      );
      expect(gameKitStartGuideSteps(const ['only']), const ['only']);
      expect(gameKitStartGuideXpLabel(40), '+40 XP');
    });

    testWidgets('start mission is shown and the fourth step is not', (
      tester,
    ) async {
      var started = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameKitStartGuideView(
              input: const GameKitStartGuideInput(
                gameTitle: 'Market Haggle',
                gameDescription: 'Agree a fair price.',
                objectiveXp: 40,
                culturalTip: 'Greet before you haggle.',
                steps: ['Listen', 'Offer', 'Agree', 'Leave'],
                characterName: 'Amina',
                characterTitle: 'Trader',
              ),
              onStart: () => started++,
            ),
          ),
        ),
      );
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('Trader'), findsOneWidget);
      expect(find.text('Market Haggle'), findsOneWidget);
      expect(find.text('+40 XP'), findsOneWidget);
      expect(find.text('Mission Objective'), findsOneWidget);
      expect(find.text('Agree a fair price.'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
      expect(find.text('1. Listen'), findsOneWidget);
      expect(find.text('2. Offer'), findsOneWidget);
      expect(find.text('3. Agree'), findsOneWidget);
      expect(find.textContaining('Leave'), findsNothing);
      expect(find.text('Cultural Tip'), findsOneWidget);
      expect(find.text('Greet before you haggle.'), findsOneWidget);
      expect(find.text('Review Vocabulary'), findsOneWidget);
      await tester.tap(find.text('Start Mission'));
      expect(started, 1);
    });
  });

  group('victory results', () {
    test('xp label and mastery fraction match the victory screen', () {
      expect(gameKitVictoryXpLabel(15), '+15');
      expect(gameKitVictoryMasteryFraction(40), 0.4);
      expect(gameKitVictoryMasteryFraction(0), 0);
    });

    testWidgets('claim and replay use the harvested totals', (tester) async {
      var claimed = 0;
      var replayed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameKitVictoryView(
              input: const GameKitVictoryInput(
                xpEarned: 15,
                vocabularyLearned: 3,
                finalScore: 8,
                masteryPercent: 40,
                griotRank: 'Listener',
                idiomsLearnt: 2,
              ),
              onClaimRewards: () => claimed++,
              onReplayMission: () => replayed++,
            ),
          ),
        ),
      );
      expect(find.text('Mission complete'), findsOneWidget);
      expect(find.text('Mission Complete!'), findsOneWidget);
      expect(find.text('You\'ve earned your rewards'), findsOneWidget);
      expect(find.text('+15'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Vocabulary'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
      expect(find.text('Mastery Insights'), findsOneWidget);
      expect(find.text('Idioms Learnt'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Griot Rank'), findsOneWidget);
      expect(find.text('Listener'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('gamekit-victory-mastery')),
      );
      expect(bar.value, 0.4);
      await tester.tap(find.text('Claim Rewards'));
      await tester.tap(find.text('Replay Mission'));
      expect(claimed, 1);
      expect(replayed, 1);
    });
  });
}
