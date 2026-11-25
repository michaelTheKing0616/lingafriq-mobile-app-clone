import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/hub_learn.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/vocabulary/vocabulary_flashcard_screen.dart';

/// What a vocabulary load returned. [ready] is the only status that carries words.
enum VocabularyDashboardStatus { loading, ready, empty, error, offline }

class VocabularyDashboardView {
  const VocabularyDashboardView._(this.status, this.progress);

  const VocabularyDashboardView.ready(VocabularyProgress progress)
    : this._(VocabularyDashboardStatus.ready, progress);

  const VocabularyDashboardView.empty()
    : this._(VocabularyDashboardStatus.empty, null);

  const VocabularyDashboardView.error()
    : this._(VocabularyDashboardStatus.error, null);

  const VocabularyDashboardView.offline()
    : this._(VocabularyDashboardStatus.offline, null);

  final VocabularyDashboardStatus status;
  final VocabularyProgress? progress;
}

/// True when saved words exist. A zero record is an empty dashboard.
bool vocabularyProgressHasData(VocabularyProgress progress) {
  return progress.words.isNotEmpty || progress.totalWordsLearned > 0;
}

/// Vocabulary dashboard. With no loader and no language, the page is empty.
/// A failed load clears any word list that was on screen.
class VocabularyDashboardScreen extends StatefulWidget {
  const VocabularyDashboardScreen({
    super.key,
    this.language = '',
    this.languageName = '',
    this.load,
  });

  /// App route `/learn/vocab-dashboard`. The map key drops the leading slash.
  static const String routePath = '/learn/vocab-dashboard';

  static const String routeKey = 'learn/vocab-dashboard';

  static const Key emptyKey = ValueKey<String>('learn-vocab-dashboard-empty');

  static const Key errorKey = ValueKey<String>('learn-vocab-dashboard-error');

  static const Key offlineKey = ValueKey<String>('learn-vocab-dashboard-offline');

  static const Key contentKey = ValueKey<String>('learn-vocab-dashboard-content');

  final String language;
  final String languageName;

  /// Loads the word list. Null with an empty [languageName] means there is nothing to show.
  final Future<VocabularyDashboardView> Function()? load;

  @override
  State<VocabularyDashboardScreen> createState() =>
      _VocabularyDashboardScreenState();
}

