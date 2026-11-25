/// Minimal Pair Duel logic (P8-921): sourced pairs, picture grid, async item sets.
library;

import 'dart:math';

import '../../lessons/tone_perception_drill.dart';
import '../../models/verified_lexeme.dart';
import 'league_scoring.dart';

Map<String, MinimalPairDuelMedia> minimalPairMediaFromLexemes(
  Iterable<VerifiedLexeme> lexemes,
) {
  final out = <String, MinimalPairDuelMedia>{};
  for (final lex in lexemes) {
    final media = minimalPairMediaFromLexeme(lex);
    if (media != null) out[lex.lexemeId] = media;
  }
  return out;
}

String? _primaryAudioUri(VerifiedLexeme lex) {
  if (lex.audioUris.isNotEmpty) {
    final uri = lex.audioUris.first.trim();
    if (uri.isNotEmpty) return uri;
  }
  final audio = lex.raw['audio'];
  if (audio is List) {
    for (final clip in audio) {
      if (clip is Map) {
        final uri = clip['uri'];
        if (uri is String && uri.trim().isNotEmpty) return uri.trim();
      }
    }
  }
  return null;
}

MinimalPairDuelMedia? minimalPairMediaFromLexeme(VerifiedLexeme lex) {
  final audio = _primaryAudioUri(lex);
  final image = lex.raw['image'];
  String? imageUri;
  String alt = '';
  if (image is Map) {
    final uri = image['uri'];
    if (uri is String) imageUri = uri.trim();
    final altText = image['alt_text'];
    if (altText is String) alt = altText.trim();
  }
  if (audio == null || audio.isEmpty || imageUri == null || imageUri.isEmpty) {
    return null;
  }
  return MinimalPairDuelMedia(
    audioUri: audio,
    imageUri: imageUri,
    imageAlt: alt,
  );
}

class MinimalPairDuelMedia {
  const MinimalPairDuelMedia({
    required this.audioUri,
    required this.imageUri,
    this.imageAlt = '',
  });

  final String audioUri;
  final String imageUri;
  final String imageAlt;
}

class MinimalPairDuelOption {
  const MinimalPairDuelOption({
    required this.id,
    required this.form,
    required this.glossEn,
    required this.audioUri,
    required this.imageUri,
    this.imageAlt = '',
  });

  final String id;
  final String form;
  final String glossEn;
  final String audioUri;
  final String imageUri;
  final String imageAlt;
}

class MinimalPairDuelSet {
  const MinimalPairDuelSet({
    required this.setId,
    required this.options,
  });

  final String setId;
  final List<MinimalPairDuelOption> options;
}

class MinimalPairDuelTurn {
  const MinimalPairDuelTurn({
    required this.setId,
    required this.heardOptionId,
    required this.options,
    required this.promptGlossEn,
  });

  final String setId;
  final String heardOptionId;
  final List<MinimalPairDuelOption> options;
  final String promptGlossEn;

  String get correctOptionId => heardOptionId;
}

class MinimalPairDuelTapResult {
  const MinimalPairDuelTapResult({
    required this.correct,
    required this.selectedOptionId,
    required this.heardOptionId,
    required this.confusedPairOptionIds,
  });

  final bool correct;
  final String selectedOptionId;
  final String heardOptionId;
  final List<String> confusedPairOptionIds;
}

MinimalPairDuelSet? buildDuelSetFromDrill({
  required TonePerceptionDrillSpec drill,
  required Map<String, MinimalPairDuelMedia> mediaByOptionId,
}) {
  if (drill.options.length < 2 || drill.options.length > 4) {
    return null;
  }
  final built = <MinimalPairDuelOption>[];
  for (final opt in drill.options) {
    final media = mediaByOptionId[opt.id];
    if (media == null) return null;
    final drillClip = drill.audioUri?.trim();
    final audio = media.audioUri.trim().isNotEmpty
        ? media.audioUri.trim()
        : (drillClip != null && drillClip.isNotEmpty && opt.id == drill.correctOptionId
            ? drillClip
            : '');
    final image = media.imageUri.trim();
    if (audio.isEmpty || image.isEmpty) return null;
    built.add(
      MinimalPairDuelOption(
        id: opt.id,
        form: opt.form,
        glossEn: opt.glossEn,
        audioUri: audio,
        imageUri: image,
        imageAlt: media.imageAlt,
      ),
    );
  }
  return MinimalPairDuelSet(setId: drill.id, options: built);
}

List<MinimalPairDuelSet> buildEligibleDuelSets({
  required List<TonePerceptionDrillSpec> drills,
  required Map<String, MinimalPairDuelMedia> mediaByOptionId,
}) {
  final out = <MinimalPairDuelSet>[];
  for (final drill in drills) {
    final set = buildDuelSetFromDrill(
      drill: drill,
      mediaByOptionId: mediaByOptionId,
    );
    if (set != null) out.add(set);
  }
  return out;
}

/// Deterministic item-set order for async friend duels (AC3).
List<String> deriveAsyncItemSetIds({
  required String itemSetSeed,
  required List<MinimalPairDuelSet> eligibleSets,
  int maxSets = 5,
}) {
  if (eligibleSets.isEmpty || maxSets <= 0) return const [];
  final ids = eligibleSets.map((s) => s.setId).toList(growable: false);
  final sorted = List<String>.from(ids)..sort();
  final rng = Random(_seedToInt(itemSetSeed));
  final bag = List<String>.from(sorted);
  final picked = <String>[];
  while (picked.length < maxSets && bag.isNotEmpty) {
    final idx = rng.nextInt(bag.length);
    picked.add(bag.removeAt(idx));
  }
  return picked;
}

int _seedToInt(String seed) {
  var hash = 0;
  for (final code in seed.codeUnits) {
    hash = 0x1fffffff & (hash + code);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= hash >> 11;
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

MinimalPairDuelTurn buildMinimalPairDuelTurn({
  required MinimalPairDuelSet set,
  required Random rng,
}) {
  final heard = set.options[rng.nextInt(set.options.length)];
  final shuffled = List<MinimalPairDuelOption>.from(set.options);
  shuffled.shuffle(rng);
  return MinimalPairDuelTurn(
    setId: set.setId,
    heardOptionId: heard.id,
    options: shuffled,
    promptGlossEn: 'Tap the picture for the word you hear',
  );
}

MinimalPairDuelTapResult gradeMinimalPairDuelTap({
  required MinimalPairDuelTurn turn,
  required String selectedOptionId,
}) {
  final correct = selectedOptionId.trim() == turn.heardOptionId.trim();
  final confused = correct
      ? <String>[]
      : <String>[turn.heardOptionId, selectedOptionId];
  return MinimalPairDuelTapResult(
    correct: correct,
    selectedOptionId: selectedOptionId,
    heardOptionId: turn.heardOptionId,
    confusedPairOptionIds: confused,
  );
}

MinimalPairDuelLeagueScore scoreTurn({
  required MinimalPairDuelTapResult result,
  required int responseTimeMs,
}) {
  return MinimalPairDuelLeagueScore(
    correctCount: result.correct ? 1 : 0,
    totalCount: 1,
    totalTimeMs: responseTimeMs.clamp(0, 600_000),
  );
}

String? audioUriForOption(MinimalPairDuelTurn turn, String optionId) {
  for (final o in turn.options) {
    if (o.id == optionId) return o.audioUri;
  }
  return null;
}
