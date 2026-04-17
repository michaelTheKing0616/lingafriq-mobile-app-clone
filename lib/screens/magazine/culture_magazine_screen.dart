import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/culture_content_model.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/services/culture_magazine_service.dart';
import 'package:lingafriq/services/polie_content_generator.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';

class CultureMagazineScreen extends ConsumerStatefulWidget {
  const CultureMagazineScreen({super.key});

  @override
  ConsumerState<CultureMagazineScreen> createState() => _CultureMagazineScreenState();
}

class _CultureMagazineScreenState extends ConsumerState<CultureMagazineScreen> {
  // ignore: unused_field
  String _selectedCategory = 'All';

  static const int _articlesPageSize = 40;

  List<CultureContent> _allArticles = [];
  bool _isLoading = true;
  String? _errorMessage;
  late CultureMagazineService _cultureService;

  @override
  void initState() {
    super.initState();
    _cultureService = CultureMagazineService(ref);
    _loadArticles();
  }

  /// Loads published articles from the API; if none (or API error), generates cards via
  /// [PolieContentGenerator.generateCulturalArticle] (Groq). Static cards are last-resort only.
  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<CultureContent> merged = [];
    try {
      merged = await _fetchPublishedPagesFromApi();
    } catch (e, st) {
      logError(
        'Culture magazine API load failed',
        tag: 'culture_magazine',
        error: e,
        stackTrace: st,
      );
    }

