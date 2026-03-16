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
import 'game_catalog.dart';

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

    final coreGames = GameCatalog.bySection(GameCatalogSection.core);
    final culturalGames = GameCatalog.bySection(GameCatalogSection.cultural);
    final allGames = [...coreGames, ...culturalGames];
    
    // Filter games by section and category
    var filteredGames = selectedSection.value == 'core' ? coreGames : culturalGames;
    if (selectedCategory.value != null && selectedCategory.value != 'All') {
      filteredGames = filteredGames.where((g) => g.category == selectedCategory.value).toList();
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
                            final gameType = game.type;
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
                                        gameType: gameType.name,
                                        title: game.name,
                                        rules: game.rules.isNotEmpty ? game.rules : const [
                                          'Learn and have fun with this game mode.',
                                          'Focus on accuracy first, then speed.',
                                        ],
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
  final GameCatalogEntry game;
  final bool isDark;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = game.category;
    final icon = game.icon;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${game.name}, ${game.description}, $category category',
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
                              semanticLabel: '${game.name} game icon',
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xs),
              child: Text(
                game.name,
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
                game.description,
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

