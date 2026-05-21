import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/services/hybrid_polie/translation_service.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'culture_magazine_enhanced_features.dart';

/// Enhanced Cultural Magazine Screen with Polie Translation, Cultural Context, Vocabulary
class CultureMagazineScreenEnhanced extends HookConsumerWidget {
  const CultureMagazineScreenEnhanced({super.key, this.initialFilterLanguage});

  /// Optional language slug from curriculum (e.g. yoruba, nigerian_pidgin).
  final String? initialFilterLanguage;

  static const int _pageSize = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = useState<List<Map<String, dynamic>>>([]);
    final translatedArticles = useState<Map<String, Map<String, String>>>({});
    final isLoading = useState(false);
    final isLoadingMore = useState(false);
    final isTranslating = useState(false);
    final selectedCategory = useState<String?>(null);
    final showTranslation = useState(false);
    final favoriteArticles = useState<Set<String>>({});
    final currentPage = useState(1);
    final hasMore = useState(true);
    final totalDocs = useState<int?>(null);
    final scrollController = useScrollController();
    final translationService = useMemoized(() => TranslationService());
    final onboarding = ref.watch(onboardingProvider);
    final userLanguage = (onboarding.selectedLanguage ?? 'english')
        .toLowerCase();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    List<Map<String, dynamic>> _parseArticleDocs(dynamic raw) {
      dynamic listCandidate = raw is Map
          ? (raw['data'] ?? raw['results'] ?? raw['articles'])
          : raw;

      if (listCandidate is Map) {
        listCandidate = listCandidate['docs'] ?? listCandidate['items'] ?? [];
      }

      if (listCandidate is! List) return [];

      return List<Map<String, dynamic>>.from(listCandidate.whereType<Map>());
    }

    bool _parseHasNextPage(dynamic raw, int fetchedCount) {
      if (raw is! Map) {
        return fetchedCount >= _pageSize;
      }
      final data = raw['data'];
      if (data is! Map) {
        return fetchedCount >= _pageSize;
      }
      if (data['hasNextPage'] == true) return true;
      final page = (data['page'] as num?)?.toInt();
      final totalPages = (data['totalPages'] as num?)?.toInt();
      if (page != null && totalPages != null) {
        return page < totalPages;
      }
      return fetchedCount >= _pageSize;
    }

    int? _parseTotalDocs(dynamic raw) {
      if (raw is! Map) return null;
      final data = raw['data'];
      if (data is! Map) return null;
      return (data['totalDocs'] as num?)?.toInt();
    }

