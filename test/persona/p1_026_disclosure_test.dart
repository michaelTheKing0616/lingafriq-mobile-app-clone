// P1-026 Mode A spec-tests. No network, no real model calls, no sleeps.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/screens/personalities/personality_chat_screen.dart';
import 'package:lingafriq/services/ai/historical_personality_service.dart';

const _arbPath = 'lib/l10n/app_en.arb';
const _viewport = Size(390, 844);

HistoricalPersonality _fixturePersonality() {
  return HistoricalPersonality(
    id: 'nkrumah',
    name: 'Kwame Nkrumah',
    country: 'Ghana',
    language: 'English',
    biography: 'fixture biography',
    achievements: const ['independence'],
    traits: const ['resolute'],
    speechPatterns: const {},
    knowledgeTopics: const ['pan-africanism'],
    culturalContext: const {},
  );
}

String _disclosureCopy() {
  final arb = jsonDecode(File(_arbPath).readAsStringSync()) as Map<String, dynamic>;
  final copy = arb['persona.ai_disclosure'] ?? arb['persona_ai_disclosure'];
  expect(copy, isA<String>(),
      reason: 'app_en.arb must define persona.ai_disclosure or persona_ai_disclosure');
  return copy as String;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'P1-026_AC2_persona_open_shows_persistent_ai_disclosure_without_scroll',
    (tester) async {
      tester.view.physicalSize = _viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final copy = _disclosureCopy();
      expect(copy.toLowerCase(), contains('ai recreation'));
      expect(copy.toLowerCase(), contains('sources'));

      final semanticsHandle = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            client.overrideWithValue(
              Dio(BaseOptions(baseUrl: 'http://127.0.0.1/')),
            ),
          ],
          child: ScreenUtilInit(
            designSize: _viewport,
            builder: (_, __) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: PersonalityChatScreen(personality: _fixturePersonality()),
            ),
          ),
        ),
      );
      await tester.pump();

      final disclosure = find.text(copy);
      expect(disclosure, findsOneWidget);

      final rect = tester.getRect(disclosure);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(_viewport.height));

      expect(
        find.ancestor(of: disclosure, matching: find.byType(Scrollable)),
        findsNothing,
        reason: 'disclosure must stay visible without scrolling',
      );

      expect(find.bySemanticsLabel(copy), findsOneWidget);
      expect(tester.getSemantics(disclosure).label, contains(copy));
      semanticsHandle.dispose();
    },
  );
}
