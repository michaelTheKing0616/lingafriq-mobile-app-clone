import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lazy_game_loader.dart';
import '../utils/games_prefetch_language.dart';

/// Clears lazy-load memory and warms common games using current prefs (fire-and-forget).
void scheduleGamesPreloadWithLoader(LazyGameLoader loader) {
  Future<void>(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = resolveGamesPrefetchLanguageSync(prefs);
      loader.clearLoadedGames();
      await loader.preloadCommonGames(language: lang);
    } catch (e, st) {
      debugPrint('scheduleGamesPreloadWithLoader: $e $st');
    }
  });
}

/// Same as [scheduleGamesPreloadWithLoader] using [lazyGameLoaderProvider].
void scheduleGamesPreloadAfterLearningLanguageSaved(WidgetRef ref) {
  scheduleGamesPreloadWithLoader(ref.read(lazyGameLoaderProvider));
}
