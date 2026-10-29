import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

import '../golden/golden_harness.dart';

/// One render variant required by the UI rubric.
class GoldenVariant {
  const GoldenVariant(
    this.name,
    this.size, {
    this.locale = const Locale('en'),
    this.scale = 1,
  });
  final String name;
  final Size size;
  final Locale locale;
  final double scale;
}

const goldenVariants = <GoldenVariant>[
  GoldenVariant('ltr_390', Size(390, 844)),
  GoldenVariant('rtl_390', Size(390, 844), locale: Locale('ar')),
  GoldenVariant('scale200_390', Size(390, 844), scale: 2),
  GoldenVariant('small_320', Size(320, 568)),
  GoldenVariant(
    'small_320_scale200_rtl',
    Size(320, 568),
    locale: Locale('ar'),
    scale: 2,
  ),
];

Future<ByteData> _bytes(String path) =>
    io.File(path).readAsBytes().then(ByteData.sublistView);

/// Loads real glyph fonts (Roboto, Material icons, Noto Sans Arabic, Lato)
/// so goldens show text, icons and Arabic instead of boxes.
Future<void> loadComplianceFonts(String testPath) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  goldenFileComparator = ThresholdGoldenComparator(Uri.parse(testPath));
  final sdk =
      '${io.Platform.environment['FLUTTER_ROOT']}/bin/cache/'
      'artifacts/material_fonts';
  await (FontLoader(
    'MaterialIcons',
  )..addFont(_bytes('$sdk/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('Roboto')
        ..addFont(_bytes('$sdk/Roboto-Regular.ttf'))
        ..addFont(_bytes('$sdk/Roboto-Medium.ttf'))
        ..addFont(_bytes('$sdk/Roboto-Bold.ttf')))
      .load();
  // 'Noto Sans' heads PanAfricanTypography's fallback list; on devices the
  // OS supplies Arabic glyphs there, so tests register Noto Sans Arabic under
  // that name too (only used for glyphs Lato lacks).
  for (final family in ['Noto Sans Arabic', 'Noto Sans']) {
    await (FontLoader(
      family,
    )..addFont(_bytes('test/fonts/NotoSansArabic.ttf'))).load();
  }
  await GoogleFonts.pendingFonts([
    for (final w in [FontWeight.w400, FontWeight.w600, FontWeight.w700])
      GoogleFonts.lato(fontWeight: w),
  ]);
}

ThemeData complianceTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  fontFamilyFallback: const ['Noto Sans Arabic'],
  colorScheme: ColorScheme.fromSeed(seedColor: PanAfricanColors.primary),
);

Future<void> pumpVariant(
  WidgetTester tester,
  GoldenVariant v,
  Widget home, {
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = v.size;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = v.scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: complianceTheme(),
          locale: v.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: TextScaler.linear(v.scale)),
            child: child!,
          ),
          home: home,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// No RenderFlex overflow or other framework error was reported.
void expectNoLayoutErrors(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
