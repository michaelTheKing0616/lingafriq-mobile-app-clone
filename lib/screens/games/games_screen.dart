import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/modern_card.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';
import 'package:lingafriq/screens/games/word_match_game.dart';
import 'package:lingafriq/screens/games/speed_challenge_game.dart';
import 'package:lingafriq/screens/games/pronunciation_game.dart';
import 'package:lingafriq/screens/games/game_router.dart';
import 'package:lingafriq/models/game/game_session_model.dart';

final languagesForGamesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(apiProvider.notifier).getLanguages();
});

class GamesScreen extends ConsumerWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      errorMessage: 'Language Games are temporarily unavailable',
      onRetry: () {
        // Retry by invalidating provider
        ref.invalidate(languagesForGamesProvider);
      },
      child: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesForGamesProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          TopGradientBox(
            borderRadius: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu_rounded, color: Colors.white),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Language Games',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Learn through play',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: languagesAsync.when(
              data: (languageResponse) {
                final languages = languageResponse.results;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a Language',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: context.adaptive,
                        ),
                      ).py8(),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: languages.length,
                        itemBuilder: (context, index) {
                          final language = languages[index];
                          return _GameLanguageCard(
                            language: language,
                            onTap: () {
                              ref.read(navigationProvider).navigateTo(
                                GameTypesScreen(language: language),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
              error: (e, s) => StreamErrorWidget(
                error: e,
                onTryAgain: () {
                  ref.invalidate(languagesForGamesProvider);
                },
              ),
              loading: () => const DynamicLoadingScreen(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameLanguageCard extends StatelessWidget {
  final Language language;
  final VoidCallback onTap;

  const _GameLanguageCard({
    Key? key,
    required this.language,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen,
                  AppColors.accentGold,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.games_rounded,
              color: Colors.white,
              size: 30.sp,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            language.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.adaptive,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Game Types Selection Screen
class GameTypesScreen extends ConsumerWidget {
  final Language language;

  const GameTypesScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Games - ${language.name}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen,
                AppColors.accentGold,
                AppColors.accentOrange,
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a Game',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: context.adaptive,
              ),
            ).py8(),
            const SizedBox(height: 16),
            // Show all registered games
            ...GameType.values.map((gameType) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GameTypeCard(
                icon: _getGameIcon(gameType),
                title: gameType.displayName,
                description: _getGameDescription(gameType),
                color: _getGameColor(gameType),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => buildGameScreen(
                        gameType: gameType,
                        language: language.name,
                        ref: ref,
                      ),
                    ),
                  );
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Get icon for game type
  IconData _getGameIcon(GameType gameType) {
    switch (gameType) {
      case GameType.wordMatchAudio:
        return Icons.quiz_rounded;
      case GameType.pronunciationDuel:
      case GameType.pronunciationKaraoke:
        return Icons.volume_up_rounded;
      case GameType.speedRoundRemix:
        return Icons.flash_on_rounded;
      case GameType.toneTrainer:
        return Icons.music_note_rounded;
      case GameType.storyBuilder:
      case GameType.clanLineageStoryBuilder:
        return Icons.auto_stories_rounded;
      case GameType.roleplayAdventure:
        return Icons.theater_comedy_rounded;
      case GameType.grammarDetective:
      case GameType.grammarJam:
        return Icons.search_rounded;
      case GameType.proverbUnlocker:
        return Icons.lightbulb_rounded;
      case GameType.drumRhythmShadowing:
      case GameType.drumToWordMatching:
        return Icons.music_video_rounded;
      case GameType.taxiBusStopSurvival:
        return Icons.directions_bus_rounded;
      case GameType.foodQuest:
        return Icons.restaurant_rounded;
      case GameType.callAndResponse:
        return Icons.call_rounded;
      case GameType.greetingDiplomacyChallenge:
        return Icons.handshake_rounded;
      case GameType.folktaleReconstruction:
        return Icons.menu_book_rounded;
      case GameType.phraseSniper:
        return Icons.gps_fixed_rounded;
      case GameType.liarLiar:
        return Icons.psychology_rounded;
      case GameType.villageQuest:
        return Icons.location_city_rounded;
      case GameType.accentDecodingPuzzle:
        return Icons.puzzle_rounded;
      case GameType.flashcardSafari:
        return Icons.style_rounded;
      case GameType.rapidTongueTwisterRace:
        return Icons.speed_rounded;
      case GameType.emojiTranslator:
        return Icons.emoji_emotions_rounded;
      case GameType.rhythmTyping:
        return Icons.keyboard_rounded;
      case GameType.eldersBlessingsChallenge:
        return Icons.favorite_rounded;
      case GameType.multilingualRelayRace:
        return Icons.repeat_rounded;
      case GameType.culturalEtiquetteScenarios:
        return Icons.people_rounded;
      case GameType.listenAndSketch:
        return Icons.draw_rounded;
      case GameType.pictureWordAssociation:
        return Icons.image_rounded;
      case GameType.memoryMap:
        return Icons.map_rounded;
      case GameType.conversationRelay:
        return Icons.chat_bubble_rounded;
      case GameType.marketBargainingSimulator:
        return Icons.shopping_cart_rounded;
      case GameType.quizChef:
        return Icons.restaurant_menu_rounded;
    }
  }

  /// Get description for game type
  String _getGameDescription(GameType gameType) {
    switch (gameType) {
      case GameType.wordMatchAudio:
        return 'Match words with their translations';
      case GameType.pronunciationDuel:
        return 'Compete in pronunciation challenges';
      case GameType.speedRoundRemix:
        return 'Answer questions as fast as you can';
      case GameType.toneTrainer:
        return 'Master tones and pronunciation';
      case GameType.storyBuilder:
        return 'Build stories in your target language';
      case GameType.roleplayAdventure:
        return 'Practice real-world scenarios';
      case GameType.grammarDetective:
        return 'Solve grammar mysteries';
      case GameType.proverbUnlocker:
        return 'Learn African proverbs and wisdom';
      case GameType.drumRhythmShadowing:
        return 'Learn through rhythm and music';
      case GameType.clanLineageStoryBuilder:
        return 'Build stories about your heritage';
      case GameType.marketBargainingSimulator:
        return 'Practice bargaining at markets';
      case GameType.taxiBusStopSurvival:
        return 'Navigate transportation scenarios';
      case GameType.foodQuest:
        return 'Learn food vocabulary and culture';
      case GameType.callAndResponse:
        return 'Practice call-and-response patterns';
      case GameType.greetingDiplomacyChallenge:
        return 'Master cultural greetings';
      case GameType.folktaleReconstruction:
        return 'Reconstruct African folktales';
      case GameType.phraseSniper:
        return 'Quick-fire phrase recognition';
      case GameType.liarLiar:
        return 'Detect truth from fiction';
      case GameType.villageQuest:
        return 'Explore village life scenarios';
      case GameType.accentDecodingPuzzle:
        return 'Decode different accents';
      case GameType.flashcardSafari:
        return 'Learn vocabulary on safari';
      case GameType.rapidTongueTwisterRace:
        return 'Master tongue twisters';
      case GameType.emojiTranslator:
        return 'Translate emojis to words';
      case GameType.rhythmTyping:
        return 'Type to the rhythm';
      case GameType.eldersBlessingsChallenge:
        return 'Learn respectful language';
      case GameType.multilingualRelayRace:
        return 'Switch between languages';
      case GameType.culturalEtiquetteScenarios:
        return 'Practice cultural etiquette';
      case GameType.drumToWordMatching:
        return 'Match drum patterns to words';
      case GameType.listenAndSketch:
        return 'Listen and draw';
      case GameType.pictureWordAssociation:
        return 'Associate pictures with words';
      case GameType.memoryMap:
        return 'Navigate with memory';
      case GameType.conversationRelay:
        return 'Pass conversations along';
      case GameType.grammarJam:
        return 'Jam with grammar';
      case GameType.pronunciationKaraoke:
        return 'Sing and learn pronunciation';
      case GameType.quizChef:
        return 'Cook up language knowledge';
    }
  }

  /// Get color for game type
  Color _getGameColor(GameType gameType) {
    final colors = [
      AppColors.primaryGreen,
      AppColors.accentOrange,
      AppColors.oceanBlue,
      AppColors.accentGold,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[gameType.index % colors.length];
  }
}

class _GameTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _GameTypeCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30.sp,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.adaptive,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.adaptive54,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: context.adaptive54,
          ),
        ],
      ),
    );
  }
}

