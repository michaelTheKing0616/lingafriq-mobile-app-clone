// P1-029 AC4 widget test: pumps CurriculumScreenMaterial3 in its real coming-soon state.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/curriculum_provider.dart';
import 'package:lingafriq/screens/curriculum/curriculum_screen_material3.dart';

/// Provider double: a loaded bundle with real units, no prefs/asset I/O.
/// The screen must still show coming-soon because no language is verified.
class _LoadedBundleCurriculumProvider extends CurriculumProvider {
  final Curriculum _bundle = Curriculum(
    meta: CurriculumMeta(
      title: 'test',
      generatedAt: DateTime(2026),
      languages: const ['yoruba'],
      levels: const ['A1'],
    ),
    languages: {
      'yoruba': {
        'A1': [
          CurriculumUnit(
            unit: 1,
            title: 'Greetings',
            lessons: const [],
            unitQuiz: const [],
          ),
        ],
      },
    },
  );

  @override
  Curriculum? get curriculum => _bundle;

  @override
  BaseProviderState build() => BaseProviderState();

  @override
  Future<void> loadCurriculumFromBundle({bool useExpanded = false}) async {}
}

void main() {
  testWidgets('P1-029_AC4_unverified_language_shows_coming_soon_widget',
      (tester) async {
    // The test font (Ahem) is far wider than real fonts; a larger surface keeps
    // the language dropdown row from overflowing for reasons unrelated to AC4.
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curriculumProvider.overrideWith(_LoadedBundleCurriculumProvider.new),
        ],
        child: ScreenUtilInit(
          designSize: const Size(1600, 2400),
          builder: (_, __) => const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CurriculumScreenMaterial3(initialLanguage: 'yoruba'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Coming Soon'), findsOneWidget);
    final announced = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.liveRegion == true,
    );
    expect(announced, findsWidgets);
    expect(find.byKey(const ValueKey('content.coming_soon')), findsOneWidget);
    semantics.dispose();
  });

  // ux_spec.goldens: language_coming_soon, light + dark. The design system
  // exposes no ThemeData, so the stock Material light/dark themes are used.
  for (final entry in {
    'light': ThemeData.light(),
    'dark': ThemeData.dark(),
  }.entries) {
    testWidgets('P1-029_AC4_language_coming_soon_golden_${entry.key}',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            curriculumProvider
                .overrideWith(_LoadedBundleCurriculumProvider.new),
          ],
          child: ScreenUtilInit(
            designSize: const Size(1600, 2400),
            builder: (_, __) => MaterialApp(
              theme: entry.value,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const CurriculumScreenMaterial3(initialLanguage: 'yoruba'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const ValueKey('content.coming_soon')), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/language_coming_soon_${entry.key}.png'),
      );
    });
  }
}
