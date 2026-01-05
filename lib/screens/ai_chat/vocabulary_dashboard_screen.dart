import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/vocabulary/vocabulary_flashcard_screen.dart';

/// Vocabulary Dashboard Screen
/// Shows vocabulary progress, mastery levels, and SRS schedule
class VocabularyDashboardScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const VocabularyDashboardScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabService = ref.read(vocabularyProgressServiceProvider);
    final progress = useState<VocabularyProgress?>(null);
    final isLoading = useState(true);
    final selectedCategory = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load progress
    useEffect(() {
      _loadProgress(vocabService, progress, isLoading);
      return null;
    }, []);

    if (isLoading.value || progress.value == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Vocabulary Progress')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = progress.value!;
    final dueWords = p.getDueWords();
    final masteredWords = p.getMasteredWords();
    final wordsByCategory = selectedCategory.value != null
        ? p.getWordsByCategory(selectedCategory.value!)
        : p.words.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Vocabulary Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadProgress(vocabService, progress, isLoading),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall Stats
                _OverallStatsCard(progress: p, isDark: isDark)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Flashcard Button
                _FlashcardButton(
                  language: language,
                  languageName: languageName,
                  category: selectedCategory.value,
                  isDark: isDark,
                )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Due for Review
                if (dueWords.isNotEmpty)
                  _DueWordsCard(
                    words: dueWords,
                    isDark: isDark,
                    onReview: () {
                      // Navigate to review screen
                    },
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Category Filter
                if (p.categoryCounts.isNotEmpty)
                  _CategoryFilter(
                    categories: p.categoryCounts.keys.toList(),
                    selectedCategory: selectedCategory.value,
                    onCategorySelected: (cat) => selectedCategory.value = cat,
                    isDark: isDark,
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 300.ms),
                SizedBox(height: PanAfricanSpacing.lg),

                // Words List
                Text(
                  'Words',
                  style: PanAfricanTypography.titleLarge(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 300.ms),
                SizedBox(height: PanAfricanSpacing.md),

                if (wordsByCategory.isEmpty)
                  Card(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.xl),
                      child: Center(
                        child: Text(
                          'No words in this category yet',
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                      ),
                    ),
                  )
                else
                  ...wordsByCategory.take(20).map((word) {
                    return _WordCard(
                      word: word,
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: 0.1);
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadProgress(
    VocabularyProgressService service,
    ValueNotifier<VocabularyProgress?> progress,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      final p = await service.loadProgress(languageName);
      progress.value = p;
    } catch (e) {
      debugPrint('Error loading vocabulary progress: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class _OverallStatsCard extends StatelessWidget {
  final VocabularyProgress progress;
  final bool isDark;

  const _OverallStatsCard({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final masteryRate = progress.totalWordsLearned > 0
        ? (progress.totalWordsMastered / progress.totalWordsLearned * 100)
        : 0.0;

    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          children: [
            Text(
              'Vocabulary Progress',
              style: PanAfricanTypography.titleLarge(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Learned',
                  value: '${progress.totalWordsLearned}',
                  icon: Icons.book,
                  color: PanAfricanColors.primary,
                ),
                _StatItem(
                  label: 'Mastered',
                  value: '${progress.totalWordsMastered}',
                  icon: Icons.star,
                  color: PanAfricanColors.accent,
                ),
                _StatItem(
                  label: 'Due',
                  value: '${progress.wordsDueForReview}',
                  icon: Icons.schedule,
                  color: PanAfricanColors.error,
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              'Mastery Rate',
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              '${masteryRate.toStringAsFixed(1)}%',
              style: PanAfricanTypography.headlineMedium(context)?.copyWith(
                fontWeight: FontWeight.bold,
                color: PanAfricanColors.accent,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            LinearProgressIndicator(
              value: masteryRate / 100.0,
              backgroundColor: PanAfricanColors.neutralLight,
              valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.accent),
              minHeight: 8.h,
            ),
          ],
        ),
      ),
    );
  }
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
        Icon(icon, color: color, size: 32.sp),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          value,
          style: PanAfricanTypography.titleMedium(context)?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xxs),
        Text(
          label,
          style: PanAfricanTypography.bodySmall(context),
        ),
      ],
    );
  }
}

class _DueWordsCard extends StatelessWidget {
  final List<WordMastery> words;
  final bool isDark;
  final VoidCallback onReview;

  const _DueWordsCard({
    required this.words,
    required this.isDark,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PanAfricanColors.error.withOpacity(0.1),
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.schedule, color: PanAfricanColors.error, size: 32.sp),
              SizedBox(width: PanAfricanSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${words.length} Words Due for Review',
                      style: PanAfricanTypography.titleMedium(context)?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PanAfricanColors.error,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      'Tap to review now',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: PanAfricanColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final bool isDark;

  const _CategoryFilter({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: Text('All'),
            selected: selectedCategory == null,
            onSelected: (_) => onCategorySelected(null),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          ...categories.map((cat) {
            return Padding(
              padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
              child: FilterChip(
                label: Text(cat),
                selected: cat == selectedCategory,
                onSelected: (_) => onCategorySelected(cat == selectedCategory ? null : cat),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _FlashcardButton extends StatelessWidget {
  final String language;
  final String languageName;
  final String? category;
  final bool isDark;

  const _FlashcardButton({
    required this.language,
    required this.languageName,
    this.category,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PanAfricanColors.primary.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            SmoothPageRoute(
              child: VocabularyFlashcardScreen(
                language: language,
                languageName: languageName,
                category: category,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: PanAfricanColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.style, color: Colors.white, size: 32.sp),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study with Flashcards',
                      style: PanAfricanTypography.titleMedium(context)?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PanAfricanColors.primary,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      'Interactive visual flashcards for better memorization',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: PanAfricanColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final WordMastery word;
  final bool isDark;

  const _WordCard({
    required this.word,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Row(
          children: [
            if (word.isMastered)
              Icon(Icons.star, color: PanAfricanColors.accent, size: 20.sp),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: PanAfricanTypography.titleSmall(context)?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Row(
                    children: [
                      Chip(
                        label: Text(word.category),
                        backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                        labelStyle: PanAfricanTypography.labelSmall(context)?.copyWith(
                          color: PanAfricanColors.primary,
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.xs),
                      Text(
                        '${(word.masteryLevel * 100).toStringAsFixed(0)}%',
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (word.isDueForReview)
              Icon(Icons.schedule, color: PanAfricanColors.error, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

