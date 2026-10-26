import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/persona_grounding.dart';

Map<String, dynamic> _marketCard() => {
      'id': 'yo.culture.market_greeting',
      'title': 'Market greetings',
      'body': 'In many Yoruba markets, buyers greet sellers before asking prices.',
      'claims': [
        {
          'kind': 'cultural',
          'source_ref': 'curriculum/sources/fsi-yoruba-unit-3',
          'text': 'Greeting precedes price negotiation in market settings.',
          'confidence': 0.92,
          'confidence_floor': 0.85,
        },
      ],
    };

void main() {
  group('PersonaCultureGrounding', () {
    test('answer uses only cited culture card claims', () {
      final cards = PersonaCultureGrounding.parseCards([_marketCard()]);
      final outcome = PersonaCultureGrounding.answerFromCitedCards(
        question: 'How do greetings work in the market?',
        allowedCards: cards,
      );

      expect(outcome.status, PersonaGroundingStatus.answered);
      expect(
        outcome.answerText,
        'Greeting precedes price negotiation in market settings.',
      );
      expect(outcome.citations, hasLength(1));
      expect(outcome.citations.first.sourceRef,
          'curriculum/sources/fsi-yoruba-unit-3');
      expect(outcome.citations.first.claimId, 'yo.culture.market_greeting#0');
    });

    test('refuses when no supporting card matches question', () {
      final cards = PersonaCultureGrounding.parseCards([_marketCard()]);
      final outcome = PersonaCultureGrounding.answerFromCitedCards(
        question: 'Explain quantum field theory.',
        allowedCards: cards,
      );

      expect(outcome.isRefusal, isTrue);
      expect(outcome.citations, isEmpty);
      expect(outcome.answerText, PersonaCultureGrounding.refusalMessage);
    });

    test('claim-level citations available on grounded answer', () {
      final cards = PersonaCultureGrounding.parseCards([_marketCard()]);
      final outcome = PersonaCultureGrounding.answerFromCitedCards(
        question: 'negotiation greeting market',
        allowedCards: cards,
      );
      final validated = PersonaCultureGrounding.validateGroundedAnswer(
        answerText: outcome.answerText,
        citations: outcome.citations,
        allowedCards: cards,
      );

      expect(validated.status, PersonaGroundingStatus.answered);
      expect(validated.citations.first.claimText, isNotEmpty);
      expect(validated.citations.first.kind, 'cultural');
    });

    test('validate rejects invented citation source', () {
      final cards = PersonaCultureGrounding.parseCards([_marketCard()]);
      final bogus = ClaimCitation(
        claimId: 'yo.culture.market_greeting#0',
        cardId: 'yo.culture.market_greeting',
        sourceRef: 'invented/source',
        claimText: 'Greeting precedes price negotiation in market settings.',
        kind: 'cultural',
      );
      final outcome = PersonaCultureGrounding.validateGroundedAnswer(
        answerText: 'Greeting precedes price negotiation in market settings.',
        citations: [bogus],
        allowedCards: cards,
      );
      expect(outcome.isRefusal, isTrue);
    });
  });
}
