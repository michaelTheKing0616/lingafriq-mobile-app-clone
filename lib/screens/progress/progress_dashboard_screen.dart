import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lingafriq/providers/progress_tracking_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      errorMessage: 'Unable to load progress dashboard. Please check your connection and try again.',
      onRetry: () {
        // Rebuild
      },
      child: _buildDashboard(context, ref),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref) {
    ref.watch(progressTrackingProvider);
    final notifier = ref.read(progressTrackingProvider.notifier);
    final metrics = notifier.metrics;
    final history = notifier.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Progress Dashboard', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewCards(context, metrics, isDark),
            SizedBox(height: 24.sp),
            
            // Words Learned Chart
            _buildWordsLearnedChart(context, history, isDark),
            SizedBox(height: 24.sp),
            
            // Activity Distribution Chart
            _buildActivityChart(context, metrics, isDark),
            SizedBox(height: 24.sp),
            
            // Time Spent Chart
            _buildTimeChart(context, history, isDark),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, metrics, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Words Learned',
                '${metrics.wordsLearned}',
                '📚',
                isDark,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildMetricCard(
                context,
                'Known Words',
                '${metrics.knownWords}',
                '✨',
                isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Listening Hours',
                '${metrics.listeningHours.toStringAsFixed(1)}h',
                '🎧',
                isDark,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildMetricCard(
                context,
                'Speaking Hours',
                '${metrics.speakingHours.toStringAsFixed(1)}h',
                '🎤',
                isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Total Time',
                '${metrics.timeSpentHours.toStringAsFixed(1)}h',
                '⏰',
                isDark,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildMetricCard(
                context,
                'Reading Words',
                '${metrics.readingWords.toStringAsFixed(0)}',
                '📖',
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String icon,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 24.sp),
          ),
          SizedBox(height: 8.sp),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsLearnedChart(BuildContext context, history, bool isDark) {
    if (history.length < 2) {
      return _buildEmptyChart(context, 'Words Learned Over Time', isDark);
    }

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.wordsLearned.toDouble());
    }).toList();

    return _buildChartContainer(
      context,
      'Words Learned Over Time',
      LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: PanAfricanColors.primary,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: PanAfricanColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
      isDark,
    );
  }

  Widget _buildActivityChart(BuildContext context, metrics, bool isDark) {
    final activities = metrics.timeByActivity;
    if (activities.isEmpty) {
      return _buildEmptyChart(context, 'Activity Distribution', isDark);
    }

    final colors = [
      PanAfricanColors.primary,
      PanAfricanColors.tertiary,
      PanAfricanColors.kenteBlue,
      PanAfricanColors.ankaraPurple,
      PanAfricanColors.maasaiRed,
    ];

    return _buildChartContainer(
      context,
      'Activity Distribution',
      PieChart(
        PieChartData(
          sections: activities.entries.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            final pct = metrics.timeSpentHours > 0
                ? (activity.value / metrics.timeSpentHours * 100).toStringAsFixed(0)
                : '0';
            return PieChartSectionData(
              value: activity.value,
              title: '$pct%',
              color: colors[index % colors.length],
              radius: 60,
            );
          }).toList(),
        ),
      ),
      isDark,
    );
  }

  Widget _buildTimeChart(BuildContext context, history, bool isDark) {
    if (history.length < 2) {
      return _buildEmptyChart(context, 'Time Spent Learning', isDark);
    }

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.timeSpentMinutes);
    }).toList();

    return _buildChartContainer(
      context,
      'Time Spent Learning (Minutes)',
      LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: PanAfricanColors.tertiary,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: PanAfricanColors.tertiary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
      isDark,
    );
  }

  Widget _buildChartContainer(
    BuildContext context,
    String title,
    Widget chart,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.xlBR,
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PanAfricanTypography.titleMedium(context, color: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          SizedBox(
            height: 200.sp,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, String title, bool isDark) {
    return _buildChartContainer(
      context,
      title,
      Center(
        child: Text(
          'No data yet. Start learning to see your progress!',
          style: PanAfricanTypography.bodyMedium(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
        ),
      ),
      isDark,
    );
  }
}

