import 'package:flutter/foundation.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';
import 'package:lingafriq/services/quiz/item_graders.dart';
import 'package:lingafriq/utils/api_service.dart';

/// copy_keys: search.words (P7-925).
const String kSearchWordsSectionTitle = 'Words';

/// copy_keys: search.suggest (P7-925).
const String kSearchSuggestActionLabel = 'Suggest this word';

const String kSearchOfflineBanner = 'Showing results from your offline lexicon pack';

enum GlobalSearchResultKind {
  lexiconWord,
  lesson,
}

class GlobalSearchHit {
  const GlobalSearchHit({
    required this.kind,
    required this.title,
    this.subtitle,
    this.lexeme,
  });

  final GlobalSearchResultKind kind;
  final String title;
  final String? subtitle;
  final VerifiedLexeme? lexeme;

  factory GlobalSearchHit.lexicon(VerifiedLexeme lexeme) {
    final display = lexeme.standardOrthography.trim().isNotEmpty
        ? lexeme.standardOrthography.trim()
        : lexeme.lemma.trim();
    return GlobalSearchHit(
      kind: GlobalSearchResultKind.lexiconWord,
      title: display,
      subtitle: lexeme.lemma.trim().isNotEmpty && lexeme.lemma.trim() != display
          ? lexeme.lemma.trim()
          : null,
      lexeme: lexeme,
    );
  }

  factory GlobalSearchHit.lessonPlaceholder(String title) {
    return GlobalSearchHit(
      kind: GlobalSearchResultKind.lesson,
      title: title,
    );
  }
}

class LexiconSearchResult {
  const LexiconSearchResult({
    required this.query,
    required this.hits,
    required this.usedOfflinePack,
    required this.offlineOnly,
  });

  final String query;
  final List<GlobalSearchHit> hits;
  final bool usedOfflinePack;
  final bool offlineOnly;

  bool get hasLexiconHits =>
      hits.any((h) => h.kind == GlobalSearchResultKind.lexiconWord);

  bool get isEmpty => hits.isEmpty;
}

typedef LexiconRemoteSearch = Future<List<VerifiedLexeme>> Function(
  String languageCode,
  String query,
);

typedef GlobalSearchAncillaryFetch = Future<List<GlobalSearchHit>> Function(
  String languageCode,
  String query,
);

@visibleForTesting
bool lexiconSearchFieldMatches(String surface, String query) {
  final needle = foldAnswer(query.trim(), diacriticInsensitive: true);
  if (needle.isEmpty) return false;
  final haystack = foldAnswer(surface.trim(), diacriticInsensitive: true);
  if (haystack.isEmpty) return false;
  return haystack.startsWith(needle) || haystack.contains(needle);
}

@visibleForTesting
List<VerifiedLexeme> lexiconHitsFromPack({
  required List<LexiconPackEntry> entries,
  required String languageCode,
  required String query,
  int limit = 25,
}) {
  final out = <VerifiedLexeme>[];
  for (final row in entries) {
    if (!lexiconSearchFieldMatches(row.lemma, query) &&
        !lexiconSearchFieldMatches(row.standard, query)) {
      continue;
    }
    out.add(verifiedLexemeFromPackRow(row, languageCode: languageCode));
    if (out.length >= limit) break;
  }
  return out;
}

@visibleForTesting
List<GlobalSearchHit> orderGlobalSearchHits({
  required List<VerifiedLexeme> lexicon,
  required List<GlobalSearchHit> ancillary,
}) {
  final lexiconHits = lexicon.map(GlobalSearchHit.lexicon).toList();
  return [...lexiconHits, ...ancillary];
}

Future<List<VerifiedLexeme>> _defaultRemoteLexiconSearch(
  String languageCode,
  String query,
) async {
  await ApiService.initialize();
  try {
    final response = await ApiService.get(
      verifiedLexiconSearchPath,
      queryParameters: {
        'language': languageCode,
        'q': query.trim(),
        'limit': '25',
      },
    );
    if (response.statusCode != 200) return const [];
    final body = response.data;
    if (body is! Map) return const [];
    final entries = body['entries'];
    if (entries is! List) return const [];
    final out = <VerifiedLexeme>[];
    for (final row in entries) {
      if (row is Map<String, dynamic>) {
        out.add(VerifiedLexeme.fromApiJson(row));
      } else if (row is Map) {
        out.add(VerifiedLexeme.fromApiJson(row.cast<String, dynamic>()));
      }
    }
    return out;
  } catch (_) {
    return const [];
  }
}

class LexiconSearchService {
  LexiconSearchService({
    required this.languageCode,
    LexiconPackService? packService,
    LexiconRemoteSearch? remoteSearch,
    GlobalSearchAncillaryFetch? ancillarySearch,
    this.assumeOffline = false,
    this.resultLimit = 25,
  })  : _pack = packService,
        _remote = remoteSearch ?? _defaultRemoteLexiconSearch,
        _ancillary = ancillarySearch ?? _emptyAncillary;

  final String languageCode;
  final LexiconPackService? _pack;
  final LexiconRemoteSearch _remote;
  final GlobalSearchAncillaryFetch _ancillary;
  final bool assumeOffline;
  final int resultLimit;

  static Future<List<GlobalSearchHit>> _emptyAncillary(
    String languageCode,
    String query,
  ) async {
    return const [];
  }

  Future<LexiconSearchResult> search(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return LexiconSearchResult(
        query: query,
        hits: const [],
        usedOfflinePack: false,
        offlineOnly: false,
      );
    }

    final lang = lensProfileLanguageToLexiconCode(languageCode);
    final pack = _pack;
    final offlineLexicon = pack?.activePack == null
        ? <VerifiedLexeme>[]
        : lexiconHitsFromPack(
            entries: pack!.activePack!.entries,
            languageCode: lang,
            query: query,
            limit: resultLimit,
          );

    if (assumeOffline) {
      final ancillary = await _ancillary(lang, query);
      return LexiconSearchResult(
        query: query,
        hits: orderGlobalSearchHits(
          lexicon: offlineLexicon,
          ancillary: ancillary,
        ),
        usedOfflinePack: pack?.activePack != null,
        offlineOnly: true,
      );
    }

    List<VerifiedLexeme> remoteLexicon = const [];
    var remoteFailed = false;
    try {
      remoteLexicon = await _remote(lang, query);
    } catch (_) {
      remoteFailed = true;
    }

    final merged = <String, VerifiedLexeme>{};
    for (final row in offlineLexicon) {
      merged[row.lexemeId] = row;
    }
    for (final row in remoteLexicon) {
      if (lexiconSearchFieldMatches(row.lemma, query) ||
          lexiconSearchFieldMatches(row.standardOrthography, query)) {
        merged[row.lexemeId] = row;
      }
    }

    final lexiconList = merged.values.toList();
    final ancillary = await _ancillary(lang, query);
    final usedOffline = pack?.activePack != null && offlineLexicon.isNotEmpty;
    final offlineOnly = remoteFailed && usedOffline;

    return LexiconSearchResult(
      query: query,
      hits: orderGlobalSearchHits(lexicon: lexiconList, ancillary: ancillary),
      usedOfflinePack: usedOffline || offlineOnly,
      offlineOnly: offlineOnly,
    );
  }
}
