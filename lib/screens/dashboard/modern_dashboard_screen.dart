import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/screens/goals/daily_challenges_screen.dart';
import 'package:lingafriq/screens/games/language_games_screen.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/screens/global/global_progress_screen.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_screen.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen.dart';
import 'package:lingafriq/screens/chat/global_chat_screen.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern Dashboard Screen - Based on Figma Make Dashboard Design
class ModernDashboardScreen extends HookConsumerWidget {
  const ModernDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final dailyGoals = ref.watch(dailyGoalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate today's goal progress
    final completedGoals = dailyGoals.goals.where((g) => g.isCompleted).length;
    final totalGoals = dailyGoals.goals.length;
    final todayGoal = totalGoals > 0 ? (completedGoals / totalGoals * 100).round() : 0;
    
    return Scaffold(
      backgroundColor: isDark ? AfricanTheme.backgroundDark : AfricanTheme.backgroundLight,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 35.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFCE1126), // Red
                  Color(0xFFFF6B35), // Orange
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  backgroundImage: user?.avatar != null
                                      ? NetworkImage(user!.avatar!)
                                      : null,
                                  child: user?.avatar == null
                                      ? Text(
                                          (user?.username ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(
                                            color: const Color(0xFFCE1126),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(width: 3.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello,',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    Text(
                                      '${user?.username ?? 'User'}!',
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_rounded, color: Colors.white),
                              onPressed: () {
                                // Navigate to settings
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                shape: const CircleBorder(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.local_fire_department_rounded,
                                value: '${user?.streak ?? 0}',
                                label: 'Day Streak',
                                color: const Color(0xFFFF6B35),
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.bolt_rounded,
                                value: '${user?.completed_point ?? 0}',
                                label: 'Total XP',
                                color: const Color(0xFFCE1126),
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star_rounded,
                                value: 'Lvl ${user?.level ?? 1}',
                                label: 'Current',
                                color: const Color(0xFF007A3D),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Positioned(
            top: 32.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Goal Card
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: isDark ? AfricanTheme.stitchCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                      boxShadow: DesignSystem.shadowLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.track_changes_rounded,
                                  color: AfricanTheme.primaryGreen,
                                  size: 20,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Today\'s Goal',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: AfricanTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                              ),
                              child: Text(
                                '$todayGoal%',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AfricanTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (todayGoal / 100).clamp(0.0, 1.0),
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(AfricanTheme.primaryGreen),
                            minHeight: 12,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: _ProgressItem(
                                label: 'Vocabulary',
                                completed: 15,
                                total: 20,
                                color: const Color(0xFFCE1126),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _ProgressItem(
                                label: 'Grammar',
                                completed: 8,
                                total: 10,
                                color: const Color(0xFF007A3D),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _ProgressItem(
                                label: 'Speaking',
                                completed: 5,
                                total: 5,
                                color: const Color(0xFFFCD116),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 3.h),
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 3.w,
                    childAspectRatio: 1.3,
                    children: [
                      _QuickActionCard(
                        icon: Icons.menu_book_rounded,
                        label: 'Continue Learning',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFCE1126), Color(0xFFFF6B35)],
                        ),
                        onTap: () {
                          // Navigate to lessons
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.chat_bubble_rounded,
                        label: 'AI Tutor',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007A3D), Color(0xFF00A8E8)],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AiChatScreen()),
                          );
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.track_changes_rounded,
                        label: 'Daily Challenge',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFCD116), Color(0xFFFF6B35)],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DailyChallengesScreen()),
                          );
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.emoji_events_rounded,
                        label: 'Games',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2CBF), Color(0xFFCE1126)],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LanguageGamesScreen()),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 3.h),
                  // Explore More Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Explore More',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 3.w,
                    childAspectRatio: 1.5,
                    children: [
                      _ExploreCard(
                        icon: Icons.people_rounded,
                        title: 'Community Chat',
                        subtitle: 'Join the conversation',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GlobalChatScreen()),
                          );
                        },
                      ),
                      _ExploreCard(
                        icon: Icons.newspaper_rounded,
                        title: 'Magazines',
                        subtitle: 'Culture & stories',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CultureMagazineScreen()),
                          );
                        },
                      ),
                      _ExploreCard(
                        icon: Icons.trending_up_rounded,
                        title: 'Global Ranking',
                        subtitle: 'See your position',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GlobalProgressScreen()),
                          );
                        },
                      ),
                      _ExploreCard(
                        icon: Icons.access_time_rounded,
                        title: 'Progress',
                        subtitle: 'Track your journey',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProgressDashboardScreen()),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black87 : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final Color color;
  
  const _ProgressItem({
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.black54),
        ),
        Text(
          '$completed/$total',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
            boxShadow: DesignSystem.shadowMedium,
          ),
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              SizedBox(height: 1.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isDark ? AfricanTheme.stitchCardDark : Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
            boxShadow: DesignSystem.shadowMedium,
            border: Border.all(
              color: isDark ? AfricanTheme.stitchBorderDark : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AfricanTheme.primaryGreen,
                size: 24,
              ),
              SizedBox(height: 1.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  
  _PatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    const spacing = 35.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

