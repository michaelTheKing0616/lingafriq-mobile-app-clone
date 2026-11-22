import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/hub_learn.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/review_progress_model.dart';
import 'package:lingafriq/services/review_progress_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// What a review load returned. [ready] is the only status that carries stats.
enum ReviewDashboardStatus { loading, ready, empty, error, offline }

class ReviewDashboardView {
  const ReviewDashboardView._(this.status, this.statistics);

  const ReviewDashboardView.ready(ReviewStatistics statistics)
    : this._(ReviewDashboardStatus.ready, statistics);

  const ReviewDashboardView.empty() : this._(ReviewDashboardStatus.empty, null);

  const ReviewDashboardView.error() : this._(ReviewDashboardStatus.error, null);

  const ReviewDashboardView.offline()
    : this._(ReviewDashboardStatus.offline, null);

  final ReviewDashboardStatus status;
  final ReviewStatistics? statistics;
}

/// True when the saved review has something to show. An all-zero record is empty.
bool reviewStatisticsHasData(ReviewStatistics statistics) {
  return statistics.totalReviews > 0 ||
      statistics.totalItemsReviewed > 0 ||
      statistics.recentSessions.isNotEmpty ||
      statistics.accuracyByType.isNotEmpty;
}

/// Review dashboard. With no loader and no language, the page is empty.
/// A failed load clears any statistics that were on screen.
class ReviewDashboardScreen extends StatefulWidget {
  const ReviewDashboardScreen({
    super.key,
    this.language = '',
    this.languageName = '',
    this.load,
  });

  /// App route `/learn/review-dashboard`. The map key drops the leading slash.
  static const String routePath = '/learn/review-dashboard';

  static const String routeKey = 'learn/review-dashboard';

  static const Key emptyKey = ValueKey<String>('learn-review-dashboard-empty');

  static const Key errorKey = ValueKey<String>('learn-review-dashboard-error');

  static const Key offlineKey = ValueKey<String>(
    'learn-review-dashboard-offline',
  );

  static const Key contentKey = ValueKey<String>(
    'learn-review-dashboard-content',
  );

  final String language;
  final String languageName;

  /// Loads the review. Null with an empty [languageName] means there is nothing to show.
  final Future<ReviewDashboardView> Function()? load;

  @override
  State<ReviewDashboardScreen> createState() => _ReviewDashboardScreenState();
}