    if (merged.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _allArticles = merged;
        _isLoading = false;
      });
      return;
    }

    try {
      final ai = await _polieAiMagazineItems();
      if (!mounted) return;
      setState(() {
        _allArticles = ai;
        _isLoading = false;
      });
    } catch (e, st) {
      logError(
        'Polie AI magazine generation failed; using static emergency cards',
        tag: 'culture_magazine',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _allArticles = _staticEmergencyMagazineItems();
        _isLoading = false;
      });
    }
  }

  Future<List<CultureContent>> _fetchPublishedPagesFromApi() async {
    final merged = <CultureContent>[];
    final seenIds = <String>{};
    var page = 1;
    for (;;) {
      final batch = await _cultureService.getArticles(
        page: page,
        limit: _articlesPageSize,
      );
      if (batch.isEmpty) break;
      for (final a in batch) {
        if (seenIds.add(a.id)) merged.add(a);
      }
      if (batch.length < _articlesPageSize) break;
      page++;
    }
    return merged;
  }

  static const List<(ContentType, String)> _polieMagazineAiTypes = [
    (ContentType.article, 'article'),
    (ContentType.story, 'story'),
    (ContentType.music, 'music'),
    (ContentType.festival, 'festival'),
  ];

  String _languageForPolieMagazine() {
    final raw = ref.read(onboardingProvider).selectedLanguage;
    if (raw == null || raw.trim().isEmpty) return 'English';
    return raw.trim();
  }

  /// Real Polie/Groq-generated magazine cards ([PolieContentGenerator.generateCulturalArticle]).
  Future<List<CultureContent>> _polieAiMagazineItems() async {
    final gen = ref.read(polieContentGeneratorProvider);
    final language = _languageForPolieMagazine();
    final out = <CultureContent>[];

    for (final entry in _polieMagazineAiTypes) {
      try {
        final map = await gen.generateCulturalArticle(
          language: language,
          type: entry.$2,
        );
        out.add(_cultureContentFromPolieMap(map, entry.$1));
      } catch (e, st) {
        logError(
          'Polie magazine item failed (${entry.$2})',
          tag: 'culture_magazine',
          error: e,
          stackTrace: st,
        );
      }
    }

    if (out.isEmpty) {
      throw StateError('No Polie magazine items generated');
    }
    return out;
  }

  CultureContent _cultureContentFromPolieMap(Map<String, dynamic> map, ContentType type) {
    final title = (map['title']?.toString() ?? 'Cultural highlight').trim();
    final body = (map['content']?.toString() ?? '').trim();
    var desc = (map['description']?.toString() ?? '').trim();
    if (desc.isEmpty && body.isNotEmpty) {
      desc = body.substring(0, math.min(180, body.length));
    }
    final lang = (map['language']?.toString() ?? _languageForPolieMagazine()).trim();
    final id = 'polie_ai_${type.name}_${title.hashCode}';
    return CultureContent(
      id: id,
      title: title,
      description: desc.isEmpty ? 'Polie-generated cultural read' : desc,
      type: type,
      content: body.isEmpty ? desc : body,
      language: lang.isEmpty ? 'English' : lang,
      country: '🇿🇦',
      publishDate: DateTime.now(),
      isFeatured: false,
    );
  }

  /// Offline / last-resort copy when API and Groq are unavailable.
  List<CultureContent> _staticEmergencyMagazineItems() {
    const types = [
      ContentType.article,
      ContentType.story,
      ContentType.music,
      ContentType.festival,
    ];
    return types
        .map(
          (type) => CultureContent(
            id: 'polie_static_${type.name}',
            title: _staticTitle(type),
            description: _staticDescription(type),
            type: type,
            content: _staticBody(type),
            language: 'English',
            country: '🇿🇦',
            publishDate: DateTime.now(),
            isFeatured: false,
          ),
        )
        .toList();
  }

  String _staticTitle(ContentType type) {
    switch (type) {
      case ContentType.story:
        return 'Traditional African Story';
      case ContentType.music:
        return 'African Music Traditions';
      case ContentType.festival:
        return 'Cultural Festival';
      case ContentType.lore:
        return 'Ancient Wisdom';
      case ContentType.article:
        return 'Cultural Article';
      case ContentType.recipe:
        return 'Traditional Recipe';
    }
  }

  String _staticDescription(ContentType type) {
    switch (type) {
      case ContentType.story:
        return 'Discover timeless African folktales';
      case ContentType.music:
        return 'Explore the rhythms of Africa';
      case ContentType.festival:
        return 'Celebrate African traditions';
      case ContentType.lore:
        return 'Learn from ancestral wisdom';
      case ContentType.article:
        return 'Insights into African culture';
      case ContentType.recipe:
        return 'Taste of Africa';
    }
  }

  String _staticBody(ContentType type) {
    switch (type) {
      case ContentType.story:
        return 'Once upon a time, in the heart of Africa, stories were passed down through generations...';
      case ContentType.music:
        return 'African music is a rich tapestry of rhythms, melodies, and cultural expressions...';
      case ContentType.festival:
        return 'Festivals across Africa celebrate the diversity and unity of the continent...';
      case ContentType.lore:
        return 'The wisdom of African ancestors continues to guide and inspire...';
      case ContentType.article:
        return 'African culture is a vibrant mosaic of traditions, languages, and customs...';
      case ContentType.recipe:
        return 'Traditional African cuisine reflects the continent\'s rich agricultural heritage...';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Unable to load cultural magazine. Please check your connection and try again.',
      onRetry: _loadArticles,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = context.isDarkMode;
    
    // Show loading indicator
    if (_isLoading) {
      return const DynamicLoadingScreen();
    }
    
    // Show error message
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              FilledButton(
                onPressed: _loadArticles,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Use API data
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.sunset,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: PanAfricanShadows.lg,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(PanAfricanIcons.back, color: Theme.of(context).colorScheme.onPrimary),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(PanAfricanIcons.menu, color: Theme.of(context).colorScheme.onPrimary),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Scaffold.of(context).openDrawer();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Icon(
                      PanAfricanIcons.magazine,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 64.sp,
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      'Cultural Magazines',
                      style: PanAfricanTypography.headlineMedium(context, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      'Explore African culture & heritage',
                      style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            top: 22.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Category Cards
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        _CategoryCard(
                          id: 'music',
                          name: 'Music',
                          icon: Icons.music_note_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFCE1126), Color(0xFFFF6B35)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.music).length,
                          onTap: () {
                            setState(() => _selectedCategory = 'Music');
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'stories',
                          name: 'Stories',
                          icon: Icons.menu_book_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007A3D), Color(0xFF00A8E8)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.story || a.type == ContentType.lore).length,
                          onTap: () {
                            setState(() => _selectedCategory = 'Stories');
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'articles',
                          name: 'Articles',
                          icon: Icons.newspaper_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFCD116), Color(0xFFFF6B35)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.article).length,
                          onTap: () {
                            setState(() => _selectedCategory = 'Articles');
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'history',
                          name: 'History',
                          icon: Icons.public_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2CBF), Color(0xFFCE1126)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.lore).length,
                          onTap: () {
                            setState(() => _selectedCategory = 'History');
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'festivals',
                          name: 'Festivals',
                          icon: Icons.celebration_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFF7B2CBF)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.festival).length,
                          onTap: () {
                            setState(() => _selectedCategory = 'Festivals');
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'recipes',
                          name: 'Recipes',
                          icon: Icons.restaurant_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00A8E8), Color(0xFF007A3D)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.recipe).length,
                          onTap: () {
                            setState(() => _selectedCategory = 'Recipes');
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _CategoryCard extends StatelessWidget {
  final String id;
  final String name;
  final IconData icon;
  final Gradient gradient;
  final int articles;
  final VoidCallback onTap;
  final bool isDark;
  
  const _CategoryCard({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradient,
    required this.articles,
    required this.onTap,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: PanAfricanRadius.xlBR,
        child: Container(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: PanAfricanRadius.xlBR,
            boxShadow: PanAfricanShadows.sm,
            border: Border.all(
              color: isDark ? PanAfricanColors.borderDark : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: PanAfricanRadius.xlBR,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: PanAfricanRadius.lgBR,
                      boxShadow: PanAfricanShadows.sm,
                    ),
                    child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 32.sp),
                  ),
                  SizedBox(width: PanAfricanSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: PanAfricanTypography.titleMedium(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.xxs),
                        Text(
                          '$articles articles',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

