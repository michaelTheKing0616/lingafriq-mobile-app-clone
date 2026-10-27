/// Assembled illustrated audio story from a completed chain (P8-925 AC3).
library;

import 'story_chain_game.dart';

class StoryPlaybackBeat {
  const StoryPlaybackBeat({
    required this.sentenceId,
    required this.text,
    required this.authorId,
    this.audioAssetKey,
    this.illustrationKey,
  });

  final String sentenceId;
  final String text;
  final String authorId;
  final String? audioAssetKey;
  final String? illustrationKey;
}

class StoryPlaybackPlan {
  const StoryPlaybackPlan({
    required this.storyId,
    required this.languageCode,
    required this.beats,
    required this.excludedAuthorIds,
  });

  final String storyId;
  final String languageCode;
  final List<StoryPlaybackBeat> beats;
  final List<String> excludedAuthorIds;

  bool get hasBeats => beats.isNotEmpty;
}

StoryPlaybackPlan buildPlaybackPlan(StoryChainCircle circle) {
  final playable = sentencesForPlayback(circle);
  final excluded = circle.sentences
      .where((s) => !s.includedInPlayback)
      .map((s) => s.authorId)
      .toSet()
      .toList(growable: false);
  final beats = playable
      .map(
        (s) => StoryPlaybackBeat(
          sentenceId: s.id,
          text: s.playbackText,
          authorId: s.authorId,
          audioAssetKey: s.audioAssetKey,
          illustrationKey: s.illustrationKey ?? 'illustration.story.beat',
        ),
      )
      .toList(growable: false);
  return StoryPlaybackPlan(
    storyId: circle.storyId,
    languageCode: circle.languageCode,
    beats: beats,
    excludedAuthorIds: excluded,
  );
}
