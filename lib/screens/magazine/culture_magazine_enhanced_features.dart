import 'package:flutter/material.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enhanced Features for Cultural Magazine
/// Polie Translation, Cultural Context, Vocabulary Extraction, Share/Favorite, Progress Tracking, Related Articles

class MagazineEnhancedFeatures {
  /// Get Polie translation for article
  static Future<Map<String, dynamic>?> getPolieTranslation(
    String articleId,
    String language,
  ) async {
    try {
      final response = await ApiService.post(
        '/polie/tutor/translate',
        data: {
          'text': '', // Article content would be passed
          'sourceLang': 'english',
          'targetLang': language,
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Get cultural context via Polie Tutor Mode
  static Future<Map<String, dynamic>?> getCulturalContext(
    String articleId,
    String topic,
  ) async {
    try {
      final response = await ApiService.post(
        '/polie/tutor/explain',
        data: {
          'topic': topic,
          'language': 'yoruba', // Default, should be dynamic
          'userLevel': 'A1',
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Extract vocabulary from article
  static Future<List<Map<String, dynamic>>> extractVocabulary(
    String articleId,
    String content,
  ) async {
    try {
      final response = await ApiService.post(
        '/polie/tutor/story',
        data: {
          'theme': 'vocabulary_extraction',
          'language': 'yoruba',
          'content': content,
        },
      );

      if (response.statusCode == 200 && response.data['data']?['vocabulary'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']['vocabulary']);
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  /// Toggle favorite article
  static Future<bool> toggleFavorite(String articleId, bool isFavorite) async {
    try {
      final response = await ApiService.post(
        '/culture-magazine/$articleId/favorite',
        data: {'isFavorite': !isFavorite},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Share article
  static Future<void> shareArticle(String articleId, String title) async {
    final url = 'https://lingafriq.com/magazine/$articleId';
    // Use share_plus package in production
    // await Share.share('Check out this article: $title\n$url');
  }

  /// Track reading progress
  static Future<void> trackProgress(
    String articleId,
    double progress,
  ) async {
    try {
      await ApiService.post(
        '/culture-magazine/$articleId/progress',
        data: {'progress': progress},
      );
    } catch (e) {
      // Silent fail
    }
  }

  /// Get related articles
  static Future<List<Map<String, dynamic>>> getRelatedArticles(
    String articleId,
    String category,
  ) async {
    try {
      final response = await ApiService.get(
        '/culture-magazine',
        queryParameters: {
          'category': category,
          'limit': 5,
          'exclude': articleId,
        },
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      return [];
    }
    return [];
  }
}

/// Widget for Article Detail with Enhanced Features
class ArticleDetailEnhanced extends HookConsumerWidget {
  final Map<String, dynamic> article;

  const ArticleDetailEnhanced({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTranslation = useState(false);
    final showVocabulary = useState(false);
    final showCulturalContext = useState(false);
    final isFavorite = useState(article['isFavorite'] ?? false);
    final readingProgress = useState(0.0);
    final relatedArticles = useState<List<Map<String, dynamic>>>([]);
    final vocabulary = useState<List<Map<String, dynamic>>>([]);
    final culturalContext = useState<Map<String, dynamic>?>(null);
    final translation = useState<Map<String, dynamic>?>(null);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    useEffect(() {
      // Load related articles
      MagazineEnhancedFeatures.getRelatedArticles(
        article['_id'] ?? '',
        article['category'] ?? '',
      ).then((articles) {
        relatedArticles.value = articles;
      });

      // Extract vocabulary
      MagazineEnhancedFeatures.extractVocabulary(
        article['_id'] ?? '',
        article['content'] ?? '',
      ).then((vocab) {
        vocabulary.value = vocab;
      });

      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(article['title'] ?? 'Article'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite.value ? Icons.favorite : Icons.favorite_border,
              color: isFavorite.value ? PanAfricanColors.error : null,
            ),
            onPressed: () async {
              final success = await MagazineEnhancedFeatures.toggleFavorite(
                article['_id'] ?? '',
                isFavorite.value,
              );
              if (success) {
                isFavorite.value = !isFavorite.value;
                HapticFeedback.mediumImpact();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              MagazineEnhancedFeatures.shareArticle(
                article['_id'] ?? '',
                article['title'] ?? '',
              );
            },
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
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article Content
              Text(
                showTranslation.value && translation.value != null
                    ? translation.value!['translation'] ?? ''
                    : article['content'] ?? '',
                style: PanAfricanTypography.bodyLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.lg),

              // Translation Toggle
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (translation.value == null) {
                          final trans = await MagazineEnhancedFeatures.getPolieTranslation(
                            article['_id'] ?? '',
                            'yoruba',
                          );
                          translation.value = trans;
                        }
                        showTranslation.value = !showTranslation.value;
                      },
                      icon: Icon(Icons.translate),
                      label: Text(showTranslation.value ? 'Show Original' : 'Translate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => showVocabulary.value = !showVocabulary.value,
                      icon: Icon(Icons.book),
                      label: Text('Vocabulary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.secondary,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.lg),

              // Vocabulary Drawer
              if (showVocabulary.value && vocabulary.value.isNotEmpty)
                _buildVocabularySection(context, vocabulary.value, isDark),

              // Cultural Context
              if (showCulturalContext.value && culturalContext.value != null)
                _buildCulturalContextSection(context, culturalContext.value!, isDark),

              // Reading Progress
              _buildProgressSection(context, readingProgress.value, isDark),

              // Related Articles
              if (relatedArticles.value.isNotEmpty)
                _buildRelatedArticlesSection(context, relatedArticles.value, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVocabularySection(
    BuildContext context,
    List<Map<String, dynamic>> vocab,
    bool isDark,
  ) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: ExpansionTile(
        title: Text('Vocabulary (${vocab.length})'),
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              children: vocab.map((v) {
                return ListTile(
                  title: Text(v['word'] ?? ''),
                  subtitle: Text(v['meaning'] ?? ''),
                  trailing: v['example'] != null
                      ? IconButton(
                          icon: Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Example'),
                                content: Text(v['example']),
                              ),
                            );
                          },
                        )
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalContextSection(
    BuildContext context,
    Map<String, dynamic> contextData,
    bool isDark,
  ) {
    return Card(
      color: PanAfricanColors.primaryContainer.withOpacity(0.3),
      child: ListTile(
        leading: Icon(Icons.public, color: PanAfricanColors.primary),
        title: Text('Cultural Context'),
        subtitle: Text(contextData['explanation'] ?? ''),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Cultural Context'),
              content: SingleChildScrollView(
                child: Text(contextData['explanation'] ?? ''),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    double progress,
    bool isDark,
  ) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Progress',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: PanAfricanColors.neutralLight,
              valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              '${(progress * 100).toInt()}% complete',
              style: PanAfricanTypography.bodySmall(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedArticlesSection(
    BuildContext context,
    List<Map<String, dynamic>> articles,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Articles',
          style: PanAfricanTypography.titleLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        ...articles.map((article) {
          return Card(
            margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            child: ListTile(
              leading: Icon(Icons.article),
              title: Text(article['title'] ?? ''),
              subtitle: Text(article['excerpt'] ?? ''),
              trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    child: ArticleDetailEnhanced(article: article),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

