import 'package:lingafriq/utils/api_service.dart';

/// POST `/api/v2/lexicon-verify/suggestions` (P7-920).
const String lexiconSuggestApiPath = '/api/v2/lexicon-verify/suggestions';

const String lexiconVerifyQueuePath = '/api/v2/lexicon-verify/suggestions';

/// copy_keys: verify.pending, verify.approve, verify.reject
const String verifyPendingKey = 'verify.pending';
const String verifyApproveKey = 'verify.approve';
const String verifyRejectKey = 'verify.reject';

class LexiconSuggestionDto {
  LexiconSuggestionDto({
    required this.suggestionId,
    required this.language,
    required this.lemma,
    required this.glossEn,
    required this.status,
    required this.lexemeId,
    this.suggesterCreditKind,
    this.suggesterCreditName,
  });

  final String suggestionId;
  final String language;
  final String lemma;
  final String glossEn;
  final String status;
  final String lexemeId;
  final String? suggesterCreditKind;
  final String? suggesterCreditName;

  factory LexiconSuggestionDto.fromJson(Map<String, dynamic> json) {
    final credit = json['suggester_credit'] as Map<String, dynamic>?;
    return LexiconSuggestionDto(
      suggestionId: '${json['suggestion_id'] ?? ''}',
      language: '${json['language'] ?? ''}',
      lemma: '${json['lemma'] ?? ''}',
      glossEn: '${json['gloss_en'] ?? ''}',
      status: '${json['status'] ?? ''}',
      lexemeId: '${json['lexeme_id'] ?? ''}',
      suggesterCreditKind: credit?['kind'] as String?,
      suggesterCreditName: credit?['display_name'] as String?,
    );
  }
}

typedef LexiconSuggestPost = Future<Map<String, dynamic>> Function(
  String path, {
  Map<String, Object?>? data,
});

class LexiconSuggestClient {
  LexiconSuggestClient({LexiconSuggestPost? post}) : _post = post ?? _defaultPost;

  final LexiconSuggestPost _post;

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

  Future<LexiconSuggestionDto> submitSuggestion({
    required String language,
    required String lemma,
    required String glossEn,
    bool creditOptOut = false,
    String suggesterAgeBand = 'unknown',
    String? suggesterDisplayName,
  }) async {
    final body = <String, Object?>{
      'language': language,
      'lemma': lemma.trim(),
      'gloss_en': glossEn.trim(),
      'credit_opt_out': creditOptOut,
      'suggester_age_band': suggesterAgeBand,
      if (suggesterDisplayName != null && suggesterDisplayName.trim().isNotEmpty)
        'suggester_display_name': suggesterDisplayName.trim(),
    };
    final json = await _post(lexiconSuggestApiPath, data: body);
    final suggestion = json['suggestion'] as Map<String, dynamic>? ?? json;
    return LexiconSuggestionDto.fromJson(suggestion);
  }

  Future<List<LexiconSuggestionDto>> fetchPendingQueue() async {
    await ApiService.initialize();
    final response = await ApiService.get(
      lexiconVerifyQueuePath,
      queryParameters: const {'status': 'pending'},
    );
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      return const [];
    }
    final list = (json['suggestions'] as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(LexiconSuggestionDto.fromJson)
        .toList();
  }

  Future<LexiconSuggestionDto> approve(String suggestionId) async {
    final json = await _post(
      '$lexiconVerifyQueuePath/$suggestionId/approve',
      data: const <String, Object?>{},
    );
    final suggestion = json['suggestion'] as Map<String, dynamic>? ?? json;
    return LexiconSuggestionDto.fromJson(suggestion);
  }

  Future<LexiconSuggestionDto> reject(String suggestionId) async {
    final json = await _post(
      '$lexiconVerifyQueuePath/$suggestionId/reject',
      data: const <String, Object?>{},
    );
    final suggestion = json['suggestion'] as Map<String, dynamic>? ?? json;
    return LexiconSuggestionDto.fromJson(suggestion);
  }
}