class _VocabularyDashboardScreenState extends State<VocabularyDashboardScreen> {
  VocabularyDashboardStatus _status = VocabularyDashboardStatus.loading;
  VocabularyProgress? _progress;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.load == null && widget.languageName.trim().isEmpty) {
      _status = VocabularyDashboardStatus.empty;
      _progress = null;
      return;
    }
    _run(_generation);
  }

  @override
  void didUpdateWidget(VocabularyDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        oldWidget.languageName == widget.languageName &&
        oldWidget.language == widget.language) {
      return;
    }
    _progress = null;
    _generation += 1;
    if (widget.load == null && widget.languageName.trim().isEmpty) {
      _status = VocabularyDashboardStatus.empty;
      return;
    }
    _status = VocabularyDashboardStatus.loading;
    _run(_generation);
  }

  Future<void> _run(int generation) async {
    final Future<VocabularyDashboardView> Function() load =
        widget.load ?? () => _loadNamed(widget.languageName);
    try {
      final VocabularyDashboardView view = await load();
      if (!mounted || generation != _generation) return;
      setState(() => _apply(view));
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = VocabularyDashboardStatus.error;
        _progress = null;
      });
    }
  }

  Future<VocabularyDashboardView> _loadNamed(String languageName) async {
    final String name = languageName.trim();
    if (name.isEmpty) return const VocabularyDashboardView.empty();
    final ProviderContainer container = ProviderScope.containerOf(context);
    final VocabularyProgressService service = container.read(
      vocabularyProgressServiceProvider,
    );
    final VocabularyProgress progress = await service.loadProgress(name);
    if (!vocabularyProgressHasData(progress)) {
      return const VocabularyDashboardView.empty();
    }
    return VocabularyDashboardView.ready(progress);
  }

  void _apply(VocabularyDashboardView view) {
    final VocabularyProgress? progress = view.progress;
    if (view.status == VocabularyDashboardStatus.ready &&
        progress != null &&
        vocabularyProgressHasData(progress)) {
      _status = VocabularyDashboardStatus.ready;
      _progress = progress;
      return;
    }
    _progress = null;
    if (view.status == VocabularyDashboardStatus.offline) {
      _status = VocabularyDashboardStatus.offline;
    } else if (view.status == VocabularyDashboardStatus.error ||
        view.status == VocabularyDashboardStatus.loading) {
      _status = VocabularyDashboardStatus.error;
    } else {
      _status = VocabularyDashboardStatus.empty;
    }
  }

  void _retry() {
    setState(() {
      _progress = null;
      _status = VocabularyDashboardStatus.loading;
      _generation += 1;
    });
    _run(_generation);
  }

  void _back() {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  void _openPath() {
    Navigator.of(context).pushNamed(LearnRoutes.path);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    switch (_status) {
      case VocabularyDashboardStatus.loading:
        return _statusPage(
          l10n,
          Text(
            l10n.loading,
            style: lingBody(
              LingPalette.of(Theme.of(context).brightness).onSurface,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        );
      case VocabularyDashboardStatus.empty:
        return _statusPage(
          l10n,
          LingEmptyState(
            key: VocabularyDashboardScreen.emptyKey,
            title: l10n.revRvLearnVocabDashboard,
            whatHappened: l10n.revRvLearnVocabEmptyWhat,
            why: l10n.revRvLearnVocabEmptyWhy,
            whatToDo: l10n.revRvLearnVocabEmptyNext,
            actionLabel: l10n.hubLearnOpenPath,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _openPath,
          ),
        );
      case VocabularyDashboardStatus.error:
        return _statusPage(
          l10n,
          LingErrorState(
            key: VocabularyDashboardScreen.errorKey,
            whatHappened: l10n.revRvLearnVocabFailWhat,
            why: l10n.revRvLearnVocabFailWhy,
            whatToDo: l10n.revRvLearnVocabFailNext,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _retry,
          ),
        );
      case VocabularyDashboardStatus.offline:
        return _statusPage(
          l10n,
          LingOfflineState(
            key: VocabularyDashboardScreen.offlineKey,
            whatHappened: l10n.shellOfflineWhat,
            why: l10n.revRvLearnVocabOfflineWhy,
            whatToDo: l10n.shellOfflineNext,
            queuedActions: 0,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _retry,
          ),
        );
      case VocabularyDashboardStatus.ready:
        return _VocabularyReady(
          key: VocabularyDashboardScreen.contentKey,
          language: widget.language,
          languageName: widget.languageName,
          progress: _progress!,
          onReload: _retry,
        );
    }
  }

  Widget _statusPage(AppLocalizations l10n, Widget body) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.revRvLearnVocabDashboard,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            body,
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              label: l10n.hubLearnBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: _back,
            ),
          ],
        ),
      ),
    );
  }
}

/// Word list for a loaded vocabulary record.
class _VocabularyReady extends HookConsumerWidget {
  const _VocabularyReady({
    super.key,
    required this.language,
    required this.languageName,
    required this.progress,
    required this.onReload,
  });

