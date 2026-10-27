/// Griot's Story Chain flagship logic (P8-925): turn order, grammar gate, playback.
library;

import 'dart:math';

/// Moderation outcome for a contributed sentence.
enum StorySentenceModeration {
  clear,
  flagged,
  pending,
}

class StoryGrammarSuggestion {
  const StoryGrammarSuggestion({
    required this.suggestedText,
    required this.explanation,
    required this.category,
    this.unavailable = false,
  });

  final String suggestedText;
  final String explanation;
  final String category;
  final bool unavailable;

  static const unavailableState = StoryGrammarSuggestion(
    suggestedText: '',
    explanation: 'Grammar check is unavailable right now. You can keep your sentence.',
    category: 'grammar',
    unavailable: true,
  );
}

class StoryChainSentence {
  const StoryChainSentence({
    required this.id,
    required this.authorId,
    required this.text,
    required this.turnIndex,
    this.audioAssetKey,
    this.illustrationKey,
    this.moderation = StorySentenceModeration.clear,
    this.acceptedGrammarFix = false,
    this.finalText,
  });

  final String id;
  final String authorId;
  final String text;
  final int turnIndex;
  final String? audioAssetKey;
  final String? illustrationKey;
  final StorySentenceModeration moderation;
  final bool acceptedGrammarFix;
  final String? finalText;

  String get playbackText =>
      (finalText ?? text).trim().isEmpty ? text : (finalText ?? text);

  bool get includedInPlayback =>
      moderation != StorySentenceModeration.flagged &&
      playbackText.trim().isNotEmpty;
}

class StoryChainCircle {
  StoryChainCircle({
    required this.storyId,
    required this.hostId,
    required this.memberIds,
    required this.inviteCode,
    required this.languageCode,
    this.maxTurns = 6,
    List<StoryChainSentence>? sentences,
    this.currentTurnIndex = 0,
    this.completed = false,
    this.isMinorSafeShare = true,
  }) : sentences = sentences ?? <StoryChainSentence>[];

  final String storyId;
  final String hostId;
  final List<String> memberIds;
  final String inviteCode;
  final String languageCode;
  final int maxTurns;
  final List<StoryChainSentence> sentences;
  int currentTurnIndex;
  bool completed;
  final bool isMinorSafeShare;

  String? activePlayerId() {
    if (completed || memberIds.isEmpty) return null;
    return memberIds[currentTurnIndex % memberIds.length];
  }

  bool isMembersTurn(String playerId) => activePlayerId() == playerId;

  bool canJoinWithInvite(String code, String userId) {
    if (code.trim().toUpperCase() != inviteCode.trim().toUpperCase()) {
      return false;
    }
    if (memberIds.contains(userId)) return true;
    return !completed && sentences.length < maxTurns;
  }
}

String generateInviteCode(Random rng) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return List.generate(6, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
}

StoryChainCircle createLocalCircle({
  required String hostId,
  required String languageCode,
  List<String>? extraMembers,
  Random? random,
}) {
  final rng = random ?? Random();
  final members = <String>[hostId, ...?extraMembers];
  return StoryChainCircle(
    storyId: 'local-${rng.nextInt(1 << 30)}',
    hostId: hostId,
    memberIds: List<String>.from(members),
    inviteCode: generateInviteCode(rng),
    languageCode: languageCode,
  );
}

/// Append a sentence for the active player; advances turn or completes chain.
StoryChainCircle appendSentence({
  required StoryChainCircle circle,
  required String playerId,
  required String sentenceId,
  required String text,
  String? audioAssetKey,
  String? illustrationKey,
}) {
  if (!circle.isMembersTurn(playerId)) {
    throw StateError('not_your_turn');
  }
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('empty_sentence');
  }
  circle.sentences.add(
    StoryChainSentence(
      id: sentenceId,
      authorId: playerId,
      text: trimmed,
      turnIndex: circle.sentences.length,
      audioAssetKey: audioAssetKey,
      illustrationKey: illustrationKey,
    ),
  );
  circle.currentTurnIndex += 1;
  if (circle.sentences.length >= circle.maxTurns) {
    circle.completed = true;
  }
  return circle;
}

StoryChainSentence applyGrammarChoice({
  required StoryChainSentence sentence,
  required bool acceptSuggestion,
  required StoryGrammarSuggestion suggestion,
}) {
  if (suggestion.unavailable) {
    return sentence;
  }
  if (!acceptSuggestion) {
    return StoryChainSentence(
      id: sentence.id,
      authorId: sentence.authorId,
      text: sentence.text,
      turnIndex: sentence.turnIndex,
      audioAssetKey: sentence.audioAssetKey,
      illustrationKey: sentence.illustrationKey,
      moderation: sentence.moderation,
      acceptedGrammarFix: false,
      finalText: sentence.text,
    );
  }
  final fixed = suggestion.suggestedText.trim().isEmpty
      ? sentence.text
      : suggestion.suggestedText.trim();
  return StoryChainSentence(
    id: sentence.id,
    authorId: sentence.authorId,
    text: sentence.text,
    turnIndex: sentence.turnIndex,
    audioAssetKey: sentence.audioAssetKey,
    illustrationKey: sentence.illustrationKey,
    moderation: sentence.moderation,
    acceptedGrammarFix: true,
    finalText: fixed,
  );
}

StoryChainSentence markModerationFlagged(StoryChainSentence sentence) {
  return StoryChainSentence(
    id: sentence.id,
    authorId: sentence.authorId,
    text: sentence.text,
    turnIndex: sentence.turnIndex,
    audioAssetKey: sentence.audioAssetKey,
    illustrationKey: sentence.illustrationKey,
    moderation: StorySentenceModeration.flagged,
    acceptedGrammarFix: sentence.acceptedGrammarFix,
    finalText: sentence.finalText,
  );
}

List<StoryChainSentence> sentencesForPlayback(StoryChainCircle circle) {
  final sorted = List<StoryChainSentence>.from(circle.sentences)
    ..sort((a, b) => a.turnIndex.compareTo(b.turnIndex));
  return sorted.where((s) => s.includedInPlayback).toList(growable: false);
}
