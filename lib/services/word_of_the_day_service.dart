import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/services/lens/lexicon_label_resolver.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';

/// copy_keys: wotd.title (P7-926).
const String kWotdTitle = 'Word of the day';

const Set<String> kWotdVerifiedStatuses = {
  'expert_reviewed',
  'native_verified',
};

class WordOfTheDay {
  const WordOfTheDay({
    required this.calendarDayUtc,
    required this.language,
    required this.lexeme,
    required this.story,
  });

  final String calendarDayUtc;
  final String language;
  final VerifiedLexeme lexeme;
  final String story;
}

typedef WotdCatalogFetch = Future<List<VerifiedLexeme>> Function(String language);

/// Reads a curator-authored story from lexicon entry fields only (no invention).
@visibleForTesting
String? extractWordStory(Map<String, dynamic> entry) {
  for (final key in ['word_story', 'story', 'word_of_day_story']) {
    final raw = entry[key];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  }
  final culture = entry['culture_notes'] ?? entry['cultural_notes'];
  if (culture is String && culture.trim().isNotEmpty) return culture.trim();
  if (culture is List) {
    for (final item in culture) {
      if (item is String && item.trim().isNotEmpty) return item.trim();
    }
  }
  return null;
}

@visibleForTesting
bool lexemeQualifiesForWotd(VerifiedLexeme lexeme) {
  final status = lexeme.verificationStatus.trim().toLowerCase();
  if (!kWotdVerifiedStatuses.contains(status)) return false;
  final story = extractWordStory(lexeme.raw);
  return story != null && story.isNotEmpty;
}

@visibleForTesting
String utcCalendarDay(DateTime instant) {
  final utc = instant.toUtc();
  final y = utc.year.toString().padLeft(4, '0');
  final m = utc.month.toString().padLeft(2, '0');
  final d = utc.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

@visibleForTesting
int stableWotdIndex({
  required String calendarDayUtc,
  required String language,
  required int candidateCount,
}) {
  if (candidateCount <= 0) return 0;
  final digest = sha256.convert(utf8.encode('$language|$calendarDayUtc')).bytes;
  var value = 0;
  for (var i = 0; i < 4; i++) {
    value = (value << 8) | digest[i];
  }
  return value.abs() % candidateCount;
}

@visibleForTesting
WordOfTheDay? pickWordOfTheDay({
  required DateTime dayUtc,
  required String language,
  required List<VerifiedLexeme> catalog,
}) {
  final lang = language.trim().toLowerCase();
  if (lang.isEmpty) return null;

  final eligible = <VerifiedLexeme>[];
  for (final row in catalog) {
    if (row.language.trim().toLowerCase() != lang &&
        row.language.trim().isNotEmpty) {
      continue;
    }
    if (!lexemeQualifiesForWotd(row)) continue;
    eligible.add(row);
  }
  if (eligible.isEmpty) return null;

  eligible.sort((a, b) => a.lexemeId.compareTo(b.lexemeId));
  final day = utcCalendarDay(dayUtc);
  final index = stableWotdIndex(
    calendarDayUtc: day,
    language: lang,
    candidateCount: eligible.length,
  );
  final chosen = eligible[index];
  final story = extractWordStory(chosen.raw);
  if (story == null || story.isEmpty) return null;

  return WordOfTheDay(
    calendarDayUtc: day,
    language: lang,
    lexeme: chosen,
    story: story,
  );
}

class WordOfTheDayService {
  WordOfTheDayService({
    LexiconPackService? packService,
    WotdCatalogFetch? fetchCatalog,
  })  : _pack = packService ?? LexiconPackService(),
        _fetchCatalog = fetchCatalog ?? _defaultFetchCatalog;

  final LexiconPackService _pack;
  final WotdCatalogFetch _fetchCatalog;

  static Future<List<VerifiedLexeme>> _defaultFetchCatalog(
    String language,
  ) async {
    final lang = lensProfileLanguageToLexiconCode(language.trim());
    if (lang.isEmpty) return const [];
    await ApiService.initialize();
    try {
      final response = await ApiService.get(
        verifiedLexiconSearchPath,
        queryParameters: {
          'language': lang,
          'q': '',
          'limit': '100',
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

  Future<List<VerifiedLexeme>> _catalogFromPack(String language) async {
    final lang = language.trim().toLowerCase();
    final installed = _pack.activePack;
    if (installed == null) return const [];
    if (installed.manifest.language.trim().toLowerCase() != lang) {
      return const [];
    }
    return installed.entries
        .map((e) => verifiedLexemeFromPackRow(e, languageCode: lang))
        .toList();
  }

  Future<WordOfTheDay?> loadForToday({
    required String language,
    DateTime? nowUtc,
  }) async {
    final lang = language.trim().toLowerCase();
    if (lang.isEmpty) return null;
    final instant = (nowUtc ?? DateTime.now()).toUtc();

    List<VerifiedLexeme> catalog = await _fetchCatalog(lang);
    if (catalog.isEmpty) {
      catalog = await _catalogFromPack(lang);
    }
    return pickWordOfTheDay(
      dayUtc: instant,
      language: lang,
      catalog: catalog,
    );
  }
}
