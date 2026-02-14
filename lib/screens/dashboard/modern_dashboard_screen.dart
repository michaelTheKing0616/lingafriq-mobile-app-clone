import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/screens/goals/daily_challenges_screen.dart';
import 'package:lingafriq/screens/games/language_games_screen.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_language_setup_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/global/global_progress_screen.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_screen.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen.dart';
import 'package:lingafriq/screens/chat/global_chat_screen.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/screens/settings/settings_screen_material3.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern Dashboard Screen - Based on Figma Make Dashboard Design
class ModernDashboardScreen extends HookConsumerWidget {
  const ModernDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final dailyGoalsNotifier = ref.read(dailyGoalsProvider.notifier);
    final dailyGoals = dailyGoalsNotifier.goals;
    final currentStreak = dailyGoalsNotifier.currentStreak;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate today's goal progress
    final completedGoals = dailyGoals.where((g) => g.completed).length;
    final totalGoals = dailyGoals.length;
    final todayGoal = totalGoals > 0 ? (completedGoals / totalGoals * 100).round() : 0;
    
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Solid header
          Container(
            height: 35.h,
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(PanAfricanRadius.xxl),
                bottomRight: Radius.circular(PanAfricanRadius.xxl),
              ),
              boxShadow: PanAfricanShadows.sm,
            ),
            child: ResponsiveSafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                    child: Column(
                      children: [
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                user?.avatar != null && user!.avatar!.isNotEmpty
                                    ? ClipOval(
                                        child: LazyImage(
                                          imageUrl: user!.avatar!,
                                          width: 48,
                                          height: 48,
                                          placeholder: CircleAvatar(
                                            radius: 24,
                                            backgroundColor: Theme.of(context).colorScheme.surface,
                                            child: Text(
                                              (user.username ?? 'U')[0].toUpperCase(),
                                              style: TextStyle(
                                                color: const Color(0xFFCE1126),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Theme.of(context).colorScheme.surface,
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
                                SizedBox(width: PanAfricanSpacing.sm),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello,',
                                      style: PanAfricanTypography.bodyMedium(context)
                                          .copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9)),
                                    ),
                                    Text(
                                      '${user?.username ?? 'User'}!',
                                      style: PanAfricanTypography.titleLarge(context)
                                          .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.settings_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 24.sp),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    child: const SettingsScreenMaterial3(),
                                  ),
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                                shape: const CircleBorder(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.local_fire_department_rounded,
                                value: '$currentStreak',
                                label: 'Day Streak',
                                color: PanAfricanColors.tertiary,
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: PanAfricanSpacing.sm),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.bolt_rounded,
                                value: '${user?.completed_point ?? 0}',
                                label: 'Total XP',
                                color: PanAfricanColors.kenteRed,
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: PanAfricanSpacing.sm),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star_rounded,
                                value: 'Lvl ${user?.level ?? 1}',
                                label: 'Current',
                                color: PanAfricanColors.primary,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          // Main Content (second Stack child)
          Positioned(
            top: 32.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: PanAfricanSpacing.lg),
                  // Today's Goal Card
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      borderRadius: PanAfricanRadius.lgBR,
                      boxShadow: PanAfricanShadows.sm,
                      border: Border.all(
                        color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                        width: 1,
                      ),
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
                                  color: PanAfricanColors.primary,
                                  size: 20.sp,
                                ),
                                SizedBox(width: PanAfricanSpacing.xs),
                                Text(
                                  'Today\'s Goal',
                                  style: PanAfricanTypography.titleMedium(context),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: PanAfricanSpacing.sm,
                                vertical: PanAfricanSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: PanAfricanColors.primary.withOpacity(0.1),
                                borderRadius: PanAfricanRadius.roundBR,
                              ),
                              child: Text(
                                '$todayGoal%',
                                style: PanAfricanTypography.labelMedium(context)
                                    .copyWith(color: PanAfricanColors.primary),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        ClipRRect(
                          borderRadius: PanAfricanRadius.smBR,
                          child: LinearProgressIndicator(
                            value: (todayGoal / 100).clamp(0.0, 1.0),
                            backgroundColor: isDark ? PanAfricanColors.neutralMedium : PanAfricanColors.neutralLight,
                            valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                            minHeight: 8,
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _ProgressItem(
                                label: 'Vocabulary',
                                completed: 15,
                                total: 20,
                                color: PanAfricanColors.kenteRed,
                              ),
                            ),
                            SizedBox(width: PanAfricanSpacing.sm),
                            Expanded(
                              child: _ProgressItem(
                                label: 'Grammar',
                                completed: 8,
                                total: 10,
                                color: PanAfricanColors.primary,
                              ),
                            ),
                            SizedBox(width: PanAfricanSpacing.sm),
                            Expanded(
                              child: _ProgressItem(
                                label: 'Speaking',
                                completed: 5,
                                total: 5,
                                color: PanAfricanColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: PanAfricanSpacing.xl),
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: PanAfricanTypography.titleLarge(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: PanAfricanSpacing.md,
                    mainAxisSpacing: PanAfricanSpacing.md,
                    childAspectRatio: 1.5,
                    children: [
                      _QuickActionCard(
                        icon: Icons.menu_book_rounded,
                        label: 'Continue Learning',
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              child: const LanguageGamesScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.chat_bubble_rounded,
                        label: 'AI Tutor',
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              child: const AiChatLanguageSetupScreen(
                                initialMode: PolieMode.translation,
                              ),
                            ),
                          );
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.track_changes_rounded,
                        label: 'Daily Challenge',
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const DailyChallengesScreen()),
                          );
                        },
                      ),
                      _QuickActionCard(
                        icon: Icons.emoji_events_rounded,
                        label: 'Games',
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const LanguageGamesScreen()),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: PanAfricanSpacing.xl),
                  // Explore More Section
                  Text(
                    'Explore More',
                    style: PanAfricanTypography.titleLarge(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: PanAfricanSpacing.md,
                    mainAxisSpacing: PanAfricanSpacing.md,
                    childAspectRatio: 1.5,
                    children: [
                      _ExploreCard(
                        icon: Icons.people_rounded,
                        title: 'Community Chat',
                        subtitle: 'Join the conversation',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const GlobalChatScreen()),
                          );
                        },
                      ),
                      _ExploreCard(
                        icon: Icons.newspaper_rounded,
                        title: 'Magazines',
                        subtitle: 'Culture & stories',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const CultureMagazineScreen()),
                          );
                        },
                      ),
                      _ExploreCard(
                        icon: Icons.trending_up_rounded,
                        title: 'Global Ranking',
                        subtitle: 'See your position',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const GlobalProgressScreen()),
                          );
                        },
                      ),
                      _ExploreCard(
                        icon: Icons.access_time_rounded,
                        title: 'Progress',
                        subtitle: 'Track your journey',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const ProgressDashboardScreen()),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: PanAfricanSpacing.xl),
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
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.xxs),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: PanAfricanRadius.mdBR,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            value,
            style: PanAfricanTypography.headlineMedium(context),
          ),
          Text(
            label,
            style: PanAfricanTypography.bodySmall(context)
                .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            borderRadius: PanAfricanRadius.xsBR,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xxs),
        Text(
          label,
          style: PanAfricanTypography.bodySmall(context),
        ),
        Text(
          '$completed/$total',
          style: PanAfricanTypography.labelMedium(context),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: PanAfricanRadius.lgBR,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: PanAfricanRadius.lgBR,
            boxShadow: PanAfricanShadows.sm,
            border: Border.all(
              color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: PanAfricanColors.primary, size: 24.sp),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                label,
                style: PanAfricanTypography.titleMedium(context)
                    .copyWith(color: textColor),
                textAlign: TextAlign.center,
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
        borderRadius: PanAfricanRadius.lgBR,
        child: Container(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: PanAfricanRadius.lgBR,
            boxShadow: PanAfricanShadows.sm,
            border: Border.all(
              color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: PanAfricanColors.primary,
                size: 24.sp,
              ),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                title,
                style: PanAfricanTypography.titleSmall(context),
              ),
              SizedBox(height: PanAfricanSpacing.xxs),
              Text(
                subtitle,
                style: PanAfricanTypography.bodySmall(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


