import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/onboarding_state.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart';
import 'package:lingafriq/services/onboarding_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const previouslyWritten =
      '{"resume_step":4,"steps":{"1":{},"2":{"proficiency_language":"en","learning_language":"yo"},"3":{"primary_goal":"heritage","learning_reasons":["heritage","travel"]},"4":{"daily_duration_minutes":10,"reminders_enabled":true}}}';

  Future<SharedPreferences> prefs([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test(
    'round trip saves each step with jsonEncode and keeps the answer types',
    () async {
      final store = await prefs();
      final service = OnboardingStateService(store);
      final first = await service.saveStep(step: 1, answer: const {});
      expect(first.error, isNull);
      final second = await service.saveStep(
        step: 2,
        answer: const {'proficiency_language': 'en', 'learning_language': 'yo'},
      );
      expect(second.error, isNull);
      final third = await service.saveStep(
        step: 3,
        answer: const {
          'primary_goal': 'heritage',
          'learning_reasons': ['heritage', 'travel'],
          'daily_duration_minutes': 10,
          'reminders_enabled': true,
        },
      );
      expect(third.error, isNull);

      final raw = store.getString(OnboardingStateService.storageKey);
      expect(raw, isNotNull);
      expect(raw, jsonEncode(third.state!.toJson()));
      expect(raw, third.state!.encode());
      expect(raw, contains('"learning_language"'));
      expect(raw, contains('"learning_reasons"'));
      expect(raw, isNot(contains('{learning_language:')));
      expect(raw, isNot(contains('learning_reasons:')));

      final again = OnboardingStateService(store).read();
      expect(again.error, isNull);
      expect(again.state!.resumeStep, 3);
      expect(again.state!.answersByStep[2]!['learning_language'], 'yo');
      expect(again.state!.answersByStep[3]!['learning_reasons'], [
        'heritage',
        'travel',
      ]);
      expect(again.state!.answersByStep[3]!['daily_duration_minutes'], 10);
      expect(again.state!.answersByStep[3]!['reminders_enabled'], true);
      expect(again.state!.mergedAnswers().containsKey('age_category'), isFalse);

      final serviceSource = File(
        'lib/services/onboarding_state_service.dart',
      ).readAsStringSync();
      final modelSource = File(
        'lib/models/onboarding_state.dart',
      ).readAsStringSync();
      expect(serviceSource, contains('jsonEncode'));
      expect(modelSource, contains('jsonEncode'));
      expect(serviceSource, isNot(contains('.toString()')));
      expect(modelSource, isNot(contains('Map.toString')));
    },
  );

  test('resume returns the last saved step after a new read', () async {
    final store = await prefs();
    final service = OnboardingStateService(store);
    await service.saveStep(step: 1, answer: const {});
    await service.saveStep(step: 2, answer: const {'learning_language': 'sw'});
    await service.saveStep(step: 3, answer: const {'primary_goal': 'travel'});

    final read = OnboardingStateService(store).read();
    final placed = placeOnboardingResume(
      read,
      stepCount: unifiedOnboardingStepCount(const []),
    );
    expect(read.state!.resumeStep, 3);
    expect(placed.step, 3);
    expect(placed.pageIndex, 2);
    expect(placed.error, isNull);
    expect(placed.answers['learning_language'], 'sw');
    expect(placed.answers['primary_goal'], 'travel');
    expect(placed.answers.containsKey('app_tone'), isFalse);
  });

  test('update keeps a previously written payload', () async {
    final store = await prefs({
      OnboardingStateService.storageKey: previouslyWritten,
    });
    final read = OnboardingStateService(store).read();
    final placed = placeOnboardingResume(read, stepCount: 12);

    expect(read.error, isNull);
    expect(read.state!.resumeStep, 4);
    expect(read.state!.answersByStep[2]!['learning_language'], 'yo');
    expect(read.state!.answersByStep[3]!['learning_reasons'], [
      'heritage',
      'travel',
    ]);
    expect(read.state!.answersByStep[4]!['daily_duration_minutes'], 10);
    expect(read.state!.answersByStep[4]!['reminders_enabled'], true);
    expect(placed.step, 4);
    expect(placed.pageIndex, 3);
    expect(
      store.getString(OnboardingStateService.storageKey),
      previouslyWritten,
    );
  });

  test(
    'corrupt payload restarts at step 1 and keeps the typed error',
    () async {
      const corrupt = '{resume_step: 4, steps: {4: {learning_language: yo}}}';
      final store = await prefs({OnboardingStateService.storageKey: corrupt});
      final read = OnboardingStateService(store).read();
      final placed = placeOnboardingResume(read, stepCount: 12);

      expect(read.state, isNull);
      expect(read.error, isA<OnboardingStateException>());
      expect(read.error.toString(), contains(OnboardingStateException.code));
      expect(
        OnboardingStateException.explanation.toLowerCase(),
        contains('saved answers could not be read'),
      );
      expect(
        read.error.toString(),
        contains(OnboardingStateException.explanation),
      );
      expect(placed.step, 1);
      expect(placed.pageIndex, 0);
      expect(placed.answers, isEmpty);
      expect(placed.error, same(read.error));
      expect(store.getString(OnboardingStateService.storageKey), corrupt);

      final skipped = await OnboardingStateService(
        store,
      ).saveStep(step: 4, answer: const {'learning_language': 'yo'});
      expect(skipped.error, isNotNull);
      expect(store.getString(OnboardingStateService.storageKey), corrupt);

      final restarted = await OnboardingStateService(
        store,
      ).saveStep(step: 1, answer: const {});
      expect(restarted.error, isNull);
      expect(restarted.state!.resumeStep, 1);
      expect(
        jsonDecode(store.getString(OnboardingStateService.storageKey)!),
        isA<Map>(),
      );
    },
  );

  test('a missing step or answer is an error, not a guessed step', () async {
    final missingStep = OnboardingStateService.readPayload(
      '{"resume_step":3,"steps":{"1":{},"3":{"primary_goal":"heritage"}}}',
    );
    expect(missingStep.state, isNull);
    expect(missingStep.error, isA<OnboardingStateException>());
    expect(placeOnboardingResume(missingStep, stepCount: 12).step, 1);

    final missingAnswers = OnboardingStateService.readPayload(
      '{"resume_step":2}',
    );
    expect(missingAnswers.error, isA<OnboardingStateException>());
    expect(
      placeOnboardingResume(missingAnswers, stepCount: 12).answers,
      isEmpty,
    );

    final store = await prefs();
    final gap = await OnboardingStateService(
      store,
    ).saveStep(step: 3, answer: const {'primary_goal': 'travel'});
    expect(gap.error, isA<OnboardingStateException>());
    expect(store.getString(OnboardingStateService.storageKey), isNull);

    final fresh = OnboardingStateService(store).read();
    expect(fresh.error, isNull);
    expect(fresh.state, isNull);
    expect(placeOnboardingResume(fresh, stepCount: 12).step, 1);
  });

  test('explanation matches the english catalogue', () {
    final arb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(
      arb['onboardingTheSavedAnswersCouldNotBeRead'],
      OnboardingStateException.explanation,
    );
  });

  test('full onboarding flow has a stable step count', () {
    expect(unifiedOnboardingStepCount(const []), 12);
    expect(
      unifiedOnboardingStepCount(const ['learning_language']),
      lessThan(12),
    );
  });

  testWidgets('corrupt save shows the explanation and restarts at step 1', (
    tester,
  ) async {
    await _pumpOnboarding(tester, {
      OnboardingStateService.storageKey: '{resume_step: 4}',
    });
    expect(find.text(OnboardingStateException.explanation), findsOneWidget);
    expect(_stepValue(tester), 'Step 1 of 12');
    await _drainOnboarding(tester);
  });

  testWidgets('a saved step is the step shown after restart', (tester) async {
    await _pumpOnboarding(tester, {
      OnboardingStateService.storageKey: previouslyWritten,
    });
    expect(find.text(OnboardingStateException.explanation), findsNothing);
    expect(_stepValue(tester), 'Step 4 of 12');
    await _drainOnboarding(tester);
  });
}

Future<void> _drainOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}

Future<void> _pumpOnboarding(
  WidgetTester tester,
  Map<String, Object> values,
) async {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('CastStage') &&
        message.contains(
          'setState() or markNeedsBuild() called during build',
        )) {
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues(values);
  final store = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              SharedPreferencesProvider(store),
            ),
          ],
          child: const MaterialApp(home: UnifiedOnboardingScreen()),
        ),
      ),
    ),
  );
  await tester.pump();
}

String? _stepValue(WidgetTester tester) {
  final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
  for (final node in semantics) {
    final value = node.properties.value;
    if (value != null && value.startsWith('Step ')) return value;
  }
  return null;
}
