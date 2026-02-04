import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'culture_magazine_enhanced_features.dart';

/// Enhanced Cultural Magazine Screen with Polie Translation, Cultural Context, Vocabulary
class CultureMagazineScreenEnhanced extends HookConsumerWidget {
  const CultureMagazineScreenEnhanced({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final selectedCategory = useState<String?>(null);
    final showTranslation = useState(false);
    final favoriteArticles = useState<Set<String>>({});

    final isDark = Theme.of(context).brightness == Brightness.dark;

    static List<Map<String, dynamic>> _placeholderArticles() {
      return [
        {'_id': '1', 'title': 'Greetings Across Africa', 'slug': 'greetings-across-africa', 'excerpt': 'Learn how to say hello in Yoruba, Swahili, Zulu, and more.', 'category': 'language', 'published': true},
        {'_id': '2', 'title': 'Proverbs and Wisdom', 'slug': 'proverbs-and-wisdom', 'excerpt': 'African proverbs that teach life lessons and cultural values.', 'category': 'culture', 'published': true},
        {'_id': '3', 'title': 'Music and Rhythm', 'slug': 'music-and-rhythm', 'excerpt': 'The role of drumming and music in African languages and communication.', 'category': 'culture', 'published': true},
        {'_id': '4', 'title': 'Family and Respect', 'slug': 'family-and-respect', 'excerpt': 'Terms for family members and showing respect in different African cultures.', 'category': 'language', 'published': true},
        {'_id': '5', 'title': 'Markets and Bargaining', 'slug': 'markets-and-bargaining', 'excerpt': 'Essential phrases for shopping and bargaining in local markets.', 'category': 'language', 'published': true},
      ];
    }

    Future<void> loadArticles() async {
      isLoading.value = true;
      try {
        final response = await ApiService.get(
          Api.cultureArticles(published: true),
          queryParameters: selectedCategory.value != null
              ? {'category': selectedCategory.value}
              : null,
        );

        if (response.statusCode == 200) {
          final raw = response.data;
          final dynamic listCandidate = raw is Map
              ? (raw['data'] ?? raw['results'] ?? raw['articles'])
              : raw;

          if (listCandidate is List) {
            final list = List<Map<String, dynamic>>.from(listCandidate.whereType<Map>());
            articles.value = list.isNotEmpty ? list : _placeholderArticles();
          } else {
            articles.value = _placeholderArticles();
          }
        } else {
          articles.value = _placeholderArticles();
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
        articles.value = _placeholderArticles();
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> toggleTranslation(String articleId, String language) async {
      // In production, this would call Polie translation API
      showTranslation.value = !showTranslation.value;
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
      // Share functionality
      final url = 'https://lingafriq.com/magazine/${article['slug']}';
      // Use share_plus package in production
    }

    useEffect(() {
      loadArticles();
      return null;
    }, [selectedCategory.value]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cultural Magazine'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(showTranslation.value ? Icons.translate : Icons.translate_outlined),
            onPressed: () => showTranslation.value = !showTranslation.value,
            tooltip: 'Toggle Translation',
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
                  ? Center(child: CircularProgressIndicator())
                  : articles.value.isEmpty
                      ? Center(
                          child: Text(
                            'No articles found',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(PanAfricanSpacing.md),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: PanAfricanSpacing.md,
                            mainAxisSpacing: PanAfricanSpacing.md,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: articles.value.length,
                          itemBuilder: (context, index) {
                            final article = articles.value[index];
                            return _ArticleCard(
                              article: article,
                              showTranslation: showTranslation.value,
                              isFavorite: favoriteArticles.value.contains(article['_id']),
                              onFavorite: () => toggleFavorite(article['_id']),
                              onShare: () => shareArticle(article),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    child: ArticleDetailEnhanced(
                                      article: article,
                                    ),
                                  ),
                                );
                              },
                              isDark: isDark,
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
          final isSelected = (category == 'All' && selectedCategory == null) ||
              category.toLowerCase() == selectedCategory?.toLowerCase();

          return Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                onCategoryChanged(selected && category != 'All' ? category.toLowerCase() : null);
              },
              selectedColor: PanAfricanColors.primaryContainer,
              checkmarkColor: PanAfricanColors.primary,
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
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
                    Center(
                      child: Icon(
                        Icons.article,
                        size: 48.sp,
                        color: Colors.white70,
                      ),
                    ),
                    Positioned(
                      top: PanAfricanSpacing.xs,
                      right: PanAfricanSpacing.xs,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? PanAfricanColors.error : Colors.white,
                              size: 20.sp,
                            ),
                            onPressed: onFavorite,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(Icons.share, color: Colors.white, size: 20.sp),
                            onPressed: onShare,
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
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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


