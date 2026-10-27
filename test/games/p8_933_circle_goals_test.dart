import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/games/circles/circle_goal_screen.dart';
import 'package:lingafriq/games/circles/circle_goal_service.dart';
import 'package:lingafriq/games/gamekit/game_meta_layer.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/learning/core/bkt_mastery.dart';
import 'package:lingafriq/services/cultural_mastery_service.dart';

void main() {
  group('newlyLearnedSkillIdsFromSession', () {
    test('counts only mastery threshold crossings', () {
      final session = GameSession(
        sessionId: 's1',
        userId: 'u1',
        gameId: 'tone_forge',
        language: 'yo',
        startTime: DateTime.now(),
        metadata: {
          'skill_mastery_snapshots': {
            'a': {
              'before': BktMastery.masteryThreshold - 0.05,
              'after': BktMastery.masteryThreshold,
            },
            'b': {'before': 0.4, 'after': 0.7},
          },
        },
      );
      expect(newlyLearnedSkillIdsFromSession(session), ['a']);
    });
  });

  group('CircleGoalScreen', () {
    testWidgets('circle_goals_playing shows collective progress', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: CircleGoalScreen(
              groupId: 'g1',
              initialSnapshot: const CircleWordGoalSnapshot(
                empty: false,
                goalWords: 20,
                progressWords: 8,
                members: [
                  CircleWordGoalMemberLabel(slot: 'Circle learner 1', isViewer: true),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('8 / 20'), findsOneWidget);
      expect(find.textContaining('no ranking'), findsOneWidget);
    });

    testWidgets('circle_goals_results shows goal reached', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: CircleGoalScreen(
              groupId: 'g1',
              initialSnapshot: const CircleWordGoalSnapshot(
                empty: false,
                goalWords: 5,
                progressWords: 5,
                complete: true,
                members: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Goal reached'), findsOneWidget);
    });

    testWidgets('circle_goals_why_wrong empty state copy', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: CircleGoalScreen(
              groupId: 'g1',
              initialSnapshot: const CircleWordGoalSnapshot(
                empty: true,
                goalWords: 0,
                progressWords: 0,
                members: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Set a circle goal'), findsOneWidget);
      expect(find.textContaining('practice mode'), findsOneWidget);
    });
  });

  group('meta layer circle sync', () {
    test('skips practice sessions', () async {
      final layer = GameMetaLayer(masteryService: CulturalMasteryService());
      final session = GameSession(
        sessionId: 'p',
        userId: 'u',
        gameId: 'g',
        language: 'yo',
        startTime: DateTime.now(),
        metadata: {
          'practice_not_scored': true,
          'skill_mastery_snapshots': {
            'x': {'before': 0.5, 'after': 0.99},
          },
        },
      );
      final recorded = await layer.syncCircleWordGoalAfterSession(
        session: session,
        circleGroupId: 'circle-1',
        circleGoals: CircleGoalService(),
      );
      expect(recorded, 0);
    });
  });
}
