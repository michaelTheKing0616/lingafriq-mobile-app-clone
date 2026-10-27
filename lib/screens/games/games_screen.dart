import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/utils/games_prefetch_language.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/screens/games/pronunciation_game.dart';
import 'package:lingafriq/screens/games/word_match_game.dart';
import 'package:lingafriq/screens/games/fill_in_the_blank_game.dart';
import 'package:lingafriq/screens/games/speed_challenge_game.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

final languagesForGamesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(apiProvider.notifier).getLanguages();
});

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesForGamesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const AppDrawer(),
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
            TopGradientBox(
              borderRadius: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: colorScheme.onPrimary,
                          size: 24.sp,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final scaffoldState = Scaffold.of(context);
                          scaffoldState.openDrawer();
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Language Games',
                              style: PanAfricanTypography.titleLarge(
                                context,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            SizedBox(height: PanAfricanSpacing.xxs),
                            Text(
                              'Learn through play',
                              style: PanAfricanTypography.bodyMedium(
                                context,
                                color: colorScheme.onPrimary.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Fun games icon
                      Container(
                        padding: EdgeInsets.all(PanAfricanSpacing.sm),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                          borderRadius: PanAfricanRadius.roundBR,
                        ),
                        child: Icon(
                          Icons.sports_esports_rounded,
                          color: colorScheme.onPrimary,
                          size: 24.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: languagesAsync.when(
                data: (languageResponse) {
                  final seen = <String>{};
                  final languages = <Language>[];
                  for (final lang in languageResponse.results) {
                    final slug = gamesHubSlugFromApiLanguage(lang);
                    if (slug == null) continue;
                    if (!seen.add(slug)) continue;
                    languages.add(
                      languageNormalizedForGamesHub(lang, fallbackSlug: slug),
                    );
                  }
                  if (languages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(PanAfricanSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.translate_outlined,
                              size: 48.sp,
                              color: PanAfricanColors.neutralMedium,
                            ),
                            SizedBox(height: PanAfricanSpacing.md),
                            Text(
                              'No game-ready languages from the server',
                              textAlign: TextAlign.center,
                              style: PanAfricanTypography.titleMedium(context),
                            ),
                            SizedBox(height: PanAfricanSpacing.sm),
                            Text(
                              'Only languages that map to the games hub are listed here.',
                              textAlign: TextAlign.center,
                              style: PanAfricanTypography.bodyMedium(
                                context,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            SizedBox(height: PanAfricanSpacing.lg),
                            FilledButton(
                              onPressed: () {
                                ref.invalidate(languagesForGamesProvider);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a Language',
                          style: PanAfricanTypography.titleLarge(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),
                        OptimizedListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: PanAfricanSpacing.md,
                                mainAxisSpacing: PanAfricanSpacing.md,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: languages.length,
                          itemBuilder: (context, index) {
                            final language = languages[index];
                            return _GameLanguageCard(
                              language: language,
                              colorIndex: index,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(navigationProvider)
                                    .navigateTo(
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
                loading: () => const AdaptiveProgressIndicator(
                  message: 'Loading languages...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameLanguageCard extends StatelessWidget {
  final Language language;
  final VoidCallback onTap;
  final int colorIndex;

  const _GameLanguageCard({
    required this.language,
    required this.onTap,
    this.colorIndex = 0,
  });

  // Vibrant category colors for visual interest
  static const List<Color> _categoryColors = [
    PanAfricanColors.kenteRed,
    PanAfricanColors.kenteBlue,
    PanAfricanColors.ankaraPurple,
    PanAfricanColors.kitengeTeal,
    PanAfricanColors.tertiary,
    PanAfricanColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[colorIndex % _categoryColors.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? PanAfricanColors.cardDark
              : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          boxShadow: PanAfricanShadows.md,
          border: Border.all(
            color: isDark
                ? PanAfricanColors.borderDark
                : PanAfricanColors.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: PanAfricanShadows.glow(color),
              ),
              child: Icon(
                Icons.sports_esports_rounded,
                color: colorScheme.onPrimary,
                size: 28.sp,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
              child: Text(
                language.name,
                style: PanAfricanTypography.titleMedium(context),
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
                'Play',
                style: PanAfricanTypography.labelSmall(context, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Game Types Selection Screen
class GameTypesScreen extends StatelessWidget {
  final Language language;

  const GameTypesScreen({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Games - ${language.name}',
          style: PanAfricanTypography.titleMedium(
            context,
            color: colorScheme.onPrimary,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: PanAfricanGradients.forest),
        ),
        elevation: 0,
        actions: [
          Semantics(
            button: true,
            label: 'Open full arcade, ${AllGamesRegistry.totalArcadeListingCount()} games by skill',
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, 'games_enhanced_catalog');
              },
              icon: Icon(Icons.view_carousel_rounded, size: 20.sp),
              label: const Text('Arcade'),
            ),
          ),
        ],
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Game',
                style: PanAfricanTypography.titleLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              _GameTypeCard(
                icon: Icons.quiz_rounded,
                title: 'Word Match',
                description: 'Match words with their translations',
                color: PanAfricanColors.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    SmoothPageRoute.platform(
                      child: WordMatchGame(language: language),
                    ),
                  );
                },
              ),
              SizedBox(height: PanAfricanSpacing.md),
              _GameTypeCard(
                icon: Icons.edit_rounded,
                title: 'Fill in the Blank',
                description: 'Complete sentences with missing words',
                color: PanAfricanColors.secondary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    SmoothPageRoute.platform(
                      child: FillInTheBlankGame(language: language),
                    ),
                  );
                },
              ),
              SizedBox(height: PanAfricanSpacing.md),
              _GameTypeCard(
                icon: Icons.volume_up_rounded,
                title: 'Pronunciation Practice',
                description: 'Listen and repeat words correctly',
                color: PanAfricanColors.tertiary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    SmoothPageRoute.platform(
                      child: PronunciationGame(language: language),
                    ),
                  );
                },
              ),
              SizedBox(height: PanAfricanSpacing.md),
              _GameTypeCard(
                icon: Icons.flash_on_rounded,
                title: 'Speed Challenge',
                description: 'Answer questions as fast as you can',
                color: PanAfricanColors.kenteBlue,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    SmoothPageRoute.platform(
                      child: SpeedChallengeGame(language: language),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal headliner row for Arcade home (P8-918).
class ArcadeHeadlinersSection extends StatelessWidget {
  const ArcadeHeadlinersSection({
    super.key,
    required this.onOpenListing,
  });

  final Future<void> Function(ArcadeGameListing listing) onOpenListing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
          child: Text(
            l10n.gamesArcadeHeadlinersTitle,
            style: PanAfricanTypography.titleSmall(context),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xxs),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
          child: Text(
            l10n.gamesArcadeHeadlinersInstructions,
            style: PanAfricanTypography.bodySmall(context),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        SizedBox(
          height: 168.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
            itemCount: kArcadeHeadlinerOrder.length,
            separatorBuilder: (_, __) => SizedBox(width: PanAfricanSpacing.sm),
            itemBuilder: (context, index) {
              final slot = kArcadeHeadlinerOrder[index];
              final playable = AllGamesRegistry.headlinerIsPlayable(slot);
              final listing = AllGamesRegistry.listingFor(slot.gameId);
              final catalog = AllGamesRegistry.catalogEntryFor(slot.gameId);
              final icon =
                  catalog?.icon ?? Icons.sports_esports_rounded;

              return ArcadeHeadlinerTile(
                title: slot.flagshipTitle,
                icon: icon,
                elevationCardId: slot.elevationCardId,
                featured: slot.showFeaturedBadge,
                comingSoon: !playable,
                onTap: playable && listing != null
                    ? () => onOpenListing(listing)
                    : null,
              );
            },
          ),
        ),
        if (!reduceMotion) SizedBox(height: PanAfricanSpacing.xs),
      ],
    );
  }
}

class ArcadeHeadlinerTile extends StatelessWidget {
  const ArcadeHeadlinerTile({
    super.key,
    required this.title,
    required this.icon,
    required this.elevationCardId,
    required this.featured,
    required this.comingSoon,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String elevationCardId;
  final bool featured;
  final bool comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = PanAfricanColors.primary;
    final label = comingSoon
        ? '$title, ${l10n.gamesArcadeHeadlinersComingSoon}'
        : '$title${featured ? ', ${l10n.gamesArcadeHeadlinersFeatured}' : ''}';

    return Semantics(
      button: onTap != null,
      label: label,
      child: SizedBox(
        width: 148.w,
        height: 168.h,
        child: Material(
          color: colorScheme.surfaceContainerHighest.withOpacity(
            comingSoon ? 0.65 : 1,
          ),
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 28.sp, color: accent),
                      if (featured) ...[
                        SizedBox(width: PanAfricanSpacing.xs),
                        Flexible(
                          child: Text(
                            l10n.gamesArcadeHeadlinersFeatured,
                            style: PanAfricanTypography.labelSmall(
                              context,
                              color: accent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    title,
                    style: PanAfricanTypography.titleSmall(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    comingSoon
                        ? l10n.gamesArcadeHeadlinersComingSoon
                        : elevationCardId,
                    style: PanAfricanTypography.labelSmall(
                      context,
                      color: comingSoon
                          ? PanAfricanColors.kenteBlue
                          : PanAfricanColors.neutralMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _GameTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? PanAfricanColors.cardDark
              : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          boxShadow: PanAfricanShadows.md,
          border: Border.all(
            color: isDark
                ? PanAfricanColors.borderDark
                : PanAfricanColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: PanAfricanRadius.mdBR,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Icon(icon, color: colorScheme.onPrimary, size: 24.sp),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: PanAfricanTypography.titleMedium(context)),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    description,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.xs),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: PanAfricanRadius.roundBR,
              ),
              child: Icon(Icons.play_arrow_rounded, color: color, size: 24.sp),
            ),
          ],
        ),
      ),
    );
  }
}
