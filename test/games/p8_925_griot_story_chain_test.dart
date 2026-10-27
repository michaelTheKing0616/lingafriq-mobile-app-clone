import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/games/griot_story_chain/story_chain_game.dart';
import 'package:lingafriq/games/griot_story_chain/story_chain_screen.dart';
import 'package:lingafriq/games/griot_story_chain/story_playback.dart';

Future<void> pumpGriotPreview(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 640));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('turn order rotates members', () {
    final circle = createLocalCircle(
      hostId: 'a',
      languageCode: 'yo',
      extraMembers: const ['b', 'c'],
      random: Random(1),
    );
    expect(circle.activePlayerId(), 'a');
    appendSentence(
      circle: circle,
      playerId: 'a',
      sentenceId: 's0',
      text: 'Ọjọ́ kan',
    );
    expect(circle.activePlayerId(), 'b');
  });

  test('playback excludes flagged sentences', () {
    final circle = createLocalCircle(
      hostId: 'host',
      languageCode: 'yo',
      random: Random(2),
    );
    appendSentence(
      circle: circle,
      playerId: 'host',
      sentenceId: 's0',
      text: 'Beat one',
    );
    circle.sentences.add(
      markModerationFlagged(
        StoryChainSentence(
          id: 's1',
          authorId: 'other',
          text: 'blocked',
          turnIndex: 1,
        ),
      ),
    );
    final plan = buildPlaybackPlan(circle);
    expect(plan.beats.length, 1);
    expect(plan.excludedAuthorIds, contains('other'));
  });

  test('grammar accept applies suggestion', () {
    const sentence = StoryChainSentence(
      id: 's',
      authorId: 'u',
      text: 'mo n lo',
      turnIndex: 0,
    );
    const suggestion = StoryGrammarSuggestion(
      suggestedText: 'Mo ń lọ',
      explanation: 'Use correct diacritics.',
      category: 'diacritic',
    );
    final updated = applyGrammarChoice(
      sentence: sentence,
      acceptSuggestion: true,
      suggestion: suggestion,
    );
    expect(updated.playbackText, 'Mo ń lọ');
  });

  test('P8-925 headliner playable when card shipped', () {
    final slot = kArcadeHeadlinerOrder[5];
    expect(slot.elevationCardId, 'P8-925');
    expect(AllGamesRegistry.headlinerIsPlayable(slot), isTrue);
  });

  testWidgets('griot_story_chain_playing golden', (tester) async {
    await pumpGriotPreview(
      tester,
      GriotStoryChainPreview(
          phaseLabel: 'Playing',
          hintEn: 'Add one sentence to continue the tale.',
          body: FilledButton(onPressed: () {}, child: const Text('Add my sentence')),
        ),
    );
    await expectLater(
      find.byType(GriotStoryChainPreview),
      matchesGoldenFile('goldens/griot_story_chain_playing.png'),
    );
  });

  testWidgets('griot_story_chain_grammar golden', (tester) async {
    await pumpGriotPreview(
      tester,
      GriotStoryChainPreview(
          phaseLabel: 'Grammar suggestion',
          hintEn: 'Polie suggests a small grammar tweak.',
          body: const Text('Keep my sentence'),
        ),
    );
    await expectLater(
      find.byType(GriotStoryChainPreview),
      matchesGoldenFile('goldens/griot_story_chain_why_wrong.png'),
    );
  });

  testWidgets('griot_story_chain_results golden', (tester) async {
    await pumpGriotPreview(
      tester,
      GriotStoryChainPreview(
          phaseLabel: 'Results',
          hintEn: 'Your chain is ready',
          body: const Text('Beat 1 of 3'),
        ),
    );
    await expectLater(
      find.byType(GriotStoryChainPreview),
      matchesGoldenFile('goldens/griot_story_chain_results.png'),
    );
  });
}
