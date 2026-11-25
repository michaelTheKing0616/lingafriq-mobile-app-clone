import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lexicon_correction_client.dart';

void main() {
  test('parses linked correction queue item from API JSON', () {
    final dto = LexiconCorrectionQueueItemDto.fromJson({
      'queue_item_id': 'q-1',
      'source': 'square',
      'link_state': 'linked',
      'lexeme_id': 'sw.lex.habari.core',
      'language': 'sw',
      'surface_lemma': 'habari',
      'proposed_gloss_en': 'hello',
      'status': 'pending',
      'square_post_id': 'post-1',
    });
    expect(dto.queueItemId, 'q-1');
    expect(dto.linkState, 'linked');
    expect(dto.lexemeId, 'sw.lex.habari.core');
    expect(dto.squarePostId, 'post-1');
  });

  test('submitFromSquare posts expected body', () async {
    Map<String, Object?>? captured;
    final client = LexiconCorrectionClient(
      post: (path, {data}) async {
        captured = data;
        return {
          'queue_item': {
            'queue_item_id': 'q-2',
            'source': 'square',
            'link_state': 'unlinked',
            'language': 'sw',
            'surface_lemma': 'foo',
            'proposed_gloss_en': 'bar',
            'status': 'pending',
            'square_post_id': 'p-2',
          },
        };
      },
    );
    final row = await client.submitFromSquare(
      language: 'sw',
      surfaceLemma: 'foo',
      proposedGlossEn: 'bar',
      squarePostId: 'p-2',
      actorAgeBand: 'adult',
    );
    expect(captured?['source'], 'square');
    expect(row.linkState, 'unlinked');
    expect(captured?['square_post_id'], 'p-2');
    expect(captured?['actor_age_band'], 'adult');
  });
}