  final String language;
  final String languageName;
  final VocabularyProgress progress;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState<String?>(null);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
              Expanded(
                child: _buildContent(context, progress, selectedCategory),
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
            label: 'Back',
            button: true,
            child: _GlassIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vocabulary Progress',
                  style: _dashboardTitle(context, size: 24).copyWith(
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
          Semantics(
            label: 'Refresh vocabulary progress',
            button: true,
            child: _GlassIconButton(
              icon: Icons.refresh_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                onReload();
              },
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

    final bool reduced = MediaQuery.disableAnimationsOf(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _motion(
            _OverallStatsCard(progress: p),
            reduced: reduced,
          ),
          SizedBox(height: PolieSpacing.lg),
          _motion(
            _FlashcardButton(
              language: language,
              languageName: languageName,
              category: selectedCategory.value,
            ),
            reduced: reduced,
            delay: 100,
          ),
          SizedBox(height: PolieSpacing.lg),
          if (dueWords.isNotEmpty)
            _motion(
              _DueWordsCard(
                words: dueWords,
                onReview: () {
                  HapticFeedback.lightImpact();
                },
              ),
              reduced: reduced,
              delay: 200,
            ),
          if (dueWords.isNotEmpty) SizedBox(height: PolieSpacing.lg),
          if (p.categoryCounts.isNotEmpty)
            _motion(
              _CategoryFilter(
                categories: p.categoryCounts.keys.toList(),
                selectedCategory: selectedCategory.value,
                onCategorySelected: (cat) {
                  HapticFeedback.lightImpact();
                  selectedCategory.value = cat;
                },
              ),
              reduced: reduced,
              delay: 300,
            ),
          SizedBox(height: PolieSpacing.lg),
          _motion(
            Text(
              'Words',
              style: _dashboardTitle(context, size: 24).copyWith(
                color: PolieColors.textPrimary,
              ),
            ),
            reduced: reduced,
            delay: 400,
          ),
          SizedBox(height: PolieSpacing.md),
          if (wordsByCategory.isEmpty)
            _buildEmptyWordsState(context)
          else
            ...wordsByCategory.take(20).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final word = entry.value;
              return _motion(
                _WordCard(word: word),
                reduced: reduced,
                delay: 450 + index * 30,
              );
            }),
        ],
      ),
    );
  }

  Widget _motion(Widget child, {required bool reduced, int delay = 0}) {
    if (reduced) return child;
    return child
        .animate(delay: delay.ms)
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.1);
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

}

TextStyle _dashboardTitle(BuildContext context, {required double size}) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return LingAfriqFonts.roleStyle(
    fontSize: size.sp,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight,
  );
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
            style: _dashboardTitle(context, size: 24).copyWith(
              color: PolieColors.textPrimary,
            ),
          ),
          SizedBox(height: PolieSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Learned',
                  value: '${progress.totalWordsLearned}',
                  icon: Icons.book_rounded,
                  color: PolieColors.royalAmethyst,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Mastered',
                  value: '${progress.totalWordsMastered}',
                  icon: Icons.star_rounded,
                  color: PolieColors.goldEmber,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Due',
                  value: '${progress.wordsDueForReview}',
                  icon: Icons.schedule_rounded,
                  color: PolieColors.error,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.lg),
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
            style: _dashboardTitle(context, size: 32).copyWith(
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
              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28.sp),
        ),
        SizedBox(height: PolieSpacing.sm),
        Text(
          value,
          style: _dashboardTitle(context, size: 24).copyWith(
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
                gradient: const LinearGradient(
                  colors: [PolieColors.goldEmber, PolieColors.goldEmberLight],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: PolieColors.goldEmber.withValues(alpha: 0.4),
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
                    style: _dashboardTitle(context, size: 24).copyWith(
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
                color: PolieColors.error.withValues(alpha: 0.2),
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
                    style: _dashboardTitle(context, size: 24).copyWith(
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
            const Icon(
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
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 1 + categories.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedCategory == null,
                  onTap: () => onCategorySelected(null),
                ),
                SizedBox(width: PolieSpacing.sm),
              ],
            );
          }
          final cat = categories[index - 1];
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
        },
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
              ? PolieColors.royalAmethyst.withValues(alpha: 0.3)
              : PolieColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(PolieRadius.pill),
          border: Border.all(
            color: isSelected
                ? PolieColors.royalAmethyst
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (word.isMastered)
              Container(
                padding: EdgeInsets.all(PolieSpacing.xs),
                decoration: BoxDecoration(
                  color: PolieColors.goldEmber.withValues(alpha: 0.2),
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
                          color: PolieColors.royalAmethyst.withValues(alpha: 0.2),
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
                  color: PolieColors.error.withValues(alpha: 0.2),
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
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.2),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
