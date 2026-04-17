import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/portrait_video_player.dart';
import 'package:lingafriq/services/hybrid_polie/translation_service.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, PolieMode;
import 'package:lingafriq/utils/api_service.dart';

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
      final originalMode = chatProvider.mode;
      chatProvider.setModeAndLanguage(
        mode: PolieMode.tutor,
        targetLanguage: language,
        sourceLanguage: 'english',
      );

      final prompt = 'Explain the cultural context of "$topic" in $language culture. '
          'Provide a clear, beginner-friendly explanation suitable for $userLevel level learners.';
      
      final response = await chatProvider.sendMessage(prompt);
      
      // Restore original mode
      chatProvider.setModeAndLanguage(
        mode: originalMode,
        targetLanguage: language,
        sourceLanguage: 'english',
      );

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
      final originalMode = chatProvider.mode;
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
      chatProvider.setModeAndLanguage(
        mode: originalMode,
        targetLanguage: language,
        sourceLanguage: 'english',
      );

      // Try to parse JSON from response, or return simple word list
      try {
        // Look for JSON array in the response
        final jsonMatch = RegExp(r'\[.*?\]', dotAll: true).firstMatch(response);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0) ?? '';
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
          final parts = line.split(RegExp(r'[:\-]')).map((s) => s.trim()).toList();
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

List<String> _readMagazineStringList(Map<String, dynamic> article, List<String> keys) {
  for (final k in keys) {
    final v = article[k];
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
  }
  return const [];
}

int? _readMagazineReadingMinutes(Map<String, dynamic> article) {
  final v = article['reading_time_minutes'] ?? article['readingTimeMinutes'];
  if (v is num) return v.round();
  return int.tryParse(v?.toString() ?? '');
}

String? _readMagazineSingleField(Map<String, dynamic> article, List<String> keys) {
  for (final k in keys) {
    final v = article[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  }
  return null;
}

/// Reading time, highlights, related topics, and license/attribution from scraper fields.
class _MagazineArticleStructuredSections extends StatelessWidget {
  const _MagazineArticleStructuredSections({required this.article});

  final Map<String, dynamic> article;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final minutes = _readMagazineReadingMinutes(article);
    final highlights = _readMagazineStringList(
      article,
      const ['highlights', 'key_takeaways', 'keyTakeaways'],
    );
    final topics = _readMagazineStringList(
      article,
      const ['related_topics', 'relatedTopics'],
    );
    final attribution = _readMagazineSingleField(
      article,
      const ['attribution', 'source', 'credit'],
    );
    final license = _readMagazineSingleField(
      article,
      const ['license', 'licence'],
    );

    final hasReading = minutes != null && minutes > 0;
    if (!hasReading &&
        highlights.isEmpty &&
        topics.isEmpty &&
        attribution == null &&
        license == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasReading) ...[
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18.sp, color: PanAfricanColors.primary),
              SizedBox(width: PanAfricanSpacing.xs),
              Text(
                l10n.magazineReadingTime(minutes),
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  color: PanAfricanColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md),
        ],
        if (highlights.isNotEmpty) ...[
          Text(
            l10n.magazineKeyTakeaways,
            style: PanAfricanTypography.titleMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          ...highlights.map(
            (h) => Padding(
              padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    String.fromCharCode(0x2022) + ' ',
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                  Expanded(
                    child: Text(h, style: PanAfricanTypography.bodyMedium(context)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
        ],
        if (topics.isNotEmpty) ...[
          Text(
            l10n.magazineRelatedTopics,
            style: PanAfricanTypography.titleMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Wrap(
            spacing: PanAfricanSpacing.xs,
            runSpacing: PanAfricanSpacing.xs,
            children: topics
                .map(
                  (t) => Chip(
                    label: Text(t, style: PanAfricanTypography.labelMedium(context)),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: PanAfricanSpacing.md),
        ],
        if (attribution != null || license != null)
          Card(
            color: Theme.of(context).brightness == Brightness.dark
                ? PanAfricanColors.cardDark
                : PanAfricanColors.cardLight,
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.magazineSourceAndLicense,
                    style: PanAfricanTypography.titleSmall(context),
                  ),
                  if (attribution != null) ...[
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(attribution, style: PanAfricanTypography.bodySmall(context)),
                  ],
                  if (license != null) ...[
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(license, style: PanAfricanTypography.bodySmall(context)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
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
              _MagazineArticleRichMedia(article: article),
              _MagazineArticleStructuredSections(article: article),
              SizedBox(height: PanAfricanSpacing.md),
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

/// Featured image, gallery, Wikimedia video, and audio for rich magazine articles.
class _MagazineArticleRichMedia extends StatelessWidget {
  const _MagazineArticleRichMedia({required this.article});

  final Map<String, dynamic> article;

  @override
  Widget build(BuildContext context) {
    final featured = article['featured_image'] as String?;
    final rawImages = article['images'];
    final images = <String>[];
    if (rawImages is List) {
      for (final e in rawImages) {
        final s = e.toString();
        if (s.startsWith('http')) images.add(s);
      }
    }
    if (featured != null && featured.startsWith('http')) {
      images.removeWhere((u) => u == featured);
    }
    final videoUrl = article['video_url'] ?? article['videoUrl'];
    final audioUrl = article['audio_url'] ?? article['audioUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featured != null && featured.startsWith('http')) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: featured,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
        ],
        if (images.isNotEmpty) ...[
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => SizedBox(width: PanAfricanSpacing.sm),
              itemBuilder: (ctx, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: images[i],
                  width: 140,
                  height: 110,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
        ],
        if (videoUrl is String && videoUrl.startsWith('http')) ...[
          PortraitPlayerPage(videoUrl: videoUrl),
          SizedBox(height: PanAfricanSpacing.md),
        ],
        if (audioUrl is String && audioUrl.startsWith('http')) _ArticleInlineAudio(url: audioUrl),
      ],
    );
  }
}

class _ArticleInlineAudio extends StatefulWidget {
  const _ArticleInlineAudio({required this.url});

  final String url;

  @override
  State<_ArticleInlineAudio> createState() => _ArticleInlineAudioState();
}

class _ArticleInlineAudioState extends State<_ArticleInlineAudio> {
  late final AudioPlayer _player = AudioPlayer();
  bool _loading = false;
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (_playing) {
        await _player.stop();
        setState(() => _playing = false);
      } else {
        await _player.setUrl(widget.url);
        await _player.play();
        setState(() => _playing = true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play this audio clip.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.audiotrack_rounded, color: PanAfricanColors.primary),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Text(
              'Related audio (open license)',
              style: PanAfricanTypography.labelLarge(context),
            ),
          ),
          IconButton(
            tooltip: _playing ? 'Stop' : 'Play',
            onPressed: _toggle,
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

