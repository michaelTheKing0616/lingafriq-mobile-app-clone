import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/models/game/game_content_models.dart';

/// Asset path for bundled game vocabulary, proverbs, and scenarios.
const String kGameContentAssetPath = 'assets/data/game_content.json';

/// Optional criteria for slicing [GameContentData] lists.
///
/// Not every field applies to every entity type; see
/// [_matchesWord], [_matchesProverb], and [_matchesScenario].
class GameContentFilter {
  final String? language;
  final String? cefr;
  final String? gameTag;
  final String? topic;

  /// Scenario game id ([GameScenario.game]); ignored for words/proverbs.
  final String? game;

  const GameContentFilter({
    this.language,
    this.cefr,
    this.gameTag,
    this.topic,
    this.game,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameContentFilter &&
          language == other.language &&
          cefr == other.cefr &&
          gameTag == other.gameTag &&
          topic == other.topic &&
          game == other.game;

  @override
  int get hashCode => Object.hash(language, cefr, gameTag, topic, game);
}

/// Loads and parses [GameContentData] from the app bundle.
///
/// [FutureProvider] keeps the future cached until invalidated.
final gameContentProvider = FutureProvider<GameContentData>((ref) async {
  final raw = await rootBundle.loadString(kGameContentAssetPath);
  return GameContentData.fromRawJson(raw);
});

/// Words from [gameContentProvider] matching [GameContentFilter].
///
/// Returns an empty list while loading, on parse/load error, or when no data.
/// Applies: [GameContentFilter.language], [GameContentFilter.cefr],
/// [GameContentFilter.gameTag] (membership in [GameWord.gameTags]),
/// [GameContentFilter.topic]. [GameContentFilter.game] is ignored.
final gameWordsProvider =
    Provider.family<List<GameWord>, GameContentFilter>((ref, filter) {
  return ref.watch(gameContentProvider).maybeWhen(
        data: (data) =>
            data.words.where((w) => _matchesWord(w, filter)).toList(),
        orElse: () => <GameWord>[],
      );
});

/// Proverbs from [gameContentProvider] matching [GameContentFilter].
///
/// Applies: language, cefr, gameTag. Ignores topic and game (no fields on model).
final gameProverbsProvider =
    Provider.family<List<GameProverb>, GameContentFilter>((ref, filter) {
  return ref.watch(gameContentProvider).maybeWhen(
        data: (data) =>
            data.proverbs.where((p) => _matchesProverb(p, filter)).toList(),
        orElse: () => <GameProverb>[],
      );
});

/// Scenarios from [gameContentProvider] matching [GameContentFilter].
///
/// Applies: language, cefr, game. Ignores gameTag and topic.
final gameScenariosProvider =
    Provider.family<List<GameScenario>, GameContentFilter>((ref, filter) {
  return ref.watch(gameContentProvider).maybeWhen(
        data: (data) =>
            data.scenarios.where((s) => _matchesScenario(s, filter)).toList(),
        orElse: () => <GameScenario>[],
      );
});

/// Grammar Jam drills from bundled [game_content.json].
final grammarDrillsProvider =
    Provider.family<List<GrammarDrill>, GameContentFilter>((ref, filter) {
  return ref.watch(gameContentProvider).maybeWhen(
        data: (data) => data.grammarDrills
            .where((d) => _matchesGrammarDrill(d, filter))
            .toList(),
        orElse: () => <GrammarDrill>[],
      );
});

/// Liar Liar rounds from bundled [game_content.json].
final liarLiarRoundsProvider =
    Provider.family<List<LiarLiarRound>, GameContentFilter>((ref, filter) {
  return ref.watch(gameContentProvider).maybeWhen(
        data: (data) => data.liarLiarRounds
            .where((r) => _matchesLiarRound(r, filter))
            .toList(),
        orElse: () => <LiarLiarRound>[],
      );
});

bool _matchesGrammarDrill(GrammarDrill drill, GameContentFilter f) {
  if (f.language != null && drill.language != f.language) return false;
  if (f.cefr != null && drill.cefr != f.cefr) return false;
  if (f.game != null && drill.game != f.game) return false;
  return true;
}

bool _matchesLiarRound(LiarLiarRound round, GameContentFilter f) {
  if (f.language != null && round.language != f.language) return false;
  if (f.cefr != null && round.cefr != f.cefr) return false;
  return true;
}

bool _matchesWord(GameWord word, GameContentFilter f) {
  if (f.language != null && word.language != f.language) return false;
  if (f.cefr != null && word.cefr != f.cefr) return false;
  if (f.gameTag != null && !word.gameTags.contains(f.gameTag!)) {
    return false;
  }
  if (f.topic != null && word.topic != f.topic) return false;
  return true;
}

bool _matchesProverb(GameProverb proverb, GameContentFilter f) {
  if (f.language != null && proverb.language != f.language) return false;
  if (f.cefr != null && proverb.cefr != f.cefr) return false;
  if (f.gameTag != null && !proverb.gameTags.contains(f.gameTag!)) {
    return false;
  }
  return true;
}

bool _matchesScenario(GameScenario scenario, GameContentFilter f) {
  if (f.language != null && scenario.language != f.language) return false;
  if (f.cefr != null && scenario.cefr != f.cefr) return false;
  if (f.game != null && scenario.game != f.game) return false;
  return true;
}
