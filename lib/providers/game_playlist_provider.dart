import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/game/game_session_model.dart';
import '../providers/progress_tracking_provider.dart';
import '../services/adaptive_learning_service.dart';
import '../providers/experiments_provider.dart';

/// A recommended playlist of games for the current learner,
/// ordered from most impactful to nice-to-have.
class GamePlaylist {
  final List<GameType> primary;
  final List<GameType> secondary;
  final String rationale;

  const GamePlaylist({
    required this.primary,
    required this.secondary,
    required this.rationale,
  });
}

/// Computes a dynamic, curriculum/CEFR-aware game playlist.
/// Uses:
/// - CEFR level + SRS stats from Polie (adaptiveLearningProvider)
/// - Progress metrics from progressTrackingProvider (listening/speaking/reading time)
final gamePlaylistProvider = Provider<GamePlaylist>((ref) {
  final experiments = ref.watch(experimentsProvider);
  final adaptive = ref.read(adaptiveLearningProvider);
  final metrics = ref.read(progressTrackingProvider.notifier).metrics;

  final cefr = adaptive.cefrLevel; // e.g. "A1", "B1"
  final dueSrs = adaptive.dueSrsItems;
  final totalSrs = adaptive.totalSrsItems;

  final listeningHours = metrics.listeningHours;
  final speakingHours = metrics.speakingHours;
  final totalHours =
      listeningHours + speakingHours + (metrics.timeSpentMinutes / 60.0);

  final listeningShare =
      totalHours > 0 ? (listeningHours / totalHours) : 0.0;
  final speakingShare =
      totalHours > 0 ? (speakingHours / totalHours) : 0.0;

  // Buckets by skill focus
  const vocabGames = <GameType>[
    GameType.wordMatchAudio,
    GameType.flashcardSafari,
    GameType.quizChef,
    GameType.foodQuest,
  ];

  const pronunciationGames = <GameType>[
    GameType.pronunciationDuel,
    GameType.pronunciationKaraoke,
    GameType.rapidTongueTwisterRace,
    GameType.drumRhythmShadowing,
    GameType.rhythmTyping,
    GameType.callAndResponse,
  ];

  const conversationGames = <GameType>[
    GameType.conversationRelay,
    GameType.roleplayAdventure,
    GameType.villageQuest,
    GameType.marketBargainingSimulator,
    GameType.greetingDiplomacyChallenge,
  ];

  const cultureGames = <GameType>[
    GameType.proverbUnlocker,
    GameType.folktaleReconstruction,
    GameType.clanLineageStoryBuilder,
    GameType.culturalEtiquetteScenarios,
    GameType.eldersBlessingsChallenge,
    GameType.multilingualRelayRace,
  ];

  // Start from the full set of implemented games used in the modern UI
  const allGames = <GameType>[
    GameType.wordMatchAudio,
    GameType.pronunciationDuel,
    GameType.speedRoundRemix,
    GameType.toneTrainer,
    GameType.storyBuilder,
    GameType.roleplayAdventure,
    GameType.grammarDetective,
    GameType.listenAndSketch,
    GameType.pictureWordAssociation,
    GameType.memoryMap,
    GameType.conversationRelay,
    GameType.grammarJam,
    GameType.pronunciationKaraoke,
    GameType.quizChef,
    GameType.proverbUnlocker,
    GameType.drumRhythmShadowing,
    GameType.clanLineageStoryBuilder,
    GameType.marketBargainingSimulator,
    GameType.taxiBusStopSurvival,
    GameType.foodQuest,
    GameType.callAndResponse,
    GameType.greetingDiplomacyChallenge,
    GameType.folktaleReconstruction,
    GameType.phraseSniper,
    GameType.liarLiar,
    GameType.villageQuest,
    GameType.accentDecodingPuzzle,
    GameType.flashcardSafari,
    GameType.rapidTongueTwisterRace,
    GameType.emojiTranslator,
    GameType.rhythmTyping,
    GameType.eldersBlessingsChallenge,
    GameType.multilingualRelayRace,
    GameType.culturalEtiquetteScenarios,
    GameType.drumToWordMatching,
  ];

  // --- Strategy selection via experiments ---
  final playlistStrategy =
      experiments.variants['games_playlist_treatment'] ?? 'standard';

  // Baseline strategy: static curated mix that ignores telemetry.
  if (playlistStrategy == 'baseline') {
    const primary = <GameType>[
      GameType.wordMatchAudio,
      GameType.pronunciationDuel,
      GameType.storyBuilder,
      GameType.villageQuest,
      GameType.proverbUnlocker,
      GameType.foodQuest,
    ];
    const secondary = <GameType>[
      GameType.grammarDetective,
      GameType.toneTrainer,
      GameType.pronunciationKaraoke,
      GameType.flashcardSafari,
      GameType.marketBargainingSimulator,
      GameType.multilingualRelayRace,
      GameType.culturalEtiquetteScenarios,
      GameType.rapidTongueTwisterRace,
      GameType.drumRhythmShadowing,
    ];

    return const GamePlaylist(
      primary: primary,
      secondary: secondary,
      rationale:
          'Baseline playlist: a curated mix of core vocab, pronunciation, stories, and culture games.',
    );
  }

  // --- Adaptive strategy (default) ---

  // Scoring per game
  final Map<GameType, double> scores = {
    for (final g in allGames) g: 0.0,
  };

  // 1) Vocabulary review pressure: lots of due SRS items -> boost vocab games
  if (dueSrs > 0) {
    final pressure =
        totalSrs > 0 ? (dueSrs / totalSrs).clamp(0.0, 1.0) : 0.5;
    for (final g in vocabGames) {
      scores[g] = scores[g]! + 3.0 * pressure;
    }
  }

  // 2) Speaking / listening deficits -> boost pronunciation & conversation games
  if (speakingShare < 0.25) {
    for (final g in pronunciationGames) {
      scores[g] = scores[g]! + 2.5;
    }
  }
  if (listeningShare < 0.25) {
    for (final g in pronunciationGames) {
      scores[g] = scores[g]! + 1.5;
    }
  }

  // 3) CEFR level: early learners focus on core vocab + simple pronunciation;
  // higher-level learners see more conversation/culture.
  final upperCefr = cefr.toUpperCase();
  if (upperCefr.startsWith('A')) {
    for (final g in vocabGames) {
      scores[g] = scores[g]! + 2.0;
    }
    for (final g in pronunciationGames) {
      scores[g] = scores[g]! + 1.5;
    }
  } else if (upperCefr.startsWith('B')) {
    for (final g in conversationGames) {
      scores[g] = scores[g]! + 2.5;
    }
    for (final g in cultureGames) {
      scores[g] = scores[g]! + 1.5;
    }
  } else {
    // C-level: prioritize rich conversation + culture
    for (final g in conversationGames) {
      scores[g] = scores[g]! + 3.0;
    }
    for (final g in cultureGames) {
      scores[g] = scores[g]! + 2.0;
    }
  }

  // 4) Always keep a few high-value core games in rotation
  const anchorGames = <GameType>[
    GameType.wordMatchAudio,
    GameType.pronunciationDuel,
    GameType.proverbUnlocker,
    GameType.villageQuest,
  ];
  for (final g in anchorGames) {
    scores[g] = scores[g]! + 1.0;
  }

  // Sort games by score (descending) and take top-N as primary
  final sorted = List<GameType>.from(allGames)
    ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

  final primary = sorted.take(6).toList();
  final secondary = sorted.skip(6).take(12).toList();

  final rationale =
      'Playlist tuned for CEFR $cefr, with ${dueSrs > 0 ? '$dueSrs review items' : 'fresh practice'} '
      'and speaking/listening balance (speaking ${(speakingShare * 100).toStringAsFixed(0)}%).';

  return GamePlaylist(
    primary: primary,
    secondary: secondary,
    rationale: rationale,
  );
});

