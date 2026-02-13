import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:velocity_x/velocity_x.dart';

/// Cultural Content Hub Screen
/// Tabs: Stories, Proverbs, Music, Traditions, Food, History
class CulturalHubScreen extends ConsumerStatefulWidget {
  final String? language;

  const CulturalHubScreen({
    Key? key,
    this.language,
  }) : super(key: key);

  @override
  ConsumerState<CulturalHubScreen> createState() => _CulturalHubScreenState();
}

class _CulturalHubScreenState extends ConsumerState<CulturalHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CulturalContent> _allContent = [];
  Map<String, bool> _completedItems = {};
  bool _isLoading = true;
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
    setState(() => _isLoading = true);
    
    try {
      // TODO: Replace with actual API call
      // final content = await contentService.getCulturalContent(widget.language);
      _allContent = _getDefaultContent();
    } catch (e) {
      debugPrint('Error loading cultural content: $e');
      _allContent = _getDefaultContent();
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadCompletedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final completedJson = prefs.getString('cultural_completed') ?? '{}';
    // Parse and populate _completedItems
  }

  Future<void> _markAsCompleted(String itemId) async {
    setState(() {
      _completedItems[itemId] = true;
    });
    final prefs = await SharedPreferences.getInstance();
    // Save completion status
  }

  List<CulturalContent> _getDefaultContent() {
    return [
      // Stories
      CulturalContent(
        id: 'story_1',
        type: CulturalContentType.story,
        title: 'The Wise Tortoise',
        description: 'A traditional African folktale about wisdom and patience',
        content: 'Long ago, in the heart of Africa, there lived a wise tortoise...',
        vocabulary: ['tortoise', 'wisdom', 'patience', 'journey'],
        xpReward: 50,
        language: widget.language ?? 'sw',
      ),
      CulturalContent(
        id: 'story_2',
        type: CulturalContentType.story,
        title: 'The Lion and the Mouse',
        description: 'A story teaching the value of kindness',
        content: 'A lion was sleeping when a mouse ran over him...',
        vocabulary: ['lion', 'mouse', 'kindness', 'help'],
        xpReward: 50,
        language: widget.language ?? 'sw',
      ),
      
      // Proverbs
      CulturalContent(
        id: 'proverb_1',
        type: CulturalContentType.proverb,
        title: 'Unity is Strength',
        description: 'Swahili: "Umoja ni nguvu"',
        content: 'This proverb emphasizes that working together makes us stronger.',
        vocabulary: ['unity', 'strength', 'together'],
        xpReward: 30,
        language: widget.language ?? 'sw',
        translation: 'Unity is strength',
        culturalContext: 'Commonly used to encourage cooperation in communities.',
      ),
      CulturalContent(
        id: 'proverb_2',
        type: CulturalContentType.proverb,
        title: 'Slow and Steady Wins',
        description: 'Yoruba: "A kì í rí ìgbà tí a kò ní rí ìgbà"',
        content: 'Patience and persistence lead to success.',
        vocabulary: ['patience', 'success', 'persistence'],
        xpReward: 30,
        language: widget.language ?? 'yo',
        translation: 'There is no time we won\'t see time',
        culturalContext: 'Encourages patience in achieving goals.',
      ),
      
      // Music
      CulturalContent(
        id: 'music_1',
        type: CulturalContentType.music,
        title: 'Jambo Bwana',
        description: 'Popular Swahili greeting song',
        content: 'Jambo, jambo bwana\nHabari gani, mzuri sana...',
        vocabulary: ['jambo', 'bwana', 'habari', 'sana'],
        xpReward: 40,
        language: widget.language ?? 'sw',
        lyrics: 'Jambo, jambo bwana\nHabari gani, mzuri sana\nWageni, mwakaribishwa\nKenya yetu, hakuna matata',
        translation: 'Hello, hello sir\nHow are you, very well\nGuests, you are welcome\nOur Kenya, no worries',
      ),
      
      // Traditions
      CulturalContent(
        id: 'tradition_1',
        type: CulturalContentType.tradition,
        title: 'Greeting Customs',
        description: 'Learn proper greeting etiquette in African cultures',
        content: 'Greetings are very important in African cultures. In many communities, you greet elders first...',
        vocabulary: ['greeting', 'elder', 'respect', 'custom'],
        xpReward: 40,
        language: widget.language ?? 'sw',
      ),
      CulturalContent(
        id: 'tradition_2',
        type: CulturalContentType.tradition,
        title: 'Naming Ceremonies',
        description: 'Understanding naming traditions across Africa',
        content: 'Naming ceremonies are significant events in many African cultures...',
        vocabulary: ['naming', 'ceremony', 'tradition', 'celebration'],
        xpReward: 40,
        language: widget.language ?? 'sw',
      ),
      
      // Food
      CulturalContent(
        id: 'food_1',
        type: CulturalContentType.food,
        title: 'Jollof Rice',
        description: 'West African staple dish',
        content: 'Jollof rice is a beloved dish across West Africa. It\'s made with rice, tomatoes, and spices...',
        vocabulary: ['rice', 'tomato', 'spice', 'dish'],
        xpReward: 35,
        language: widget.language ?? 'pcm',
      ),
      CulturalContent(
        id: 'food_2',
        type: CulturalContentType.food,
        title: 'Injera',
        description: 'Ethiopian sourdough flatbread',
        content: 'Injera is a traditional Ethiopian flatbread made from teff flour...',
        vocabulary: ['bread', 'flour', 'traditional', 'flatbread'],
        xpReward: 35,
        language: widget.language ?? 'am',
      ),
      
      // History
      CulturalContent(
        id: 'history_1',
        type: CulturalContentType.history,
        title: 'Ancient Kingdoms',
        description: 'Great African empires and kingdoms',
        content: 'Africa was home to many powerful kingdoms including Mali, Ghana, and Songhai...',
        vocabulary: ['kingdom', 'empire', 'ancient', 'power'],
        xpReward: 45,
        language: widget.language ?? 'sw',
      ),
      CulturalContent(
        id: 'history_2',
        type: CulturalContentType.history,
        title: 'Trade Routes',
        description: 'Historical trade networks across Africa',
        content: 'Africa had extensive trade networks connecting different regions...',
        vocabulary: ['trade', 'network', 'route', 'exchange'],
        xpReward: 45,
        language: widget.language ?? 'sw',
      ),
    ];
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
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
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
          Tab(text: 'Stories', icon: Icon(Icons.menu_book_rounded, size: 20.sp)),
          Tab(text: 'Proverbs', icon: Icon(Icons.format_quote_rounded, size: 20.sp)),
          Tab(text: 'Music', icon: Icon(Icons.music_note_rounded, size: 20.sp)),
          Tab(text: 'Traditions', icon: Icon(Icons.celebration_rounded, size: 20.sp)),
          Tab(text: 'Food', icon: Icon(Icons.restaurant_rounded, size: 20.sp)),
          Tab(text: 'History', icon: Icon(Icons.history_rounded, size: 20.sp)),
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
    
    if (content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64.sp, color: PolieColors.textSecondary),
            SizedBox(height: PolieSpacing.md),
            Text(
              'No content available',
              style: PolieTypography.h3(context).copyWith(
                color: PolieColors.textSecondary,
              ),
            ),
          ],
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
                            Icon(
                              Icons.check_circle,
                              color: PolieColors.success,
                              size: 20.sp,
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: PolieColors.textSecondary,
                ),
              ],
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
          Container(
            margin: EdgeInsets.symmetric(vertical: PolieSpacing.md),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: PolieColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
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
                    SizedBox(
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
