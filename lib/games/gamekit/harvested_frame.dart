import 'dart:math';

import 'package:flutter/material.dart';

import '../../screens/games/templates/game_template_shell.dart';

/// Six template classes live under lib/screens/games/templates/.
/// A seventh template class is not in the repo.
const String kGameKitMissingTemplate = 'not present';

const int kGameKitStartGuideStepCap = 3;

const Duration kGameKitLoadingPulse = Duration(milliseconds: 2400);
const Duration kGameKitLoadingProgress = Duration(seconds: 8);
const Duration kGameKitLoadingDots = Duration(milliseconds: 1800);

/// Facts from the universal loading screen. Em dashes in that file were
/// replaced with periods so the GameKit copy stays plain text.
const List<String> kGameKitLoadingFacts = [
  'Yoruba has 3 tonal levels. High, mid, and low change word meaning entirely.',
  'Swahili is spoken by over 100 million people across East Africa.',
  'The Ge\'ez script used for Amharic has 231 characters. It is one of the oldest alphabets still in use.',
  'Zulu has 15 noun classes, each affecting verbs, adjectives, and pronouns.',
  'Wolof greetings can last several minutes. They are a form of social bonding.',
];

enum GameKitTemplateKind {
  matchBoard,
  narrative,
  pronunciation,
  rhythm,
  strategic,
  timedQuiz,
}

class GameKitTemplateSlots {
  const GameKitTemplateSlots({
    required this.playSlot,
    required this.actionSlot,
  });

  final String playSlot;
  final String actionSlot;
}

/// Slot names copied from the six template constructors.
GameKitTemplateSlots gameKitTemplateSlots(GameKitTemplateKind kind) {
  switch (kind) {
    case GameKitTemplateKind.matchBoard:
      return const GameKitTemplateSlots(
        playSlot: 'board',
        actionSlot: 'controls',
      );
    case GameKitTemplateKind.narrative:
      return const GameKitTemplateSlots(
        playSlot: 'narrativeContent',
        actionSlot: 'actions',
      );
    case GameKitTemplateKind.pronunciation:
      return const GameKitTemplateSlots(
        playSlot: 'content',
        actionSlot: 'micControls',
      );
    case GameKitTemplateKind.rhythm:
      return const GameKitTemplateSlots(
        playSlot: 'rhythmArea',
        actionSlot: 'controls',
      );
    case GameKitTemplateKind.strategic:
      return const GameKitTemplateSlots(
        playSlot: 'board',
        actionSlot: 'controls',
      );
    case GameKitTemplateKind.timedQuiz:
      return const GameKitTemplateSlots(
        playSlot: 'questionArea',
        actionSlot: 'actions',
      );
  }
}

/// [factText] wins, including an empty string. Otherwise the list is indexed
/// with the caller's [Random], so one seed returns one fact.
String gameKitLoadingFact({String? factText, required Random random}) {
  if (factText != null) return factText;
  return kGameKitLoadingFacts[random.nextInt(kGameKitLoadingFacts.length)];
}

/// Dot index from the loading screen: `(value * 3).floor()` clamped to 0..2.
int gameKitLoadingDotIndex(double animationValue) {
  final scaled = (animationValue * 3).floor();
  if (scaled < 0) return 0;
  if (scaled > 2) return 2;
  return scaled;
}

bool gameKitLoadingShowsSkip(bool hasSkip) => hasSkip;

bool gameKitLoadingShowsBack(bool canPop) => canPop;

/// The start guide paints the first three steps and drops the rest.
List<String> gameKitStartGuideSteps(List<String> steps) {
  if (steps.length <= kGameKitStartGuideStepCap) {
    return List<String>.from(steps);
  }
  return steps.take(kGameKitStartGuideStepCap).toList();
}

String gameKitVictoryXpLabel(int xpEarned) => '+$xpEarned';

String gameKitStartGuideXpLabel(int objectiveXp) => '+$objectiveXp XP';

/// Mastery bar fraction from the victory screen: percent divided by 100.
double gameKitVictoryMasteryFraction(int masteryPercent) =>
    masteryPercent / 100;

class GameKitTemplateFrame extends StatelessWidget {
  const GameKitTemplateFrame({
    super.key,
    required this.kind,
    required this.title,
    required this.play,
    this.action,
    this.loading = false,
    this.progressLabel,
    this.languageLabel,
    this.scoreLabel,
  });

  final GameKitTemplateKind kind;
  final String title;
  final Widget play;
  final Widget? action;
  final bool loading;
  final String? progressLabel;
  final String? languageLabel;
  final String? scoreLabel;

