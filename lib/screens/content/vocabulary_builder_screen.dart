import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:velocity_x/velocity_x.dart';

/// Enhanced Vocabulary Builder Screen
/// Visual vocabulary cards, word families, picture matching, daily word
class VocabularyBuilderScreen extends ConsumerStatefulWidget {
  final String? language;

  const VocabularyBuilderScreen({
    Key? key,
    this.language,
  }) : super(key: key);

  @override
  ConsumerState<VocabularyBuilderScreen> createState() => _VocabularyBuilderScreenState();
}

class _VocabularyBuilderScreenState extends ConsumerState<VocabularyBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VocabularyWord> _allWords = [];
  Map<String, WordFamily> _wordFamilies = {};
  VocabularyWord? _wordOfTheDay;
  VocabularyStats _stats = VocabularyStats();
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedFamily = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVocabulary();
    _loadWordOfTheDay();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Replace with actual API call
      _allWords = _getDefaultWords();
      _wordFamilies = _organizeIntoFamilies(_allWords);
    } catch (e) {
      debugPrint('Error loading vocabulary: $e');
      _allWords = _getDefaultWords();
      _wordFamilies = _organizeIntoFamilies(_allWords);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadWordOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString('word_of_day_date');
    
    if (savedDate == today && _allWords.isNotEmpty) {
      final wordId = prefs.getString('word_of_day_id');
      _wordOfTheDay = _allWords.firstWhere(
        (w) => w.id == wordId,
        orElse: () => _allWords.first,
      );
    } else {
      // Select new word of the day
      if (_allWords.isNotEmpty) {
        _wordOfTheDay = _allWords[DateTime.now().day % _allWords.length];
        await prefs.setString('word_of_day_id', _wordOfTheDay!.id);
        await prefs.setString('word_of_day_date', today);
      }
    }
    
    setState(() {});
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    _stats = VocabularyStats(
      totalLearned: prefs.getInt('vocab_total_learned') ?? _allWords.length,
      mastered: prefs.getInt('vocab_mastered') ?? 0,
      inReview: prefs.getInt('vocab_in_review') ?? 0,
    );
    setState(() {});
  }

  List<VocabularyWord> _getDefaultWords() {
    return [
      // Colors
      VocabularyWord(
        id: 'color_red',
        word: 'nyekundu',
        translation: 'red',
        pronunciation: 'nye-KUN-du',
        imageUrl: 'assets/images/colors/red.png',
        audioUrl: null,
        family: 'colors',
        language: widget.language ?? 'sw',
      ),
      VocabularyWord(
        id: 'color_blue',
        word: 'bluu',
        translation: 'blue',
        pronunciation: 'BLOO',
        imageUrl: 'assets/images/colors/blue.png',
        audioUrl: null,
        family: 'colors',
        language: widget.language ?? 'sw',
      ),
      
      // Animals
      VocabularyWord(
        id: 'animal_lion',
        word: 'simba',
        translation: 'lion',
        pronunciation: 'SIM-ba',
        imageUrl: 'assets/images/animals/lion.png',
        audioUrl: null,
        family: 'animals',
        language: widget.language ?? 'sw',
      ),
      VocabularyWord(
        id: 'animal_elephant',
        word: 'tembo',
        translation: 'elephant',
        pronunciation: 'TEM-bo',
        imageUrl: 'assets/images/animals/elephant.png',
        audioUrl: null,
        family: 'animals',
        language: widget.language ?? 'sw',
      ),
      
      // Food
      VocabularyWord(
        id: 'food_rice',
        word: 'wali',
        translation: 'rice',
        pronunciation: 'WA-li',
        imageUrl: 'assets/images/food/rice.png',
        audioUrl: null,
        family: 'food',
        language: widget.language ?? 'sw',
      ),
      VocabularyWord(
        id: 'food_bread',
        word: 'mkate',
        translation: 'bread',
        pronunciation: 'm-KA-te',
        imageUrl: 'assets/images/food/bread.png',
        audioUrl: null,
        family: 'food',
        language: widget.language ?? 'sw',
      ),
      
      // Family
      VocabularyWord(
        id: 'family_mother',
        word: 'mama',
        translation: 'mother',
        pronunciation: 'MA-ma',
        imageUrl: 'assets/images/family/mother.png',
        audioUrl: null,
        family: 'family',
        language: widget.language ?? 'sw',
      ),
      VocabularyWord(
        id: 'family_father',
        word: 'baba',
        translation: 'father',
        pronunciation: 'BA-ba',
        imageUrl: 'assets/images/family/father.png',
        audioUrl: null,
        family: 'family',
        language: widget.language ?? 'sw',
      ),
      
      // Numbers
      VocabularyWord(
        id: 'number_one',
        word: 'moja',
        translation: 'one',
        pronunciation: 'MO-ja',
        imageUrl: 'assets/images/numbers/one.png',
        audioUrl: null,
        family: 'numbers',
        language: widget.language ?? 'sw',
      ),
      VocabularyWord(
        id: 'number_two',
        word: 'mbili',
        translation: 'two',
        pronunciation: 'MBI-li',
        imageUrl: 'assets/images/numbers/two.png',
        audioUrl: null,
        family: 'numbers',
        language: widget.language ?? 'sw',
      ),
      
      // Body parts
      VocabularyWord(
        id: 'body_head',
        word: 'kichwa',
        translation: 'head',
        pronunciation: 'KI-chwa',
        imageUrl: 'assets/images/body/head.png',
        audioUrl: null,
        family: 'body',
        language: widget.language ?? 'sw',
      ),
      VocabularyWord(
        id: 'body_hand',
        word: 'mkono',
        translation: 'hand',
        pronunciation: 'm-KO-no',
        imageUrl: 'assets/images/body/hand.png',
        audioUrl: null,
        family: 'body',
        language: widget.language ?? 'sw',
      ),
      
      // Emotions
      VocabularyWord(
        id: 'emotion_happy',
        word: 'furaha',
        translation: 'happy',
        pronunciation: 'fu-RA-ha',
        imageUrl: 'assets/images/emotions/happy.png',
        audioUrl: null,
        family: 'emotions',
        language: widget.language ?? 'sw',
      ),
      VocabularyWord(
        id: 'emotion_sad',
        word: 'huzuni',
        translation: 'sad',
        pronunciation: 'hu-ZU-ni',
        imageUrl: 'assets/images/emotions/sad.png',
        audioUrl: null,
        family: 'emotions',
        language: widget.language ?? 'sw',
      ),
    ];
  }

  Map<String, WordFamily> _organizeIntoFamilies(List<VocabularyWord> words) {
    final families = <String, WordFamily>{};
    
    for (final word in words) {
      if (!families.containsKey(word.family)) {
        families[word.family] = WordFamily(
          id: word.family,
          name: _getFamilyName(word.family),
          icon: _getFamilyIcon(word.family),
          words: [],
        );
      }
      families[word.family]!.words.add(word);
    }
    
    return families;
  }

  String _getFamilyName(String familyId) {
    switch (familyId) {
      case 'colors':
        return 'Colors';
      case 'animals':
        return 'Animals';
      case 'food':
        return 'Food';
      case 'family':
        return 'Family';
      case 'numbers':
        return 'Numbers';
      case 'body':
        return 'Body Parts';
      case 'emotions':
        return 'Emotions';
      default:
        return familyId;
    }
  }

  IconData _getFamilyIcon(String familyId) {
    switch (familyId) {
      case 'colors':
        return Icons.palette_rounded;
      case 'animals':
        return Icons.pets_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'family':
        return Icons.family_restroom_rounded;
      case 'numbers':
        return Icons.numbers_rounded;
      case 'body':
        return Icons.accessibility_rounded;
      case 'emotions':
        return Icons.sentiment_satisfied_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _playAudio(String? audioUrl, String word) async {
    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    } else {
      // Use TTS fallback
      HapticFeedback.lightImpact();
    }
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
              _buildStatsBar(context),
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
                  'Vocabulary Builder',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  'Build your word bank',
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

  Widget _buildStatsBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
      padding: EdgeInsets.all(PolieSpacing.md),
      decoration: BoxDecoration(
        color: PolieColors.surfaceContainerLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PolieRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Total',
            value: '${_stats.totalLearned}',
            icon: Icons.library_books_rounded,
            color: PolieColors.electricTeal,
          ),
          _StatItem(
            label: 'Mastered',
            value: '${_stats.mastered}',
            icon: Icons.check_circle_rounded,
            color: PolieColors.success,
          ),
          _StatItem(
            label: 'In Review',
            value: '${_stats.inReview}',
            icon: Icons.refresh_rounded,
            color: PolieColors.goldEmber,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: PolieColors.surfaceContainerLight.withOpacity(0.1),
      child: TabBar(
        controller: _tabController,
        indicatorColor: PolieColors.electricTeal,
        labelColor: PolieColors.textPrimary,
        unselectedLabelColor: PolieColors.textSecondary,
        tabs: [
          Tab(text: 'Word Families', icon: Icon(Icons.category_rounded, size: 20.sp)),
          Tab(text: 'Picture Match', icon: Icon(Icons.image_search_rounded, size: 20.sp)),
          Tab(text: 'Visual Cards', icon: Icon(Icons.style_rounded, size: 20.sp)),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildWordFamiliesTab(),
        _buildPictureMatchTab(),
        _buildVisualCardsTab(),
      ],
    );
  }

  Widget _buildWordFamiliesTab() {
    final families = _wordFamilies.values.toList();
    
    return Column(
      children: [
        if (_wordOfTheDay != null) _buildWordOfTheDay(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(PolieSpacing.md),
            itemCount: families.length,
            itemBuilder: (context, index) {
              final family = families[index];
              return _FamilyCard(
                family: family,
                onTap: () {
                  setState(() {
                    _selectedFamily = family.id;
                  });
                  _tabController.animateTo(2);
                },
              )
                  .animate(delay: (index * 50).ms)
                  .fadeIn(duration: 200.ms)
                  .slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordOfTheDay() {
    if (_wordOfTheDay == null) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.all(PolieSpacing.md),
      padding: EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PolieColors.goldEmber, PolieColors.goldEmberLight],
        ),
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        boxShadow: [
          BoxShadow(
            color: PolieColors.goldEmber.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 24.sp),
              SizedBox(width: PolieSpacing.sm),
              Text(
                'Word of the Day',
                style: PolieTypography.titleLarge(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _wordOfTheDay!.word,
                      style: PolieTypography.h1(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _wordOfTheDay!.pronunciation,
                      style: PolieTypography.body(context).copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: PolieSpacing.xs),
                    Text(
                      _wordOfTheDay!.translation,
                      style: PolieTypography.titleMedium(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up_rounded, color: Colors.white),
                onPressed: () => _playAudio(_wordOfTheDay!.audioUrl, _wordOfTheDay!.word),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPictureMatchTab() {
    // Picture matching game - tap the image that matches the word
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search_rounded, size: 64.sp, color: PolieColors.textSecondary),
          SizedBox(height: PolieSpacing.md),
          Text(
            'Picture Matching',
            style: PolieTypography.h3(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
          SizedBox(height: PolieSpacing.sm),
          Text(
            'Coming soon',
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualCardsTab() {
    final words = _selectedFamily == 'all'
        ? _allWords
        : _wordFamilies[_selectedFamily]?.words ?? _allWords;
    
    return GridView.builder(
      padding: EdgeInsets.all(PolieSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: PolieSpacing.md,
        mainAxisSpacing: PolieSpacing.md,
        childAspectRatio: 0.75,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return _VocabularyCard(
          word: word,
          onTap: () => _showWordDetail(word),
          onPlayAudio: () => _playAudio(word.audioUrl, word.word),
        )
            .animate(delay: (index * 30).ms)
            .fadeIn(duration: 200.ms)
            .scale(begin: Offset(0.9, 0.9));
      },
    );
  }

  void _showWordDetail(VocabularyWord word) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _WordDetailSheet(
        word: word,
        onPlayAudio: () => _playAudio(word.audioUrl, word.word),
      ),
    );
  }
}

class VocabularyWord {
  final String id;
  final String word;
  final String translation;
  final String pronunciation;
  final String? imageUrl;
  final String? audioUrl;
  final String family;
  final String language;

  VocabularyWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.pronunciation,
    this.imageUrl,
    this.audioUrl,
    required this.family,
    required this.language,
  });
}

class WordFamily {
  final String id;
  final String name;
  final IconData icon;
  final List<VocabularyWord> words;

  WordFamily({
    required this.id,
    required this.name,
    required this.icon,
    required this.words,
  });
}

class VocabularyStats {
  final int totalLearned;
  final int mastered;
  final int inReview;

  VocabularyStats({
    this.totalLearned = 0,
    this.mastered = 0,
    this.inReview = 0,
  });
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(height: PolieSpacing.xs),
        Text(
          value,
          style: PolieTypography.h3(context).copyWith(
            color: PolieColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: PolieTypography.bodySmall(context).copyWith(
            color: PolieColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final WordFamily family;
  final VoidCallback onTap;

  const _FamilyCard({
    required this.family,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: PolieSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        boxShadow: [
          BoxShadow(
            color: PolieColors.royalAmethyst.withOpacity(0.15),
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
              children: [
                Container(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  decoration: BoxDecoration(
                    color: PolieColors.royalAmethyst.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                  ),
                  child: Icon(
                    family.icon,
                    color: PolieColors.royalAmethyst,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: PolieSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.name,
                        style: PolieTypography.h3(context).copyWith(
                          color: PolieColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: PolieSpacing.xs),
                      Text(
                        '${family.words.length} words',
                        style: PolieTypography.bodySmall(context).copyWith(
                          color: PolieColors.textSecondary,
                        ),
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

class _VocabularyCard extends StatelessWidget {
  final VocabularyWord word;
  final VoidCallback onTap;
  final VoidCallback onPlayAudio;

  const _VocabularyCard({
    required this.word,
    required this.onTap,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        boxShadow: [
          BoxShadow(
            color: PolieColors.royalAmethyst.withOpacity(0.15),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: PolieColors.royalAmethyst.withOpacity(0.1),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.lg)),
                  ),
                  child: word.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: word.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.image_outlined,
                            size: 48.sp,
                            color: PolieColors.textSecondary,
                          ),
                        )
                      : Icon(
                          Icons.image_outlined,
                          size: 48.sp,
                          color: PolieColors.textSecondary,
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(PolieSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            word.word,
                            style: PolieTypography.h3(context).copyWith(
                              color: PolieColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.volume_up_rounded, size: 18.sp),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onPlayAudio();
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      word.translation,
                      style: PolieTypography.body(context).copyWith(
                        color: PolieColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordDetailSheet extends StatelessWidget {
  final VocabularyWord word;
  final VoidCallback onPlayAudio;

  const _WordDetailSheet({
    required this.word,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: PolieSpacing.md),
              decoration: BoxDecoration(
                color: PolieColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (word.imageUrl != null)
            Container(
              height: 200.h,
              width: double.infinity,
              margin: EdgeInsets.only(bottom: PolieSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PolieRadius.md),
              ),
              child: CachedNetworkImage(
                imageUrl: word.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: PolieTypography.h1(context).copyWith(
                        color: PolieColors.textPrimary,
                      ),
                    ),
                    Text(
                      word.pronunciation,
                      style: PolieTypography.body(context).copyWith(
                        color: PolieColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up_rounded, size: 32.sp),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onPlayAudio();
                },
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.md),
          Text(
            'Translation',
            style: PolieTypography.titleMedium(context),
          ),
          SizedBox(height: PolieSpacing.xs),
          Text(
            word.translation,
            style: PolieTypography.bodyLarge(context),
          ),
        ],
      ),
    );
  }
}
