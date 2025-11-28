import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlobalProgressScreen extends ConsumerWidget {
  const GlobalProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    
    // Mock data - replace with actual API calls
    final globalStats = {
      'totalUsers': 12500,
      'totalWordsLearned': 2500000,
      'totalHours': 45000,
      'activeLanguages': 12,
    };

    final topLanguages = [
      {'name': 'Yoruba', 'learners': 3200, 'color': AppColors.primaryGreen},
      {'name': 'Swahili', 'learners': 2800, 'color': AppColors.primaryOrange},
      {'name': 'Hausa', 'learners': 2100, 'color': Colors.blue},
      {'name': 'Igbo', 'learners': 1800, 'color': Colors.purple},
      {'name': 'Zulu', 'learners': 1500, 'color': Colors.pink},
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Global Progress'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Global Stats Cards
            _buildGlobalStats(context, globalStats, isDark),
            SizedBox(height: 24.sp),
            
            // Top Languages Chart
            _buildTopLanguagesChart(context, topLanguages, isDark),
            SizedBox(height: 24.sp),
            
            // Leaderboard Section
            Text(
              'Top Learners',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16.sp),
            _buildLeaderboard(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats(BuildContext context, Map<String, dynamic> stats, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Global Statistics',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 16.sp),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Users',
                '${(stats['totalUsers'] as int).toString()}',
                '👥',
                isDark,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildStatCard(
                context,
                'Words Learned',
                '${(stats['totalWordsLearned'] as int / 1000000).toStringAsFixed(1)}M',
                '📚',
                isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Learning Hours',
                '${(stats['totalHours'] as int / 1000).toStringAsFixed(1)}K',
                '⏰',
                isDark,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildStatCard(
                context,
                'Languages',
                '${stats['activeLanguages']}',
                '🌍',
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String icon,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.8),
            AppColors.primaryOrange.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 32.sp),
          ),
          SizedBox(height: 8.sp),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLanguagesChart(BuildContext context, List<Map<String, dynamic>> languages, bool isDark) {
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
            'Most Popular Languages',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 20.sp),
          SizedBox(
            height: 200.sp,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 4000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < languages.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8.sp),
                            child: Text(
                              languages[index]['name'],
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: languages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lang = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (lang['learners'] as int).toDouble(),
                        color: lang['color'] as Color,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, bool isDark) {
    // Mock leaderboard data
    final leaders = [
      {'rank': 1, 'name': 'Amina K.', 'points': 12500, 'country': '🇳🇬'},
      {'rank': 2, 'name': 'Kwame M.', 'points': 11800, 'country': '🇬🇭'},
      {'rank': 3, 'name': 'Fatou D.', 'points': 11200, 'country': '🇸🇳'},
      {'rank': 4, 'name': 'Thabo S.', 'points': 10800, 'country': '🇿🇦'},
      {'rank': 5, 'name': 'Aisha H.', 'points': 10200, 'country': '🇰🇪'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        children: leaders.map((leader) {
          final isTopThree = leader['rank'] as int <= 3;
          return Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 40.sp,
                  height: 40.sp,
                  decoration: BoxDecoration(
                    color: isTopThree
                        ? AppColors.primaryGreen.withOpacity(0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isTopThree ? '🏆' : '#${leader['rank']}',
                      style: TextStyle(
                        fontSize: isTopThree ? 20.sp : 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isTopThree
                            ? AppColors.primaryGreen
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.sp),
                // Country flag
                Text(
                  leader['country'] as String,
                  style: TextStyle(fontSize: 24.sp),
                ),
                SizedBox(width: 12.sp),
                // Name
                Expanded(
                  child: Text(
                    leader['name'] as String,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                // Points
                Text(
                  '${leader['points']} pts',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

