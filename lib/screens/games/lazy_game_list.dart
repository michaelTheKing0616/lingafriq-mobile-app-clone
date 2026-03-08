import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'language_games_screen_components.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Lazy-loaded game list with pagination
class LazyGameList extends HookConsumerWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;
  final Function(GameType) onGameSelected;

  const LazyGameList({super.key, 
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coreGamesPage = useState(0);
    final culturalGamesPage = useState(0);
    final isLoadingMore = useState(false);
    
    const gamesPerPage = 6;
    
    final allCoreGames = [
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
      GameType.scrabbleSprintArena,
    ];
    
    final allCulturalGames = [
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
      GameType.marketMonopolyChallenge,
    ];
    
    final visibleCoreGames = allCoreGames.take((coreGamesPage.value + 1) * gamesPerPage).toList();
    final visibleCulturalGames = allCulturalGames.take((culturalGamesPage.value + 1) * gamesPerPage).toList();
    
    final hasMoreCore = visibleCoreGames.length < allCoreGames.length;
    final hasMoreCultural = visibleCulturalGames.length < allCulturalGames.length;
    
    // Preload games when they become visible
    useEffect(() {
      final loader = ref.read(lazyGameLoaderProvider);
      Future.microtask(() async {
        for (final game in visibleCoreGames) {
          await loader.loadGameOnDemand(game);
        }
        for (final game in visibleCulturalGames) {
          await loader.loadGameOnDemand(game);
        }
      });
      return null;
    }, [visibleCoreGames.length, visibleCulturalGames.length]);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Language selector
          LanguageSelector(
            selectedLanguage: selectedLanguage,
            onLanguageChanged: onLanguageChanged,
          ),
          SizedBox(height: 2.h),
          // Core Games Section with Lazy Loading
          GameSection(
            title: 'Core Games',
            games: visibleCoreGames,
            onGameSelected: onGameSelected,
          ),
          if (hasMoreCore)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: FilledButton.icon(
                onPressed: () async {
                  isLoadingMore.value = true;
                  await Future.delayed(const Duration(milliseconds: 300));
                  coreGamesPage.value++;
                  isLoadingMore.value = false;
                },
                icon: isLoadingMore.value
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text('Load More Core Games'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          SizedBox(height: 2.h),
          // Cultural Games Section with Lazy Loading
          GameSection(
            title: 'Cultural Games',
            games: visibleCulturalGames,
            onGameSelected: onGameSelected,
          ),
          if (hasMoreCultural)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: FilledButton.icon(
                onPressed: () async {
                  isLoadingMore.value = true;
                  await Future.delayed(const Duration(milliseconds: 300));
                  culturalGamesPage.value++;
                  isLoadingMore.value = false;
                },
                icon: isLoadingMore.value
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text('Load More Cultural Games'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  foregroundColor: Colors.purple,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

