import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Beautiful Material 3 Games Screen
class GamesScreenMaterial3 extends HookConsumerWidget {
  const GamesScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState('yoruba');
    final selectedCategory = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'afrikaans', 'pidgin'];
    final categories = ['All', 'Vocabulary', 'Grammar', 'Pronunciation', 'Cultural'];
    final selectedSection = useState<'core' | 'cultural'>('core');

    // ALL 35+ GAMES PROPERLY CATEGORIZED
    final coreGames = [
      {'name': 'Word Match Audio', 'description': 'Match words with audio', 'category': 'Vocabulary', 'icon': Icons.headphones, 'type': 'wordMatchAudio'},
      {'name': 'Pronunciation Duel', 'description': 'Master pronunciation', 'category': 'Pronunciation', 'icon': Icons.record_voice_over, 'type': 'pronunciationDuel'},
      {'name': 'Speed Round', 'description': 'Fast-paced vocabulary', 'category': 'Vocabulary', 'icon': Icons.speed, 'type': 'speedRound'},
      {'name': 'Tone Trainer', 'description': 'Learn tonal patterns', 'category': 'Pronunciation', 'icon': Icons.graphic_eq, 'type': 'toneTrainer'},
      {'name': 'Story Builder', 'description': 'Build stories', 'category': 'Grammar', 'icon': Icons.auto_stories, 'type': 'storyBuilder'},
      {'name': 'Roleplay Adventure', 'description': 'Interactive conversations', 'category': 'Cultural', 'icon': Icons.theater_comedy, 'type': 'roleplayAdventure'},
      {'name': 'Grammar Detective', 'description': 'Solve grammar mysteries', 'category': 'Grammar', 'icon': Icons.search, 'type': 'grammarDetective'},
      {'name': 'Listen & Sketch', 'description': 'Draw what you hear', 'category': 'Vocabulary', 'icon': Icons.draw, 'type': 'listenAndSketch'},
      {'name': 'Picture Word Match', 'description': 'Match words with images', 'category': 'Vocabulary', 'icon': Icons.image, 'type': 'pictureWordMatch'},
      {'name': 'Memory Map', 'description': 'Memory challenge', 'category': 'Vocabulary', 'icon': Icons.map, 'type': 'memoryMap'},
      {'name': 'Conversation Relay', 'description': 'Chain conversations', 'category': 'Cultural', 'icon': Icons.chat, 'type': 'conversationRelay'},
      {'name': 'Grammar Jam', 'description': 'Grammar rhythm game', 'category': 'Grammar', 'icon': Icons.music_note, 'type': 'grammarJam'},
      {'name': 'Pronunciation Karaoke', 'description': 'Sing and pronounce', 'category': 'Pronunciation', 'icon': Icons.mic, 'type': 'pronunciationKaraoke'},
      {'name': 'Quiz Chef', 'description': 'Cook up answers', 'category': 'Vocabulary', 'icon': Icons.restaurant, 'type': 'quizChef'},
    ];

    final culturalGames = [
      {'name': 'Proverb Unlocker', 'description': 'Unlock wisdom', 'category': 'Cultural', 'icon': Icons.auto_awesome, 'type': 'proverbUnlocker'},
      {'name': 'Drum Rhythm', 'description': 'Follow the rhythm', 'category': 'Pronunciation', 'icon': Icons.music_note, 'type': 'drumRhythm'},
      {'name': 'Clan Story Builder', 'description': 'Build clan stories', 'category': 'Cultural', 'icon': Icons.account_tree, 'type': 'clanStoryBuilder'},
      {'name': 'Market Bargaining', 'description': 'Practice bargaining', 'category': 'Cultural', 'icon': Icons.store, 'type': 'marketBargaining'},
      {'name': 'Taxi Survival', 'description': 'Navigate transportation', 'category': 'Cultural', 'icon': Icons.directions_transit, 'type': 'taxiSurvival'},
      {'name': 'Food Quest', 'description': 'Explore cuisine', 'category': 'Cultural', 'icon': Icons.restaurant_menu, 'type': 'foodQuest'},
      {'name': 'Call & Response', 'description': 'Traditional patterns', 'category': 'Cultural', 'icon': Icons.call, 'type': 'callAndResponse'},
      {'name': 'Greeting Diplomacy', 'description': 'Master greetings', 'category': 'Cultural', 'icon': Icons.waving_hand, 'type': 'greetingDiplomacy'},
      {'name': 'Folktale Builder', 'description': 'Rebuild stories', 'category': 'Cultural', 'icon': Icons.book, 'type': 'folktaleBuilder'},
      {'name': 'Phrase Sniper', 'description': 'Target phrases', 'category': 'Vocabulary', 'icon': Icons.center_focus_strong, 'type': 'phraseSniper'},
      {'name': 'Liar Liar', 'description': 'Detect truth', 'category': 'Grammar', 'icon': Icons.psychology, 'type': 'liarLiar'},
      {'name': 'Village Quest', 'description': 'Adventure quest', 'category': 'Cultural', 'icon': Icons.explore, 'type': 'villageQuest'},
      {'name': 'Accent Puzzle', 'description': 'Decode accents', 'category': 'Pronunciation', 'icon': Icons.puzzle, 'type': 'accentPuzzle'},
      {'name': 'Flashcard Safari', 'description': 'Safari vocabulary', 'category': 'Vocabulary', 'icon': Icons.flash_on, 'type': 'flashcardSafari'},
      {'name': 'Tongue Twister', 'description': 'Master twisters', 'category': 'Pronunciation', 'icon': Icons.speed, 'type': 'tongueTwister'},
      {'name': 'Emoji Translator', 'description': 'Translate emojis', 'category': 'Vocabulary', 'icon': Icons.emoji_emotions, 'type': 'emojiTranslator'},
      {'name': 'Rhythm Typing', 'description': 'Type to rhythm', 'category': 'Vocabulary', 'icon': Icons.keyboard, 'type': 'rhythmTyping'},
      {'name': 'Elders Blessings', 'description': 'Learn blessings', 'category': 'Cultural', 'icon': Icons.hands, 'type': 'eldersBlessings'},
      {'name': 'Multilingual Relay', 'description': 'Language relay', 'category': 'Cultural', 'icon': Icons.swap_horiz, 'type': 'multilingualRelay'},
      {'name': 'Cultural Etiquette', 'description': 'Learn etiquette', 'category': 'Cultural', 'icon': Icons.groups, 'type': 'culturalEtiquette'},
      {'name': 'Drum Word Match', 'description': 'Match drum patterns', 'category': 'Cultural', 'icon': Icons.music_note, 'type': 'drumWordMatch'},
    ];

    final allGames = [...coreGames, ...culturalGames];
    
    // Filter games by section and category
    var filteredGames = selectedSection.value == 'core' ? coreGames : culturalGames;
    if (selectedCategory.value != null && selectedCategory.value != 'All') {
      filteredGames = filteredGames.where((g) => g['category'] == selectedCategory.value).toList();
    }

    return Scaffold(
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

            // Section Tabs (Core vs Cultural)
            Container(
              padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
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
              ).paddingSymmetric(horizontal: PanAfricanSpacing.md),
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
                            // This will be handled by the game routing system
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
    final color = _getCategoryColor(category);
    final icon = game['icon'] as IconData? ?? Icons.sports_esports;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
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
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
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
              ),
              child: Icon(
                icon,
                size: 32.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              game['name'] ?? 'Game',
              style: PanAfricanTypography.titleSmall(context),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              game['description'] ?? '',
              style: PanAfricanTypography.bodySmall(context),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            PanAfricanBadge(
              label: category,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vocabulary':
        return PanAfricanColors.primary;
      case 'grammar':
        return PanAfricanColors.kenteBlue;
      case 'pronunciation':
        return PanAfricanColors.tertiary;
      case 'cultural':
        return PanAfricanColors.kenteRed;
      default:
        return PanAfricanColors.secondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vocabulary':
        return Icons.book;
      case 'grammar':
        return Icons.menu_book;
      case 'pronunciation':
        return Icons.record_voice_over;
      case 'cultural':
        return Icons.public;
      default:
        return Icons.sports_esports;
    }
  }
}

