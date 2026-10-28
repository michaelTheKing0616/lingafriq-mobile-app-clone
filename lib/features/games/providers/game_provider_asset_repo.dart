part of 'package:lingafriq/providers/game_provider.dart';

mixin GameProviderAssetRepoMixin on Notifier<BaseProviderState> {
  GameProvider get _game => this as GameProvider;
List<PhraseCard> _buildCardsFromAssetWordRepo(
    String language,
    String? level,
    int count,
    String? userId,
) {
    final canonicalLang = _assetRepoCanonicalKeyForUiLanguage(language);
    final entries =
        GameProvider._assetWordRepoByLanguage?[canonicalLang] ??
        const <Map<String, dynamic>>[];
    if (entries.isEmpty || count <= 0) return const <PhraseCard>[];

    final rng = Random();
    final shuffled = List<Map<String, dynamic>>.from(entries)..shuffle(rng);
    final cards = <PhraseCard>[];
    for (var i = 0; i < min(count, shuffled.length); i++) {
      final item = shuffled[i];
      final text = (item['text'] ?? '').toString().trim();
      final gloss = (item['gloss'] ?? '').toString().trim();
      if (text.isEmpty || gloss.isEmpty) continue;
      final cardId = 'asset_${canonicalLang}_${i}_${text.hashCode.abs()}';
      final tagList = <String>[
        ...(item['game_tags'] is List
            ? (item['game_tags'] as List).map((e) => e.toString())
            : const <String>[]),
        (item['topic'] ?? '').toString(),
        (item['cefr'] ?? '').toString(),
      ].where((e) => e.trim().isNotEmpty).toList();

      cards.add(
        PhraseCard(
          cardId: cardId,
          language: language,
          text: text,
          ascii: (item['ascii'] ?? text).toString(),
          gloss: gloss,
          level: ((item['cefr'] ?? level ?? 'A1').toString()),
          tags: tagList,
          srs:
              _game._userSRS['${userId ?? _game._currentSession?.userId ?? 'user'}_${cardId}_$language'] ??
              SRSState(),
        ),
      );
    }
    return cards;
}

void _repairCardsWithAssetLexicon(List<PhraseCard> cards, String language) {
    if (cards.isEmpty) return;
    final normalizedLang = _game._normalizeLanguageKey(language);
    final lexicon = GameProvider._assetEnglishToTargetByLanguage?[normalizedLang];
    if (lexicon == null || lexicon.isEmpty) return;

    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      var text = card.text.trim();
      final gloss = card.gloss.trim();

      if (_looksLikelyEnglish(text)) {
        final candidate =
            lexicon[text.toLowerCase()] ?? lexicon[gloss.toLowerCase()];
        if (candidate != null && candidate.trim().isNotEmpty) {
          text = candidate.trim();
          cards[i] = card.copyWith(
            text: text,
            ascii: card.ascii.trim().isEmpty ? text : card.ascii,
            gloss: gloss.isEmpty ? card.text : gloss,
          );
          continue;
        }
      }

      if (gloss.isEmpty && lexicon.isNotEmpty) {
        final backfillGloss = lexicon.entries
            .firstWhere(
              (e) => e.value.toLowerCase() == text.toLowerCase(),
              orElse: () => const MapEntry('', ''),
            )
            .key;
        if (backfillGloss.isNotEmpty) {
          cards[i] = card.copyWith(gloss: backfillGloss);
        }
      }
    }
}

void _sanitizeWordMatchCards(List<PhraseCard> cards, String language) {
    if (cards.isEmpty) return;
    final original = List<PhraseCard>.from(cards);
    final deduped = <PhraseCard>[];
    final seenTargets = <String>{};
    final seenGlosses = <String>{};

    for (final card in cards) {
      final text = card.text.trim();
      if (text.isEmpty || _looksLikeSentence(text)) continue;
      var gloss = card.gloss.trim();
      if (gloss.isEmpty ||
          !_looksLikelyEnglish(gloss) ||
          _looksLikeSentence(gloss)) {
        final recovered = _lookupEnglishGlossForTarget(
          language: language,
          target: text,
          ascii: card.ascii,
        );
        if (recovered != null && recovered.isNotEmpty) {
          gloss = recovered;
        }
      }
      if (gloss.isEmpty ||
          !_looksLikelyEnglish(gloss) ||
          _looksLikeSentence(gloss)) {
        continue;
      }

      final targetKey = text.toLowerCase();
      final glossKey = gloss.toLowerCase();
      if (seenTargets.contains(targetKey) || seenGlosses.contains(glossKey)) {
        continue;
      }
      seenTargets.add(targetKey);
      seenGlosses.add(glossKey);
      deduped.add(card.copyWith(gloss: gloss));
    }

    var next = deduped;
    const minPairs = 4;
    if (original.length >= minPairs && next.length < minPairs) {
      final relaxed = <PhraseCard>[];
      final seenTargets2 = <String>{};
      final seenGlosses2 = <String>{};
      for (final card in original) {
        final text = card.text.trim();
        if (text.isEmpty) continue;
        var gloss = card.gloss.trim();
        if (gloss.isEmpty) {
          final recovered = _lookupEnglishGlossForTarget(
            language: language,
            target: text,
            ascii: card.ascii,
          );
          if (recovered != null && recovered.isNotEmpty) {
            gloss = recovered;
          }
        }
        if (gloss.isEmpty) continue;

        final targetKey = text.toLowerCase();
        final glossKey = gloss.toLowerCase();
        if (seenTargets2.contains(targetKey) || seenGlosses2.contains(glossKey)) {
          continue;
        }
        seenTargets2.add(targetKey);
        seenGlosses2.add(glossKey);
        relaxed.add(card.copyWith(gloss: gloss));
      }
      next = relaxed;
    }

    cards
      ..clear()
      ..addAll(next);
}