  @override
  Widget build(BuildContext context) {
    final slots = gameKitTemplateSlots(kind);
    return GameTemplateShell(
      title: title,
      languageLabel: languageLabel,
      progressLabel: progressLabel,
      scoreLabel: scoreLabel,
      loading: loading,
      playArea: KeyedSubtree(
        key: ValueKey<String>(slots.playSlot),
        child: play,
      ),
      actionBar: action == null
          ? null
          : KeyedSubtree(
              key: ValueKey<String>(slots.actionSlot),
              child: action!,
            ),
    );
  }
}

class GameKitLoadingView extends StatelessWidget {
  const GameKitLoadingView({
    super.key,
    required this.fact,
    this.onSkip,
    this.canPop = false,
    this.dotIndex = 0,
    this.onBack,
  });

  final String fact;
  final VoidCallback? onSkip;
  final bool canPop;
  final int dotIndex;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeDot = dotIndex < 0 ? 0 : (dotIndex > 2 ? 2 : dotIndex);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('LingAfriq', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text('Did You Know?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(fact, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(3, (index) {
            final active = index == activeDot;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.circle,
                key: ValueKey<int>(index),
                size: active ? 10 : 6,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: active ? 0.9 : 0.35,
                ),
              ),
            );
          }),
        ),
        if (gameKitLoadingShowsSkip(onSkip != null))
          TextButton(onPressed: onSkip, child: const Text('Skip')),
        if (gameKitLoadingShowsBack(canPop))
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
      ],
    );
  }
}

class GameKitStartGuideInput {
  const GameKitStartGuideInput({
    required this.gameTitle,
    required this.gameDescription,
    required this.objectiveXp,
    required this.culturalTip,
    required this.steps,
    required this.characterName,
    required this.characterTitle,
  });

  final String gameTitle;
  final String gameDescription;
  final int objectiveXp;
  final String culturalTip;
  final List<String> steps;
  final String characterName;
  final String characterTitle;
}

class GameKitStartGuideView extends StatelessWidget {
  const GameKitStartGuideView({
    super.key,
    required this.input,
    required this.onStart,
    this.onReviewVocab,
  });

  final GameKitStartGuideInput input;
  final VoidCallback onStart;
  final VoidCallback? onReviewVocab;

  @override
  Widget build(BuildContext context) {
    final shown = gameKitStartGuideSteps(input.steps);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(input.characterName, style: theme.textTheme.titleLarge),
          Text(input.characterTitle),
          Text(input.gameTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(gameKitStartGuideXpLabel(input.objectiveXp)),
          const Text('Mission Objective'),
          Text(input.gameDescription),
          const SizedBox(height: 12),
          const Text('How to Play'),
          for (var i = 0; i < shown.length; i++) Text('${i + 1}. ${shown[i]}'),
          const SizedBox(height: 12),
          const Text('Cultural Tip'),
          Text(input.culturalTip),
          const SizedBox(height: 16),
          FilledButton(onPressed: onStart, child: const Text('Start Mission')),
          TextButton(
            onPressed: onReviewVocab,
            child: const Text('Review Vocabulary'),
          ),
        ],
      ),
    );
  }
}

class GameKitVictoryInput {
  const GameKitVictoryInput({
    required this.xpEarned,
    required this.vocabularyLearned,
    required this.finalScore,
    required this.masteryPercent,
    required this.griotRank,
    required this.idiomsLearnt,
  });

  final int xpEarned;
  final int vocabularyLearned;
  final int finalScore;
  final int masteryPercent;
  final String griotRank;
  final int idiomsLearnt;
}

class GameKitVictoryView extends StatelessWidget {
  const GameKitVictoryView({
    super.key,
    required this.input,
    required this.onClaimRewards,
    this.onReplayMission,
  });

  final GameKitVictoryInput input;
  final VoidCallback onClaimRewards;
  final VoidCallback? onReplayMission;

  @override
  Widget build(BuildContext context) {
    final fraction = gameKitVictoryMasteryFraction(input.masteryPercent);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Mission complete'),
          const Text('Mission Complete!'),
          const Text('You\'ve earned your rewards'),
          Text(gameKitVictoryXpLabel(input.xpEarned)),
          const Text('XP'),
          Text('${input.vocabularyLearned}'),
          const Text('Vocabulary'),
          Text('${input.finalScore}'),
          const Text('Score'),
          const Text('Mastery Insights'),
          const Text('Idioms Learnt'),
          Text('${input.idiomsLearnt}'),
          const Text('Griot Rank'),
          Text(input.griotRank),
          Text('${input.masteryPercent}%'),
          LinearProgressIndicator(
            key: const Key('gamekit-victory-mastery'),
            value: fraction,
          ),
          FilledButton(
            onPressed: onClaimRewards,
            child: const Text('Claim Rewards'),
          ),
          TextButton(
            onPressed: onReplayMission,
            child: const Text('Replay Mission'),
          ),
        ],
      ),
    );
  }
}
