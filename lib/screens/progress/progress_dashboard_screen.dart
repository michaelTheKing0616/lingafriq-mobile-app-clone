import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lingafriq/providers/progress_tracking_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      errorMessage: 'Progress Dashboard is temporarily unavailable',
      onRetry: () {
        // Rebuild
      },
      child: _buildDashboard(context, ref),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(progressTrackingProvider.notifier).metrics;
    final history = ref.watch(progressTrackingProvider.notifier).history;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
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
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
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
              color: isDark ? Colors.white : Colors.black87,
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
              color: AppColors.primaryGreen,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryGreen.withOpacity(0.1),
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
      AppColors.primaryGreen,
      AppColors.primaryOrange,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    return _buildChartContainer(
      context,
      'Activity Distribution',
      PieChart(
        PieChartData(
          sections: activities.entries.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            return PieChartSectionData(
              value: activity.value,
              title: '${(activity.value / metrics.timeSpentHours * 100).toStringAsFixed(0)}%',
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
              color: AppColors.primaryOrange,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryOrange.withOpacity(0.1),
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
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.sp),
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
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ),
      isDark,
    );
  }
}