class _ReviewDashboardScreenState extends State<ReviewDashboardScreen> {
  ReviewDashboardStatus _status = ReviewDashboardStatus.loading;
  ReviewStatistics? _statistics;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.load == null && widget.languageName.trim().isEmpty) {
      _status = ReviewDashboardStatus.empty;
      _statistics = null;
      return;
    }
    _run(_generation);
  }

  @override
  void didUpdateWidget(ReviewDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        oldWidget.languageName == widget.languageName) {
      return;
    }
    _statistics = null;
    _generation += 1;
    if (widget.load == null && widget.languageName.trim().isEmpty) {
      _status = ReviewDashboardStatus.empty;
      return;
    }
    _status = ReviewDashboardStatus.loading;
    _run(_generation);
  }

  Future<void> _run(int generation) async {
    final Future<ReviewDashboardView> Function() load =
        widget.load ?? () => _loadNamed(widget.languageName);
    try {
      final ReviewDashboardView view = await load();
      if (!mounted || generation != _generation) return;
      setState(() => _apply(view));
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = ReviewDashboardStatus.error;
        _statistics = null;
      });
    }
  }

  Future<ReviewDashboardView> _loadNamed(String languageName) async {
    final String name = languageName.trim();
    if (name.isEmpty) return const ReviewDashboardView.empty();
    final ProviderContainer container = ProviderScope.containerOf(context);
    final ReviewProgressService service = container.read(
      reviewProgressServiceProvider,
    );
    final ReviewStatistics stats = await service.loadStatistics(name);
    if (!reviewStatisticsHasData(stats)) {
      return const ReviewDashboardView.empty();
    }
    return ReviewDashboardView.ready(stats);
  }

  void _apply(ReviewDashboardView view) {
    final ReviewStatistics? stats = view.statistics;
    if (view.status == ReviewDashboardStatus.ready &&
        stats != null &&
        reviewStatisticsHasData(stats)) {
      _status = ReviewDashboardStatus.ready;
      _statistics = stats;
      return;
    }
    _statistics = null;
    if (view.status == ReviewDashboardStatus.offline) {
      _status = ReviewDashboardStatus.offline;
    } else if (view.status == ReviewDashboardStatus.error ||
        view.status == ReviewDashboardStatus.loading) {
      _status = ReviewDashboardStatus.error;
    } else {
      _status = ReviewDashboardStatus.empty;
    }
  }

  void _retry() {
    setState(() {
      _statistics = null;
      _status = ReviewDashboardStatus.loading;
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
      case ReviewDashboardStatus.loading:
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
      case ReviewDashboardStatus.empty:
        return _statusPage(
          l10n,
          LingEmptyState(
            key: ReviewDashboardScreen.emptyKey,
            title: l10n.revRvLearnReviewDashboard,
            whatHappened: l10n.revRvLearnReviewEmptyWhat,
            why: l10n.revRvLearnReviewEmptyWhy,
            whatToDo: l10n.revRvLearnReviewEmptyNext,
            actionLabel: l10n.hubLearnOpenPath,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _openPath,
          ),
        );
      case ReviewDashboardStatus.error:
        return _statusPage(
          l10n,
          LingErrorState(
            key: ReviewDashboardScreen.errorKey,
            whatHappened: l10n.revRvLearnReviewFailWhat,
            why: l10n.revRvLearnReviewFailWhy,
            whatToDo: l10n.revRvLearnReviewFailNext,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _retry,
          ),
        );
      case ReviewDashboardStatus.offline:
        return _statusPage(
          l10n,
          LingOfflineState(
            key: ReviewDashboardScreen.offlineKey,
            whatHappened: l10n.shellOfflineWhat,
            why: l10n.revRvLearnReviewOfflineWhy,
            whatToDo: l10n.shellOfflineNext,
            queuedActions: 0,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: _retry,
          ),
        );
      case ReviewDashboardStatus.ready:
        return _ready(context, _statistics!);
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
              l10n.revRvLearnReviewDashboard,
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

  Widget _ready(BuildContext context, ReviewStatistics stats) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<double> accuracyTrend = stats.getAccuracyTrend(days: 7);
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      key: ReviewDashboardScreen.contentKey,
      appBar: AppBar(
        title: const Text('Review Statistics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _retry,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : const LinearGradient(
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
                _motion(
                  _OverallStatsCard(statistics: stats, isDark: isDark),
                  reduced: reduced,
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                _motion(
                  _AccuracyTrendCard(trend: accuracyTrend, isDark: isDark),
                  reduced: reduced,
                  delay: 100,
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                if (stats.accuracyByType.isNotEmpty)
                  _motion(
                    _AccuracyByTypeCard(statistics: stats, isDark: isDark),
                    reduced: reduced,
                    delay: 200,
                  ),
                SizedBox(height: PanAfricanSpacing.lg),
                if (stats.recentSessions.isNotEmpty)
                  _motion(
                    _RecentSessionsCard(
                      sessions: stats.recentSessions,
                      isDark: isDark,
                    ),
                    reduced: reduced,
                    delay: 300,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _motion(Widget child, {required bool reduced, int delay = 0}) {
    if (reduced) return child;
    return child
        .animate(delay: delay.ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1);
  }
}

class _OverallStatsCard extends StatelessWidget {
  final ReviewStatistics statistics;
  final bool isDark;

  const _OverallStatsCard({
    required this.statistics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
              'Review Statistics',
              style: PanAfricanTypography.titleLarge(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Reviews',
                    value: '${statistics.totalReviews}',
                    icon: Icons.refresh,
                    color: PanAfricanColors.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Items',
                    value: '${statistics.totalItemsReviewed}',
                    icon: Icons.quiz,
                    color: PanAfricanColors.secondary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Streak',
                    value: '${statistics.currentStreak}',
                    icon: Icons.local_fire_department,
                    color: PanAfricanColors.error,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            const Divider(),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              'Average Accuracy',
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              '${statistics.averageAccuracy.toStringAsFixed(1)}%',
              style: PanAfricanTypography.headlineMedium(context).copyWith(
                fontWeight: FontWeight.bold,
                color: PanAfricanColors.accent,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            LinearProgressIndicator(
              value: statistics.averageAccuracy / 100.0,
              backgroundColor: PanAfricanColors.neutralLight,
              valueColor: const AlwaysStoppedAnimation<Color>(PanAfricanColors.accent),
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
          style: PanAfricanTypography.titleMedium(context).copyWith(
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

class _AccuracyTrendCard extends StatelessWidget {
  final List<double> trend;
  final bool isDark;

  const _AccuracyTrendCard({
    required this.trend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: PanAfricanColors.accent),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Text(
                    'Accuracy Trend (Last 7 Days)',
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            SizedBox(
              height: 150.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: trend.asMap().entries.map((entry) {
                  final value = entry.value;
                  final maxValue = trend.reduce((a, b) => a > b ? a : b);
                  final height = maxValue > 0 ? (value / maxValue) : 0.0;
                  
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height * 120.h,
                            decoration: BoxDecoration(
                              color: PanAfricanColors.accent,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(PanAfricanRadius.xs),
                              ),
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          Text(
                            '${(value).toStringAsFixed(0)}%',
                            style: PanAfricanTypography.labelSmall(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracyByTypeCard extends StatelessWidget {
  final ReviewStatistics statistics;
  final bool isDark;

  const _AccuracyByTypeCard({
    required this.statistics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: PanAfricanColors.secondary),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Text(
                    'Accuracy by Type',
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...statistics.accuracyByType.entries.map((entry) {
              final type = entry.key;
              final correct = entry.value;
              
              // Count only items that were actually reviewed for this type.
              final totalForType = statistics.recentSessions.fold<int>(
                0,
                (sum, session) => sum + session.itemsReviewed
                    .where((item) => item.type == type)
                    .length,
              );
              if (totalForType <= 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                  child: Text(
                    type,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                );
              }
              final int total = totalForType;
              final percentage = (correct / total * 100).clamp(0.0, 100.0);
              
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type,
                            style: PanAfricanTypography.bodyMedium(context),
                          ),
                        ),
                        Text(
                          '$correct / $total',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: PanAfricanTypography.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.bold,
                            color: percentage >= 80 
                                ? PanAfricanColors.success 
                                : percentage >= 60 
                                    ? PanAfricanColors.accent 
                                    : PanAfricanColors.error,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    LinearProgressIndicator(
                      value: percentage / 100.0,
                      backgroundColor: PanAfricanColors.neutralLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 80 
                            ? PanAfricanColors.success 
                            : percentage >= 60 
                                ? PanAfricanColors.accent 
                                : PanAfricanColors.error,
                      ),
                      minHeight: 6.h,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  final List<ReviewSessionResult> sessions;
  final bool isDark;

  const _RecentSessionsCard({
    required this.sessions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: PanAfricanColors.tertiary),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Text(
                    'Recent Sessions',
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...sessions.take(5).map((session) {
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      session.accuracy >= 80 ? Icons.check_circle : Icons.error,
                      color: session.accuracy >= 80
                          ? PanAfricanColors.success
                          : PanAfricanColors.error,
                      size: 20.sp,
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${session.totalItems} items reviewed',
                            style: PanAfricanTypography.bodyMedium(context),
                          ),
                          Text(
                            '${session.accuracy.toStringAsFixed(0)}% accuracy',
                            style: PanAfricanTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(session.completedAt),
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

