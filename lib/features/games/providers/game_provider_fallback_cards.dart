part of 'package:lingafriq/providers/game_provider.dart';

mixin GameProviderFallbackMixin on Notifier<BaseProviderState> {
  GameProvider get _game => this as GameProvider;
/// Generate curated fallback cards (used only when API is unavailable and no cached data exists)
List<PhraseCard> _generateFallbackCards(
    String language,
    String? level,
    int count,
    String? userId,
) {
    final cards = <PhraseCard>[];
    final lang = language.toLowerCase();

    // Curated fallback phrase bank (offline-first; used only when backend is unreachable).
    final fallbackData = _curatedGameFallbackPhraseBank();

    // Merge LanguageWords (richer, 30-90 per language) with inline fallback
    final langWordsAll = LanguageWords.getWordsByLanguage();
    final capitalizedLang = lang.isNotEmpty
        ? lang[0].toUpperCase() + lang.substring(1)
        : lang;
    final richWords =
        langWordsAll[capitalizedLang] ?? langWordsAll['Yoruba'] ?? [];

    // Build a combined list: LanguageWords first (richer), then inline fallback
    final combined = <Map<String, dynamic>>[];
    for (final w in richWords) {
      combined.add({
        'text': w['translation'] ?? '',
        'gloss': w['english'] ?? '',
        'tags': <String>['language-words'],
      });
    }

    final inlineData = fallbackData[lang] ?? fallbackData['yoruba']!;
    for (final item in inlineData) {
      final text = item['text'] as String;
      if (!combined.any((c) => c['text'] == text)) {
        combined.add(item);
      }
    }

    // Shuffle and take unique subset
    final rng = Random();
    combined.shuffle(rng);
    final take = min(count, combined.length);

    if (take < 4) {
      // Universal safety net phrases for any language
      final universalPhrases = [
        {
          'text': 'Hello',
          'gloss': 'Greeting',
          'tags': <String>['universal-fallback'],
        },
        {
          'text': 'Thank you',
          'gloss': 'Gratitude',
          'tags': <String>['universal-fallback'],
        },
        {
          'text': 'Yes',
          'gloss': 'Affirmative',
          'tags': <String>['universal-fallback'],
        },
        {
          'text': 'No',
          'gloss': 'Negative',
          'tags': <String>['universal-fallback'],
        },
        {
          'text': 'Please',
          'gloss': 'Polite request',
          'tags': <String>['universal-fallback'],
        },
        {
          'text': 'Goodbye',
          'gloss': 'Farewell',
          'tags': <String>['universal-fallback'],
        },
      ];
      combined.addAll(universalPhrases);
    }

    final actualTake = min(count, combined.length);

    for (var i = 0; i < actualTake; i++) {
      final item = combined[i];
      final cardId = '${lang}_card_$i';
      cards.add(
        PhraseCard(
        cardId: cardId,
        language: language,
          text: (item['text'] as String?) ?? '',
          ascii: (item['text'] as String?) ?? '',
          gloss: (item['gloss'] as String?) ?? '',
        level: level ?? 'A0',
          tags:
              (item['tags'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          srs:
              _game._userSRS['${userId ?? _game._currentSession?.userId ?? 'user'}_${cardId}_$language'] ??
              SRSState(),
        ),
      );
    }

    return cards;
}
}
