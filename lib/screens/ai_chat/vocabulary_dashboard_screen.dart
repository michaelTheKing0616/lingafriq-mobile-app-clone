import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/vocabulary/vocabulary_flashcard_screen.dart';

/// Vocabulary Dashboard Screen - Polie Dark Theme
/// Shows vocabulary progress, mastery levels, and SRS schedule
class VocabularyDashboardScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const VocabularyDashboardScreen({
    super.key,
    required this.language,
    required this.languageName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabService = ref.read(vocabularyProgressServiceProvider);
    final progress = useState<VocabularyProgress?>(null);
    final isLoading = useState(true);
    final selectedCategory = useState<String?>(null);

    useEffect(() {
      _loadProgress(vocabService, progress, isLoading);
      return null;
    }, []);

    return Scaffold(
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
              _buildHeader(context, vocabService, progress, isLoading),
              Expanded(
                child: isLoading.value || progress.value == null
                    ? _buildLoadingState(context)
                    : _buildContent(context, progress.value!, selectedCategory),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VocabularyProgressService service,
    ValueNotifier<VocabularyProgress?> progress,
    ValueNotifier<bool> isLoading,
  ) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vocabulary Progress',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  languageName,
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _GlassIconButton(
            icon: Icons.refresh_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadProgress(service, progress, isLoading);
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48.w,
            height: 48.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(PolieColors.goldEmber),
            ),
          ),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'Loading vocabulary...',
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    VocabularyProgress p,
    ValueNotifier<String?> selectedCategory,
  ) {
    final dueWords = p.getDueWords();
    final wordsByCategory = selectedCategory.value != null
        ? p.getWordsByCategory(selectedCategory.value!)
        : p.words.values.toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverallStatsCard(progress: p)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.1),
          SizedBox(height: PolieSpacing.lg),
          _FlashcardButton(
            language: language,
            languageName: languageName,
            category: selectedCategory.value,
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.1),
          SizedBox(height: PolieSpacing.lg),
          if (dueWords.isNotEmpty)
            _DueWordsCard(
              words: dueWords,
              onReview: () {
                HapticFeedback.lightImpact();
                // Navigate to review
              },
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1),
          if (dueWords.isNotEmpty) SizedBox(height: PolieSpacing.lg),
          if (p.categoryCounts.isNotEmpty)
            _CategoryFilter(
              categories: p.categoryCounts.keys.toList(),
              selectedCategory: selectedCategory.value,
              onCategorySelected: (cat) {
                HapticFeedback.lightImpact();
                selectedCategory.value = cat;
              },
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 300.ms),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'Words',
            style: PolieTypography.h2(context).copyWith(
              color: PolieColors.textPrimary,
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 300.ms),
          SizedBox(height: PolieSpacing.md),
          if (wordsByCategory.isEmpty)
            _buildEmptyWordsState(context)
          else
            ...wordsByCategory.take(20).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final word = entry.value;
              return _WordCard(word: word)
                  .animate(delay: (450 + index * 30).ms)
                  .fadeIn(duration: 200.ms)
                  .slideX(begin: 0.1);
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyWordsState(BuildContext context) {
    return _PolieGlassCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(PolieSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.book_outlined,
                size: 48.sp,
                color: PolieColors.textSecondary,
              ),
              SizedBox(height: PolieSpacing.md),
              Text(
                'No words in this category yet',
                style: PolieTypography.body(context).copyWith(
                  color: PolieColors.textSecondary,
                ),
              ),
            ],
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

  const _OverallStatsCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final masteryRate = progress.totalWordsLearned > 0
        ? (progress.totalWordsMastered / progress.totalWordsLearned * 100)
        : 0.0;

    final masteryColor = masteryRate >= 80
        ? PolieColors.success
        : masteryRate >= 60
            ? PolieColors.electricTeal
            : masteryRate >= 40
                ? PolieColors.goldEmber
                : PolieColors.error;

    return _PolieGlassCard(
      child: Column(
        children: [
          Text(
            'Vocabulary Progress',
            style: PolieTypography.h2(context).copyWith(
              color: PolieColors.textPrimary,
            ),
          ),
          SizedBox(height: PolieSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Learned',
                value: '${progress.totalWordsLearned}',
                icon: Icons.book_rounded,
                color: PolieColors.royalAmethyst,
              ),
              _StatItem(
                label: 'Mastered',
                value: '${progress.totalWordsMastered}',
                icon: Icons.star_rounded,
                color: PolieColors.goldEmber,
              ),
              _StatItem(
                label: 'Due',
                value: '${progress.wordsDueForReview}',
                icon: Icons.schedule_rounded,
                color: PolieColors.error,
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.lg),
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'Mastery Rate',
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
          SizedBox(height: PolieSpacing.sm),
          Text(
            '${masteryRate.toStringAsFixed(1)}%',
            style: PolieTypography.h1(context).copyWith(
              color: masteryColor,
              fontSize: 40.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: PolieSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(PolieRadius.pill),
            child: LinearProgressIndicator(
              value: masteryRate / 100.0,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(masteryColor),
              minHeight: 8.h,
            ),
          ),
        ],
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
        Container(
          padding: EdgeInsets.all(PolieSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28.sp),
        ),
        SizedBox(height: PolieSpacing.sm),
        Text(
          value,
          style: PolieTypography.h2(context).copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: PolieSpacing.xs),
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

class _FlashcardButton extends StatelessWidget {
  final String language;
  final String languageName;
  final String? category;

  const _FlashcardButton({
    required this.language,
    required this.languageName,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
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
      child: _PolieGlassCard(
        glowColor: PolieColors.goldEmber,
        child: Row(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [PolieColors.goldEmber, PolieColors.goldEmberLight],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PolieColors.goldEmber.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(Icons.style_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 28.sp),
            ),
            SizedBox(width: PolieSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study with Flashcards',
                    style: PolieTypography.h2(context).copyWith(
                      color: PolieColors.goldEmber,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.xs),
                  Text(
                    'Interactive visual flashcards for better memorization',
                    style: PolieTypography.bodySmall(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: PolieColors.goldEmber,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _DueWordsCard extends StatelessWidget {
  final List<WordMastery> words;
  final VoidCallback onReview;

  const _DueWordsCard({
    required this.words,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReview,
      child: _PolieGlassCard(
        glowColor: PolieColors.error,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(PolieSpacing.md),
              decoration: BoxDecoration(
                color: PolieColors.error.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: PolieColors.error,
                size: 28.sp,
              ),
            ),
            SizedBox(width: PolieSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${words.length} Words Due for Review',
                    style: PolieTypography.h2(context).copyWith(
                      color: PolieColors.error,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.xs),
                  Text(
                    'Tap to review now',
                    style: PolieTypography.bodySmall(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: PolieColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const _CategoryFilter({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          SizedBox(width: PolieSpacing.sm),
          ...categories.map((cat) {
            return Padding(
              padding: EdgeInsets.only(right: PolieSpacing.sm),
              child: _FilterChip(
                label: cat,
                isSelected: cat == selectedCategory,
                onTap: () => onCategorySelected(
                  cat == selectedCategory ? null : cat,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: PolieSpacing.md,
          vertical: PolieSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? PolieColors.royalAmethyst.withOpacity(0.3)
              : PolieColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(PolieRadius.pill),
          border: Border.all(
            color: isSelected
                ? PolieColors.royalAmethyst
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: PolieTypography.label(context).copyWith(
            color: isSelected
                ? PolieColors.royalAmethyst
                : PolieColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final WordMastery word;

  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final masteryColor = word.isMastered
        ? PolieColors.goldEmber
        : PolieColors.royalAmethyst;

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.sm),
      child: Container(
        padding: EdgeInsets.all(PolieSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PolieRadius.md),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (word.isMastered)
              Container(
                padding: EdgeInsets.all(PolieSpacing.xs),
                decoration: BoxDecoration(
                  color: PolieColors.goldEmber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: PolieColors.goldEmber,
                  size: 18.sp,
                ),
              )
            else
              SizedBox(width: 26.w),
            SizedBox(width: PolieSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.xs),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PolieSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PolieColors.royalAmethyst.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(PolieRadius.sm),
                        ),
                        child: Text(
                          word.category,
                          style: PolieTypography.bodySmall(context).copyWith(
                            color: PolieColors.royalAmethyst,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: PolieSpacing.sm),
                      Text(
                        '${(word.masteryLevel * 100).toStringAsFixed(0)}%',
                        style: PolieTypography.bodySmall(context).copyWith(
                          color: masteryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (word.isDueForReview)
              Container(
                padding: EdgeInsets.all(PolieSpacing.xs),
                decoration: BoxDecoration(
                  color: PolieColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: PolieColors.error,
                  size: 18.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Polie glass card
class _PolieGlassCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;

  const _PolieGlassCard({
    required this.child,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : PolieElevation.level1(context),
      ),
      child: child,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: PolieColors.surfaceContainerLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: PolieColors.textPrimary,
          size: 22.sp,
        ),
      ),
    );
  }
}
