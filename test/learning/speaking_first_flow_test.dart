import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/speaking/speaking_first_flow_policy.dart';

void main() {
  group('session one speak-first', () {
    test('first interaction is speak', () {
      expect(firstInteractionForSession(1), LessonInteractionKind.speak);
      expect(firstInteractionForSession(2), LessonInteractionKind.listen);
    });

    test('default plan starts with speak', () {
      expect(sessionOneStartsWithSpeak(sessionOneSpeakingFirstPlan), isTrue);
      expect(
        sessionOneStartsWithSpeak(const [
          LessonInteractionKind.readPassage,
          LessonInteractionKind.speak,
        ]),
        isFalse,
      );
    });
  });

  group('polie recasts', () {
    test('only recast style is allowed on errors', () {
      expect(polieErrorStyleAllowed(PolieCorrectionStyle.recast), isTrue);
      expect(polieErrorStyleAllowed(PolieCorrectionStyle.ruleDump), isFalse);
      expect(polieErrorStyleAllowed(PolieCorrectionStyle.explicitMarking), isFalse);
    });

    test('detects grammar rule dumps', () {
      expect(
        looksLikeGrammarRuleDump('The rule is that verbs must agree.'),
        isTrue,
      );
      expect(
        isRecastReply(
          reply: 'Try: Mo n lọ sí ọjà.',
          targetLanguageExcerpt: 'Mo n lọ sí ọjà',
        ),
        isTrue,
      );
      expect(
        isRecastReply(
          reply: 'Incorrect because you used the wrong tense.',
          targetLanguageExcerpt: 'Mo n lọ',
        ),
        isFalse,
      );
    });
  });

  group('text budget', () {
    test('flags text-heavy screens', () {
      final longBody = List.filled(50, 'word').join(' ');
      expect(
        screenIsTextHeavy(instructionText: 'Say this phrase.', bodyText: longBody),
        isTrue,
      );
      expect(
        screenIsTextHeavy(
          instructionText: 'Hold to speak.',
          bodyText: 'Repeat after Polie.',
        ),
        isFalse,
      );
    });
  });

  group('step ordering', () {
    test('places speak before readPassage when needed', () {
      final ordered = orderSpeakingBeforeReading(const [
        LessonInteractionKind.choose,
        LessonInteractionKind.readPassage,
        LessonInteractionKind.speak,
      ]);
      expect(ordered.indexOf(LessonInteractionKind.speak),
          lessThan(ordered.indexOf(LessonInteractionKind.readPassage)));
    });
  });

  test('spec documents speak-first, recast, and text budgets', () {
    final spec = File('docs/build/specs/P5-038-speaking-first-flow.md').readAsStringSync();
    expect(spec.contains('sessionOneStartsWithSpeak'), isTrue);
    expect(spec.contains('polieErrorStyleAllowed'), isTrue);
    expect(spec.contains('screenIsTextHeavy'), isTrue);
    expect(spec.contains('recast'), isTrue);
  });
}
