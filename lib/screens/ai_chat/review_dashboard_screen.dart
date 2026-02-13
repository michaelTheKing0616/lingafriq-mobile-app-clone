import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/review_progress_model.dart';
import 'package:lingafriq/services/review_progress_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Review Dashboard Screen
/// Shows review statistics, accuracy trends, and review schedule
class ReviewDashboardScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const ReviewDashboardScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewService = ref.read(reviewProgressServiceProvider);
    final statistics = useState<ReviewStatistics?>(null);
    final isLoading = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load statistics
    useEffect(() {
      _loadStatistics(reviewService, statistics, isLoading);
      return null;
    }, []);

    if (isLoading.value || statistics.value == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Review Statistics')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = statistics.value!;
    final accuracyTrend = stats.getAccuracyTrend(days: 7);

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Statistics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadStatistics(reviewService, statistics, isLoading),
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
                _OverallStatsCard(statistics: stats, isDark: isDark)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Accuracy Trend
                _AccuracyTrendCard(trend: accuracyTrend, isDark: isDark)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Accuracy by Type
                if (stats.accuracyByType.isNotEmpty)
                  _AccuracyByTypeCard(statistics: stats, isDark: isDark)
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1),
                SizedBox(height: PanAfricanSpacing.lg),

                // Recent Sessions
                if (stats.recentSessions.isNotEmpty)
                  _RecentSessionsCard(sessions: stats.recentSessions, isDark: isDark)
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadStatistics(
    ReviewProgressService service,
    ValueNotifier<ReviewStatistics?> statistics,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      final stats = await service.loadStatistics(languageName);
      statistics.value = stats;
    } catch (e) {
      debugPrint('Error loading review statistics: $e');
    } finally {
      isLoading.value = false;
    }
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Reviews',
                  value: '${statistics.totalReviews}',
                  icon: Icons.refresh,
                  color: PanAfricanColors.primary,
                ),
                _StatItem(
                  label: 'Items',
                  value: '${statistics.totalItemsReviewed}',
                  icon: Icons.quiz,
                  color: PanAfricanColors.secondary,
                ),
                _StatItem(
                  label: 'Streak',
                  value: '${statistics.currentStreak}',
                  icon: Icons.local_fire_department,
                  color: PanAfricanColors.error,
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
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
                Icon(Icons.trending_up, color: PanAfricanColors.accent),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Accuracy Trend (Last 7 Days)',
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
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
                Icon(Icons.bar_chart, color: PanAfricanColors.secondary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Accuracy by Type',
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...statistics.accuracyByType.entries.map((entry) {
              final type = entry.key;
              final correct = entry.value;
              
              // Calculate total items for this type from recent sessions
              final totalForType = statistics.recentSessions.fold<int>(
                0,
                (sum, session) => sum + session.itemsReviewed
                    .where((item) => item.type == type)
                    .length,
              );
              
              // If no recent sessions, use correct count as estimate
              final total = totalForType > 0 ? totalForType : (correct * 1.3).round();
              final percentage = total > 0 
                  ? (correct / total * 100).clamp(0.0, 100.0)
                  : 0.0;
              
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
                Icon(Icons.history, color: PanAfricanColors.tertiary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Recent Sessions',
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
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

