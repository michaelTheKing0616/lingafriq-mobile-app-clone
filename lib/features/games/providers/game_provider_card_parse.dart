part of 'package:lingafriq/providers/game_provider.dart';

mixin GameProviderCardParseMixin on Notifier<BaseProviderState> {
  GameProvider get _game => this as GameProvider;
void _appendCardFromMap({
    required List<PhraseCard> cards,
    required Map<String, dynamic> item,
    required String language,
    required String? level,
    String? userId,
}) {
    final cardId =
        (item['id'] ??
                item['card_id'] ??
                item['content_id'] ??
                'card_${cards.length}')
            .toString();
    final lang = (item['language'] ?? language).toString();
    final text = (item['text'] ?? item['phrase'] ?? item['content'] ?? '')
        .toString();
    final gloss =
        (item['gloss'] ?? item['translation'] ?? item['meaning'] ?? '')
            .toString();
    final parsedLevel = (item['level'] ?? level ?? 'A0').toString();

    if (text.trim().isEmpty) return;

    cards.add(
      PhraseCard(
      cardId: cardId,
      language: lang,
      text: text,
      ascii: (item['ascii'] ?? text).toString(),
      gloss: gloss,
        ipa: (item['ipa'] ?? item['pronunciation'])?.toString(),
      level: parsedLevel,
        tags:
            (item['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['ai-generated'],
        audioNativeUrl: _extractMediaUrl(item, const [
          'audio_native_url',
          'audioNativeUrl',
          'audio_url',
          'audioUrl',
          'audio',
          'tts_url',
          'voice_url',
        ]),
        imageUrl: resolveMediaUrl(
          (item['image_url'] ?? item['imageUrl'] ?? item['image'])?.toString(),
        ),
        contextExamples:
            (item['context_examples'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            (item['examples'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        srs:
            _game._userSRS['${userId ?? _game._currentSession?.userId ?? 'user'}_${cardId}_$lang'] ??
            SRSState(),
      ),
    );
}

String? _extractMediaUrl(Map<String, dynamic> map, List<String> keys) {
    dynamic crawl(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) {
        for (final item in value) {
          final nested = crawl(item);
          if (nested != null && nested.toString().trim().isNotEmpty) {
            return nested;
          }
        }
        return null;
      }
      if (value is Map) {
        for (final nestedKey in const ['url', 'file_url', 'src', 'path']) {
          final nested = crawl(value[nestedKey]);
          if (nested != null && nested.toString().trim().isNotEmpty) {
            return nested;
          }
        }
      }
      return value.toString();
    }

    for (final key in keys) {
      final raw = crawl(map[key]);
      if (raw != null && raw.toString().trim().isNotEmpty) {
        final resolved = resolveMediaUrl(raw.toString());
        if (resolved != null && resolved.isNotEmpty) return resolved;
      }
    }
    return null;
}

Future<void> _ensureAssetWordRepoLoaded() async {
    if (GameProvider._assetWordRepoByLanguage != null &&
        GameProvider._assetEnglishToTargetByLanguage != null) {
      return;
    }
    try {
      final raw = await rootBundle.loadString(
        'assets/data/word_repo_game_seed.json',
      );
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final languages = decoded['languages'];
      if (languages is! Map<String, dynamic>) return;

      final repo = <String, List<Map<String, dynamic>>>{};
      final lexicon = <String, Map<String, String>>{};
      GameProvider._assetWordRepoAliasToCanonicalKey.clear();

      languages.forEach((key, value) {
        if (value is! List) return;
        final normalizedKey = _game._normalizeLanguageKey(key);
        final entries = <Map<String, dynamic>>[];
        final map = <String, String>{};

        for (final item in value) {
          if (item is! Map<String, dynamic>) continue;
          final text = (item['text'] ?? '').toString().trim();
          final gloss = (item['gloss'] ?? '').toString().trim();
          if (text.isEmpty || gloss.isEmpty) continue;
          entries.add(item);
          map[gloss.toLowerCase()] = text;
        }

        if (entries.isNotEmpty) {
          repo[normalizedKey] = entries;
          lexicon[normalizedKey] = map;
          _game._registerAssetRepoAliases(normalizedKey, key);
        }
      });

      GameProvider._assetWordRepoByLanguage = repo;
      GameProvider._assetEnglishToTargetByLanguage = lexicon;
    } catch (e) {
      logger.warn(
        'Failed to load asset word repository; using existing fallback bank',
        tag: 'game-provider',
        context: {'error': e.toString()},
      );
    }
}

}