String? _lookupEnglishGlossForTarget({
    required String language,
    required String target,
    String? ascii,
}) {
    final canonicalLang = _assetRepoCanonicalKeyForUiLanguage(language);
    final lexicon = GameProvider._assetEnglishToTargetByLanguage?[canonicalLang];
    if (lexicon == null || lexicon.isEmpty) return null;
    final targetLower = target.trim().toLowerCase();
    final asciiLower = (ascii ?? '').trim().toLowerCase();
    for (final entry in lexicon.entries) {
      final candidateTarget = entry.value.trim().toLowerCase();
      if (candidateTarget == targetLower ||
          (asciiLower.isNotEmpty && candidateTarget == asciiLower)) {
        return entry.key;
      }
    }
    return null;
}

void _registerAssetRepoAliases(String canonicalKey, String rawJsonKey) {
    void put(String alias, String value) {
      final k = _normRepoAlias(alias);
      if (k.isEmpty) return;
      GameProvider._assetWordRepoAliasToCanonicalKey.putIfAbsent(k, () => value);
    }

    put(rawJsonKey, canonicalKey);
    put(canonicalKey, canonicalKey);

    final lower = rawJsonKey.toLowerCase();
    put(lower, canonicalKey);

    // Parentheses often encode alternate names, e.g. "fula (fulfulde)".
    final noParen = lower.replaceAll('(', ' ').replaceAll(')', ' ');
    put(noParen, canonicalKey);

    final parts =
        lower.split(RegExp(r'[^a-z]+')).where((e) => e.length >= 3).toList();
    for (final p in parts) {
      put(p, canonicalKey);
    }
}

String _foldLatinDiacriticsLite(String s) {
    var o = s;
    o = o.replaceAll('à', 'a').replaceAll('á', 'a').replaceAll('â', 'a').replaceAll('ã', 'a').replaceAll('ä', 'a').replaceAll('å', 'a');
    o = o.replaceAll('è', 'e').replaceAll('é', 'e').replaceAll('ê', 'e').replaceAll('ë', 'e');
    o = o.replaceAll('ì', 'i').replaceAll('í', 'i').replaceAll('î', 'i').replaceAll('ï', 'i');
    o = o.replaceAll('ò', 'o').replaceAll('ó', 'o').replaceAll('ô', 'o').replaceAll('õ', 'o').replaceAll('ö', 'o');
    o = o.replaceAll('ù', 'u').replaceAll('ú', 'u').replaceAll('û', 'u').replaceAll('ü', 'u');
    o = o.replaceAll('ý', 'y').replaceAll('ÿ', 'y');
    o = o.replaceAll('ñ', 'n').replaceAll('ç', 'c');
    return o;
}

String _normRepoAlias(String raw) {
    final folded = _foldLatinDiacriticsLite(raw.trim().toLowerCase());
    return folded.replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String _assetRepoCanonicalKeyForUiLanguage(String language) {
    final repo = GameProvider._assetWordRepoByLanguage;
    if (repo == null || repo.isEmpty) {
      return _game._normalizeLanguageKey(language);
    }

    final direct = _game._normalizeLanguageKey(language);
    if (repo.containsKey(direct) && (repo[direct]?.isNotEmpty ?? false)) {
      return direct;
    }

    final display = LanguageWords.resolveWordListDisplayKey(language);
    final candidates = <String>{
      _normRepoAlias(language),
      _normRepoAlias(display),
      _normRepoAlias(direct),
      _normRepoAlias(_game._normalizeLanguageKey(display)),
    }..removeWhere((e) => e.isEmpty);

    for (final c in candidates) {
      final hit = GameProvider._assetWordRepoAliasToCanonicalKey[c];
      if (hit != null && (repo[hit]?.isNotEmpty ?? false)) return hit;
    }

    // Last resort: stable normalization (may still miss; fallback generators cover gaps).
    return direct;
}

String _normalizeLanguageKey(String language) {
    var s = language.trim().toLowerCase();
    if (s == 'nigerian pidgin' || s == 'pidgin english') return 'pidgin';
    if (s.startsWith('yor') || s == 'yorùbá') return 'yoruba';
    if (s == 'kiswahili') return 'swahili';
    return s;
}

bool _looksLikelyEnglish(String value) {
    final s = value.trim().toLowerCase();
    if (s.isEmpty) return false;
    const common = {
      'the',
      'and',
      'is',
      'are',
      'you',
      'hello',
      'good',
      'morning',
      'thank',
      'please',
      'how',
      'where',
      'food',
      'water',
      'friend',
      'school',
      'teacher',
      'student',
      'house',
      'book',
      'day',
      'night',
    };
    final tokens = s
        .split(RegExp(r'[^a-z]+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return false;
    final hits = tokens.where(common.contains).length;
    return hits >= (tokens.length / 2).ceil();
}

bool _looksLikeSentence(String value) {
    final tokens = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    return tokens.length > 3;
}
}
