import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:velocity_x/velocity_x.dart';

/// Cultural Content Hub Screen
/// Tabs: Stories, Proverbs, Music, Traditions, Food, History
class CulturalHubScreen extends ConsumerStatefulWidget {
  final String? language;

  const CulturalHubScreen({
    super.key,
    this.language,
  });

  @override
  ConsumerState<CulturalHubScreen> createState() => _CulturalHubScreenState();
}

class _CulturalHubScreenState extends ConsumerState<CulturalHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CulturalContent> _allContent = [];
  final Map<String, bool> _completedItems = {};
  bool _isLoading = true;
  bool _hasError = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadContent();
    _loadCompletedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      _allContent = await _fetchCulturalContent();
    } catch (e) {
      debugPrint('Error loading cultural content: $e');
      _allContent = [];
      _hasError = true;
    }
    
    setState(() => _isLoading = false);
  }

  Future<List<CulturalContent>> _fetchCulturalContent() async {
    final language = widget.language ?? 'sw';
    final response = await ApiService.get(
      Api.cultureArticles(published: true),
      queryParameters: {
        'language': language,
      },
    );

    final raw = response.data;
    final dynamic listCandidate = raw is Map
        ? (raw['data'] ?? raw['results'] ?? raw['articles'] ?? raw['content'])
        : raw;

    if (listCandidate is! List) return const [];

    return listCandidate
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw);
          final id = (item['_id'] ?? item['id'])?.toString();
          final title = item['title']?.toString();
          final body = (item['content'] ?? item['excerpt'])?.toString();
          if (id == null || title == null || body == null) return null;
          final tags = item['tags'] is List ? List<String>.from(item['tags']) : const <String>[];
          return CulturalContent(
            id: id,
            type: _typeFromCategory(item['category']?.toString()),
            title: title,
            description: item['excerpt']?.toString() ?? '',
            content: body,
            vocabulary: tags,
            xpReward: 40,
            language: item['language']?.toString() ?? language,
            translation: null,
            culturalContext: item['country']?.toString(),
            lyrics: null,
          );
        })
        .whereType<CulturalContent>()
        .toList();
  }

  CulturalContentType _typeFromCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'music':
        return CulturalContentType.music;
      case 'history':
        return CulturalContentType.history;
      case 'cuisine':
        return CulturalContentType.food;
      case 'tradition':
      case 'festivals':
        return CulturalContentType.tradition;
      case 'literature':
      case 'art':
      case 'language':
        return CulturalContentType.story;
      default:
        return CulturalContentType.story;
    }
  }

  Future<void> _loadCompletedItems() async {
    // Parse and populate _completedItems
  }

  Future<void> _markAsCompleted(String itemId) async {
    setState(() {
      _completedItems[itemId] = true;
    });
    // Save completion status
  }

  List<CulturalContent> _getContentByType(CulturalContentType type) {
    return _allContent.where((c) => c.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? PolieColors.obsidian : PolieColors.surfaceLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(context),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: PolieColors.electricTeal))
                    : _buildTabContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary, semanticLabel: 'Back'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cultural Hub',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  'Explore African culture',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: PolieColors.surfaceContainerLight.withOpacity(0.1),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: PolieColors.electricTeal,
        labelColor: PolieColors.textPrimary,
        unselectedLabelColor: PolieColors.textSecondary,
        tabs: [
          Tab(text: 'Stories', icon: Icon(Icons.menu_book_rounded, size: 20.sp, semanticLabel: 'Stories')),
          Tab(text: 'Proverbs', icon: Icon(Icons.format_quote_rounded, size: 20.sp, semanticLabel: 'Proverbs')),
          Tab(text: 'Music', icon: Icon(Icons.music_note_rounded, size: 20.sp, semanticLabel: 'Music')),
          Tab(text: 'Traditions', icon: Icon(Icons.celebration_rounded, size: 20.sp, semanticLabel: 'Traditions')),
          Tab(text: 'Food', icon: Icon(Icons.restaurant_rounded, size: 20.sp, semanticLabel: 'Food')),
          Tab(text: 'History', icon: Icon(Icons.history_rounded, size: 20.sp, semanticLabel: 'History')),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildContentList(CulturalContentType.story),
        _buildContentList(CulturalContentType.proverb),
        _buildContentList(CulturalContentType.music),
        _buildContentList(CulturalContentType.tradition),
        _buildContentList(CulturalContentType.food),
        _buildContentList(CulturalContentType.history),
      ],
    );
  }

  Widget _buildContentList(CulturalContentType type) {
    final content = _getContentByType(type);

    if (_hasError && content.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(PolieSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64.sp, color: PolieColors.error),
              SizedBox(height: PolieSpacing.md),
              Text(
                'Failed to load content',
                style: PolieTypography.h3(context).copyWith(
                  color: PolieColors.textPrimary,
                ),
              ),
              SizedBox(height: PolieSpacing.sm),
              Text(
                'Check your connection and try again',
                style: PolieTypography.body(context).copyWith(
                  color: PolieColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: PolieSpacing.lg),
              TextButton.icon(
                onPressed: _loadContent,
                icon: Icon(Icons.refresh_rounded, color: PolieColors.electricTeal),
                label: Text(
                  'Retry',
                  style: PolieTypography.label(context).copyWith(
                    color: PolieColors.electricTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (content.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(PolieSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64.sp, color: PolieColors.textSecondary),
              SizedBox(height: PolieSpacing.md),
              Text(
                'No cultural content available',
                style: PolieTypography.h3(context).copyWith(
                  color: PolieColors.textSecondary,
                ),
              ),
              SizedBox(height: PolieSpacing.sm),
              Text(
                'Pull to refresh or check back soon',
                style: PolieTypography.body(context).copyWith(
                  color: PolieColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: PolieSpacing.lg),
              TextButton.icon(
                onPressed: _loadContent,
                icon: Icon(Icons.refresh_rounded, color: PolieColors.electricTeal),
                label: Text(
                  'Retry',
                  style: PolieTypography.label(context).copyWith(
                    color: PolieColors.electricTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(PolieSpacing.md),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[index];
        final isCompleted = _completedItems[item.id] ?? false;
        return _ContentCard(
          content: item,
          isCompleted: isCompleted,
          onTap: () => _showContentDetail(item),
          onComplete: () => _markAsCompleted(item.id),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.1);
      },
    );
  }

  void _showContentDetail(CulturalContent content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContentDetailSheet(
        content: content,
        isCompleted: _completedItems[content.id] ?? false,
        onComplete: () {
          _markAsCompleted(content.id);
          Navigator.pop(context);
        },
        audioPlayer: _audioPlayer,
      ),
    );
  }
}

enum CulturalContentType {
  story,
  proverb,
  music,
  tradition,
  food,
  history,
}

class CulturalContent {
  final String id;
  final CulturalContentType type;
  final String title;
  final String description;
  final String content;
  final List<String> vocabulary;
  final int xpReward;
  final String language;
  final String? translation;
  final String? culturalContext;
  final String? lyrics;

  CulturalContent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.content,
    required this.vocabulary,
    required this.xpReward,
    required this.language,
    this.translation,
    this.culturalContext,
    this.lyrics,
  });
}

class _ContentCard extends StatelessWidget {
  final CulturalContent content;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _ContentCard({
    required this.content,
    required this.isCompleted,
    required this.onTap,
    required this.onComplete,
  });

  IconData _getTypeIcon() {
    switch (content.type) {
      case CulturalContentType.story:
        return Icons.menu_book_rounded;
      case CulturalContentType.proverb:
        return Icons.format_quote_rounded;
      case CulturalContentType.music:
        return Icons.music_note_rounded;
      case CulturalContentType.tradition:
        return Icons.celebration_rounded;
      case CulturalContentType.food:
        return Icons.restaurant_rounded;
      case CulturalContentType.history:
        return Icons.history_rounded;
    }
  }

  Color _getTypeColor() {
    switch (content.type) {
      case CulturalContentType.story:
        return PolieColors.royalAmethyst;
      case CulturalContentType.proverb:
        return PolieColors.goldEmber;
      case CulturalContentType.music:
        return PolieColors.electricTeal;
      case CulturalContentType.tradition:
        return PolieColors.success;
      case CulturalContentType.food:
        return PolieColors.error;
      case CulturalContentType.history:
        return PolieColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final typeColor = _getTypeColor();

    return Container(
      margin: EdgeInsets.only(bottom: PolieSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        border: Border.all(
          color: isCompleted ? PolieColors.success.withOpacity(0.5) : typeColor.withOpacity(0.3),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          label: '${content.title}. ${content.description}',
          button: true,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(PolieRadius.lg),
            child: Padding(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: typeColor,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: PolieSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              content.title,
                              style: PolieTypography.h3(context).copyWith(
                                color: PolieColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Semantics(
                              label: 'Completed',
                              child: Icon(
                                Icons.check_circle,
                                color: PolieColors.success,
                                size: 20.sp,
                                semanticLabel: 'Completed',
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: PolieSpacing.xs),
                      Text(
                        content.description,
                        style: PolieTypography.body(context).copyWith(
                          color: PolieColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: PolieSpacing.sm),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PolieSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PolieColors.goldEmber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(PolieRadius.sm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12.sp, color: PolieColors.goldEmber),
                                SizedBox(width: 4),
                                Text(
                                  '${content.xpReward} XP',
                                  style: PolieTypography.bodySmall(context).copyWith(
                                    color: PolieColors.goldEmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: PolieSpacing.sm),
                          Text(
                            '${content.vocabulary.length} words',
                            style: PolieTypography.bodySmall(context).copyWith(
                              color: PolieColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Semantics(
                  excludeSemantics: true,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: PolieColors.textSecondary,
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

class _ContentDetailSheet extends StatelessWidget {
  final CulturalContent content;
  final bool isCompleted;
  final VoidCallback onComplete;
  final AudioPlayer audioPlayer;

  const _ContentDetailSheet({
    required this.content,
    required this.isCompleted,
    required this.onComplete,
    required this.audioPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final typeColor = _getTypeColor();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
      ),
      child: Column(
        children: [
          // Handle
          Semantics(
            excludeSemantics: true,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: PolieSpacing.md),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: PolieColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(PolieSpacing.md),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(PolieRadius.md),
                        ),
                        child: Icon(
                          _getTypeIcon(),
                          color: typeColor,
                          size: 32.sp,
                        ),
                      ),
                      SizedBox(width: PolieSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content.title,
                              style: PolieTypography.h2(context).copyWith(
                                color: PolieColors.textPrimary,
                              ),
                            ),
                            Text(
                              content.description,
                              style: PolieTypography.body(context).copyWith(
                                color: PolieColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PolieSpacing.lg),
                  Text(
                    content.content,
                    style: PolieTypography.bodyLarge(context).copyWith(
                      color: PolieColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                  if (content.lyrics != null) ...[
                    SizedBox(height: PolieSpacing.lg),
                    Container(
                      padding: EdgeInsets.all(PolieSpacing.md),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(PolieRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lyrics',
                            style: PolieTypography.titleMedium(context).copyWith(
                              color: typeColor,
                            ),
                          ),
                          SizedBox(height: PolieSpacing.sm),
                          Text(
                            content.lyrics!,
                            style: PolieTypography.body(context).copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (content.translation != null) ...[
                            SizedBox(height: PolieSpacing.md),
                            Text(
                              'Translation',
                              style: PolieTypography.titleSmall(context),
                            ),
                            SizedBox(height: PolieSpacing.xs),
                            Text(
                              content.translation!,
                              style: PolieTypography.body(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (content.translation != null && content.lyrics == null) ...[
                    SizedBox(height: PolieSpacing.lg),
                    Container(
                      padding: EdgeInsets.all(PolieSpacing.md),
                      decoration: BoxDecoration(
                        color: PolieColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(PolieRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Translation',
                            style: PolieTypography.titleMedium(context),
                          ),
                          SizedBox(height: PolieSpacing.sm),
                          Text(
                            content.translation!,
                            style: PolieTypography.body(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (content.culturalContext != null) ...[
                    SizedBox(height: PolieSpacing.lg),
                    Container(
                      padding: EdgeInsets.all(PolieSpacing.md),
                      decoration: BoxDecoration(
                        color: PolieColors.royalAmethyst.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(PolieRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cultural Context',
                            style: PolieTypography.titleMedium(context).copyWith(
                              color: PolieColors.royalAmethyst,
                            ),
                          ),
                          SizedBox(height: PolieSpacing.sm),
                          Text(
                            content.culturalContext!,
                            style: PolieTypography.body(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: PolieSpacing.lg),
                  Container(
                    padding: EdgeInsets.all(PolieSpacing.md),
                    decoration: BoxDecoration(
                      color: PolieColors.electricTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vocabulary',
                          style: PolieTypography.titleMedium(context).copyWith(
                            color: PolieColors.electricTeal,
                          ),
                        ),
                        SizedBox(height: PolieSpacing.sm),
                        Wrap(
                          spacing: PolieSpacing.sm,
                          runSpacing: PolieSpacing.sm,
                          children: content.vocabulary.map((word) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: PolieSpacing.sm,
                                vertical: PolieSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: PolieColors.electricTeal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(PolieRadius.sm),
                              ),
                              child: Text(
                                word,
                                style: PolieTypography.label(context).copyWith(
                                  color: PolieColors.electricTeal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: PolieSpacing.lg),
                  if (!isCompleted)
                    Semantics(
                      label: 'Mark as completed and earn ${content.xpReward} XP',
                      button: true,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onComplete();
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PolieColors.success,
                          padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
                            SizedBox(width: PolieSpacing.sm),
                            Text(
                              'Mark as Completed (+${content.xpReward} XP)',
                              style: PolieTypography.labelLarge(context).copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (content.type) {
      case CulturalContentType.story:
        return Icons.menu_book_rounded;
      case CulturalContentType.proverb:
        return Icons.format_quote_rounded;
      case CulturalContentType.music:
        return Icons.music_note_rounded;
      case CulturalContentType.tradition:
        return Icons.celebration_rounded;
      case CulturalContentType.food:
        return Icons.restaurant_rounded;
      case CulturalContentType.history:
        return Icons.history_rounded;
    }
  }

  Color _getTypeColor() {
    switch (content.type) {
      case CulturalContentType.story:
        return PolieColors.royalAmethyst;
      case CulturalContentType.proverb:
        return PolieColors.goldEmber;
      case CulturalContentType.music:
        return PolieColors.electricTeal;
      case CulturalContentType.tradition:
        return PolieColors.success;
      case CulturalContentType.food:
        return PolieColors.error;
      case CulturalContentType.history:
        return PolieColors.textSecondary;
    }
  }
}
