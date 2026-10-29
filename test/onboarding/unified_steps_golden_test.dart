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
    await tapVisible(tester, find.text('Yoruba'));
    await _shot(tester, '02_language$suffix');
    await next(tester);
    await tapVisible(tester, find.text('Talk to family'));
    await _shot(tester, '03_reason$suffix');
    await next(tester);
    await tapVisible(tester, find.text("I'm new"));
    await _shot(tester, '04_level$suffix');
    await next(tester);
    await tapVisible(tester, find.text('Steady'));
    await _shot(tester, '05_daily_goal$suffix');
    await next(tester);
    await _shot(tester, '06_first_win_hear$suffix');
    await tapVisible(tester, find.text('Play greeting'));
    await tester.pump(const Duration(milliseconds: 50));
    await next(tester);
    await tapVisible(tester, find.text('Báwo ni'));
    await _shot(tester, '07_first_win_tap$suffix');
    await next(tester);
    await _shot(tester, '08_first_win_say$suffix');
    await tapVisible(tester, find.text('I said it'));
    await next(tester, 'Finish lesson');
    await _shot(tester, '09_celebration$suffix');
    await next(tester, 'Keep going');
    await enterBirthYear(tester, 10);
    await _shot(tester, '10_birth_year_child$suffix');
    await enterBirthYear(tester, 25);
    await _shot(tester, '11_birth_year_adult$suffix');
    await next(tester);
    await _shot(tester, '12_reminders$suffix');
    await next(tester, 'Not now');
    await tapVisible(tester, find.text('Listening'));
    await _shot(tester, '13_style$suffix');
    await next(tester);
    await tapVisible(tester, find.text('Friendly'));
    await _shot(tester, '14_tone$suffix');
    await next(tester);
    await _shot(tester, '15_profile$suffix');
    await next(tester, 'Skip for now');
    await _shot(tester, '16_save_progress$suffix');
  }

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
  testWidgets('offline notice', (tester) async {
    await pumpOnboarding(tester, reducedMotion: true, online: false);
    await settleOnce(tester);
    await next(tester, 'Get started');
    await _shot(tester, '02_language_offline');
  });
}
