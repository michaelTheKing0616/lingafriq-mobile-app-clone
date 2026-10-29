import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart';
import 'package:rive/rive.dart';

import '../golden/golden_harness.dart';
import '../screens/onboarding/unified_onboarding_screen_test.dart' hide main;

Future<void> _shot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(UnifiedOnboardingScreen),
    matchesGoldenFile('goldens/unified/$name.png'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CastFileCache.instance.renderer = Factory.flutter;

  setUpAll(() async {
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
    // Submit state: Continue disables while the year saves.
    await tapVisible(tester, label('Continue').first);
    await _shot(tester, '11b_birth_year_submit$suffix');
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
    await _shot(tester, '17_save_progress_loading$suffix');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/unified/18_signin_google$suffix.png'),
    );
  }

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
    await tapVisible(tester, find.text('اليوروبا'));
    expect(find.text('ماذا تريد أن تتعلم؟'), findsOneWidget);
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
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/unified/19_offline_finish_error.png'),
    );
  });
}
