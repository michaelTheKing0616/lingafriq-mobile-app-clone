import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/services/hybrid_polie/translation_service.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';

/// Enhanced Features for Cultural Magazine
/// Polie Translation, Cultural Context, Vocabulary Extraction, Share/Favorite, Progress Tracking, Related Articles

class MagazineEnhancedFeatures {
  /// Get Polie translation for article
  /// Uses TranslationService (Groq-based pipeline) instead of old /polie/tutor/translate endpoint
  static Future<Map<String, dynamic>?> getPolieTranslation(
    String articleId,
    String language, {
    String? articleContent,
  }) async {
    if (articleContent == null || articleContent.isEmpty) {
      return null;
    }
    
    try {
      final translationService = TranslationService();
      final result = await translationService.translate(
        text: articleContent,
        sourceLang: 'english',
        targetLang: language,
      );

      return {
        'translation': result.translation,
        'model': result.model,
        'confidence': result.confidence,
      };
    } catch (e) {
      return null;
    }
  }

  /// Get cultural context via GroqChatProvider (Groq-based pipeline)
  /// Uses GroqChatProvider instead of old /polie/tutor/explain endpoint
  static Future<Map<String, dynamic>?> getCulturalContext(
    String articleId,
    String topic, {
    required WidgetRef ref,
    String language = 'yoruba',
    String userLevel = 'A1',
  }) async {
    try {
      final chatProvider = ref.read(groqChatProvider.notifier);
      
      // Set mode to tutor temporarily for cultural context explanation
      final originalMode = ref.read(groqChatProvider).mode;
      chatProvider.setModeAndLanguage(
        mode: PolieMode.tutor,
        targetLanguage: language,
        sourceLanguage: 'english',
      );

      final prompt = 'Explain the cultural context of "$topic" in $language culture. '
          'Provide a clear, beginner-friendly explanation suitable for $userLevel level learners.';
      
      final response = await chatProvider.sendMessage(prompt);
      
      // Restore original mode
      if (originalMode != null) {
        chatProvider.setModeAndLanguage(
          mode: originalMode,
          targetLanguage: language,
          sourceLanguage: 'english',
        );
      }

      return {
        'explanation': response,
        'topic': topic,
        'language': language,
      };
    } catch (e) {
      return null;
    }
  }

  /// Extract vocabulary from article using GroqChatProvider (Groq-based pipeline)
  /// Uses GroqChatProvider instead of old /polie/tutor/story endpoint
  static Future<List<Map<String, dynamic>>> extractVocabulary(
    String articleId,
    String content, {
    required WidgetRef ref,
    String language = 'yoruba',
  }) async {
    if (content.isEmpty) {
      return [];
    }
    
    try {
      final chatProvider = ref.read(groqChatProvider.notifier);
      
      // Set mode to vocab temporarily for vocabulary extraction
      final originalMode = ref.read(groqChatProvider).mode;
      chatProvider.setModeAndLanguage(
        mode: PolieMode.vocab,
        targetLanguage: language,
        sourceLanguage: 'english',
      );

      final prompt = 'Extract key vocabulary words from this article content and provide their meanings:\n\n'
          '$content\n\n'
          'Format your response as a JSON array of objects with "word" and "meaning" fields. '
          'Focus on important $language words that would help a language learner.';
      
      final response = await chatProvider.sendMessage(prompt);
      
      // Restore original mode
      if (originalMode != null) {
        chatProvider.setModeAndLanguage(
          mode: originalMode,
          targetLanguage: language,
          sourceLanguage: 'english',
        );
      }

      // Try to parse JSON from response, or return simple word list
      try {
        // Look for JSON array in the response
        final jsonMatch = RegExp(r'\[.*?\]', dotAll: true).firstMatch(response);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0);
          final decoded = jsonDecode(jsonStr) as List;
          return decoded.map((item) => {
            'word': item['word'] ?? '',
            'meaning': item['meaning'] ?? '',
          }).toList();
        }
      } catch (e) {
        // If JSON parsing fails, extract words manually
      }

      // Fallback: extract words from response text
      final words = <Map<String, dynamic>>[];
      final lines = response.split('\n');
      for (final line in lines) {
        if (line.contains(':') || line.contains('-')) {
          final parts = line.split(RegExp(r'[:-\-]')).map((s) => s.trim()).toList();
          if (parts.length >= 2) {
            words.add({
              'word': parts[0],
              'meaning': parts.sublist(1).join(' '),
            });
          }
        }
      }

      return words;
    } catch (e) {
      return [];
    }
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
  final String? translatedTitle;
  final String? translatedExcerpt;
  final bool showTranslation;
  final String userLanguage;

  const ArticleDetailEnhanced({
    super.key,
    required this.article,
    this.translatedTitle,
    this.translatedExcerpt,
    this.showTranslation = false,
    this.userLanguage = 'english',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTranslationState = useState(showTranslation);
    final showVocabulary = useState(false);
    final showCulturalContext = useState(false);
    final isFavorite = useState(article['isFavorite'] ?? false);
    final readingProgress = useState(0.0);
    final relatedArticles = useState<List<Map<String, dynamic>>>([]);
    final vocabulary = useState<List<Map<String, dynamic>>>([]);
    final culturalContext = useState<Map<String, dynamic>?>(null);
    final isTranslating = useState(false);
    final translationService = useMemoized(() => TranslationService());
    final contentTranslation = useState<String?>(null);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    useEffect(() {
      // Load related articles
      MagazineEnhancedFeatures.getRelatedArticles(
        article['_id'] ?? '',
        article['category'] ?? '',
      ).then((articles) {
        relatedArticles.value = articles;
      });

      // Extract vocabulary using Groq provider
      MagazineEnhancedFeatures.extractVocabulary(
        article['_id'] ?? '',
        article['content'] ?? '',
        ref: ref,
        language: userLanguage,
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
                showTranslationState.value && contentTranslation.value != null
                    ? contentTranslation.value!
                    : article['content'] ?? article['excerpt'] ?? '',
                style: PanAfricanTypography.bodyLarge(context),
              ),
              SizedBox(height: PanAfricanSpacing.lg),

              // Translation Toggle
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isTranslating.value ? null : () async {
                        if (!showTranslationState.value && contentTranslation.value == null) {
                          isTranslating.value = true;
                          try {
                            final content = article['content'] ?? article['excerpt'] ?? '';
                            final result = await translationService.translate(
                              text: content,
                              sourceLang: 'english',
                              targetLang: userLanguage,
                            );
                            contentTranslation.value = result.translation;
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Translation failed. Check your connection.'),
                                  action: SnackBarAction(
                                    label: 'Retry',
                                    onPressed: () {
                                      // Re-trigger translation on next tap
                                      contentTranslation.value = null;
                                      showTranslationState.value = false;
                                    },
                                  ),
                                ),
                              );
                            }
                          } finally {
                            isTranslating.value = false;
                          }
                        }
                        showTranslationState.value = !showTranslationState.value;
                      },
                      icon: isTranslating.value 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                            )
                          : Icon(Icons.translate),
                      label: Text(showTranslationState.value ? 'Show Original' : 'Translate to $userLanguage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
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

