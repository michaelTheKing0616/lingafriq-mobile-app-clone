import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/today/home_safari_card.dart';
import 'package:lingafriq/services/lens/home_safari_service.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

AfricanObjectSet _kitchenSet() {
  final ids = List.generate(
    6,
    (i) => AfricanObjectSetEntry(
      objectSetId: 'afr.kitchen.$i',
      mlKitLabels: ['Cup'],
      livingDictionaryLexemeId: 'yo.lex.k$i',
    ),
  );
  return AfricanObjectSet(version: 1, entries: ids);
}

void main() {
  group('homeSafariPickKitchenTargets', () {
    test('picks five distinct kitchen ids for the week', () {
      final targets = homeSafariPickKitchenTargets(
        _kitchenSet(),
        weekKey: '2026-W43',
      );
      expect(targets.length, homeSafariQuestTargetCount);
      expect(targets.toSet().length, homeSafariQuestTargetCount);
    });
  });

  group('HomeSafariService', () {
    const userId = 'user_safari_910';
    final weekStart = DateTime.utc(2026, 10, 20, 12);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    HomeSafariService service({DateTime? now}) {
      return HomeSafariService(
        objectSetLoader: () async => _kitchenSet(),
        clock: () => now ?? weekStart,
      );
    }

    test('generates active quest for new week', () async {
      final snap = await service().loadSnapshot(userId);
      expect(snap.phase, HomeSafariQuestPhase.active);
      expect(snap.targetCount, homeSafariQuestTargetCount);
      expect(snap.confirmedCount, 0);
    });

    test('tracks progress on confirm', () async {
      final svc = service();
      final first = await svc.loadSnapshot(userId);
      final target = first.targetObjectSetIds.first;

      final r1 = await svc.confirmRecognisedItem(
        userId: userId,
        objectSetId: target,
      );
      expect(r1.alreadyCounted, isFalse);
      expect(r1.snapshot.confirmedCount, 1);
      expect(r1.snapshot.progressLabel(), '1 of 5');

      final r2 = await svc.confirmRecognisedItem(
        userId: userId,
        objectSetId: target,
      );
      expect(r2.alreadyCounted, isTrue);
      expect(r2.snapshot.confirmedCount, 1);
    });

    test('grants reward once on fifth confirm', () async {
      final svc = service();
      final snap = await svc.loadSnapshot(userId);
      HomeSafariRewardGrant? onlyReward;

      for (final id in snap.targetObjectSetIds) {
        final r = await svc.confirmRecognisedItem(
          userId: userId,
          objectSetId: id,
        );
        if (r.reward != null) {
          onlyReward = r.reward;
        }
      }

      expect(onlyReward, isNotNull);
      expect(onlyReward!.cowries, homeSafariCompletionCowries);

      final again = await svc.confirmRecognisedItem(
        userId: userId,
        objectSetId: snap.targetObjectSetIds.first,
      );
      expect(again.reward, isNull);
      expect(again.snapshot.phase, HomeSafariQuestPhase.complete);
      expect(again.snapshot.rewardGranted, isTrue);
    });

    test('expires unfinished quest on week rollover and starts fresh', () async {
      final svc = service();
      final active = await svc.loadSnapshot(userId);
      await svc.confirmRecognisedItem(
        userId: userId,
        objectSetId: active.targetObjectSetIds.first,
      );

      final nextWeek = weekStart.add(const Duration(days: 8));
      final afterRoll = await HomeSafariService(
        objectSetLoader: () async => _kitchenSet(),
        clock: () => nextWeek,
      ).loadSnapshot(userId);

      expect(afterRoll.weekKey, isNot(active.weekKey));
      expect(afterRoll.phase, HomeSafariQuestPhase.active);
      expect(afterRoll.confirmedCount, 0);
    });
  });

  group('HomeSafariCard', () {
    testWidgets('shows on Today tab when quest active', (tester) async {
      const snap = HomeSafariQuestSnapshot(
        phase: HomeSafariQuestPhase.active,
        weekKey: '2026-W43',
        targetObjectSetIds: ['a', 'b', 'c', 'd', 'e'],
        confirmedObjectSetIds: ['a'],
        rewardGranted: false,
      );
      expect(HomeSafariCard.shouldShowOnTodayTab(snap), isTrue);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: HomeSafariCard(snapshot: snap),
            ),
          ),
        ),
      );
      expect(find.textContaining('1 of 5'), findsOneWidget);
      expect(find.textContaining('safari.progress'), findsOneWidget);
    });

    testWidgets('hides when empty', (tester) async {
      const snap = HomeSafariQuestSnapshot(
        phase: HomeSafariQuestPhase.empty,
        weekKey: '2026-W43',
        targetObjectSetIds: [],
        confirmedObjectSetIds: [],
        rewardGranted: false,
      );
      expect(HomeSafariCard.shouldShowOnTodayTab(snap), isFalse);
    });
  });
}
