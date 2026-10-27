import 'package:flutter/foundation.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';
import 'package:lingafriq/utils/api_service.dart';

/// copy_keys: wordcard.notfound (P7-923).
const String kWordCardNotFoundCopyKey = 'wordcard.notfound';
const String kWordCardOfflineMissingCopyKey = 'wordcard.offline_missing';
const String kWordCardSuggestCopyKey = 'wordcard.suggest';

const String verifiedLexiconSearchPath = '/api/v2/verified-lexicon/search';

enum LexiconLookupKind {
  hit,
  notFound,
  offlineMissing,
}

class LexiconLookupResult {
  const LexiconLookupResult({
    required this.kind,
    required this.surface,
    this.lexeme,
    this.resolvedLemma,
    this.usedOfflinePack = false,
  });

  final LexiconLookupKind kind;
  final String surface;
  final VerifiedLexeme? lexeme;
  final String? resolvedLemma;
  final bool usedOfflinePack;
}

typedef LexiconSearchFetch = Future<List<VerifiedLexeme>> Function(
  String languageCode,
  String query,
);

typedef LexiconIdFetch = Future<VerifiedLexeme?> Function(String lexemeId);

VerifiedLexeme verifiedLexemeFromPackRow(
  LexiconPackEntry row, {
  required String languageCode,
}) {
  return VerifiedLexeme(
    lexemeId: row.lexemeId,
    language: languageCode,
    verificationStatus: row.verificationStatus,
    lemma: row.lemma,
    standardOrthography: row.standard,
    exampleSentence: null,
    audioUris: List<String>.from(row.audioUris),
    raw: {
      'id': row.lexemeId,
      'lemma': row.lemma,
      'orthography': {'standard': row.standard},
      if (row.audioUris.isNotEmpty)
        'audio': row.audioUris
            .map((uri) => {'uri': uri, 'kind': 'human'})
            .toList(),
    },
  );
}

@visibleForTesting
bool lexemeEntryMatchesSurface(VerifiedLexeme lexeme, String surface) {
  final needle = surface.trim();
  if (needle.isEmpty) return false;
  final lower = needle.toLowerCase();
  if (lexeme.lemma.trim() == needle ||
      lexeme.standardOrthography.trim() == needle) {
    return true;
  }
  if (lexeme.lemma.toLowerCase() == lower ||
      lexeme.standardOrthography.toLowerCase() == lower) {
    return true;
  }
  final ortho = lexeme.raw['orthography'];
  if (ortho is Map) {
    final ascii = ortho['ascii_fallback']?.toString().trim();
    if (ascii != null && (ascii == needle || ascii.toLowerCase() == lower)) {
      return true;
    }
  }
  final infl = lexeme.raw['inflected_forms'];
  if (infl is List) {
    for (final form in infl) {
      final text = form.toString().trim();
      if (text == needle || text.toLowerCase() == lower) return true;
    }
  }
  return false;
}

@visibleForTesting
String? resolveLemmaForSurface(VerifiedLexeme lexeme, String surface) {
  if (!lexemeEntryMatchesSurface(lexeme, surface)) return null;
  final lemma = lexeme.lemma.trim();
  return lemma.isNotEmpty ? lemma : lexeme.standardOrthography.trim();
}

class LexiconLookupService {
  LexiconLookupService({
    required this.languageCode,
    LexiconPackService? packService,
    LexiconIdFetch? fetchLexemeById,
    LexiconSearchFetch? searchLexemes,
    this.assumeOffline = false,
  })  : _pack = packService,
        _fetchById = fetchLexemeById ?? _defaultFetchById,
        _search = searchLexemes ?? _defaultSearch;

  final String languageCode;
  final LexiconPackService? _pack;
  final LexiconIdFetch _fetchById;
  final LexiconSearchFetch _search;
  final bool assumeOffline;

  static Future<VerifiedLexeme?> _defaultFetchById(String lexemeId) async {
    await ApiService.initialize();
    final path =
        '$lensVerifiedLexiconEntriesPath${Uri.encodeComponent(lexemeId.trim())}';
    try {
      final response = await ApiService.get(path);
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return VerifiedLexeme.fromApiJson(body);
      }
      if (body is Map) {
        return VerifiedLexeme.fromApiJson(body.cast<String, dynamic>());
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<List<VerifiedLexeme>> _defaultSearch(
    String languageCode,
    String query,
  ) async {
    await ApiService.initialize();
    try {
      final response = await ApiService.get(
        verifiedLexiconSearchPath,
        queryParameters: {
          'language': lensProfileLanguageToLexiconCode(languageCode),
          'q': query.trim(),
          'limit': '12',
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

  Future<LexiconLookupResult> lookupSurface(String surface) async {
    final token = surface.trim();
    if (token.isEmpty) {
      return LexiconLookupResult(
        kind: LexiconLookupKind.notFound,
        surface: surface,
      );
    }

    final lang = lensProfileLanguageToLexiconCode(languageCode);
    final pack = _pack;

    if (pack != null && pack.activePack != null) {
      final direct = pack.lookupLemma(token);
      if (direct != null) {
        var lexeme = verifiedLexemeFromPackRow(direct, languageCode: lang);
        if (!assumeOffline) {
          final enriched = await _fetchById(direct.lexemeId);
          if (enriched != null) lexeme = enriched;
        }
        return LexiconLookupResult(
          kind: LexiconLookupKind.hit,
          surface: token,
          lexeme: lexeme,
          resolvedLemma: resolveLemmaForSurface(lexeme, token),
          usedOfflinePack: true,
        );
      }

      if (!assumeOffline) {
        for (final row in pack.activePack!.entries) {
          if (row.lemma.toLowerCase() == token.toLowerCase() ||
              row.standard.toLowerCase() == token.toLowerCase()) {
            continue;
          }
          final enriched = await _fetchById(row.lexemeId);
          if (enriched != null && lexemeEntryMatchesSurface(enriched, token)) {
            return LexiconLookupResult(
              kind: LexiconLookupKind.hit,
              surface: token,
              lexeme: enriched,
              resolvedLemma: resolveLemmaForSurface(enriched, token),
              usedOfflinePack: true,
            );
          }
        }
      }
    }

    if (assumeOffline) {
      return LexiconLookupResult(
        kind: LexiconLookupKind.offlineMissing,
        surface: token,
        usedOfflinePack: pack?.activePack != null,
      );
    }

    final remoteHits = await _search(lang, token);
    for (final hit in remoteHits) {
      if (lexemeEntryMatchesSurface(hit, token)) {
        return LexiconLookupResult(
          kind: LexiconLookupKind.hit,
          surface: token,
          lexeme: hit,
          resolvedLemma: resolveLemmaForSurface(hit, token),
          usedOfflinePack: false,
        );
      }
    }

    if (pack?.activePack != null) {
      return LexiconLookupResult(
        kind: LexiconLookupKind.offlineMissing,
        surface: token,
        usedOfflinePack: true,
      );
    }

    return LexiconLookupResult(
      kind: LexiconLookupKind.notFound,
      surface: token,
    );
  }
}
