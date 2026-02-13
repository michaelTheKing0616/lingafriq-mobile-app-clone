import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';

/// Enhanced Games Screen with ALL 35+ Games Properly Categorized
class GamesScreenEnhanced extends HookConsumerWidget {
  const GamesScreenEnhanced({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final selectedCategory = useState<String?>(null);
    final selectedSection = useState<String>('core');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final availableLanguages = AppLanguage.values;

    // All 35+ Games Properly Categorized
    final coreGames = [
      {
        'type': GameType.wordMatchAudio,
        'name': 'Word Match Audio',
        'description': 'Match words with audio',
        'category': 'Vocabulary',
        'icon': Icons.headphones,
        'color': PanAfricanColors.primary,
      },
      {
        'type': GameType.pronunciationDuel,
        'name': 'Pronunciation Duel',
        'description': 'Master pronunciation',
        'category': 'Pronunciation',
        'icon': Icons.record_voice_over,
        'color': PanAfricanColors.kenteRed,
      },
      {
        'type': GameType.speedRoundRemix,
        'name': 'Speed Round',
        'description': 'Fast-paced vocabulary',
        'category': 'Vocabulary',
        'icon': Icons.speed,
        'color': PanAfricanColors.secondary,
      },
      {
        'type': GameType.toneTrainer,
        'name': 'Tone Trainer',
        'description': 'Learn tonal patterns',
        'category': 'Pronunciation',
        'icon': Icons.graphic_eq,
        'color': PanAfricanColors.tertiary,
      },
      {
        'type': GameType.storyBuilder,
        'name': 'Story Builder',
        'description': 'Build stories',
        'category': 'Grammar',
        'icon': Icons.auto_stories,
        'color': PanAfricanColors.kenteBlue,
      },
      {
        'type': GameType.roleplayAdventure,
        'name': 'Roleplay Adventure',
        'description': 'Interactive conversations',
        'category': 'Cultural',
        'icon': Icons.theater_comedy,
        'color': PanAfricanColors.ankaraPurple,
      },
      {
        'type': GameType.grammarDetective,
        'name': 'Grammar Detective',
        'description': 'Solve grammar mysteries',
        'category': 'Grammar',
        'icon': Icons.search,
        'color': PanAfricanColors.kenteBlue,
      },
      {
        'type': GameType.listenAndSketch,
        'name': 'Listen & Sketch',
        'description': 'Draw what you hear',
        'category': 'Vocabulary',
        'icon': Icons.draw,
        'color': PanAfricanColors.primary,
      },
      {
        'type': GameType.pictureWordAssociation,
        'name': 'Picture Word Match',
        'description': 'Match words with images',
        'category': 'Vocabulary',
        'icon': Icons.image,
        'color': PanAfricanColors.primary,
      },
      {
        'type': GameType.memoryMap,
        'name': 'Memory Map',
        'description': 'Memory challenge',
        'category': 'Vocabulary',
        'icon': Icons.map,
        'color': PanAfricanColors.secondary,
      },
      {
        'type': GameType.conversationRelay,
        'name': 'Conversation Relay',
        'description': 'Chain conversations',
        'category': 'Cultural',
        'icon': Icons.chat,
        'color': PanAfricanColors.ankaraPurple,
      },
      {
        'type': GameType.grammarJam,
        'name': 'Grammar Jam',
        'description': 'Grammar rhythm game',
        'category': 'Grammar',
        'icon': Icons.music_note,
        'color': PanAfricanColors.kenteBlue,
      },
      {
        'type': GameType.pronunciationKaraoke,
        'name': 'Pronunciation Karaoke',
        'description': 'Sing and pronounce',
        'category': 'Pronunciation',
        'icon': Icons.mic,
        'color': PanAfricanColors.kenteRed,
      },
      {
        'type': GameType.quizChef,
        'name': 'Quiz Chef',
        'description': 'Cook up answers',
        'category': 'Vocabulary',
        'icon': Icons.restaurant,
        'color': PanAfricanColors.tertiary,
      },
    ];

    final culturalGames = [
      {
        'type': GameType.proverbUnlocker,
        'name': 'Proverb Unlocker',
        'description': 'Unlock wisdom',
        'category': 'Cultural',
        'icon': Icons.auto_awesome,
        'color': PanAfricanColors.kenteRed,
      },
      {
        'type': GameType.drumRhythmShadowing,
        'name': 'Drum Rhythm',
        'description': 'Follow the rhythm',
        'category': 'Pronunciation',
        'icon': Icons.music_note,
        'color': PanAfricanColors.ankaraPurple,
      },
      {
        'type': GameType.clanLineageStoryBuilder,
        'name': 'Clan Story Builder',
        'description': 'Build clan stories',
        'category': 'Cultural',
        'icon': Icons.account_tree,
        'color': PanAfricanColors.primary,
      },
      {
        'type': GameType.marketBargainingSimulator,
        'name': 'Market Bargaining',
        'description': 'Practice bargaining',
        'category': 'Cultural',
        'icon': Icons.store,
        'color': PanAfricanColors.secondary,
      },
      {
        'type': GameType.taxiBusStopSurvival,
        'name': 'Taxi Survival',
        'description': 'Navigate transportation',
        'category': 'Cultural',
        'icon': Icons.directions_transit,
        'color': PanAfricanColors.tertiary,
      },
      {
        'type': GameType.foodQuest,
        'name': 'Food Quest',
        'description': 'Explore cuisine',
        'category': 'Cultural',
        'icon': Icons.restaurant_menu,
        'color': PanAfricanColors.kenteRed,
      },
      {
        'type': GameType.callAndResponse,
        'name': 'Call & Response',
        'description': 'Traditional patterns',
        'category': 'Cultural',
        'icon': Icons.call,
        'color': PanAfricanColors.ankaraPurple,
      },
      {
        'type': GameType.greetingDiplomacyChallenge,
        'name': 'Greeting Diplomacy',
        'description': 'Master greetings',
        'category': 'Cultural',
        'icon': Icons.waving_hand,
        'color': PanAfricanColors.secondary,
      },
      {
        'type': GameType.folktaleReconstruction,
        'name': 'Folktale Builder',
        'description': 'Rebuild stories',
        'category': 'Cultural',
        'icon': Icons.book,
        'color': PanAfricanColors.kenteBlue,
      },
      {
        'type': GameType.phraseSniper,
        'name': 'Phrase Sniper',
        'description': 'Target phrases',
        'category': 'Vocabulary',
        'icon': Icons.center_focus_strong,
        'color': PanAfricanColors.primary,
      },
      {
        'type': GameType.liarLiar,
        'name': 'Liar Liar',
        'description': 'Detect truth',
        'category': 'Grammar',
        'icon': Icons.psychology,
        'color': PanAfricanColors.kenteRed,
      },
      {
        'type': GameType.villageQuest,
        'name': 'Village Quest',
        'description': 'Adventure quest',
        'category': 'Cultural',
        'icon': Icons.explore,
        'color': PanAfricanColors.tertiary,
      },
      {
        'type': GameType.accentDecodingPuzzle,
        'name': 'Accent Puzzle',
        'description': 'Decode accents',
        'category': 'Pronunciation',
        'icon': Icons.extension,
        'color': PanAfricanColors.ankaraPurple,
      },
      {
        'type': GameType.flashcardSafari,
        'name': 'Flashcard Safari',
        'description': 'Safari vocabulary',
        'category': 'Vocabulary',
        'icon': Icons.flash_on,
        'color': PanAfricanColors.secondary,
      },
      {
        'type': GameType.rapidTongueTwisterRace,
        'name': 'Tongue Twister',
        'description': 'Master twisters',
        'category': 'Pronunciation',
        'icon': Icons.speed,
        'color': PanAfricanColors.kenteRed,
      },
      {
        'type': GameType.emojiTranslator,
        'name': 'Emoji Translator',
        'description': 'Translate emojis',
        'category': 'Vocabulary',
        'icon': Icons.emoji_emotions,
        'color': PanAfricanColors.secondary,
      },
      {
        'type': GameType.rhythmTyping,
        'name': 'Rhythm Typing',
        'description': 'Type to rhythm',
        'category': 'Vocabulary',
        'icon': Icons.keyboard,
        'color': PanAfricanColors.primary,
      },
      {
        'type': GameType.eldersBlessingsChallenge,
        'name': 'Elders Blessings',
        'description': 'Learn blessings',
        'category': 'Cultural',
        'icon': Icons.favorite,
        'color': PanAfricanColors.kenteBlue,
      },
      {
        'type': GameType.multilingualRelayRace,
        'name': 'Multilingual Relay',
        'description': 'Language relay',
        'category': 'Cultural',
        'icon': Icons.swap_horiz,
        'color': PanAfricanColors.ankaraPurple,
      },
      {
        'type': GameType.culturalEtiquetteScenarios,
        'name': 'Cultural Etiquette',
        'description': 'Learn etiquette',
        'category': 'Cultural',
        'icon': Icons.groups,
        'color': PanAfricanColors.primary,
      },
      {
        'type': GameType.drumToWordMatching,
        'name': 'Drum Word Match',
        'description': 'Match drum patterns',
        'category': 'Cultural',
        'icon': Icons.music_note,
        'color': PanAfricanColors.ankaraPurple,
      },
    ];

    final allGames = [...coreGames, ...culturalGames];
    final categories = ['All', 'Vocabulary', 'Grammar', 'Pronunciation', 'Cultural'];

    // Filter games
    var filteredGames = selectedSection.value == 'core' ? coreGames : culturalGames;
    if (selectedCategory.value != null && selectedCategory.value != 'All') {
      filteredGames = filteredGames.where((g) => g['category'] == selectedCategory.value).toList();
    }

    final isLoading = useState(false);
    
    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Loading games...',
      child: Scaffold(
      appBar: AppBar(
        title: Text('Language Games (${allGames.length}+)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: Column(
          children: [
            // Language Selector
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: DropdownButtonFormField<AppLanguage>(
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
                items: availableLanguages.map((lang) {
                  return DropdownMenuItem<AppLanguage>(
                    value: lang,
                    child: Text(
                      lang.name.substring(0, 1).toUpperCase() + lang.name.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedLanguage.value = value;
                },
              ),
            ),

            // Section Tabs (Core vs Cultural)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
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
                  SizedBox(width: PanAfricanSpacing.sm),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Cultural Games (${culturalGames.length})'),
                      selected: selectedSection.value == 'cultural',
                      onSelected: (selected) {
                        if (selected) {
                          selectedSection.value = 'cultural';
                          HapticFeedback.lightImpact();
                        }
                      },
                      selectedColor: PanAfricanColors.secondaryContainer,
                      labelStyle: PanAfricanTypography.labelMedium(context),
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
                        child: PanAfricanChip(
                          label: category,
                          selected: isSelected,
                          onSelected: () {
                            selectedCategory.value = isSelected && category != 'All' ? null : category;
                            if (category == 'All') selectedCategory.value = null;
                            HapticFeedback.lightImpact();
                          },
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
                          Icon(
                            Icons.sports_esports_outlined,
                            size: 64.sp,
                            color: PanAfricanColors.neutralMedium,
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            'No games in this category',
                            style: PanAfricanTypography.bodyLarge(context),
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
                            // Navigate to game using game router
                            final loader = ref.read(lazyGameLoaderProvider);
                            loader.loadGameOnDemand(game['type'] as GameType);
                            // Navigate to game screen
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
    final color = game['color'] as Color? ?? PanAfricanColors.primary;
    final icon = game['icon'] as IconData? ?? Icons.sports_esports_rounded;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: PanAfricanCard(
        hasHoverEffect: true,
        hasGlow: true,
        glowColor: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: PanAfricanShadows.glow(color),
              ),
              child: Icon(
                icon,
                size: 24.sp,
                color: colorScheme.onPrimary,
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
                color: color.withOpacity(0.15),
                borderRadius: PanAfricanRadius.roundBR,
              ),
              child: Text(
                category,
                style: PanAfricanTypography.labelSmall(context, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

