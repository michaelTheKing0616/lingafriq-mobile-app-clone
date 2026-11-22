import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart';

import 'unified_onboarding_screen_test.dart' hide main;

/// English lines spoken on KijijiOnboardingScreen, in that screen's page order.
/// Form labels and the three self-report prompts are not part of the story.
const kijijiStoryEnglish = <String>[
  'Welcome to\nKijiji cha Lugha',
  'The Language Village\nYour journey begins here',
  'Welcome, traveler. I am Pa LingAfriq,\nkeeper of the village memory.',
  'Tell me: who are you?',
  'Why are you learning?',
  'I am Adisa, the Weaver.\nChoose the threads of your voice.',
  'I am Nuru the Rhythm Master.\nTap the drum that sings to your spirit.',
  'I am Zawadi, keeper of time.\nWhen shall we train your tongue?',
  'Choose your path.',
  'I am Amina the Griot.\nHow shall I speak to you?',
  'I am the Healer.\nLet me make your journey smooth.',
  'Build your clan.',
  'A learner without a name is a drum without a rhythm!\nTell us what you wish to be called.',
  'Let us see where you stand, traveler.',
];

const _selfReportPrompts = <String>[
  'How would you describe your familiarity',
  'Can you read or write in',
  'How confident are you in understanding',
];

Finder _line(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data == text || widget.data == '\u2066$text\u2069'),
  description: 'story line',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('village story lines are the Kijiji dialogue in screen order', () {
    final lines = kijijiVillageStoryLines(
      lookupAppLocalizations(const Locale('en')),
    );
    expect(lines, kijijiStoryEnglish);
    final joined = lines.join('\n');
    expect(joined.contains('\u2014'), isFalse);
    expect(joined.toLowerCase().contains('world-class'), isFalse);
    expect(joined.toLowerCase().contains('elite'), isFalse);
    expect(joined.toLowerCase().contains('seamless'), isFalse);
    for (final prompt in _selfReportPrompts) {
      expect(joined.contains(prompt), isFalse, reason: prompt);
    }
  });

  testWidgets(
    'village story is an optional panel on the unified welcome step',
    (tester) async {
      await pumpOnboarding(tester, reducedMotion: true);
      await settleOnce(tester);

      expect(find.byKey(const ValueKey('village-story-panel')), findsNothing);
      expect(label('Get started'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('village-story-open')));
      await tester.pump();

      expect(find.byType(KijijiVillageStoryPanel), findsOneWidget);
      for (final line in kijijiStoryEnglish) {
        expect(_line(line), findsOneWidget, reason: line);
      }
      expect(label('Get started').hitTestable(), findsNothing);
      expect(
        find.byKey(const ValueKey('village-story-close')).hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('village-story-close')));
      await tester.pump();

      expect(find.byKey(const ValueKey('village-story-panel')), findsNothing);
      expect(label('Get started'), findsOneWidget);
      expect(label('Yoruba'), findsNothing);
    },
  );

  test(
    'old onboarding variants are archived and routes use the unified screen',
    () {
      const moved = <String>[
        'kijiji_onboarding_screen.dart',
        'enhanced_onboarding_flow_screen.dart',
        'modern_onboarding_screen.dart',
        'onboarding_screen.dart',
        'onboarding_screen_material3.dart',
        'placement_quiz_screen.dart',
      ];
      for (final name in moved) {
        expect(
          File('lib/screens/onboarding/$name').existsSync(),
          isFalse,
          reason: name,
        );
        expect(
          File('legacy/onboarding/$name').existsSync(),
          isTrue,
          reason: name,
        );
      }
      expect(
        File('lib/screens/onboarding/placement_test_screen.dart').existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/screens/onboarding/unified_onboarding_screen.dart',
        ).readAsStringSync(),
        contains('PlacementTestScreen'),
      );

      final banned = RegExp(
        r'\b(KijijiOnboardingScreen|EnhancedOnboardingFlowScreen|ModernOnboardingScreen|OnboardingScreenMaterial3|PlacementQuizScreen)\b|\bclass OnboardingScreen\b',
      );
      final lib = Directory('lib');
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        expect(banned.hasMatch(text), isFalse, reason: entity.path);
      }

      for (final path in const [
        'lib/providers/auth_provider.dart',
        'lib/screens/auth/sign_in_options.dart',
        'lib/services/passkey_service.dart',
      ]) {
        final text = File(path).readAsStringSync();
        expect(text, contains('UnifiedOnboardingScreen'), reason: path);
        expect(
          text.contains('OnboardingScreenMaterial3'),
          isFalse,
          reason: path,
        );
      }

      final routes = File('lib/my_app.dart').readAsStringSync();
      expect(banned.hasMatch(routes), isFalse);
    },
  );
}
