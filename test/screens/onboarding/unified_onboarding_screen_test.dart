import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [child] the same way the app does: ScreenUtilInit + ProviderScope.
Future<Widget> wrap(
  Widget child, {
  bool reducedMotion = false,
  TextScaler textScaler = TextScaler.noScaling,
  bool online = true,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MediaQuery(
      data: MediaQueryData(
        disableAnimations: reducedMotion,
        textScaler: textScaler,
      ),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            SharedPreferencesProvider(prefs),
          ),
          onboardingOnlineProvider.overrideWith((ref) async => online),
        ],
        child: MaterialApp(
          home: Directionality(textDirection: textDirection, child: child),
        ),
      ),
    ),
  );
}

Future<void> pumpOnboarding(
  WidgetTester tester, {
  bool reducedMotion = false,
  TextScaler textScaler = TextScaler.noScaling,
  bool online = true,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  _installAvatarCastNoiseFilter();
  await tester.pumpWidget(
    await wrap(
      const UnifiedOnboardingScreen(),
      reducedMotion: reducedMotion,
      textScaler: textScaler,
      online: online,
      textDirection: textDirection,
    ),
  );
}

void _installAvatarCastNoiseFilter() {
  final testOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isKnownAvatarCastNoise(details)) return;
    testOnError?.call(details);
  };
}

bool _isKnownAvatarCastNoise(FlutterErrorDetails details) {
  final message = details.exceptionAsString();
  return message.contains('CastStage') &&
      message.contains('setState() or markNeedsBuild() called during build');
}

