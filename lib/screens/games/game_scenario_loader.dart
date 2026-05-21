import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/providers/game_content_provider.dart';

export 'package:lingafriq/models/game/game_content_models.dart'
    show GameScenario, GameWord, GameProverb;

/// Loads bundled [game_content.json] scenarios for a Polie-driven game.
List<GameScenario> loadBundledGameScenarios(
  WidgetRef ref, {
  required String language,
  required String game,
  int max = 10,
}) {
  final lang = language.toLowerCase();
  final loaded = ref.read(
    gameScenariosProvider(
      GameContentFilter(language: lang, game: game),
    ),
  );
  if (loaded.isEmpty) return loaded;
  final shuffled = List<GameScenario>.from(loaded)..shuffle(Random());
  if (shuffled.length <= max) return shuffled;
  return shuffled.sublist(0, max);
}

/// Builds shuffled MCQ options with [correct] always included.
List<String> buildShuffledOptions(
  String correct,
  Iterable<String> pool, {
  int count = 4,
  Random? random,
}) {
  final rng = random ?? Random();
  final options = <String>{correct};
  for (final item in pool) {
    if (options.length >= count) break;
    final t = item.trim();
    if (t.isNotEmpty && t != correct) options.add(t);
  }
  while (options.length < count) {
    options.add('—');
  }
  final list = options.toList()..shuffle(rng);
  return list.take(count).toList();
}

List<GameWord> loadBundledGameWords(
  WidgetRef ref, {
  required String language,
  required String gameTag,
  int max = 24,
}) {
  final lang = language.toLowerCase();
  final loaded = ref.read(
    gameWordsProvider(
      GameContentFilter(language: lang, gameTag: gameTag),
    ),
  );
  if (loaded.isEmpty) return loaded;
  final shuffled = List<GameWord>.from(loaded)..shuffle(Random());
  if (shuffled.length <= max) return shuffled;
  return shuffled.sublist(0, max);
}

List<GameProverb> loadBundledProverbs(
  WidgetRef ref, {
  required String language,
  String? gameTag,
  int max = 8,
}) {
  final loaded = ref.read(
    gameProverbsProvider(
      GameContentFilter(
        language: language.toLowerCase(),
        gameTag: gameTag,
      ),
    ),
  );
  if (loaded.isEmpty) return loaded;
  final shuffled = List<GameProverb>.from(loaded)..shuffle(Random());
  if (shuffled.length <= max) return shuffled;
  return shuffled.sublist(0, max);
}
