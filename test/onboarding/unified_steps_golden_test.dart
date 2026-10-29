import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/screens/auth/sign_in_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart';
import 'package:rive/rive.dart';

import '../golden/golden_harness.dart';
import 'onboarding_art.dart';
import '../screens/onboarding/unified_onboarding_screen_test.dart' hide main;

Future<void> _shot(WidgetTester tester, String name) async {
  await scrollToTop(tester);
  await settleArt(tester);
  expectNoBlankCast(tester, name);
  await expectLater(
    find.byType(UnifiedOnboardingScreen),
    matchesGoldenFile('goldens/unified/$name.png'),
  );
}

/// Saving does real I/O (prefs, outbox); give it real time until sign-in
/// is on screen. Offline never leaves save progress.
Future<void> _untilSignIn(WidgetTester tester, {bool online = true}) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await settleArt(tester);
    if (find.byKey(const ValueKey('signin-hero')).evaluate().isNotEmpty) {
      // Finish the route transition before any golden.
      for (var j = 0; j < 5; j++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      return;
    }
  }
  if (online) fail('sign-in never opened after saving');
}

final _signInBack = find.descendant(
  of: find.byType(SignInOptionsScreen),
  matching: find.byType(BackButtonIcon),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CastFileCache.instance.renderer = Factory.flutter;

  // rootBundle caches asset futures; one completed in an earlier test's
  // fake zone never resumes here, so the rig's part catalog would stall.
  setUp(rootBundle.clear);

  setUpAll(() async {
    // Decode the rig once in a real zone: a decode begun inside one test's
    // fake clock never resumes in the next, which left 01 on the still.
    await CastFileCache.instance.load();
    // Brand type is bundled in assets/google_fonts, so no network is used.
    GoogleFonts.config.allowRuntimeFetching = false;
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/onboarding/unified_steps_golden_test.dart'),
    );
    await loadPinnedFont();
    await GoogleFonts.pendingFonts([
      for (final w in [
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
      ])
        GoogleFonts.plusJakartaSans(fontWeight: w),
    ]);
    // Icons and Material default text (fields, outlined buttons) render as
    // glyphs, not boxes, so goldens show the real UI.
    Future<ByteData> sdkFont(String name) => io.File(
      '${io.Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/'
      'material_fonts/$name',
    ).readAsBytes().then(ByteData.sublistView);
    await (FontLoader(
      'MaterialIcons',
    )..addFont(sdkFont('MaterialIcons-Regular.otf'))).load();
    // Real Arabic glyphs for the RTL run (OFL, test-only asset).
    await (FontLoader('Noto Sans Arabic')..addFont(
          io.File(
            'test/fonts/NotoSansArabic.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader('Roboto')
          ..addFont(sdkFont('Roboto-Regular.ttf'))
          ..addFont(sdkFont('Roboto-Medium.ttf'))
          ..addFont(sdkFont('Roboto-Bold.ttf')))
        .load();
  });

  Future<void> walk(
    WidgetTester tester, {
    required String suffix,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
    bool online = true,
  }) async {
    await pumpOnboarding(
      tester,
      reducedMotion: true,
      textScaler: textScaler,
      textDirection: textDirection,
      online: online,
    );
    await settleOnce(tester);
    await settleRive(tester);
    await _shot(tester, '01_welcome$suffix');
    await next(tester, 'Get started');
    await tapVisible(tester, label('Yoruba'));
    await _shot(tester, '02_language$suffix');
    await next(tester);
    await tapVisible(tester, label('Talk to family'));
    await _shot(tester, '03_reason$suffix');
    await next(tester);
    await tapVisible(tester, label("I'm new"));
    await _shot(tester, '04_level$suffix');
    await next(tester);
    await tapVisible(tester, label('Steady'));
    await _shot(tester, '05_daily_goal$suffix');
    await next(tester);
    await _shot(tester, '06_first_win_hear$suffix');
    await tapVisible(tester, label('Play greeting'));
    await tester.pump(const Duration(milliseconds: 50));
    await next(tester);
    await tapVisible(tester, label('Báwo ni'));
    await _shot(tester, '07_first_win_tap$suffix');
    await next(tester);
    await _shot(tester, '08_first_win_say$suffix');
    await tapVisible(tester, label('I said it'));
    await next(tester, 'Finish lesson');
    await _shot(tester, '09_celebration$suffix');
    await next(tester, 'Keep going');
    await enterBirthYear(tester, 10);
    await _shot(tester, '10_birth_year_child$suffix');
    await enterBirthYear(tester, 25);
    await _shot(tester, '11_birth_year_adult$suffix');
    // The save is instant with mocked storage, so no submit frame exists to
    // capture; the in-button 'Saving…' state is covered by golden 17.
    await tapVisible(tester, label('Continue').first);
    await settleOnce(tester);
    await _shot(tester, '12_reminders$suffix');
    await next(tester, 'Not now');
    await tapVisible(tester, label('Listening'));
    await _shot(tester, '13_style$suffix');
    await next(tester);
    await tapVisible(tester, label('Friendly'));
    await _shot(tester, '14_tone$suffix');
    await next(tester);
    await _shot(tester, '15_profile$suffix');
    await next(tester, 'Skip for now');
    await _shot(tester, '16_save_progress$suffix');
    // Loading: tapping an account choice shows the saving overlay first.
    await tapVisible(tester, label('Continue with Google'));
    // Let the disabled styling finish its 200 ms shape/colour transition.
    await tester.pump(const Duration(milliseconds: 300));
    if (online) expect(label('Saving your progress…'), findsOneWidget);
    await _shot(tester, '17_save_progress_loading$suffix');
    await _untilSignIn(tester, online: online);
    expect(find.textContaining('provider_invalid'), findsNothing);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/unified/18_signin_google$suffix.png'),
    );
    if (!online) {
      expect(find.byKey(const ValueKey('finish-error')), findsOneWidget);
      await expectLastButtonReachable(tester, 'save progress offline');
      return;
    }
    // Same chrome as every step: back + bead progress, plus Polie's greeting.
    expect(_signInBack, findsOneWidget);
    expect(find.byKey(const ValueKey('signin-hero')), findsOneWidget);
    await expectLastButtonReachable(
      tester,
      'sign-in$suffix',
      bodyKey: const Key('signin-body'),
    );
    // Back returns to save progress (onboarding stays underneath).
    await tester.tap(_signInBack);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const ValueKey('save-basket')), findsOneWidget);
    await expectLastButtonReachable(tester, 'save progress$suffix');
  }

  testWidgets('Arabic locale: save progress and sign-in in Arabic, mirrored', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      reducedMotion: true,
      textDirection: TextDirection.rtl,
      locale: const Locale('ar'),
    );
    await settleOnce(tester);
    await advanceToFirstWin(tester);
    await completeFirstWin(tester);
    await advanceToSaveProgress(tester);
    for (final ar in [
      'هل تريد حفظ تقدّمك؟',
      'المتابعة باستخدام Google',
      'إنشاء حساب بالبريد الإلكتروني',
      'لدي حساب بالفعل',
      'لاحقًا. تبقى إجاباتي على هذا الهاتف',
    ]) {
      expect(find.text(ar), findsOneWidget, reason: ar);
    }
    for (final en in ['Save your', 'Continue with', 'Sign up', 'Later.']) {
      expect(find.textContaining(en), findsNothing, reason: en);
    }
    await _shot(tester, '16a_save_progress_arabic_rtl');
    await tapVisible(tester, find.text('المتابعة باستخدام Google'));
    await _untilSignIn(tester);
    for (final ar in ['اختر طريقة تسجيل الدخول', 'أو', 'أرسل لي رابطًا']) {
      expect(find.text(ar), findsOneWidget, reason: ar);
    }
    for (final en in ['Choose how', 'Email me', 'Continue with']) {
      expect(find.textContaining(en), findsNothing, reason: en);
    }
    // Mirrored: back at the right (start) edge.
    expect(tester.getCenter(_signInBack).dx, greaterThan(195));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/unified/18a_signin_arabic_rtl.png'),
    );
  });

  testWidgets('Arabic locale: welcome and language in Arabic, mirrored', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      reducedMotion: true,
      textDirection: TextDirection.rtl,
      locale: const Locale('ar'),
    );
    await settleOnce(tester);
    expect(find.text('ابدأ الآن'), findsOneWidget);
    await _shot(tester, '01a_welcome_arabic_rtl');
    await tapVisible(tester, find.text('ابدأ الآن'));
    await settleOnce(tester);
    await tapVisible(tester, find.text('العربية'));
    expect(find.text('ماذا تريد أن تتعلم؟'), findsOneWidget);
    expect(find.text('غرب أفريقيا'), findsOneWidget);
    // No untranslated English left in the Arabic chrome.
    for (final en in [
      'West Africa',
      'What do you want to learn?',
      'Skip',
      'Continue',
      'Search languages',
      'I speak',
    ]) {
      expect(find.textContaining(en), findsNothing, reason: en);
    }
    // Top bar mirrors: back sits at the start (right) edge in RTL.
    final back = tester.getCenter(find.byType(BackButtonIcon));
    expect(back.dx, greaterThan(390 / 2));
    await _shot(tester, '02a_language_arabic_rtl');
  });
  testWidgets('every step, default', (tester) => walk(tester, suffix: ''));
  testWidgets(
    'every step, RTL',
    (tester) => walk(tester, suffix: '_rtl', textDirection: TextDirection.rtl),
  );
  testWidgets(
    'every step, 200% text',
    (tester) => walk(
      tester,
      suffix: '_text200',
      textScaler: const TextScaler.linear(2.0),
    ),
  );
  testWidgets(
    'every step, offline',
    (tester) => walk(tester, suffix: '_offline', online: false),
  );
  testWidgets('error: offline sign-in shows message and Retry', (tester) async {
    await pumpOnboarding(tester, reducedMotion: true, online: false);
    await settleOnce(tester);
    await advanceToFirstWin(tester);
    await completeFirstWin(tester);
    await advanceToSaveProgress(tester);
    await tapVisible(tester, label('Continue with Google'));
    await settleOnce(tester);
    expect(find.byKey(const ValueKey('finish-error')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('finish-error')),
        matching: label('Retry'),
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await settleArt(tester);
    expectNoBlankCast(tester, '19_offline_finish_error');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/unified/19_offline_finish_error.png'),
    );
  });
}
