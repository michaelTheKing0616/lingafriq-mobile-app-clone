import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';

void main() {
  final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

  test('legacy mode ids map onto Polie modes', () {
    expect(polieModeForLegacyChatId('tutor'), PolieMode.tutor);
    expect(polieModeForLegacyChatId('translate'), PolieMode.translation);
    expect(polieModeForLegacyChatId('translation'), PolieMode.translation);
    expect(polieModeForLegacyChatId('story'), PolieMode.roleplay);
    expect(polieModeForLegacyChatId('stories'), PolieMode.roleplay);
    expect(polieModeForLegacyChatId('roleplay'), PolieMode.roleplay);
    expect(polieModeForLegacyChatId('dialogue'), PolieMode.conversation);
    expect(polieModeForLegacyChatId('conversation'), PolieMode.conversation);
    expect(polieModeForLegacyChatId('vocab'), PolieMode.vocab);
    expect(polieModeForLegacyChatId('vocabulary'), PolieMode.vocab);
    expect(polieModeForLegacyChatId('assess'), PolieMode.review);
    expect(polieModeForLegacyChatId('assessment'), PolieMode.review);
    expect(polieModeForLegacyChatId('review'), PolieMode.review);
    expect(polieModeForLegacyChatId('pronunciation'), PolieMode.pronunciation);
    expect(polieModeForLegacyChatId('explain'), PolieMode.grammar);
    expect(polieModeForLegacyChatId('grammar'), PolieMode.grammar);
    expect(polieModeForLegacyChatId('unknown'), PolieMode.tutor);
  });

  test('surprise me uses the eight-item picker, twice for review', () {
    expect(polieLegacyModeIds, hasLength(8));
    expect(
      polieLegacyModeIds.where((String id) => id == 'review'),
      hasLength(2),
    );
    final PolieMode raw = surprisePolieMode(Random(1));
    expect(polieLegacyModeIds.map(polieModeForLegacyChatId), contains(raw));
    for (var seed = 0; seed < 20; seed++) {
      final PolieMode surfaced = surprisePolieModeOnSurface(Random(seed));
      expect(polieModesWithSurface, contains(surfaced));
      expect(surfaced, isNot(PolieMode.grammar));
      expect(surfaced, isNot(PolieMode.pronunciation));
    }
  });

  test('progress button follows the tracking chat switch', () {
    expect(
      polieProgressDashboardForMode(PolieMode.conversation),
      PolieProgressDashboard.conversation,
    );
    expect(
      polieProgressDashboardForMode(PolieMode.tutor),
      PolieProgressDashboard.tutor,
    );
    expect(
      polieProgressDashboardForMode(PolieMode.roleplay),
      PolieProgressDashboard.roleplay,
    );
    expect(
      polieProgressDashboardForMode(PolieMode.vocab),
      PolieProgressDashboard.vocabulary,
    );
    expect(
      polieProgressDashboardForMode(PolieMode.review),
      PolieProgressDashboard.review,
    );
    expect(polieProgressDashboardForMode(PolieMode.translation), isNull);
    expect(polieProgressDashboardForMode(PolieMode.grammar), isNull);
    expect(polieProgressDashboardForMode(PolieMode.pronunciation), isNull);
  });

  test('tracking session counts words, topics, and vocabulary', () {
    final PolieChatTrackingSession session = PolieChatTrackingSession();
    session.begin(DateTime.utc(2026, 1, 2));
    session.recordUserMessage('Hello family');
    session.recordAssistantText('We can talk about travel and food.');
    expect(session.messageCount, 1);
    expect(session.wordCount, 2);
    expect(session.vocabularyUsed['hello'], 1);
    expect(session.topics, containsAll(<String>['travel', 'food']));
    session.recordError();
    expect(session.errors, 1);
  });

  test('auto-correction keeps a different sentence and drops CORRECT', () {
    expect(polieAutoCorrectionDiffers('helo', 'hello'), isTrue);
    expect(polieAutoCorrectionDiffers('hello', 'CORRECT'), isFalse);
    expect(polieAutoCorrectionDiffers('Hello', 'hello'), isFalse);
    expect(polieAutoCorrectionDiffers('hello', '  '), isFalse);
  });

  test('topic chips prefer related topics, then other top topics', () {
    final List<String> merged = polieMergeTopicSuggestions(
      message: 'I want food tonight',
      allTopics: <String>['Food & Dining', 'Weather', 'Work'],
      topTopics: <String>['Weather', 'Food & Dining', 'Health'],
      current: <String>['Greetings'],
    );
    expect(merged.first, 'Food & Dining');
    expect(merged, contains('Weather'));
    expect(merged, contains('Health'));
    expect(
      polieMergeTopicSuggestions(
        message: 'hi',
        allTopics: <String>['Food & Dining'],
        topTopics: <String>['Weather'],
        current: <String>['Greetings'],
      ),
      <String>['Greetings'],
    );
  });

  test('fallback topics match the enhanced conversation list', () {
    expect(polieFallbackTopics(en), <String>[
      'Greetings',
      'Food & Dining',
      'Travel',
      'Shopping',
      'Weather',
      'Hobbies',
      'Family',
      'Work',
      'Health',
      'Culture',
    ]);
  });

  test('tutor turn draft uses keyword topics and a neutral score', () {
    final PolieTutorTurnDraft draft = polieTutorTurnDraft(
      userInput: 'How does this verb work?',
      response: 'Check the tense and the word order.',
      hasBackendEvaluator: false,
      names: polieTutorTopicNames(en),
    );
    expect(draft.type, 'question');
    expect(draft.score, isNull);
    expect(draft.topics, contains('Grammar'));
    expect(draft.grammar, contains('Tense'));
    expect(draft.grammar, contains('Word order'));
    expect(draft.metadata['scoring_mode'], 'neutral');
    expect(draft.metadata['is_scored'], isFalse);
  });

  test('roleplay turn note keeps vocabulary and a correction line', () {
    final PolieRoleplayTurnNote note = polieRoleplayTurnNote(
      'two plantain',
      'Correction: the plural should be plantains.',
    );
    expect(note.vocabulary, <String>['two', 'plantain']);
    expect(note.grammar, contains('plural'));
    expect(note.correction, contains('should be'));
  });

  testWidgets('conversation bar toggles auto-correction and fills a topic', (
    WidgetTester tester,
  ) async {
    final PolieHarvestController controller = PolieHarvestController();
    final TextEditingController input = TextEditingController();
    controller.topicSuggestions.value = <String>['Market'];
    addTearDown(controller.dispose);
    addTearDown(input.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PolieEnhancedConversationBar(
            controller: controller,
            input: input,
            topicPrompt: en.polieLetsTalkAbout,
            correctionOnLabel: en.polieAutoCorrectionOn,
            correctionOffLabel: en.polieAutoCorrectionOff,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('polie-enhanced-conversation')), findsOneWidget);
    expect(controller.autoCorrectionEnabled.value, isTrue);
    await tester.tap(find.byKey(const ValueKey<String>('polie-auto-correction')));
    await tester.pump();
    expect(controller.autoCorrectionEnabled.value, isFalse);
    await tester.tap(find.byKey(const ValueKey<String>('polie-topic-Market')));
    await tester.pump();
    expect(input.text, "Let's talk about Market");
    expect(controller.currentTopic.value, 'Market');
  });

  testWidgets('correction line follows the auto-correction toggle', (
    WidgetTester tester,
  ) async {
    final PolieHarvestController controller = PolieHarvestController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: PolieConversationCorrectionLine(
          harvest: controller,
          hasCorrection: true,
          feedbackLine: 'Try again',
          correction: 'hello',
          feedbackStyle: const TextStyle(),
          correctionStyle: const TextStyle(),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
    controller.autoCorrectionEnabled.value = false;
    await tester.pump();
    expect(find.text('hello'), findsNothing);
  });

  test('ai_chat_select builds the Polie workspace, not the old picker', () {
    final String myApp = File('lib/my_app.dart').readAsStringSync();
    expect(myApp, contains('polieWorkspaceForLegacyChatRoute()'));
    expect(myApp, isNot(contains('AIModeSelectionScreen')));
    expect(myApp, isNot(contains('ai_mode_selection_screen.dart')));
    expect(myApp, isNot(contains('ai_chat_screen.dart')));
    expect(myApp, isNot(contains('ai_chat_screen_new.dart')));
    expect(myApp, isNot(contains('ai_chat_screen_with_tracking.dart')));
    expect(myApp, isNot(contains('conversation_enhanced_screen.dart')));
    expect(File('legacy/ai_chat/ai_mode_selection_screen.dart').existsSync(), isTrue);
    expect(File('lib/screens/ai_chat/ai_chat_screen.dart').existsSync(), isFalse);
    expect(File('lib/screens/ai_chat/ai_chat_screen_new.dart').existsSync(), isFalse);
    expect(
      File('lib/screens/ai_chat/ai_chat_screen_with_tracking.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/screens/ai_chat/conversation_enhanced_screen.dart').existsSync(),
      isFalse,
    );
  });

  test('workspace wires the harvested controls', () {
    final String composer = File(
      'lib/features/polie_workspace/mode_surface/polie_workspace_mode_conversation_composer.dart',
    ).readAsStringSync();
    final String scaffold = File(
      'lib/features/polie_workspace/build_host/polie_workspace_build_host_scaffold.dart',
    ).readAsStringSync();
    final String send = File(
      'lib/features/polie_workspace/build_host/polie_workspace_host_handlers_4.dart',
    ).readAsStringSync();
    expect(composer, contains('PolieEnhancedConversationBar'));
    expect(scaffold, contains('surprisePolieModeOnSurface'));
    expect(scaffold, contains('onboardingConversation'));
    expect(scaffold, contains('polie-progress'));
    expect(scaffold, contains('flushConversationTracking'));
    expect(send, contains('noteConversationUserTurn'));
  });
}