    Future<void> loadArticles({bool reset = true}) async {
      if (reset) {
        if (isLoading.value) return;
        isLoading.value = true;
        currentPage.value = 1;
        hasMore.value = true;
        totalDocs.value = null;
      } else {
        if (isLoadingMore.value || isLoading.value || !hasMore.value) return;
        isLoadingMore.value = true;
      }

      try {
        final pageToFetch = reset ? 1 : currentPage.value;
        final queryParameters = <String, dynamic>{
          'page': pageToFetch,
          'limit': _pageSize,
        };
        if (selectedCategory.value != null) {
          queryParameters['category'] = selectedCategory.value!;
        }
        final filterLang = initialFilterLanguage?.trim();
        if (filterLang != null && filterLang.isNotEmpty) {
          queryParameters['language'] =
              CurriculumService.normalizeLanguageKey(filterLang);
        }

        final response = await ApiService.get(
          Api.cultureArticles(published: true),
          queryParameters: queryParameters,
        );

        if (response.statusCode == 200) {
          final raw = response.data;
          var batch = _parseArticleDocs(raw);
          if (filterLang != null && filterLang.isNotEmpty) {
            final key = CurriculumService.normalizeLanguageKey(filterLang);
            batch = batch.where((article) {
              final lang =
                  (article['language'] as String?)?.toLowerCase() ?? '';
              return lang == key ||
                  lang == filterLang.toLowerCase() ||
                  (key == 'nigerian_pidgin' && lang == 'pidgin');
            }).toList();
          }
          final nextHasMore = _parseHasNextPage(raw, batch.length);
          final total = _parseTotalDocs(raw);

          if (reset) {
            articles.value = batch;
            translatedArticles.value = {};
          } else {
            final seen = articles.value
                .map((a) => a['_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();
            final merged = [...articles.value];
            for (final item in batch) {
              final id = item['_id']?.toString() ?? '';
              if (id.isEmpty || seen.add(id)) merged.add(item);
            }
            articles.value = merged;
          }

          hasMore.value = nextHasMore;
          totalDocs.value = total;
          currentPage.value = pageToFetch + 1;
        } else if (reset) {
          articles.value = [];
          hasMore.value = false;
        }
      } catch (e) {
        if (reset) {
          try {
            final raw = await rootBundle.loadString('assets/data/magazine_articles_seed.json');
            final data = jsonDecode(raw) as Map<String, dynamic>;
            final seed = (data['articles'] as List<dynamic>?)
                    ?.whereType<Map>()
                    .map((m) => Map<String, dynamic>.from(m))
                    .toList() ??
                [];
            if (seed.isNotEmpty) {
              final filterLang = initialFilterLanguage?.trim();
              if (filterLang != null && filterLang.isNotEmpty) {
                final key = CurriculumService.normalizeLanguageKey(filterLang);
                articles.value = seed
                    .where((a) {
                      final lang = (a['language'] as String?)?.toLowerCase() ?? '';
                      return lang == key ||
                          lang == filterLang.toLowerCase() ||
                          (key == 'nigerian_pidgin' && lang == 'pidgin');
                    })
                    .toList();
              } else {
                articles.value = seed;
              }
              hasMore.value = false;
            } else {
              articles.value = [];
              hasMore.value = false;
            }
          } catch (_) {
            if (context.mounted) {
              ErrorHandler.showError(context, e);
            }
            articles.value = [];
            hasMore.value = false;
          }
        } else if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        if (reset) {
          isLoading.value = false;
        } else {
          isLoadingMore.value = false;
        }
      }
    }

    void onScroll() {
      if (!scrollController.hasClients) return;
      final position = scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 320) {
        loadArticles(reset: false);
      }
    }

    useEffect(() {
      void listener() => onScroll();
      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController, hasMore.value, isLoading.value, isLoadingMore.value]);

    Future<void> toggleTranslation(String articleId, String language) async {
      // Toggle translation view
      showTranslation.value = !showTranslation.value;

      // If enabling translation and not already translated, translate all articles
      if (showTranslation.value && translatedArticles.value.isEmpty) {
        isTranslating.value = true;

        try {
          final translations = <String, Map<String, String>>{};
          bool anyRealTranslation = false;

          for (final article in articles.value) {
            final id = article['_id']?.toString() ?? '';
            final title = article['title']?.toString() ?? '';
            final excerpt = article['excerpt']?.toString() ?? '';

            if (id.isEmpty) continue;

            final titleResult = await translationService.translate(
              text: title,
              sourceLang: 'english',
              targetLang: language,
            );

            final excerptResult = await translationService.translate(
              text: excerpt,
              sourceLang: 'english',
              targetLang: language,
            );

            if (titleResult.model != 'fallback') anyRealTranslation = true;

            translations[id] = {
              'title': titleResult.translation,
              'excerpt': excerptResult.translation,
            };
          }

          translatedArticles.value = translations;

          if (!anyRealTranslation && context.mounted) {
            ErrorHandler.showError(
              context,
              'Translation services are unavailable. Showing original text.',
            );
            showTranslation.value = false;
          }
        } catch (e) {
          if (context.mounted) {
            ErrorHandler.showError(context, e);
          }
          showTranslation.value = false;
        } finally {
          isTranslating.value = false;
        }
      }
    }

    Future<void> toggleFavorite(String articleId) async {
      final newFavorites = Set<String>.from(favoriteArticles.value);
      if (newFavorites.contains(articleId)) {
        newFavorites.remove(articleId);
      } else {
        newFavorites.add(articleId);
      }
      favoriteArticles.value = newFavorites;
    }

    Future<void> shareArticle(Map<String, dynamic> article) async {
      final title = article['title']?.toString().trim() ?? 'Cultural article';
      final slug = article['slug']?.toString().trim();
      final base = Api.baseurl.replaceAll(RegExp(r'/$'), '');
      final articleUrl = (slug != null && slug.isNotEmpty)
          ? '$base/culture-magazine/$slug'
          : '$base/culture-magazine';
      await Share.share('$title\n\n$articleUrl');
    }

    useEffect(() {
      loadArticles(reset: true);
      return null;
    }, [selectedCategory.value]);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cultural Magazine',
          style: PanAfricanTypography.titleLarge(context),
        ),
        backgroundColor: isDark
            ? PanAfricanColors.cardDark
            : PanAfricanColors.cardLight,
        foregroundColor: isDark
            ? PanAfricanColors.textPrimaryDark
            : PanAfricanColors.textPrimaryLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PanAfricanIcons.back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            tooltip: l10n.tooltipFlbHeritageArchive,
            icon: const Icon(Icons.account_balance_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pushNamed('/flb-heritage-archive');
            },
          ),
          IconButton(
            tooltip: l10n.tooltipTribeDiscovery,
            icon: const Icon(Icons.groups_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pushNamed('/tribe-discovery');
            },
          ),
          if (isTranslating.value)
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PanAfricanColors.primary,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                showTranslation.value
                    ? Icons.translate
                    : Icons.translate_outlined,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                toggleTranslation('', userLanguage);
              },
              tooltip: showTranslation.value
                  ? 'Show Original'
                  : 'Translate to $userLanguage',
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
        child: Column(
          children: [
            // Category Filter
            _buildCategoryFilter(
              context,
              selectedCategory.value,
              (category) => selectedCategory.value = category,
              isDark,
            ),

            // Articles Grid
            Expanded(
              child: isLoading.value
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: PanAfricanColors.primary,
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            'Loading articles...',
                            style: PanAfricanTypography.bodyMedium(context)
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.45),
                                ),
                          ),
                        ],
                      ),
                    )
                  : articles.value.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(PanAfricanSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: isDark
                                  ? PanAfricanColors.neutralMedium
                                  : PanAfricanColors.neutralLight,
                            ),
                            SizedBox(height: PanAfricanSpacing.md),
                            Text(
                              'No articles yet',
                              style: PanAfricanTypography.titleMedium(context),
                            ),
                            SizedBox(height: PanAfricanSpacing.xs),
                            Text(
                              'Check back soon for cultural content.',
                              textAlign: TextAlign.center,
                              style: PanAfricanTypography.bodyMedium(context)
                                  .copyWith(
                                    color: isDark
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.54)
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.45),
                                  ),
                            ),
                            SizedBox(height: PanAfricanSpacing.lg),
                            TextButton.icon(
                              onPressed: () => loadArticles(reset: true),
                              icon: Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: PanAfricanColors.primary,
                              ),
                              label: Text(
                                'Retry',
                                style: PanAfricanTypography.labelLarge(
                                  context,
                                ).copyWith(color: PanAfricanColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.all(PanAfricanSpacing.md),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: PanAfricanSpacing.md,
                              mainAxisSpacing: PanAfricanSpacing.md,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: articles.value.length,
                            itemBuilder: (context, index) {
                              final article = articles.value[index];
                        final articleId = article['_id']?.toString() ?? '';
                        final translated = translatedArticles.value[articleId];

                        // Create display article with translations if available
                        final displayArticle =
                            showTranslation.value && translated != null
                            ? {
                                ...article,
                                'title':
                                    translated['title'] ?? article['title'],
                                'excerpt':
                                    translated['excerpt'] ?? article['excerpt'],
                              }
                            : article;

                        return _ArticleCard(
                              article: displayArticle,
                              showTranslation: showTranslation.value,
                              isFavorite: favoriteArticles.value.contains(
                                article['_id'],
                              ),
                              onFavorite: () => toggleFavorite(article['_id']),
                              onShare: () => shareArticle(article),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute.platform(
                                    child: ArticleDetailEnhanced(
                                      article: article,
                                      translatedTitle: translated?['title'],
                                      translatedExcerpt: translated?['excerpt'],
                                      showTranslation: showTranslation.value,
                                      userLanguage: userLanguage,
                                    ),
                                  ),
                                );
                              },
                              isDark: isDark,
                            )
                            .animate(delay: (index * 50).ms)
                            .fadeIn(duration: 300.ms)
                            .scale(
                              begin: Offset(0.9, 0.9),
                              end: Offset(1, 1),
                            );
                            },
                          ),
                        ),
                        if (isLoadingMore.value)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: PanAfricanSpacing.md,
                            ),
                            child: CircularProgressIndicator(
                              color: PanAfricanColors.primary,
                            ),
                          )
                        else if (hasMore.value)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: PanAfricanSpacing.md,
                            ),
                            child: TextButton(
                              onPressed: () => loadArticles(reset: false),
                              child: Text(
                                'Load more articles',
                                style: PanAfricanTypography.labelLarge(
                                  context,
                                ).copyWith(color: PanAfricanColors.primary),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(
    BuildContext context,
    String? selectedCategory,
    Function(String?) onCategoryChanged,
    bool isDark,
  ) {
    final categories = [
      'All',
      'Tradition',
      'Cuisine',
      'Music',
      'History',
      'Language',
      'Festivals',
      'Art',
      'Literature',
    ];

    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: OptimizedListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected =
              (category == 'All' && selectedCategory == null) ||
              category.toLowerCase() == selectedCategory?.toLowerCase();

          return Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
            child: FilterChip(
              label: Text(
                category,
                style: PanAfricanTypography.labelMedium(context),
              ),
              selected: isSelected,
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                onCategoryChanged(
                  selected && category != 'All' ? category.toLowerCase() : null,
                );
              },
              selectedColor: PanAfricanColors.primaryContainer,
              checkmarkColor: PanAfricanColors.primary,
              backgroundColor: isDark
                  ? PanAfricanColors.surfaceContainerDark
                  : PanAfricanColors.surfaceContainerLight,
            ),
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool showTranslation;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onTap;
  final bool isDark;

  const _ArticleCard({
    required this.article,
    required this.showTranslation,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: PanAfricanGradients.sunset,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(PanAfricanRadius.lg),
                  ),
                ),
                child: Stack(
                  children: [
                    if (article['imageUrl'] != null &&
                        (article['imageUrl'] as String).isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(PanAfricanRadius.lg),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: article['imageUrl'] as String,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 180),
                          placeholder: (_, __) =>
                              _ArticleImageFallback(colors: colors),
                          errorWidget: (_, __, ___) =>
                              _ArticleImageFallback(colors: colors),
                        ),
                      )
                    else
                      _ArticleImageFallback(colors: colors),
                    Positioned(
                      top: PanAfricanSpacing.xs,
                      right: PanAfricanSpacing.xs,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? PanAfricanColors.error
                                  : Theme.of(context).colorScheme.onPrimary,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onFavorite();
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.share,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onShare();
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['title'] ?? 'Untitled',
                      style: PanAfricanTypography.titleSmall(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      article['excerpt'] ?? '',
                      style: PanAfricanTypography.bodySmall(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            article['category'] ?? 'General',
                            style: PanAfricanTypography.labelSmall(context),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Spacer(),
                        if (showTranslation)
                          Icon(
                            Icons.translate,
                            size: 16.sp,
                            color: PanAfricanColors.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleImageFallback extends StatelessWidget {
  final ColorScheme colors;
  const _ArticleImageFallback({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.article,
        size: 48.sp,
        color: colors.onPrimary.withOpacity(0.7),
      ),
    );
  }
}
