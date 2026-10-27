import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/lessons/grammar_aha_card.dart';
import 'package:lingafriq/models/coaching_pattern.dart';
import 'package:lingafriq/services/tutorials/jit_coaching_service.dart';
import 'package:lingafriq/widgets/coaching_tip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_utils.dart';

CoachingPattern _yoProgressive() {
  return CoachingPattern.fromGrammarEntry(
    GrammarPatternEntry(
      id: 'yo.pat.progressive',
      descriptionL1: 'Preverbal ń marks an action in progress',
      form: 'Subject + ń + verb phrase',
      examples: ['Mo ń kọ́ èdè Yorùbá'],
      contrasts: ['Mo ti kọ́ èdè Yorùbá (completed)'],
      commonErrors: ['Dropping ń'],
      cefr: 'A1',
      label: 'expert_reviewed',
    ),
  );
}

JitCoachingTipSession _session(CoachingPattern pattern) {
  return JitCoachingTipSession(
    pattern: pattern,
    visibility: JitCoachingVisibility.tip,
    fromHelp: false,
  );
}

void main() {
  group('JitCoachingService', () {
    test('AC3: fresh install has no launch tour', () {
      final service = JitCoachingService.inMemory();
      expect(service.hasPendingLaunchTour(), isFalse);
    });

    test('AC1: first pattern hit returns a tip session', () {
      final service = JitCoachingService.inMemory();
      final pattern = _yoProgressive();
      final session = service.onPatternEncountered(pattern);
      expect(session, isNotNull);
      expect(session!.pattern.id, pattern.id);
      expect(session.visibility, JitCoachingVisibility.tip);
    });

    test('AC2: second hit hidden; reopen from help shows again', () {
      final service = JitCoachingService.inMemory();
      final pattern = _yoProgressive();
      expect(service.onPatternEncountered(pattern), isNotNull);
      expect(service.onPatternEncountered(pattern), isNull);

      service.dismiss(pattern);
      expect(service.onPatternEncountered(pattern), isNull);

      final help = service.reopenFromHelp(pattern);
      expect(help.visibility, JitCoachingVisibility.tip);
      expect(help.fromHelp, isTrue);
    });

    test('seen state persists via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage1 = JitCoachingStorage.sharedPreferences(prefs);
      final service1 = JitCoachingService(storage1);
      final pattern = _yoProgressive();
      service1.onPatternEncountered(pattern);
      service1.dismiss(pattern);

      final storage2 = JitCoachingStorage.sharedPreferences(prefs);
      final service2 = JitCoachingService(storage2);
      expect(service2.onPatternEncountered(pattern), isNull);
      expect(service2.reopenFromHelp(pattern).fromHelp, isTrue);
    });
  });

  group('CoachingTip widget', () {
    Future<void> pumpTip(
      WidgetTester tester, {
      required JitCoachingTipSession session,
      VoidCallback? onDismiss,
      bool isOffline = false,
      bool isLoading = false,
      String? errorMessage,
    }) async {
      await pumpWidgetWithScreenUtil(
        tester,
        CoachingTip(
          session: session,
          onDismiss: onDismiss ?? () {},
          isOffline: isOffline,
          isLoading: isLoading,
          errorMessage: errorMessage,
        ),
      );
      await tester.pump();
      if (!isLoading) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    testWidgets('default state shows pattern copy and dismiss', (tester) async {
      final pattern = _yoProgressive();
      await pumpTip(tester, session: _session(pattern));
      expect(find.byKey(const ValueKey('coach-default')), findsOneWidget);
      expect(find.text(CoachingCopyKeys.defaultDismiss), findsOneWidget);
      expect(find.textContaining('ń'), findsWidgets);
    });

    testWidgets('loading state', (tester) async {
      await pumpTip(
        tester,
        session: _session(_yoProgressive()),
        isLoading: true,
      );
      expect(find.byKey(const ValueKey('coach-loading')), findsOneWidget);
    });

    testWidgets('error state', (tester) async {
      await pumpTip(
        tester,
        session: _session(_yoProgressive()),
        errorMessage: 'We could not load this tip. Try again from Help.',
      );
      expect(find.byKey(const ValueKey('coach-error')), findsOneWidget);
    });

    testWidgets('offline state adds offline copy', (tester) async {
      await pumpTip(
        tester,
        session: _session(_yoProgressive()),
        isOffline: true,
      );
      expect(find.textContaining('offline'), findsOneWidget);
    });

    testWidgets('AC4: tip is not a modal; lesson control below stays tappable', (tester) async {
      var tapped = false;
      await pumpWidgetWithScreenUtil(
        tester,
        Column(
          children: [
            CoachingTip(
              session: _session(_yoProgressive()),
              onDismiss: () {},
            ),
            ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Lesson continue'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lesson continue'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
