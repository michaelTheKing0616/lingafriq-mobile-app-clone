import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'package:lingafriq/providers/game_playlist_provider.dart';
import 'language_games_screen_components.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/supported_languages.dart';

/// Lazy-loaded game list with pagination
class LazyGameList extends HookConsumerWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;
  final Function(GameType) onGameSelected;

  const LazyGameList({
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
    ];
    
    final visibleCoreGames = allCoreGames.take((coreGamesPage.value + 1) * gamesPerPage).toList();
    final visibleCulturalGames = allCulturalGames.take((culturalGamesPage.value + 1) * gamesPerPage).toList();
    
    final hasMoreCore = visibleCoreGames.length < allCoreGames.length;
    final hasMoreCultural = visibleCulturalGames.length < allCulturalGames.length;

    // Polie-powered dynamic playlist
    final playlist = ref.watch(gamePlaylistProvider);
    
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
          _LanguageSelector(
            selectedLanguage: selectedLanguage,
            onLanguageChanged: onLanguageChanged,
          ),
          SizedBox(height: 2.h),
          // Polie-recommended row
          if (playlist.primary.isNotEmpty)
            _GameSection(
              title: 'Polie Recommends',
              games: playlist.primary,
              onGameSelected: onGameSelected,
            ),
          if (playlist.secondary.isNotEmpty) SizedBox(height: 2.h),
          // Core Games Section with Lazy Loading
          _GameSection(
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
          _GameSection(
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

class _LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;

  const _LanguageSelector({
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = SupportedLanguages.getLanguageOptions();
    final items = options
        .map((o) => DropdownMenuItem<String>(
              value: (o['name'] ?? '').toLowerCase(),
              child: Text('${o['flag'] ?? ''} ${o['name'] ?? ''}'.trim()),
            ))
        .toList();

    return Row(
      children: [
        const Icon(Icons.language_rounded),
        SizedBox(width: 2.w),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedLanguage.isEmpty ? null : selectedLanguage.toLowerCase(),
            items: items,
            onChanged: (v) {
              if (v != null) onLanguageChanged(v);
            },
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _GameSection extends StatelessWidget {
  final String title;
  final List<GameType> games;
  final Function(GameType) onGameSelected;

  const _GameSection({
    required this.title,
    required this.games,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 1.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return InkWell(
              onTap: () => onGameSelected(game),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_esports_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        game.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
