import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/widgets/ai/ai_disclosure.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('AppBar disclosure is visible and announced (en)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          appBar: AppBar(
            title: const Text('Polie'),
            bottom: const AiDisclosureBar(),
          ),
        ),
      ),
    );
    expect(find.textContaining('AI-generated'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('AI tutor')), findsOneWidget);
  });

  testWidgets('AiDisclosed keeps the body and localises (ar, RTL)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(body: AiDisclosed(child: Text('lesson body'))),
        locale: const Locale('ar'),
      ),
    );
    expect(find.text('lesson body'), findsOneWidget);
    expect(find.textContaining('الذكاء الاصطناعي'), findsOneWidget);
    expect(find.textContaining('AI-generated'), findsNothing);
  });

  test('every AI-generated surface carries the disclosure', () {
    const files = [
      'lib/features/polie_workspace/build_host/polie_workspace_build_host_scaffold.dart',
      'lib/screens/persona_missions/persona_mission_session_screen.dart',
      'lib/screens/tutor/tutor_assess_mode_screen.dart',
      'lib/screens/tutor/tutor_dialogue_mode_screen.dart',
      'lib/screens/tutor/tutor_grammar_mode_screen.dart',
      'lib/screens/tutor/tutor_story_mode_screen.dart',
      'lib/screens/tutor/tutor_translation_mode_screen.dart',
      'lib/screens/tutor/tutor_pronunciation_mode_screen.dart',
    ];
    for (final f in files) {
      expect(
        File(f).readAsStringSync(),
        matches(RegExp(r'AiDisclos(ureBar|ed)\(')),
        reason: '$f lacks the AI disclosure label',
      );
    }
    // Historical personas keep their own persistent recreation disclosure.
    expect(
      File(
        'lib/screens/personalities/personality_chat_screen.dart',
      ).readAsStringSync(),
      contains('_personaAiDisclosure'),
    );
  });
}
