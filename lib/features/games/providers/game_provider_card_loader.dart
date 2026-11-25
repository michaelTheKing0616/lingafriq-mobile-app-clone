part of 'package:lingafriq/providers/game_provider.dart';

mixin GameProviderCardLoaderMixin on Notifier<BaseProviderState> {
  GameProvider get _game => this as GameProvider;
/// Load cards for a game
/// Attempts to load from backend API, falls back to curated local data
  Future<List<PhraseCard>> _loadCardsForGame({
    required String language,
    String? level,
    int count = 10,
    String? userId,
    String? sessionId,
    String? gameId,
}) async {
    // Some game screens may accidentally request 0 cards; enforce a safe minimum
    // so we never end up with an empty deck solely due to a bad parameter.
    final effectiveCount = max(count, 10);
    final cacheKey = '${gameId ?? 'default'}_${language}_${level ?? 'A0'}';
    final isWordMatchGame = (gameId ?? '').toLowerCase().contains(
      'wordmatch_audio',
    );
    // Always require at least a small playable deck.
    final minRequired = min(4, effectiveCount);
    if (GameProvider._cardCache.containsKey(cacheKey)) {
      final cached = List<PhraseCard>.from(GameProvider._cardCache[cacheKey]!);
      if (cached.length >= minRequired) {
        cached.shuffle(Random());
        return cached.take(effectiveCount).toList();
      }
      GameProvider._cardCache.remove(cacheKey);
    }

    final cards = <PhraseCard>[];
    final resolvedUserId = userId ?? _game._currentSession?.userId;
    final resolvedSessionId = sessionId ?? _game._currentSession?.sessionId;
    await _game._ensureAssetWordRepoLoaded();

    // 1) Canonical route: POST /api/games/game-content
    // Backend mounts Polie game content under /api/games/*.
    try {
      final requestData = <String, dynamic>{
        'game_id': gameId ?? _game._currentSession?.gameType ?? 'phrase_cards',
        'language': language,
        'difficulty': level ?? 'A1',
        'count': effectiveCount,
      };
      if (resolvedUserId != null && resolvedUserId.trim().isNotEmpty) {
        requestData['user_id'] = resolvedUserId;
      }
      if (resolvedSessionId != null && resolvedSessionId.trim().isNotEmpty) {
        requestData['session_id'] = resolvedSessionId;
      }

      final response = await ref
          .read(client)
          .post(
        ApiContract.url(ApiContract.ai.polieGameContent),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = response.data;
        if (payload is List) {
          for (final item in payload) {
            if (item is Map<String, dynamic>) {
              _game._appendCardFromMap(
                cards: cards,
                item: item,
                language: language,
                level: level,
                userId: resolvedUserId,
              );
            }
          }
        } else if (payload is Map<String, dynamic>) {
          _game._appendCardFromMap(
            cards: cards,
            item: payload,
            language: language,
            level: level,
            userId: resolvedUserId,
          );
        } else {
          _game._lastContentFailure = GameContentFailure(
            type: GameContentFailureType.parseFailure,
            message: 'Primary game content payload format is invalid.',
            timestamp: DateTime.now(),
          );
        }

        if (cards.length >= minRequired) {
          _game._repairCardsWithAssetLexicon(cards, language);
          if (isWordMatchGame) {
            _game._sanitizeWordMatchCards(cards, language);
          }
        if (cards.length > effectiveCount) {
          cards.removeRange(effectiveCount, cards.length);
          }

          try {
            for (var i = 0; i < cards.length; i++) {
              final card = cards[i];
              final enforced = DiacriticsEnforcer.enforceWithMetadata(
                card.text,
                language,
                enableFuzzy: true,
                fuzzyThreshold: 0.75,
              );
              if (enforced['changed'] == true) {
                cards[i] = card.copyWith(text: enforced['text'] as String);
              }
            }
          } catch (e) {
            logger.error(
              'Diacritics enforcement failed for canonical API cards (cards still usable)',
              tag: 'game-provider',
              error: e,
            );
          }

          GameProvider._cardCache[cacheKey] = List.from(cards);
          return cards;
        }
      }
    } catch (e) {
      logger.error(
        'Error loading cards from canonical game-content API, trying legacy route',
        tag: 'game-provider',
        error: e,
      );
      _game._lastContentFailure = GameProvider.classifyGameContentFailure(
        e,
        defaultType: GameContentFailureType.serviceUnavailable,
        defaultMessage:
            'Primary game content service is unavailable. Retrying with fallback.',
      );
    }

    // 2) Legacy route: GET /api/games/cards (for backward compatibility)
    try {
      final queryParams = <String, dynamic>{
        'language': language,
        'count': effectiveCount,
      };
      if (level != null) queryParams['level'] = level;

      final response = await ref
          .read(client)
          .get(
        ApiContract.url(ApiContract.games.cards),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        final dataList = response.data as List;
        var parseErrors = 0;
        for (var item in dataList) {
          if (item is Map<String, dynamic>) {
            try {
              final cId =
                  item['id'] ?? item['card_id'] ?? 'card_${cards.length}';
              final lang = item['language'] ?? language;
              cards.add(
                PhraseCard(
                cardId: cId.toString(),
                language: lang.toString(),
                text: item['text'] ?? item['phrase'] ?? '',
                ascii: item['ascii'] ?? item['text'] ?? '',
                  gloss:
                      item['gloss'] ??
                      item['translation'] ??
                      item['meaning'] ??
                      '',
                level: item['level'] ?? level ?? 'A0',
                  tags:
                      (item['tags'] as List<dynamic>?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      [],
                  srs:
                      _game._userSRS['${resolvedUserId ?? 'user'}_${cId}_$lang'] ??
                      SRSState(),
                ),
              );
            } catch (e) {
              logger.error(
                'Error parsing card from API',
                tag: 'game-provider',
                error: e,
              );
              parseErrors++;
              continue;
            }
          } else {
            parseErrors++;
          }
        }

        // If we got enough cards from API sources, normalize and return.
        if (cards.length >= minRequired) {
          _game._repairCardsWithAssetLexicon(cards, language);
          if (isWordMatchGame) {
            _game._sanitizeWordMatchCards(cards, language);
          }
        if (cards.length > effectiveCount) {
          cards.removeRange(effectiveCount, cards.length);
          }
          try {
            for (var i = 0; i < cards.length; i++) {
              final card = cards[i];
              final enforced = DiacriticsEnforcer.enforceWithMetadata(
                card.text,
                language,
                enableFuzzy: true,
                fuzzyThreshold: 0.75,
              );

              if (enforced['changed'] == true) {
                cards[i] = card.copyWith(text: enforced['text'] as String);
              }
            }
          } catch (e) {
            logger.error(
              'Diacritics enforcement failed for API cards (cards still usable)',
              tag: 'game-provider',
              error: e,
            );
          }
          GameProvider._cardCache[cacheKey] = List.from(cards);
          return cards;
        }
        if (parseErrors > 0) {
          _game._lastContentFailure = GameContentFailure(
            type: GameContentFailureType.parseFailure,
            message: 'Legacy game card payload could not be parsed.',
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (e) {
      logger.error(
        'Error loading cards from API, using fallback',
        tag: 'game-provider',
        error: e,
      );
      _game._lastContentFailure = GameProvider.classifyGameContentFailure(
        e,
        defaultType: GameContentFailureType.serviceUnavailable,
        defaultMessage:
            'Game card API is unavailable. Using curated fallback content.',
      );
      // Continue to fallback
    }

    // Fallback to curated local data and top-up card count when APIs under-deliver.
    var neededForTarget =
        max(effectiveCount - cards.length, minRequired - cards.length);
    if (neededForTarget > 0) {
      final assetRepoCards = _game._buildCardsFromAssetWordRepo(
        language,
        level,
        neededForTarget,
        resolvedUserId,
      );
      cards.addAll(assetRepoCards);
      neededForTarget =
          max(effectiveCount - cards.length, minRequired - cards.length);
    }
    if (neededForTarget > 0) {
      final fallbackCards = _game._generateFallbackCards(
        language,
        level,
        neededForTarget,
        resolvedUserId,
      );
    cards.addAll(fallbackCards);
    }

    _game._repairCardsWithAssetLexicon(cards, language);
    if (isWordMatchGame) {
      _game._sanitizeWordMatchCards(cards, language);
      final neededForWordMatch = max(
        effectiveCount - cards.length,
        minRequired - cards.length,
      );
      if (neededForWordMatch > 0) {
        cards.addAll(
          _game._buildCardsFromAssetWordRepo(
            language,
            level,
            neededForWordMatch,
            resolvedUserId,
          ),
        );
        _game._repairCardsWithAssetLexicon(cards, language);
        _game._sanitizeWordMatchCards(cards, language);
      }

      // WordMatch requires at least a few clean (target, gloss) pairs.
      // If sanitization removed too much (e.g. sentence-like phrases), top-up with
      // the universal fallback generator and sanitize again.
      const minPairs = 4;
      if (cards.length < minPairs) {
        final topUp = minPairs - cards.length;
        if (topUp > 0) {
          cards.addAll(
            _game._generateFallbackCards(
              language,
              level,
              topUp,
              resolvedUserId,
            ),
          );
          _game._repairCardsWithAssetLexicon(cards, language);
          _game._sanitizeWordMatchCards(cards, language);
        }
      }
    }
    if (cards.length > effectiveCount) {
      cards.removeRange(effectiveCount, cards.length);
    }

    // Absolute safety net: guarantee a playable deck even if upstream services
    // and asset repos are empty or card sanitizers remove too much content.
    if (cards.length < minRequired) {
      final topUp = minRequired - cards.length;
      if (topUp > 0) {
        cards.addAll(
          _game._generateFallbackCards(
            language,
            level,
            topUp,
            resolvedUserId,
          ),
        );
        _game._repairCardsWithAssetLexicon(cards, language);
      }
    }
    if (cards.isEmpty) {
      _game._lastContentFailure = GameContentFailure(
        type: GameContentFailureType.noContent,
        message: 'No game content is available right now.',
        timestamp: DateTime.now(),
      );
    }

    // Apply diacritics enforcement to all cards (non-fatal — cards work without it)
    try {
      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        final enforced = DiacriticsEnforcer.enforceWithMetadata(
          card.text,
          language,
          enableFuzzy: true,
          fuzzyThreshold: 0.75,
        );

        if (enforced['changed'] == true) {
          cards[i] = card.copyWith(text: enforced['text'] as String);
        }
      }
    } catch (e) {
      logger.error(
        'Diacritics enforcement failed (cards still usable)',
        tag: 'game-provider',
        error: e,
      );
    }

    if (cards.length >= minRequired) {
      GameProvider._cardCache[cacheKey] = List.from(cards);
    }
    return cards;
  }
}
