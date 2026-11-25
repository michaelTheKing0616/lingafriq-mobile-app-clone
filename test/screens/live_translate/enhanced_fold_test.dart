import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/ai_chat/enhanced_translation_screen.dart';
import 'package:lingafriq/screens/live_translate/enhanced_translation_parse.dart';
import 'package:lingafriq/screens/live_translate/enhanced_translation_sections.dart';
import 'package:lingafriq/screens/live_translate/live_translate_screen.dart';
import 'package:lingafriq/screens/ugc/ugc_enhanced_rules.dart';

void main() {
  const response = '''
Primary Translation: Bawo ni
Alternative Translations:
- E kaaro (morning)
Grammar Breakdown:
omo: noun - a child
Cultural Context: Used when greeting an elder in the family
Usage Note: Use the longer form with elders
''';

  test('structured reply keeps primary, alternative, grammar, and culture', () {
    final view = parseEnhancedTranslation(response, 'hello');
    expect(view.primary, 'Bawo ni');
    expect(view.alternatives, hasLength(1));
    expect(view.alternatives.single.translation, 'E kaaro (morning)');
    expect(view.alternatives.single.context, 'morning');
    final shown = view.grammar.where(enhancedGrammarRowVisible).toList();
    final child = shown.where((item) => item.word == 'omo').single;
    expect(child.partOfSpeech, 'noun');
    expect(child.explanation, 'a child');
    expect(
      view.cultural?.context,
      'Used when greeting an elder in the family',
    );
    expect(view.cultural?.usageNote, 'Use the longer form with elders');
  });

  test('plain caption stays plain and hides source-word grammar fallback', () {
    final view = parseEnhancedTranslation('Bawo ni', 'good morning');
    expect(view.primary, 'Bawo ni');
    expect(view.alternatives, isEmpty);
    expect(view.cultural, isNull);
    expect(view.grammar.map((item) => item.word), ['good', 'morning']);
    expect(view.grammar.every((item) => item.partOfSpeech == 'word'), isTrue);
    expect(view.grammar.where(enhancedGrammarRowVisible), isEmpty);
  });

  test('em dash after an alternative is kept as its context', () {
    final dash = String.fromCharCode(0x2014);
    final view = parseEnhancedTranslation(
      '- Bawo $dash informal hello',
      'hello',
    );
    expect(view.alternatives.single.context, 'informal hello');
  });

  test('length guard matches the enhanced screen bound', () {
    expect(enhancedTranslationMaxCharacters, 5000);
    expect(enhancedTranslationMaxRetries, 2);
    expect(enhancedTranslationTooLong('a' * 5000), isFalse);
    expect(enhancedTranslationTooLong('a' * 5001), isTrue);
    expect(
      enhancedTranslationTooLongMessage(),
      'Text is too long. Please use fewer than 5000 characters.',
    );
  });

  test('prompt still asks for the enhanced reply shape', () {
    final prompt = enhancedTranslationPrompt(
      sourceLanguage: 'english',
      targetLanguage: 'yoruba',
      text: 'hello',
    );
    expect(prompt, contains('from english to yoruba'));
    expect(prompt, contains('hello'));
    expect(prompt, contains('Primary Translation'));
    expect(prompt, contains('Alternative Translations'));
    expect(prompt, contains('Grammar Breakdown'));
    expect(prompt, contains('Cultural Context'));
    expect(prompt, contains('Usage Note'));
  });

  test('history entry uses the parsed fields', () {
    final view = parseEnhancedTranslation(response, 'hello');
    final entry = enhancedTranslationEntry(
      id: 'entry-1',
      sourceText: 'hello',
      sourceLanguage: 'english',
      targetLanguage: 'yoruba',
      view: view,
      timestamp: DateTime.utc(2026, 1, 2),
    );
    expect(entry.id, 'entry-1');
    expect(entry.primaryTranslation, 'Bawo ni');
    expect(entry.alternatives, hasLength(1));
    expect(entry.grammarBreakdown.where(enhancedGrammarRowVisible), isNotEmpty);
    expect(entry.culturalContext?.usageNote, 'Use the longer form with elders');
    expect(entry.sourceLanguage, 'english');
    expect(entry.targetLanguage, 'yoruba');
  });

  testWidgets('live sections show the harvested lines', (tester) async {
    final view = parseEnhancedTranslation(response, 'hello');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: EnhancedTranslationSections(view: view)),
      ),
    );
    expect(find.text('E kaaro (morning)'), findsOneWidget);
    expect(find.text('morning'), findsWidgets);
    expect(find.text('Grammar'), findsOneWidget);
    expect(find.text('omo'), findsOneWidget);
    expect(find.text('noun'), findsOneWidget);
    expect(find.text('a child'), findsOneWidget);
    expect(find.text('Culture'), findsOneWidget);
    expect(
      find.text('Used when greeting an elder in the family'),
      findsOneWidget,
    );
    expect(find.text('Use the longer form with elders'), findsOneWidget);
  });

  test('live translate screen is the translation survivor', () {
    const screen = LiveTranslateScreen(
      sourceLanguage: 'english',
      targetLanguage: 'yoruba',
      initialText: 'hello',
    );
    expect(screen.sourceLanguage, 'english');
    expect(screen.targetLanguage, 'yoruba');
    expect(screen.initialText, 'hello');
    const forwarded = EnhancedTranslationScreen(
      sourceLanguage: 'english',
      targetLanguage: 'yoruba',
      initialText: 'hello',
    );
    expect(forwarded.sourceLanguage, 'english');
    final live = File('lib/screens/live_translate/live_translate_screen.dart')
        .readAsStringSync();
    expect(live, contains('parseEnhancedTranslation'));
    expect(live, contains('enhancedTranslationEntry'));
    expect(live, contains('enhancedTranslationTooLong'));
    final wrapper =
        File('lib/screens/ai_chat/enhanced_translation_screen.dart')
            .readAsStringSync();
    expect(wrapper, contains('return LiveTranslateScreen('));
    expect(wrapper, isNot(contains('_extractPrimaryTranslation')));
  });

  test('quiz and story checks match the enhanced rules', () {
    final shortQuiz = checkEnhancedQuiz(
      title: 'Hi',
      description: '',
      questions: const [],
    );
    expect(shortQuiz.passed, isFalse);
    expect(shortQuiz.errors, isNot(contains('Quiz title is required.')));
    expect(shortQuiz.errors, contains('Quiz title should be at least 5 characters.'));
    expect(shortQuiz.errors, contains('Add at least one question.'));

    final emptyTitle = checkEnhancedQuiz(
      title: ' ',
      description: 'a description that is long enough',
      questions: const [],
    );
    expect(emptyTitle.errors, contains('Quiz title is required.'));
    expect(emptyTitle.badges, contains('Has description'));

    final readyQuiz = checkEnhancedQuiz(
      title: 'Market greetings',
      description: 'Ask how the yam price is today',
      questions: List<Map<String, dynamic>>.generate(
        5,
        (index) => {
          'question': 'Question $index',
          'options': ['a', 'b', 'c', 'd'],
          'correctAnswer': 1,
        },
      ),
    );
    expect(readyQuiz.passed, isTrue);
    expect(readyQuiz.badges, contains('Clear title'));
    expect(readyQuiz.badges, contains('Has description'));
    expect(readyQuiz.badges, contains('Rich quiz'));
    expect(readyQuiz.badges, contains('Validation passed'));

    final brokenQuestion = checkEnhancedQuiz(
      title: 'Market greetings',
      description: '',
      questions: const [
        {
          'question': '',
          'options': ['', 'b'],
          'correctAnswer': 9,
        },
      ],
    );
    expect(
      brokenQuestion.message,
      contains('Question 1: question text is required.'),
    );
    expect(brokenQuestion.message, contains('Question 1: must have 4 options.'));
    expect(brokenQuestion.message, contains('Question 1: option 1 is required.'));
    expect(
      brokenQuestion.message,
      contains('Question 1: select a valid correct answer.'),
    );
    expect(ugcPleaseFixValidation(), 'Please fix validation errors.');

    final shortStory = checkEnhancedStory(title: 'Hi', content: 'Too short');
    expect(shortStory.errors, contains('Story title should be at least 5 characters.'));
    expect(
      shortStory.errors,
      contains('Story content should be at least 50 characters.'),
    );
    final emptyStory = checkEnhancedStory(title: '', content: '');
    expect(emptyStory.errors, contains('Story title is required.'));
    expect(emptyStory.errors, contains('Story content is required.'));

    final richStory = checkEnhancedStory(
      title: 'Market morning',
      content: List<String>.filled(120, 'word').join(' '),
    );
    expect(richStory.passed, isTrue);
    expect(richStory.badges, contains('Clear title'));
    expect(richStory.badges, contains('Rich content'));
    expect(richStory.badges, contains('Detailed story'));
    expect(richStory.badges, contains('Validation passed'));
  });

  test('lesson badges and score follow the enhanced validation map', () {
    expect(lessonQualityBadges(null), isEmpty);
    expect(
      lessonQualityBadges({
        'grammarCheck': {'passed': true},
        'culturalCheck': {'passed': false},
        'canonicalCheck': {'passed': true},
        'overallScore': 80,
      }),
      ['grammatically_perfect', 'canonical_form'],
    );
    expect(
      lessonScoreLine({
        'overallScore': 80,
      }),
      'Score: 80/100',
    );
    expect(ugcPleaseEnterLessonContent(), 'Please enter lesson content');
    expect(ugcValidateContentLabel(), 'Validate Content');
    expect(ugcValidateStoryLabel(), 'Validate Story');
    expect(ugcQualityBadgesLabel(), 'Quality Badges');
    expect(ugcValidationSummaryLabel(), 'Validation Summary');
    expect(ugcViewValidationDetails(), 'View Validation Details');
    expect(ugcViewFullDetails(), 'View Full Details');
    final lesson = File('lib/screens/ugc/create_lesson_screen.dart').readAsStringSync();
    expect(lesson, contains('lessonQualityBadges'));
    expect(lesson, contains("'/user-content/validate'"));
    expect(lesson, contains('ugcValidateContentLabel'));
    final quiz = File('lib/screens/ugc/create_quiz_screen.dart').readAsStringSync();
    expect(quiz, contains('checkEnhancedQuiz'));
    final story = File('lib/screens/ugc/create_story_screen.dart').readAsStringSync();
    expect(story, contains('checkEnhancedStory'));
    expect(story, contains('ugcValidateStoryLabel'));
  });

  test('old enhanced bodies are gone and absent pairs stay absent', () {
    expect(
      File('lib/screens/ugc/create_quiz_screen_enhanced.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/screens/ugc/create_story_screen_enhanced.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/screens/ai_chat/conversation_enhanced_screen.dart').existsSync(),
      isFalse,
    );
    final lessonRedirect =
        File('lib/screens/ugc/create_lesson_screen_enhanced.dart')
            .readAsStringSync();
    expect(lessonRedirect, contains('extends CreateLessonScreen'));
    expect(lessonRedirect, isNot(contains('ApiService')));
    for (final folder in [
      'feed',
      'profile',
      'settings',
      'curriculum',
      'practice',
    ]) {
      final dir = Directory('lib/screens/$folder');
      final enhanced = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().contains('enhanced'));
      expect(enhanced, isEmpty, reason: folder);
    }
    expect(File('lib/screens/ai_chat/polie_workspace_screen.dart').existsSync(), isTrue);
    expect(File('lib/screens/feed/x_feed_home_screen.dart').existsSync(), isTrue);
    expect(
      File('lib/screens/profile/profile_screen_material3.dart').existsSync(),
      isTrue,
    );
    expect(
      File('lib/screens/settings/settings_screen_material3.dart').existsSync(),
      isTrue,
    );
    expect(
      File('lib/screens/lessons/lessons_map_entry_screen.dart').existsSync(),
      isTrue,
    );
    expect(
      File('lib/screens/practice/pronunciation_practice_screen.dart').existsSync(),
      isTrue,
    );
    final routes = File('lib/my_app.dart').readAsStringSync();
    expect(routes, isNot(contains('enhanced_translation_screen.dart')));
    expect(routes, isNot(contains('create_quiz_screen_enhanced')));
    expect(routes, isNot(contains('create_story_screen_enhanced')));
    expect(routes, isNot(contains('create_lesson_screen_enhanced')));
    expect(routes, contains("'ugc'"));
    expect(routes, contains('UGCHubScreen'));
  });
}
