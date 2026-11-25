import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/avatars/cast/cast_stage.dart';
import 'package:lingafriq/avatars/onboarding/onboarding_avatar_widget.dart';
import 'package:lingafriq/avatars/personality_system.dart' show OnboardingStep;
import 'package:rive/rive.dart';

/// Motion evidence for Polie: welcome waves, the finish celebrates, and the
/// OS reduce-motion setting suppresses both and stills the idle loops.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CastFileCache.instance.renderer = Factory.flutter;

  Future<List<String>> fired(
    WidgetTester tester,
    OnboardingStep step, {
    required bool reduceMotion,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Center(child: OnboardingAvatarWidget(step: step)),
          ),
        ),
      ),
    );
    // The rig loads from assets off the fake clock.
    for (var i = 0; i < 20 && find.byType(CastStage).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(CastStage), findsOneWidget, reason: 'rig loaded');
    final session = tester.widget<CastStage>(find.byType(CastStage)).session;
    final out = List<String>.of(session.debugFired);
    // The engine caches a session per character; start each case clean.
    session.debugFired.clear();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    return out;
  }

  testWidgets('welcome waves; complete celebrates; reduce motion fires '
      'neither', (tester) async {
    expect(
      await fired(tester, OnboardingStep.welcome, reduceMotion: false),
      contains('wave'),
    );
    expect(
      await fired(tester, OnboardingStep.complete, reduceMotion: false),
      contains('celebrate'),
    );
    expect(
      await fired(tester, OnboardingStep.welcome, reduceMotion: true),
      isNot(anyOf(contains('wave'), contains('celebrate'))),
    );
    expect(
      await fired(tester, OnboardingStep.complete, reduceMotion: true),
      isNot(anyOf(contains('wave'), contains('celebrate'))),
    );
  });
}
