import 'package:flutter/material.dart';
import '../../models/game/game_session_model.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/pan_african_components.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Language Selector Widget
class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelector({super.key, 
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  final List<String> _languages = const [
    'yoruba',
    'swahili',
    'hausa',
    'igbo',
    'zulu',
    'xhosa',
    'amharic',
    'twi',
    'pidgin',
    'afrikaans',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Language',
            style: PanAfricanTypography.titleSmall(context),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Wrap(
            spacing: PanAfricanSpacing.xs,
            runSpacing: PanAfricanSpacing.xs,
            children: _languages.map((lang) {
              final isSelected = selectedLanguage == lang;
              return PanAfricanChip(
                label: lang.toUpperCase(),
                selected: isSelected,
                onSelected: () => onLanguageChanged(lang),
                backgroundColor: isSelected
                    ? PanAfricanColors.primaryContainer
                    : (isDark
                        ? PanAfricanColors.surfaceContainerHighDark
                        : PanAfricanColors.surfaceContainerHighLight),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Game Section Widget
class GameSection extends StatelessWidget {
  final String title;
  final List<GameType> games;
  final Function(GameType) onGameSelected;

  const GameSection({super.key, 
    required this.title,
    required this.games,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
          child: Text(
            title,
            style: PanAfricanTypography.titleLarge(context),
          ),
        ),
        ...games.map((game) => Padding(
              padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
              child: _GameCard(
                title: game.displayName,
                description: _getGameDescription(game),
                icon: _getGameIcon(game),
                gradient: _getGameGradient(game),
                onTap: () => onGameSelected(game),
                isAvailable: _isGameReady(game),
              ),
            )),
      ],
    );
  }

  String _getGameDescription(GameType game) {
    switch (game) {
      case GameType.wordMatchAudio:
        return 'Match words with translations + audio playback';
      case GameType.pronunciationDuel:
        return 'Head-to-head pronunciation scoring';
      case GameType.speedRoundRemix:
        return 'Adaptive rapid-fire questions';
      case GameType.toneTrainer:
        return 'Master tonal languages with pitch visualization';
      case GameType.storyBuilder:
        return 'Build stories collaboratively';
      case GameType.roleplayAdventure:
        return 'Branching dialogue scenarios';
      case GameType.grammarDetective:
        return 'Find and fix grammar errors';
      case GameType.listenAndSketch:
        return 'Listen and draw/select pictures';
      case GameType.pictureWordAssociation:
        return 'Map cultural images to vocabulary';
      case GameType.memoryMap:
        return 'SRS with spatial memory';
      case GameType.conversationRelay:
        return 'Asynchronous tandem practice';
      case GameType.grammarJam:
        return 'Cooperative grammar fluency';
      case GameType.pronunciationKaraoke:
        return 'Sing songs with pronunciation scoring';
      case GameType.quizChef:
        return 'Cook recipes in target language';
      case GameType.proverbUnlocker:
        return 'Decode African proverbs';
      case GameType.drumRhythmShadowing:
        return 'Match tone patterns with drums';
      case GameType.clanLineageStoryBuilder:
        return 'Journey through African villages';
      case GameType.marketBargainingSimulator:
        return 'Negotiate in African markets';
      case GameType.taxiBusStopSurvival:
        return 'Navigate transport hubs';
      case GameType.foodQuest:
        return 'Learn food vocabulary by cooking';
      case GameType.callAndResponse:
        return 'Music-based pronunciation practice';
      case GameType.greetingDiplomacyChallenge:
        return 'Master cultural greeting rituals';
      case GameType.folktaleReconstruction:
        return 'Arrange folktale parts correctly';
      case GameType.phraseSniper:
        return 'Fast-paced reaction game';
      case GameType.liarLiar:
        return 'Detect grammatical errors';
      case GameType.villageQuest:
        return 'NPC conversation game';
      case GameType.accentDecodingPuzzle:
        return 'Match accents to regions';
      case GameType.flashcardSafari:
        return 'AR vocabulary scanning';
      case GameType.rapidTongueTwisterRace:
        return 'Repeat tongue twisters fast';
      case GameType.emojiTranslator:
        return 'Translate emoji sentences';
      case GameType.rhythmTyping:
        return 'Type with drum sounds';
      case GameType.eldersBlessingsChallenge:
        return 'Learn blessing phrases';
      case GameType.multilingualRelayRace:
        return 'Switch between languages';
      case GameType.culturalEtiquetteScenarios:
        return 'Interactive cultural situations';
      case GameType.drumToWordMatching:
        return 'Decode drum patterns to words';
      case GameType.marketMonopolyChallenge:
        return 'Trade smart in a language-rich market simulation';
      case GameType.scrabbleSprintArena:
        return 'Build words fast from a live letter board';
    }
  }

  IconData _getGameIcon(GameType game) {
    switch (game) {
      case GameType.wordMatchAudio:
        return Icons.track_changes_rounded;
      case GameType.pronunciationDuel:
        return Icons.volume_up_rounded;
      case GameType.speedRoundRemix:
        return Icons.bolt_rounded;
      case GameType.toneTrainer:
        return Icons.graphic_eq_rounded;
      case GameType.storyBuilder:
        return Icons.auto_stories_rounded;
      case GameType.roleplayAdventure:
        return Icons.theater_comedy_rounded;
      case GameType.grammarDetective:
        return Icons.search_rounded;
      case GameType.listenAndSketch:
        return Icons.draw_rounded;
      case GameType.pictureWordAssociation:
        return Icons.image_rounded;
      case GameType.memoryMap:
        return Icons.map_rounded;
      case GameType.conversationRelay:
        return Icons.forum_rounded;
      case GameType.grammarJam:
        return Icons.music_note_rounded;
      case GameType.pronunciationKaraoke:
        return Icons.mic_rounded;
      case GameType.quizChef:
        return Icons.restaurant_rounded;
      case GameType.proverbUnlocker:
        return Icons.lightbulb_rounded;
      case GameType.drumRhythmShadowing:
        return Icons.music_note;
      case GameType.clanLineageStoryBuilder:
        return Icons.account_tree_rounded;
      case GameType.marketBargainingSimulator:
        return Icons.shopping_cart_rounded;
      case GameType.taxiBusStopSurvival:
        return Icons.directions_bus_rounded;
      case GameType.foodQuest:
        return Icons.restaurant_menu_rounded;
      case GameType.callAndResponse:
        return Icons.queue_music_rounded;
      case GameType.greetingDiplomacyChallenge:
        return Icons.handshake_rounded;
      case GameType.folktaleReconstruction:
        return Icons.book_rounded;
      case GameType.phraseSniper:
        return Icons.speed_rounded;
      case GameType.liarLiar:
        return Icons.psychology_rounded;
      case GameType.villageQuest:
        return Icons.location_city;
      case GameType.accentDecodingPuzzle:
        return Icons.language_rounded;
      case GameType.flashcardSafari:
        return Icons.camera_alt_rounded;
      case GameType.rapidTongueTwisterRace:
        return Icons.speed_rounded;
      case GameType.emojiTranslator:
        return Icons.emoji_emotions_rounded;
      case GameType.rhythmTyping:
        return Icons.keyboard_rounded;
      case GameType.eldersBlessingsChallenge:
        return Icons.favorite_rounded;
      case GameType.multilingualRelayRace:
        return Icons.swap_horiz_rounded;
      case GameType.culturalEtiquetteScenarios:
        return Icons.people_rounded;
      case GameType.drumToWordMatching:
        return Icons.music_note_rounded;
      case GameType.marketMonopolyChallenge:
        return Icons.storefront_rounded;
      case GameType.scrabbleSprintArena:
        return Icons.spellcheck_rounded;
    }
  }

  LinearGradient _getGameGradient(GameType game) {
    // Generate gradients based on game type
    final gradients = [
      const LinearGradient(colors: [Color(0xFFCE1126), Color(0xFFFF6B35)]),
      const LinearGradient(colors: [Color(0xFF007A3D), Color(0xFF00A8E8)]),
      const LinearGradient(colors: [Color(0xFFFCD116), Color(0xFFFF6B35)]),
      const LinearGradient(colors: [Color(0xFF7B2CBF), Color(0xFFCE1126)]),
      const LinearGradient(colors: [Color(0xFF00A8E8), Color(0xFF007A3D)]),
    ];
    return gradients[game.index % gradients.length];
  }

  bool _isGameReady(GameType game) {
    // All games listed are routable via `game_router.dart`.
    // If a game isn't available at runtime (assets/network/etc.), it should fail with a user-friendly
    // in-game error state instead of being hidden/disabled at the catalog level.
    return true;
  }
}

/// Extended Game Card with availability indicator
class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isAvailable;

  const _GameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight;
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.6,
      child: PanAfricanCard(
        onTap: isAvailable ? onTap : null,
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        backgroundColor:
            isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        hasHoverEffect: true,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                boxShadow: PanAfricanShadows.sm,
                border: Border.all(color: borderColor.withOpacity(0.2)),
              ),
              child: Icon(icon, color: colorScheme.onPrimary, size: 28.sp),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: PanAfricanTypography.titleMedium(context),
                        ),
                      ),
                      PanAfricanBadge(
                        label: isAvailable ? 'READY' : 'SOON',
                        color: isAvailable
                            ? PanAfricanColors.success
                            : PanAfricanColors.warning,
                        icon: isAvailable
                            ? Icons.bolt_rounded
                            : Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    description,
                    style: PanAfricanTypography.bodySmall(context).copyWith(
                      color: isDark
                          ? PanAfricanColors.textSecondaryDark
                          : PanAfricanColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.sp,
              color: isDark
                  ? PanAfricanColors.textSecondaryDark
                  : PanAfricanColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

