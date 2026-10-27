import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';
import 'package:lingafriq/providers/learner_model_provider.dart';
import 'package:lingafriq/screens/games/game_mastery_map_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('mastery map empty state shows instructions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          masteryMapSkillRowsProvider.overrideWith(
            (ref, _) async => const <MasteryMapSkillRow>[],
          ),
          masteryMapSessionRecordsProvider.overrideWith(
            (ref, _) async => const [],
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const GameMasteryMapScreen(learnerId: 'test_learner_empty'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('arcade games'), findsOneWidget);
  });
}
