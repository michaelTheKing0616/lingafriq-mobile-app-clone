import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart' hide ErrorBoundary;
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/game_router.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_onboarding_overlay.dart';

const _gameRules = <GameType, String>{
  GameType.wordMatchAudio: 'Match African language words on the left with their English meanings on the right. Tap a word to hear its pronunciation!',
  GameType.pronunciationDuel: 'Listen to the native pronunciation, then record yourself saying the word. Score 85+ to win each round!',
  GameType.speedRoundRemix: 'Choose the correct translation as fast as you can! You have 60 seconds.',
  GameType.scrabbleSprintArena: 'Build valid words using the given letters. Longer words score more points!',
  GameType.roleplayAdventure: 'Choose the best response in a real-life scenario. Practice natural conversation!',
  GameType.grammarDetective: 'Find and fix the grammar error in each sentence.',
  GameType.storyBuilder: 'Continue the story using your target language. Get creative!',
};

/// Beautiful Material 3 Games Screen
class GamesScreenMaterial3 extends HookConsumerWidget {
  const GamesScreenMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState('yoruba');
    final selectedCategory = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'afrikaans', 'pidgin'];
    final categories = ['All', 'Vocabulary', 'Grammar', 'Pronunciation', 'Cultural'];
    final selectedSection = useState('core');
    final isLoading = useState(false);

    // ALL 35+ GAMES PROPERLY CATEGORIZED
    final coreGames = [
      {'name': 'Word Match Audio', 'description': 'Match words with audio', 'category': 'Vocabulary', 'icon': Icons.headphones, 'type': GameType.wordMatchAudio},
      {'name': 'Pronunciation Duel', 'description': 'Master pronunciation', 'category': 'Pronunciation', 'icon': Icons.record_voice_over, 'type': GameType.pronunciationDuel},
      {'name': 'Speed Round', 'description': 'Fast-paced vocabulary', 'category': 'Vocabulary', 'icon': Icons.speed, 'type': GameType.speedRoundRemix},
      {'name': 'Story Builder', 'description': 'Build stories', 'category': 'Grammar', 'icon': Icons.auto_stories, 'type': GameType.storyBuilder},
      {'name': 'Roleplay Adventure', 'description': 'Interactive conversations', 'category': 'Cultural', 'icon': Icons.theater_comedy, 'type': GameType.roleplayAdventure},
      {'name': 'Grammar Detective', 'description': 'Solve grammar mysteries', 'category': 'Grammar', 'icon': Icons.search, 'type': GameType.grammarDetective},
      {'name': 'Listen & Sketch', 'description': 'Draw what you hear', 'category': 'Vocabulary', 'icon': Icons.draw, 'type': GameType.listenAndSketch},
      {'name': 'Picture Word Match', 'description': 'Match words with images', 'category': 'Vocabulary', 'icon': Icons.image, 'type': GameType.pictureWordAssociation},
      {'name': 'Memory Map', 'description': 'Memory challenge', 'category': 'Vocabulary', 'icon': Icons.map, 'type': GameType.memoryMap},
      {'name': 'Conversation Relay', 'description': 'Chain conversations', 'category': 'Cultural', 'icon': Icons.chat, 'type': GameType.conversationRelay},
      {'name': 'Grammar Jam', 'description': 'Grammar rhythm game', 'category': 'Grammar', 'icon': Icons.music_note, 'type': GameType.grammarJam},
      {'name': 'Pronunciation Karaoke', 'description': 'Sing and pronounce', 'category': 'Pronunciation', 'icon': Icons.mic, 'type': GameType.pronunciationKaraoke},
      {'name': 'Quiz Chef', 'description': 'Cook up answers', 'category': 'Vocabulary', 'icon': Icons.restaurant, 'type': GameType.quizChef},
      {'name': 'Scrabble Sprint', 'description': 'Build words under pressure', 'category': 'Vocabulary', 'icon': Icons.spellcheck, 'type': GameType.scrabbleSprintArena},
    ];

    final culturalGames = [
      {'name': 'Proverb Unlocker', 'description': 'Unlock wisdom', 'category': 'Cultural', 'icon': Icons.auto_awesome, 'type': GameType.proverbUnlocker},
      {'name': 'Drum Rhythm', 'description': 'Follow the rhythm', 'category': 'Pronunciation', 'icon': Icons.music_note, 'type': GameType.drumRhythmShadowing},
      {'name': 'Clan Story Builder', 'description': 'Build clan stories', 'category': 'Cultural', 'icon': Icons.account_tree, 'type': GameType.clanLineageStoryBuilder},
      {'name': 'Market Bargaining', 'description': 'Practice bargaining', 'category': 'Cultural', 'icon': Icons.store, 'type': GameType.marketBargainingSimulator},
      {'name': 'Taxi Survival', 'description': 'Navigate transportation', 'category': 'Cultural', 'icon': Icons.directions_transit, 'type': GameType.taxiBusStopSurvival},
      {'name': 'Food Quest', 'description': 'Explore cuisine', 'category': 'Cultural', 'icon': Icons.restaurant_menu, 'type': GameType.foodQuest},
      {'name': 'Call & Response', 'description': 'Traditional patterns', 'category': 'Cultural', 'icon': Icons.call, 'type': GameType.callAndResponse},
      {'name': 'Greeting Diplomacy', 'description': 'Master greetings', 'category': 'Cultural', 'icon': Icons.waving_hand, 'type': GameType.greetingDiplomacyChallenge},
      {'name': 'Folktale Builder', 'description': 'Rebuild stories', 'category': 'Cultural', 'icon': Icons.book, 'type': GameType.folktaleReconstruction},
      {'name': 'Phrase Sniper', 'description': 'Target phrases', 'category': 'Vocabulary', 'icon': Icons.center_focus_strong, 'type': GameType.phraseSniper},
      {'name': 'Liar Liar', 'description': 'Detect truth', 'category': 'Grammar', 'icon': Icons.psychology, 'type': GameType.liarLiar},
      {'name': 'Village Quest', 'description': 'Adventure quest', 'category': 'Cultural', 'icon': Icons.explore, 'type': GameType.villageQuest},
      {'name': 'Accent Puzzle', 'description': 'Decode accents', 'category': 'Pronunciation', 'icon': Icons.extension, 'type': GameType.accentDecodingPuzzle},
      {'name': 'Flashcard Safari', 'description': 'Safari vocabulary', 'category': 'Vocabulary', 'icon': Icons.flash_on, 'type': GameType.flashcardSafari},
      {'name': 'Tongue Twister', 'description': 'Master twisters', 'category': 'Pronunciation', 'icon': Icons.speed, 'type': GameType.rapidTongueTwisterRace},
      {'name': 'Emoji Translator', 'description': 'Translate emojis', 'category': 'Vocabulary', 'icon': Icons.emoji_emotions, 'type': GameType.emojiTranslator},
      {'name': 'Rhythm Typing', 'description': 'Type to rhythm', 'category': 'Vocabulary', 'icon': Icons.keyboard, 'type': GameType.rhythmTyping},
      {'name': 'Elders Blessings', 'description': 'Learn blessings', 'category': 'Cultural', 'icon': Icons.favorite, 'type': GameType.eldersBlessingsChallenge},
      {'name': 'Multilingual Relay', 'description': 'Language relay', 'category': 'Cultural', 'icon': Icons.swap_horiz, 'type': GameType.multilingualRelayRace},
      {'name': 'Cultural Etiquette', 'description': 'Learn etiquette', 'category': 'Cultural', 'icon': Icons.groups, 'type': GameType.culturalEtiquetteScenarios},
      {'name': 'Drum Word Match', 'description': 'Match drum patterns', 'category': 'Cultural', 'icon': Icons.music_note, 'type': GameType.drumToWordMatching},
      {'name': 'Market Monopoly', 'description': 'Strategic market negotiations', 'category': 'Cultural', 'icon': Icons.storefront, 'type': GameType.marketMonopolyChallenge},
    ];

    final allGames = [...coreGames, ...culturalGames];
    
    // Filter games by section and category
    var filteredGames = selectedSection.value == 'core' ? coreGames : culturalGames;
    if (selectedCategory.value != null && selectedCategory.value != 'All') {
      filteredGames = filteredGames.where((g) => g['category'] == selectedCategory.value).toList();
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Opening game...',
      child: Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, semanticLabel: 'Back'),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
        ),
        title: Text('Language Games (${allGames.length}+)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: isDark
            ? PanAfricanColors.surfaceDark
            : PanAfricanColors.surfaceLight,
        child: Column(
          children: [
            // Language Selector
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Semantics(
                label: 'Select language',
                child: DropdownButtonFormField<String>(
                  value: selectedLanguage.value,
                  decoration: InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  items: languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedLanguage.value = value;
                  },
                ),
              ),
            ),

            // Section Tabs (Core vs Cultural)
            Container(
              padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Core Games, ${coreGames.length} games',
                      button: true,
                      selected: selectedSection.value == 'core',
                      child: ChoiceChip(
                        label: Text('Core Games (${coreGames.length})'),
                        selected: selectedSection.value == 'core',
                        onSelected: (selected) {
                          if (selected) {
                            selectedSection.value = 'core';
                            HapticFeedback.lightImpact();
                          }
                        },
                        selectedColor: PanAfricanColors.primaryContainer,
                        labelStyle: PanAfricanTypography.labelMedium(context),
                      ),
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Expanded(
                    child: Semantics(
                      label: 'Cultural Games, ${culturalGames.length} games',
                      button: true,
                      selected: selectedSection.value == 'cultural',
                      child: ChoiceChip(
                        label: Text('Cultural Games (${culturalGames.length})'),
                        selected: selectedSection.value == 'cultural',
                        onSelected: (selected) {
                          if (selected) {
                            selectedSection.value = 'cultural';
                            HapticFeedback.lightImpact();
                          }
                        },
                        selectedColor: PanAfricanColors.primaryContainer,
                        labelStyle: PanAfricanTypography.labelMedium(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Filters
            Container(
              padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                child: Row(
                  children: [
                    ...categories.map((category) {
                      final isSelected = selectedCategory.value == category ||
                          (category == 'All' && selectedCategory.value == null);
                      return Padding(
                        padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
                        child: Semantics(
                          label: 'Filter by $category category',
                          button: true,
                          selected: isSelected,
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              selectedCategory.value = selected && category != 'All' ? category : null;
                              HapticFeedback.lightImpact();
                            },
                            selectedColor: PanAfricanColors.primaryContainer,
                            checkmarkColor: PanAfricanColors.primary,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Games Grid
            Expanded(
              child: filteredGames.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.sports_esports_outlined,
                              size: 64.sp,
                              color: PanAfricanColors.neutralMedium,
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          Semantics(
                            label: 'No games in this category',
                            child: Text(
                              'No games in this category',
                              style: PanAfricanTypography.bodyLarge(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: PanAfricanSpacing.md,
                        mainAxisSpacing: PanAfricanSpacing.md,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredGames.length,
                      itemBuilder: (context, index) {
                        final game = filteredGames[index];
                        return _GameCard(
                          game: game,
                          isDark: isDark,
                          onTap: () {
                            final gameType = game['type'] as GameType;
                            final loader = ref.read(lazyGameLoaderProvider);

                            safeAsync(
                              context: context,
                              operation: () async {
                                isLoading.value = true;
                                try {
                                  await loader.loadGameOnDemand(gameType);
                                } catch (_) {
                                  // Preload is optional; still open the game
                                }
                                if (!context.mounted) return;
                                try {
                                  final gameWidget = buildGameScreen(
                                    gameType: gameType,
                                    language: selectedLanguage.value,
                                    onBack: () => Navigator.of(context).pop(),
                                    ref: ref,
                                  );
                                  if (!context.mounted) return;

                                  final prefs = await SharedPreferences.getInstance();
                                  final dismissed = prefs.getBool('game_onboarding_${gameType.name}_dismissed') ?? false;
                                  if (!dismissed && context.mounted) {
                                    await showDialog(
                                      context: context,
                                      builder: (ctx) => GameOnboardingOverlay(
                                        gameName: game['name'] as String,
                                        rules: _gameRules[gameType] ?? 'Match words and have fun!',
                                        onDismiss: () async {
                                          await prefs.setBool('game_onboarding_${gameType.name}_dismissed', true);
                                          Navigator.pop(ctx);
                                        },
                                      ),
                                    );
                                  }

                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    SmoothPageRoute(
                                      child: ErrorBoundary(
                                        errorMessage: 'This game could not load.',
                                        onRetry: () => Navigator.of(context).pop(),
                                        child: gameWidget,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ErrorHandler.showError(context, e);
                                  }
                                } finally {
                                  isLoading.value = false;
                                }
                              },
                              errorContext: 'openGame',
                              showError: true,
                            );
                          },
                        )
                            .animate(delay: (index * 50).ms)
                            .fadeIn(duration: 300.ms)
                            .scale(begin: Offset(0.9, 0.9), end: Offset(1, 1));
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Map<String, dynamic> game;
  final bool isDark;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = game['category'] ?? 'game';
    final icon = game['icon'] as IconData? ?? Icons.sports_esports_rounded;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${game['name'] ?? 'Game'}, ${game['description'] ?? ''}, $category category',
      button: true,
      child: PanAfricanCard(
        hasHoverEffect: true,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: PanAfricanColors.primary,
                shape: BoxShape.circle,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Icon(
                icon,
                size: 24.sp,
                color: colorScheme.onPrimary,
                semanticLabel: '${game['name']} game icon',
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xs),
              child: Text(
                game['name'] ?? 'Game',
                style: PanAfricanTypography.titleSmall(context),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xs),
              child: Text(
                game['description'] ?? '',
                style: PanAfricanTypography.bodySmall(context),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.sm,
                vertical: PanAfricanSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: PanAfricanColors.primaryContainer.withOpacity(0.5),
                borderRadius: PanAfricanRadius.roundBR,
              ),
              child: Text(
                category,
                style: PanAfricanTypography.labelSmall(
                  context,
                  color: PanAfricanColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

