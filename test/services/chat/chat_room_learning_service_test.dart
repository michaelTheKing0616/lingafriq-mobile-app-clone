import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/chat/chat_room_learning_service.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';

void main() {
  test('message check parses tutor_correct JSON', () async {
    final service = ChatRoomLearningService(
      languageCode: 'yo',
      learnerUserId: 'u1',
      messageCheck: ({
        required draftText,
        required languageCode,
      }) async {
        expect(languageCode, 'yo');
        return ChatMessageCheckResult(
          originalText: draftText,
          suggestedText: 'Mo n ṣe',
          explanation: 'Verb tone tweak',
        );
      },
    );

    final result = await service.checkMessageBeforeSend('Mo n se');
    expect(result.hasSuggestion, isTrue);
    expect(result.suggestedText, 'Mo n ṣe');
  });

  test('peer language status hidden when policy blocks minors', () async {
    final service = ChatRoomLearningService(
      languageCode: 'yo',
      learnerUserId: 'u1',
      policyFetch: () async =>
          ChatLearningSurfacePolicy.hiddenForMinorOrUnknownAge,
      peerStatusFetch: (_) async => [
        const ChatLanguageStatusEntry(
          languageCode: 'yo',
          role: ChatLanguageRole.learning,
          visibleToViewer: true,
          displayName: 'Yoruba',
        ),
      ],
    );

    final rows = await service.fetchPeerLanguageStatus(42);
    expect(rows, isEmpty);
  });

  test('saveWordToReview enrols FSRS id chat:lexeme', () async {
    final service = ChatRoomLearningService(
      languageCode: 'yo',
      learnerUserId: 'learner-1',
    );
    const lookup = LexiconLookupResult(
      kind: LexiconLookupKind.hit,
      surface: 'ọkọ',
      lexeme: VerifiedLexeme(
        lexemeId: 'yo-lex-1',
        language: 'yo',
        verificationStatus: 'expert_reviewed',
        lemma: 'ọkọ',
        standardOrthography: 'ọkọ',
        exampleSentence: null,
        audioUris: const [],
        raw: const {},
      ),
      resolvedLemma: 'ọkọ',
    );

    final first = await service.saveWordToReview(lookup: lookup);
    expect(first.itemId, 'chat:yo-lex-1');
    expect(first.created, isTrue);

    final second = await service.saveWordToReview(lookup: lookup);
    expect(second.created, isFalse);
  });
}
