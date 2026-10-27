import 'package:lingafriq/utils/api_service.dart';

/// POST `/api/v2/lexicon-verify/corrections` (P7-921).
const String lexiconCorrectionApiPath = '/api/v2/lexicon-verify/corrections';

const String lexiconCorrectionQueuePath = '/api/v2/lexicon-verify/corrections';

class LexiconCorrectionQueueItemDto {
  LexiconCorrectionQueueItemDto({
    required this.queueItemId,
    required this.source,
    required this.linkState,
    required this.lexemeId,
    required this.language,
    required this.surfaceLemma,
    required this.proposedGlossEn,
    required this.status,
    this.squarePostId,
    this.nativeCorrectionId,
  });

  final String queueItemId;
  final String source;
  final String linkState;
  final String? lexemeId;
  final String language;
  final String surfaceLemma;
  final String proposedGlossEn;
  final String status;
  final String? squarePostId;
  final String? nativeCorrectionId;

  factory LexiconCorrectionQueueItemDto.fromJson(Map<String, dynamic> json) {
    return LexiconCorrectionQueueItemDto(
      queueItemId: '${json['queue_item_id'] ?? ''}',
      source: '${json['source'] ?? ''}',
      linkState: '${json['link_state'] ?? ''}',
      lexemeId: json['lexeme_id'] as String?,
      language: '${json['language'] ?? ''}',
      surfaceLemma: '${json['surface_lemma'] ?? ''}',
      proposedGlossEn: '${json['proposed_gloss_en'] ?? ''}',
      status: '${json['status'] ?? ''}',
      squarePostId: json['square_post_id'] as String?,
      nativeCorrectionId: json['native_correction_id'] as String?,
    );
  }
}

typedef LexiconCorrectionPost = Future<Map<String, dynamic>> Function(
  String path, {
  Map<String, Object?>? data,
});

class LexiconCorrectionClient {
  LexiconCorrectionClient({LexiconCorrectionPost? post}) : _post = post ?? _defaultPost;

  final LexiconCorrectionPost _post;

  static Future<Map<String, dynamic>> _defaultPost(
    String path, {
    Map<String, Object?>? data,
  }) async {
    await ApiService.initialize();
    final response = await ApiService.post(path, data: data);
    final json = response.data;
    if (json is Map<String, dynamic>) {
      return json;
    }
    return <String, dynamic>{'ok': true};
  }

  Future<LexiconCorrectionQueueItemDto> submitFromNativeCorrections({
    required String language,
    required String surfaceLemma,
    required String proposedGlossEn,
    required String nativeCorrectionId,
    String actorAgeBand = 'unknown',
    String? lexemeIdHint,
  }) async {
    return _submit(
      source: 'native_corrections',
      language: language,
      surfaceLemma: surfaceLemma,
      proposedGlossEn: proposedGlossEn,
      actorAgeBand: actorAgeBand,
      nativeCorrectionId: nativeCorrectionId,
      lexemeIdHint: lexemeIdHint,
    );
  }

  Future<LexiconCorrectionQueueItemDto> submitFromSquare({
    required String language,
    required String surfaceLemma,
    required String proposedGlossEn,
    required String squarePostId,
    String actorAgeBand = 'unknown',
    String? lexemeIdHint,
  }) async {
    return _submit(
      source: 'square',
      language: language,
      surfaceLemma: surfaceLemma,
      proposedGlossEn: proposedGlossEn,
      actorAgeBand: actorAgeBand,
      squarePostId: squarePostId,
      lexemeIdHint: lexemeIdHint,
    );
  }

  Future<LexiconCorrectionQueueItemDto> _submit({
    required String source,
    required String language,
    required String surfaceLemma,
    required String proposedGlossEn,
    required String actorAgeBand,
    String? nativeCorrectionId,
    String? squarePostId,
    String? lexemeIdHint,
  }) async {
    final body = <String, Object?>{
      'source': source,
      'language': language,
      'surface_lemma': surfaceLemma.trim(),
      'proposed_gloss_en': proposedGlossEn.trim(),
      'actor_age_band': actorAgeBand,
      if (nativeCorrectionId != null) 'native_correction_id': nativeCorrectionId,
      if (squarePostId != null) 'square_post_id': squarePostId,
      if (lexemeIdHint != null && lexemeIdHint.trim().isNotEmpty)
        'lexeme_id_hint': lexemeIdHint.trim(),
    };
    final json = await _post(lexiconCorrectionApiPath, data: body);
    final item = json['queue_item'] as Map<String, dynamic>? ?? json;
    return LexiconCorrectionQueueItemDto.fromJson(item);
  }

  Future<List<LexiconCorrectionQueueItemDto>> fetchPendingQueue() async {
    await ApiService.initialize();
    final response = await ApiService.get(
      lexiconCorrectionQueuePath,
      queryParameters: const {'status': 'pending'},
    );
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      return const [];
    }
    final list = (json['corrections'] as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(LexiconCorrectionQueueItemDto.fromJson)
        .toList();
  }
}