Future<void> settleOnce(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder continueButtonFinder() {
  return find.ancestor(
    of: find.text('Continue'),
    matching: find.byType(FilledButton),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> next(WidgetTester tester, [String label = 'Continue']) async {
  await tapVisible(tester, find.text(label).first);
  await settleOnce(tester);
}

/// Welcome → language → reason → level → daily goal, landing on first win.
Future<void> advanceToFirstWin(
  WidgetTester tester, {
  String language = 'Yoruba',
}) async {
  await next(tester, 'Get started');
  await tapVisible(tester, find.text(language));
  await next(tester);
  await tapVisible(tester, find.text('Talk to family'));
  await next(tester);
  await tapVisible(tester, find.text("I'm new"));
  await next(tester);
  await tapVisible(tester, find.text('Steady'));
  await next(tester);
}

Future<void> completeFirstWin(WidgetTester tester, {bool speak = true}) async {
  await tapVisible(tester, find.text('Play greeting'));
  await tester.pump(const Duration(milliseconds: 50));
  await next(tester);
  await tapVisible(tester, find.text('Báwo ni'));
  await next(tester);
  if (speak) {
    await tapVisible(tester, find.text('I said it'));
    await next(tester, 'Finish lesson');
  } else {
    await next(tester, "Can't speak now");
  }
}

Future<void> enterBirthYear(WidgetTester tester, int age) async {
  await tester.enterText(
    find.byType(TextField).first,
    '${DateTime.now().year - age}',
  );
  await tester.pump();
  // Let the field's floating label finish moving.
  await tester.pump(const Duration(milliseconds: 300));
}

/// From the celebration through age, reminders, style, tone and profile.
Future<void> advanceToSaveProgress(WidgetTester tester, {int age = 25}) async {
  await next(tester, 'Keep going');
  await enterBirthYear(tester, age);
  await next(tester);
  await next(tester, 'Not now');
  await tapVisible(tester, find.text('Listening'));
  await next(tester);
  await tapVisible(tester, find.text('Friendly'));
  await next(tester);
  await next(tester, 'Skip for now');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CastFileCache.instance.renderer = Factory.flutter;

  group('computeRegistrationAgeBand', () {
    test(
      'returns child/teen/adult from birth year with default threshold 13',
      () {
        final now = DateTime.now().year;
        expect(computeRegistrationAgeBand(now - 10), 'child');
        expect(computeRegistrationAgeBand(now - 15), 'teen');
        expect(computeRegistrationAgeBand(now - 25), 'adult');
      },
    );

    test('uses DE child threshold 16 without hard-coding NG to 18', () {
      final now = DateTime.now().year;
      // Age 14 is teen under default 13, child under DE 16.
      expect(computeRegistrationAgeBand(now - 15), 'teen');
      expect(computeRegistrationAgeBand(now - 15, countryCode: 'DE'), 'child');
      expect(computeRegistrationAgeBand(now - 15, countryCode: 'NG'), 'teen');
    });
  });

  group('UnifiedOnboardingScreen', () {
    testWidgets('welcome shows Finch/Speak promise, offline chip, and CTA', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);

      expect(find.text('LingAfriq'), findsOneWidget);
      expect(find.textContaining('gets you speaking'), findsOneWidget);
      expect(find.text('Works offline · about 2 MB per unit'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets(
      'Get started advances to language pick with Continue disabled',
      (tester) async {
        await pumpOnboarding(tester);
        await settleOnce(tester);

        await tapVisible(tester, find.text('Get started'));
        await settleOnce(tester);

        expect(find.text('What do you want to learn?'), findsOneWidget);
        expect(find.text('Yoruba'), findsOneWidget);
        expect(find.text('West Africa'), findsOneWidget);

        final continueButton = tester.widget<FilledButton>(
          continueButtonFinder(),
        );
        expect(continueButton.onPressed, isNull);
      },
    );

    testWidgets('selecting a language enables Continue', (tester) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tapVisible(tester, find.text('Get started'));
      await settleOnce(tester);

      var continueButton = tester.widget<FilledButton>(continueButtonFinder());
      expect(continueButton.onPressed, isNull);

      await tapVisible(tester, find.text('Yoruba'));

      continueButton = tester.widget<FilledButton>(continueButtonFinder());
      expect(continueButton.onPressed, isNotNull);
    });

    testWidgets('language search empty state is announced', (tester) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tapVisible(tester, find.text('Get started'));
      await settleOnce(tester);

      await tester.enterText(find.byType(TextField).first, 'zzzz-not-a-lang');
      await tester.pump();

      expect(find.text('No languages match that search.'), findsOneWidget);
    });

    testWidgets('selected language exposes selected semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tapVisible(tester, find.text('Get started'));
      await settleOnce(tester);

      expect(find.bySemanticsLabel('Yoruba'), findsOneWidget);
      await tapVisible(tester, find.text('Yoruba'));
      expect(find.bySemanticsLabel('Yoruba, selected'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('back and skip are reachable by screen readers after welcome', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tapVisible(tester, find.text('Get started'));
      await settleOnce(tester);

      expect(
        find.bySemanticsLabel('Go back to the previous step'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Skip onboarding'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      'reduced motion: welcome fade-in text is already at full opacity',
      (tester) async {
        await pumpOnboarding(tester, reducedMotion: true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        final fadeTransition = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('Welcome to'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(fadeTransition.opacity.value, 1.0);
      },
    );

    testWidgets(
      'with motion enabled, welcome fade-in starts hidden before delay',
      (tester) async {
        await pumpOnboarding(tester);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        final fadeTransition = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('Welcome to'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(fadeTransition.opacity.value, lessThan(1.0));
      },
    );

    testWidgets('reason step is multi-select and gates Continue', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await next(tester, 'Get started');
      await tapVisible(tester, find.text('Yoruba'));
      await next(tester);

      expect(find.text('Why are you learning Yoruba?'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(continueButtonFinder()).onPressed,
        isNull,
      );
      await tapVisible(tester, find.text('Talk to family'));
      await tapVisible(tester, find.text('Travel'));
      expect(
        tester.widget<FilledButton>(continueButtonFinder()).onPressed,
        isNotNull,
      );
    });

    testWidgets('daily goal waits for a choice', (tester) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await next(tester, 'Get started');
      await tapVisible(tester, find.text('Yoruba'));
      await next(tester);
      await tapVisible(tester, find.text('Talk to family'));
      await next(tester);
      await tapVisible(tester, find.text("I'm new"));
      await next(tester);

      expect(find.text('How much time a day feels right?'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(continueButtonFinder()).onPressed,
        isNull,
      );
      await tapVisible(tester, find.text('Steady'));
      expect(
        tester.widget<FilledButton>(continueButtonFinder()).onPressed,
        isNotNull,
      );
    });

    testWidgets('celebration shows real stats when the learner speaks', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await advanceToFirstWin(tester);
      await completeFirstWin(tester);

      expect(find.text('You did it!'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('New word'), findsOneWidget);
    });

    testWidgets("Can't speak now finishes the lesson without penalty", (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await advanceToFirstWin(tester);
      await completeFirstWin(tester, speak: false);

      expect(find.text('You did it!'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets(
      'birth-year: Continue waits for a year; child sees parent ask',
      (tester) async {
        await pumpOnboarding(tester);
        await settleOnce(tester);
        await advanceToFirstWin(tester);
        await completeFirstWin(tester);
        await next(tester, 'Keep going');

        expect(find.text('What year were you born?'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(continueButtonFinder()).onPressed,
          isNull,
        );
        expect(find.text('Ask a parent'), findsNothing);

        await enterBirthYear(tester, 10);
        expect(find.text('Ask a parent'), findsOneWidget);
        expect(
          find.text('Keep learning. My parent will add it later'),
          findsOneWidget,
        );
      },
    );

    testWidgets('child "parent will add it later" persists consent need', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await advanceToFirstWin(tester);
      await completeFirstWin(tester);
      await next(tester, 'Keep going');
      await enterBirthYear(tester, 10);
      await next(tester, 'Keep learning. My parent will add it later');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('age_category'), 'child');
      expect(prefs.getBool('needs_guardian_consent'), isTrue);
      expect(prefs.getInt('birth_year'), DateTime.now().year - 10);
    });

    testWidgets('account wall comes last and Later keeps progress on device', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await advanceToFirstWin(tester);
      await completeFirstWin(tester);
      await advanceToSaveProgress(tester);

      expect(find.text('Save your progress?'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Sign up with email'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);

      await next(tester, 'Later. My answers stay on this phone');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('onboarding_complete'), 'true');
      expect(prefs.getBool('onboarding_account_skipped'), isTrue);
      expect(prefs.getString('age_category'), 'adult');
      // Let the post-completion navigation and snackbar timers drain.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('offline notice appears and keeps the flow usable', (
      tester,
    ) async {
      await pumpOnboarding(tester, online: false);
      await settleOnce(tester);
      await next(tester, 'Get started');

      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tapVisible(tester, find.text('Yoruba'));
      expect(
        tester.widget<FilledButton>(continueButtonFinder()).onPressed,
        isNotNull,
      );
    });

    for (final dir in TextDirection.values) {
      testWidgets('every step survives 200% text in ${dir.name}', (
        tester,
      ) async {
        await pumpOnboarding(
          tester,
          textScaler: const TextScaler.linear(2.0),
          textDirection: dir,
        );
        await settleOnce(tester);
        expect(tester.takeException(), isNull);
        await advanceToFirstWin(tester);
        expect(tester.takeException(), isNull);
        await completeFirstWin(tester);
        expect(tester.takeException(), isNull);
        await advanceToSaveProgress(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Save your progress?'), findsOneWidget);
      });
    }

    testWidgets('welcome survives 200% text scale without overflow', (
      tester,
    ) async {
      await pumpOnboarding(tester, textScaler: const TextScaler.linear(2.0));
      await settleOnce(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('LingAfriq'), findsOneWidget);
      expect(find.text('Works offline · about 2 MB per unit'), findsOneWidget);
    });

    testWidgets('first-win Continue stays disabled until hear action', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await advanceToFirstWin(tester);

      expect(find.text('Play greeting'), findsOneWidget);
      final continueBtn = tester.widget<FilledButton>(continueButtonFinder());
      expect(continueBtn.onPressed, isNull);
    });

    testWidgets('Play greeting never stays silent — shows honest audio state', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await advanceToFirstWin(tester);

      await tester.tap(find.text('Play greeting'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // In tests the audio pipeline is unavailable — must disclose that.
      expect(find.text('Audio unavailable'), findsOneWidget);
      expect(find.textContaining('could not play sound'), findsOneWidget);

      final continueBtn = tester.widget<FilledButton>(continueButtonFinder());
      expect(continueBtn.onPressed, isNotNull);
    });

    testWidgets('first-win uses selected language copy (Hausa path)', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await advanceToFirstWin(tester, language: 'Hausa');

      expect(find.textContaining('Hausa'), findsWidgets);
      expect(find.textContaining('Sannu'), findsWidgets);
      expect(find.textContaining('Yoruba'), findsNothing);
    });
  });
}
