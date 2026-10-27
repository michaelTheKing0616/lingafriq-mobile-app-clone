import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/lingafriq_scaffold.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart'
    show AppLanguage;
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/game_router.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'package:lingafriq/utils/error_handler.dart' hide ErrorBoundary;
import 'package:lingafriq/utils/games_prefetch_language.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_screen.dart';
import 'package:lingafriq/screens/games/game_catalog.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';

/// Enhanced Games Screen with ALL 35+ Games Properly Categorized
class GamesScreenEnhanced extends HookConsumerWidget {
  const GamesScreenEnhanced({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    useEffect(() {
      var alive = true;
      Future(() async {
        final prefs = await SharedPreferences.getInstance();
        final lang = resolveGamesHubAppLanguageSync(prefs);
        if (!alive) return;
        selectedLanguage.value = lang;
      });
      return () {
        alive = false;
      };
    }, const []);

    final isLoading = useState(false);
    final shelves = ArcadeSkillShelf.values;
    final totalGames = AllGamesRegistry.totalArcadeListingCount();

    Future<void> openListing(
      BuildContext context,
      ArcadeGameListing listing,
    ) async {
      final lang = gamesBackendSlugFromAppLanguage(selectedLanguage.value);
      if (listing.gameId == AllGamesRegistry.toneForgeGameId) {
        await Navigator.of(context).push(
          SmoothPageRoute.platform(
            child: ToneForgeScreen(
              language: lang,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        );
        return;
      }
      final gameType = listing.routeGameType;
      if (gameType == null) return;
      final loader = ref.read(lazyGameLoaderProvider);
      safeAsync(
        context: context,
        errorContext: 'GamesScreenEnhanced.openGame',
        operation: () async {
          isLoading.value = true;
          try {
            await loader.loadGameOnDemand(gameType, language: lang);
          } catch (_) {}
          if (!context.mounted) return;
          try {
            final gameWidget = buildGameScreen(
              gameType: gameType,
              language: lang,
              onBack: () => Navigator.of(context).pop(),
              ref: ref,
            );
            if (!context.mounted) return;
            await Navigator.push(
              context,
              SmoothPageRoute.platform(
                child: ErrorBoundary(
                  errorMessage: 'This game could not load.',
                  onRetry: () => Navigator.of(context).pop(),
                  child: gameWidget,
                ),
              ),
            );
          } catch (e) {
            if (context.mounted) ErrorHandler.showError(context, e);
          } finally {
            isLoading.value = false;
          }
        },
      );
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Loading games...',
      child: LingafriqScaffold(
        applyTopSafeArea: false,
        appBar: AppBar(
          title: Text('Arcade · $totalGames games'),
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
                  items: kAppLanguagesForGamesHub.map((lang) {
                    return DropdownMenuItem<AppLanguage>(
                      value: lang,
                      child: Text(lang.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedLanguage.value = value;
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                child: Text(
                  'Pick a skill shelf — every game has a home.',
                  style: PanAfricanTypography.bodyMedium(context),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Expanded(
                child: ListView.builder(
                  itemCount: shelves.length,
                  itemBuilder: (context, shelfIndex) {
                    final shelf = shelves[shelfIndex];
                    final listings =
                        AllGamesRegistry.listingsOnShelf(shelf);
                    if (listings.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(PanAfricanSpacing.md),
                        child: Text(
                          '${shelf.title}: no games yet',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.only(bottom: PanAfricanSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: PanAfricanSpacing.md,
                            ),
                            child: Text(
                              shelf.title,
                              style: PanAfricanTypography.titleSmall(context),
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.sm),
                          SizedBox(
                            height: 168.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: PanAfricanSpacing.md,
                              ),
                              itemCount: listings.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(width: PanAfricanSpacing.sm),
                              itemBuilder: (context, index) {
                                final listing = listings[index];
                                final catalogEntry =
                                    AllGamesRegistry.catalogEntryFor(
                                  listing.gameId,
                                );
                                final displayName = catalogEntry?.name ??
                                    (listing.gameId == AllGamesRegistry
                                            .toneForgeGameId
                                        ? 'Tone Forge'
                                        : listing.gameId);
                                final description =
                                    catalogEntry?.description ?? '';
                                final icon = catalogEntry?.icon ??
                                    Icons.sports_esports_rounded;
                                final tile = ArcadeGameShelfTile(
                                  title: displayName,
                                  description: description,
                                  icon: icon,
                                  elevationCardId: listing.elevationCardId,
                                  elevationPending: listing.elevationPending,
                                  featured: listing.featured,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    openListing(context, listing);
                                  },
                                );
                                if (reduceMotion || shelfIndex > 0) {
                                  return tile;
                                }
                                return tile
                                    .animate()
                                    .fadeIn(duration: 220.ms)
                                    .slideX(begin: 0.04, end: 0);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
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

/// One game chip on a skill shelf (widget-tested for elevation states).
class ArcadeGameShelfTile extends StatelessWidget {
  const ArcadeGameShelfTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.elevationCardId,
    required this.elevationPending,
    required this.onTap,
    this.featured = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final String elevationCardId;
  final bool elevationPending;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = PanAfricanColors.primary;

    return Semantics(
      button: true,
      label:
          '$title${elevationPending ? ', elevation pending' : ''}, card $elevationCardId',
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: SizedBox(
            width: 148.w,
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
                            'Featured',
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
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    description,
                    style: PanAfricanTypography.bodySmall(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    elevationCardId,
                    style: PanAfricanTypography.labelSmall(
                      context,
                      color: PanAfricanColors.neutralMedium,
                    ),
                  ),
                  if (elevationPending)
                    Text(
                      'Elevation pending',
                      style: PanAfricanTypography.labelSmall(
                        context,
                        color: PanAfricanColors.kenteBlue,
                      ),
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
