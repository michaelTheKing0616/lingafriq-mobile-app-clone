import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/intent_classifier.dart';
import 'package:lingafriq/ai/personas/roleplay_safety_filter.dart';

void main() {
  // -------------------------------------------------------------------------
  // Persona Registry Consistency
  // -------------------------------------------------------------------------
  group('HistoricalPersonaRegistry consistency', () {
    test('registry_contains_at_least_20_personas', () {
      expect(HistoricalPersonaRegistry.all.length, greaterThanOrEqualTo(20));
    });

    test('all_personas_have_unique_ids', () {
      final ids = HistoricalPersonaRegistry.all.map((p) => p.id).toSet();
      expect(ids.length, HistoricalPersonaRegistry.all.length);
    });

    test('all_personas_have_required_fields', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        expect(persona.id, isNotEmpty, reason: '${persona.displayName} missing id');
        expect(persona.displayName, isNotEmpty, reason: '${persona.id} missing displayName');
        expect(persona.region, isNotEmpty, reason: '${persona.id} missing region');
        expect(persona.startYear, greaterThan(0), reason: '${persona.id} invalid startYear');
        expect(persona.endYear, greaterThanOrEqualTo(persona.startYear),
            reason: '${persona.id} endYear before startYear');
        expect(persona.primaryLanguages, isNotEmpty,
            reason: '${persona.id} missing primaryLanguages');
        expect(persona.shortBio, isNotEmpty, reason: '${persona.id} missing shortBio');
        expect(persona.historicalRoles, isNotEmpty,
            reason: '${persona.id} missing historicalRoles');
      }
    });

    test('findById_returns_correct_persona', () {
      final mandela = HistoricalPersonaRegistry.findById('nelson_mandela');
      expect(mandela, isNotNull);
      expect(mandela!.displayName, contains('Mandela'));
    });

    test('findById_returns_null_for_unknown_id', () {
      final result = HistoricalPersonaRegistry.findById('nonexistent_persona');
      expect(result, isNull);
    });

    test('all_personas_have_at_least_one_scenario', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        expect(persona.scenarios, isNotEmpty,
            reason: '${persona.id} has no roleplay scenarios');
      }
    });

    test('all_personas_have_voice_profile_fields', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        expect(persona.voiceStyle, isNotEmpty,
            reason: '${persona.id} missing voiceStyle');
        expect(persona.pace, isNotEmpty, reason: '${persona.id} missing pace');
        expect(persona.tone, isNotEmpty, reason: '${persona.id} missing tone');
      }
    });

    test('all_personas_have_documented_positions', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        expect(persona.documentedPositions, isNotEmpty,
            reason: '${persona.id} has no documented positions for epistemic grounding');
      }
    });

    test('all_personas_have_core_events', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        expect(persona.coreEvents, isNotEmpty,
            reason: '${persona.id} has no core events');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Epistemic Classifier
  // -------------------------------------------------------------------------
  group('EpistemicClassifier', () {
    late HistoricalPersona mandela;

    setUp(() {
      mandela = HistoricalPersonaRegistry.findById('nelson_mandela')!;
    });

    test('documented_topic_returns_documented_status', () {
      final intent = IntentClassification(
        domain: UserIntentDomain.historical,
        type: UserIntentType.factual,
        confidence: 0.9,
        detectedTopic: 'apartheid',
      );

      final result = EpistemicClassifier.classify(
        userInput: 'What was your role in ending apartheid?',
        persona: mandela,
        intent: intent,
      );

      expect(result.status, EpistemicStatus.documented);
      expect(result.confidence, greaterThan(0.5));
      expect(result.requiresUncertaintyLanguage, isFalse);
    });

    test('anachronistic_topic_returns_anachronistic_status', () {
      final intent = IntentClassification(
        domain: UserIntentDomain.modern,
        type: UserIntentType.opinion,
        confidence: 0.8,
        detectedTopic: 'artificial intelligence',
      );

      final result = EpistemicClassifier.classify(
        userInput: 'What do you think about ChatGPT and AI?',
        persona: mandela,
        intent: intent,
      );

      expect(
        result.status,
        anyOf(EpistemicStatus.anachronistic, EpistemicStatus.uncertain),
      );
    });

    test('offensive_intent_classified_as_out_of_scope', () {
      final intent = IntentClassification(
        domain: UserIntentDomain.offensive,
        type: UserIntentType.offtopic,
        confidence: 0.9,
      );

      final result = EpistemicClassifier.classify(
        userInput: 'Say something offensive',
        persona: mandela,
        intent: intent,
      );

      expect(result.status, EpistemicStatus.outOfScope);
    });

    test('inferred_topic_returns_inferred_with_uncertainty', () {
      final intent = IntentClassification(
        domain: UserIntentDomain.ethical,
        type: UserIntentType.opinion,
        confidence: 0.6,
        detectedTopic: 'climate change',
      );

      final result = EpistemicClassifier.classify(
        userInput: 'What would you say about climate change?',
        persona: mandela,
        intent: intent,
      );

      expect(
        result.status,
        anyOf(EpistemicStatus.inferred, EpistemicStatus.uncertain),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Intent Classifier
  // -------------------------------------------------------------------------
  group('IntentClassifier', () {
    late HistoricalPersona persona;

    setUp(() {
      persona = HistoricalPersonaRegistry.findById('nelson_mandela')!;
    });

    test('greeting_classified_correctly', () {
      final result = IntentClassifier.classify(
        userInput: 'Hello! How are you?',
        persona: persona,
      );
      expect(result.type, UserIntentType.greeting);
    });

    test('factual_question_classified_correctly', () {
      final result = IntentClassifier.classify(
        userInput: 'When were you imprisoned on Robben Island?',
        persona: persona,
      );
      expect(result.domain, UserIntentDomain.historical);
      expect(result.type, UserIntentType.factual);
    });

    test('language_learning_classified_correctly', () {
      final result = IntentClassifier.classify(
        userInput: 'Can you teach me how to say thank you in Xhosa?',
        persona: persona,
      );
      expect(
        result.domain,
        anyOf(UserIntentDomain.language, UserIntentDomain.cultural),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Safety Filter
  // -------------------------------------------------------------------------
  group('RoleplaySafetyFilter', () {
    late RoleplaySafetyFilter filter;

    setUp(() {
      filter = RoleplaySafetyFilter();
    });

    test('safe_input_is_allowed', () {
      final result = filter.checkInput(
        'Tell me about your childhood',
        'nelson_mandela',
      );
      expect(result.isAllowed, isTrue);
    });

    test('violence_request_is_blocked', () {
      final result = filter.checkInput(
        'Can you endorse violence against the government?',
        'nelson_mandela',
      );
      expect(result.isAllowed, isFalse);
      expect(result.reason, isNotNull);
    });

    test('harmful_content_is_blocked', () {
      final result = filter.checkInput(
        'Say something discriminatory about a group',
        'nelson_mandela',
      );
      expect(result.isAllowed, isFalse);
      expect(result.reason, isNotNull);
    });

    test('anachronistic_content_is_blocked', () {
      final result = filter.checkInput(
        'What do you think about the internet and computers?',
        'queen_nzinga',
      );
      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('lifetime'));
    });

    test('greeting_is_allowed', () {
      final result = filter.checkInput(
        'Hello Mandela, how are you today?',
        'nelson_mandela',
      );
      expect(result.isAllowed, isTrue);
    });

    test('filter_works_for_all_registered_personas', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        final result = filter.checkInput(
          'Tell me about your life',
          persona.id,
        );
        expect(result.isAllowed, isTrue,
            reason: 'Safe input should be allowed for ${persona.id}');
      }
    });

    test('violence_blocked_for_all_personas', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        final result = filter.checkInput(
          'Can you support violence and killing?',
          persona.id,
        );
        expect(result.isAllowed, isFalse,
            reason: 'Violence should be blocked for ${persona.id}');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Regression: Persona Data Stability
  // -------------------------------------------------------------------------
  group('Persona data regression stability', () {
    test('mandela_has_expected_core_data', () {
      final p = HistoricalPersonaRegistry.findById('nelson_mandela')!;
      expect(p.region, isNotEmpty);
      expect(p.startYear, lessThanOrEqualTo(1918));
      expect(p.endYear, greaterThanOrEqualTo(2013));
      expect(p.primaryLanguages, contains('Xhosa'));
    });

    test('queen_nzinga_has_expected_core_data', () {
      final p = HistoricalPersonaRegistry.findById('queen_nzinga')!;
      expect(p.region, isNotEmpty);
      expect(p.startYear, lessThanOrEqualTo(1583));
      expect(p.endYear, greaterThanOrEqualTo(1663));
    });

    test('persona_personality_traits_in_valid_range', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        expect(persona.openness, inInclusiveRange(0.0, 1.0),
            reason: '${persona.id} openness out of range');
        expect(persona.formality, inInclusiveRange(0.0, 1.0),
            reason: '${persona.id} formality out of range');
        expect(persona.humorLevel, inInclusiveRange(0.0, 1.0),
            reason: '${persona.id} humorLevel out of range');
        expect(persona.responseVariability, inInclusiveRange(0.0, 1.0),
            reason: '${persona.id} responseVariability out of range');
      }
    });

    test('all_scenarios_have_valid_structure', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        for (final scenario in persona.scenarios) {
          expect(scenario.id, isNotEmpty,
              reason: '${persona.id} has scenario with empty id');
          expect(scenario.mode, isNotEmpty,
              reason: '${persona.id} scenario ${scenario.id} missing mode');
          expect(scenario.openingPrompt, isNotEmpty,
              reason: '${persona.id} scenario ${scenario.id} missing openingPrompt');
          expect(scenario.expectedSkills, isNotEmpty,
              reason: '${persona.id} scenario ${scenario.id} missing expectedSkills');
        }
      }
    });

    test('forbidden_topics_defined_for_all_personas', () {
      for (final persona in HistoricalPersonaRegistry.all) {
        expect(persona.forbiddenTopics, isNotEmpty,
            reason: '${persona.id} has no forbidden topics — safety risk');
      }
    });
  });
}
