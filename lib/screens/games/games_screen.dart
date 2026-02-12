import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/screens/games/word_match_game.dart';
import 'package:lingafriq/screens/games/fill_in_the_blank_game.dart';
import 'package:lingafriq/screens/games/speed_challenge_game.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

final languagesForGamesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(apiProvider.notifier).getLanguages();
});

class GamesScreen extends ConsumerWidget {
  const GamesScreen({Key? key}) : super(key: key);

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
                            style: PanAfricanTypography.titleLarge(context, color: colorScheme.onPrimary),
                            ),
                            SizedBox(height: PanAfricanSpacing.xxs),
                            Text(
                              'Learn through play',
                            style: PanAfricanTypography.bodyMedium(context, color: colorScheme.onPrimary.withOpacity(0.9)),
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
                  final languages = languageResponse.results;
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
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
    Key? key,
    required this.language,
    required this.onTap,
    this.colorIndex = 0,
  }) : super(key: key);

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
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          boxShadow: PanAfricanShadows.md,
          border: Border.all(
            color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
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
                  colors: [
                    color,
                    color.withOpacity(0.7),
                  ],
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

  const GameTypesScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
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
          style: PanAfricanTypography.titleMedium(context, color: colorScheme.onPrimary),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: PanAfricanGradients.forest,
          ),
        ),
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
                    SmoothPageRoute(
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
                    SmoothPageRoute(
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
                  // Navigate to pronunciation game
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
                    SmoothPageRoute(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          boxShadow: PanAfricanShadows.md,
          border: Border.all(
            color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
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
                  colors: [
                    color,
                    color.withOpacity(0.7),
                  ],
                ),
                borderRadius: PanAfricanRadius.mdBR,
                boxShadow: PanAfricanShadows.sm,
              ),
              child: Icon(
                icon,
                color: colorScheme.onPrimary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PanAfricanTypography.titleMedium(context),
                  ),
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
              child: Icon(
                Icons.play_arrow_rounded,
                color: color,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

