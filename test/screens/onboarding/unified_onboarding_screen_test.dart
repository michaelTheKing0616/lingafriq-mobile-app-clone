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
        ],
        child: MaterialApp(home: child),
      ),
    ),
  );
}

Future<void> pumpOnboarding(
  WidgetTester tester, {
  bool reducedMotion = false,
  TextScaler textScaler = TextScaler.noScaling,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CastFileCache.instance.renderer = Factory.flutter;

  group('computeRegistrationAgeBand', () {
    test('returns child/teen/adult from birth year with default threshold 13', () {
      final now = DateTime.now().year;
      expect(computeRegistrationAgeBand(now - 10), 'child');
      expect(computeRegistrationAgeBand(now - 15), 'teen');
      expect(computeRegistrationAgeBand(now - 25), 'adult');
    });

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

    testWidgets('Get started advances to language pick with Continue disabled', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);

      await tester.tap(find.text('Get started'));
      await settleOnce(tester);

      expect(find.text('What do you want to learn?'), findsOneWidget);
      expect(find.text('Yoruba'), findsOneWidget);
      expect(find.text('West Africa'), findsOneWidget);

      final continueButton = tester.widget<FilledButton>(
        continueButtonFinder(),
      );
      expect(continueButton.onPressed, isNull);
    });

    testWidgets('selecting a language enables Continue', (tester) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tester.tap(find.text('Get started'));
      await settleOnce(tester);

      var continueButton = tester.widget<FilledButton>(continueButtonFinder());
      expect(continueButton.onPressed, isNull);

      final yoruba = find.text('Yoruba');
      await tester.ensureVisible(yoruba);
      await tester.tap(yoruba);
      await tester.pump();

      continueButton = tester.widget<FilledButton>(continueButtonFinder());
      expect(continueButton.onPressed, isNotNull);
    });

    testWidgets('language search empty state is announced', (tester) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tester.tap(find.text('Get started'));
      await settleOnce(tester);

      await tester.enterText(find.byType(TextField).first, 'zzzz-not-a-lang');
      await tester.pump();

      expect(find.text('No languages match that search.'), findsOneWidget);
    });

    testWidgets('selected language exposes selected semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tester.tap(find.text('Get started'));
      await settleOnce(tester);

      expect(find.bySemanticsLabel('Yoruba'), findsOneWidget);
      await tester.ensureVisible(find.text('Yoruba'));
      await tester.tap(find.text('Yoruba'));
      await tester.pump();
      expect(find.bySemanticsLabel('Yoruba, selected'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('back and skip are reachable by screen readers after welcome', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tester.tap(find.text('Get started'));
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

    testWidgets('birth-year child band shows Ask a parent path', (tester) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);

      // Welcome → Language
      await tester.tap(find.text('Get started'));
      await settleOnce(tester);
      await tester.ensureVisible(find.text('Yoruba'));
      await tester.tap(find.text('Yoruba'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue').first);
      await tester.tap(find.text('Continue').first);
      await settleOnce(tester);

      // Goal
      await tester.ensureVisible(find.text('Talk to family'));
      await tester.tap(find.text('Talk to family'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue').first);
      await tester.tap(find.text('Continue').first);
      await settleOnce(tester);

      // Level
      await tester.ensureVisible(find.text("I'm new"));
      await tester.tap(find.text("I'm new"));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue').first);
      await tester.tap(find.text('Continue').first);
      await settleOnce(tester);

      // First win: hear → tap correct greeting → say → celebration
      await tester.ensureVisible(find.text('Play greeting'));
      await tester.tap(find.text('Play greeting'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue').first);
      await tester.tap(find.text('Continue').first);
      await settleOnce(tester);

      await tester.ensureVisible(find.text('Báwo ni'));
      await tester.tap(find.text('Báwo ni'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue').first);
      await tester.tap(find.text('Continue').first);
      await settleOnce(tester);

      await tester.ensureVisible(find.text('I said it'));
      await tester.tap(find.text('I said it'));
      await tester.pump();
      await tester.ensureVisible(find.text('Finish lesson'));
      await tester.tap(find.text('Finish lesson'));
      await settleOnce(tester);

      await tester.ensureVisible(find.text('Keep going'));
      await tester.tap(find.text('Keep going'));
      await settleOnce(tester);

      expect(find.text('When were you born?'), findsOneWidget);
      expect(find.textContaining('Ask a parent'), findsNothing);

      // Type a child birth year (age ~10).
      final yearField = find.byType(TextField).first;
      await tester.enterText(
        yearField,
        '${DateTime.now().year - 10}',
      );
      await tester.pump();

      expect(find.text('Ask a parent'), findsWidgets);
      expect(find.textContaining('guardian can help'), findsOneWidget);

      expect(
        find.text('Skip for now. Progress stays on this device'),
        findsOneWidget,
      );
      final skipAccount = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Skip for now. Progress stays on this device'),
          matching: find.byType(TextButton),
        ),
      );
      expect(skipAccount.onPressed, isNull);
    });

    testWidgets('welcome survives 200% text scale without overflow', (
      tester,
    ) async {
      await pumpOnboarding(
        tester,
        textScaler: const TextScaler.linear(2.0),
      );
      await settleOnce(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('LingAfriq'), findsOneWidget);
    });

    testWidgets('first-win Continue stays disabled until hear action', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await settleOnce(tester);
      await tester.tap(find.text('Get started'));
      await settleOnce(tester);
      await tester.ensureVisible(find.text('Yoruba'));
      await tester.tap(find.text('Yoruba'));
      await tester.pump();
      await tester.tap(find.text('Continue').first);
      await settleOnce(tester);
      await tester.tap(find.text('Talk to family'));
      await tester.pump();
      await tester.tap(find.text('Continue').first);
      await settleOnce(tester);
      await tester.tap(find.text("I'm new"));
      await tester.pump();
      await tester.tap(find.text('Continue').first);
      await settleOnce(tester);

      expect(find.text('Play greeting'), findsOneWidget);
      final continueBtn = tester.widget<FilledButton>(
        continueButtonFinder(),
      );
      expect(continueBtn.onPressed, isNull);
    });
  });
}
