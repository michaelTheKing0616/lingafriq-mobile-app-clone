import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/tutor/tutor_dashboard_screen.dart';
import 'package:lingafriq/screens/ai_chat/ai_language_selection_screen.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen_enhanced.dart';
import 'package:lingafriq/screens/games/language_games_screen.dart';
import 'package:lingafriq/screens/goals/daily_challenges_screen.dart';
import 'package:lingafriq/widgets/offline/offline_indicator.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/screens/games/language_games_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/providers/gamification_provider.dart';

/// Beautiful Material 3 Dashboard with Pan-African Design
class DashboardScreenMaterial3 extends HookConsumerWidget {
  const DashboardScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch state so UI updates when gamification model changes.
    ref.watch(gamificationProvider);
    final gamification = ref.read(gamificationProvider.notifier).gamification;

    final greeting = useState(_getGreeting());

    useEffect(() {
      // Update greeting based on time of day
      final timer = Stream.periodic(Duration(hours: 1), (_) {
        greeting.value = _getGreeting();
      });
      return timer.listen((_) {}).cancel;
    }, []);

    return OfflineIndicator(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, ref, greeting.value, isDark),
              
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceDark
                        : PanAfricanColors.surfaceLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(PanAfricanRadius.xl),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats
                        _buildQuickStats(
                          context,
                          isDark,
                          streak: gamification.dailyStreak,
                          totalXp: gamification.xp,
                          level: gamification.level,
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Quick Actions
                        _buildQuickActions(context, isDark),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Continue Learning
                        _buildContinueLearning(context, isDark),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Recommended Content
                        _buildRecommendedContent(context, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String greeting, bool isDark) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () {
                  ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                },
                tooltip: 'Menu',
              ).animate().fadeIn(duration: 250.ms),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: PanAfricanTypography.headlineMedium(context)
                        .copyWith(color: Colors.white),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Text(
                    'Ready to learn?',
                    style: PanAfricanTypography.bodyMedium(context)
                        .copyWith(color: Colors.white70),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                ],
              ),
              CircleAvatar(
                radius: 28.r,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.person, color: Colors.white, size: 28.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    bool isDark, {
    required int streak,
    required int totalXp,
    required int level,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '$streak',
            icon: Icons.local_fire_department,
            color: PanAfricanColors.tertiary,
            isDark: isDark,
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideX(begin: -0.2),
        ),
        SizedBox(width: PanAfricanSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'XP',
            value: _formatCompactNumber(totalXp),
            icon: Icons.star,
            color: PanAfricanColors.secondary,
            isDark: isDark,
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideX(begin: 0.2),
        ),
        SizedBox(width: PanAfricanSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'Level',
            value: '$level',
            icon: Icons.trending_up,
            color: PanAfricanColors.primary,
            isDark: isDark,
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms).slideX(begin: 0.2),
        ),
      ],
    );
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}K';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toString();
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: PanAfricanTypography.titleLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: PanAfricanSpacing.md,
          mainAxisSpacing: PanAfricanSpacing.md,
          childAspectRatio: 1.5,
          children: [
            _QuickActionCard(
              title: 'Polie Tutor',
              icon: Icons.school,
              color: PanAfricanColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(child: TutorDashboardScreen(),
                  ),
                );
              },
              isDark: isDark,
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms).scale(begin: Offset(0.9, 0.9)),
            _QuickActionCard(
              title: 'AI Assistant',
              icon: Icons.chat_bubble,
              color: PanAfricanColors.kenteBlue,
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(child: AILanguageSelectionScreen(),
                  ),
                );
              },
              isDark: isDark,
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms).scale(begin: Offset(0.9, 0.9)),
            _QuickActionCard(
              title: 'Magazine',
              icon: Icons.article,
              color: PanAfricanColors.kenteRed,
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(child: CultureMagazineScreenEnhanced(),
                  ),
                );
              },
              isDark: isDark,
            ).animate(delay: 300.ms).fadeIn(duration: 300.ms).scale(begin: Offset(0.9, 0.9)),
            _QuickActionCard(
              title: 'Games',
              icon: Icons.sports_esports,
              color: PanAfricanColors.secondary,
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(child: LanguageGamesScreen(),
                  ),
                );
              },
              isDark: isDark,
            ).animate(delay: 400.ms).fadeIn(duration: 300.ms).scale(begin: Offset(0.9, 0.9)),
          ],
        ),
      ],
    );
  }

  Widget _buildContinueLearning(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Continue Learning',
              style: PanAfricanTypography.titleLarge(context),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    child: const LanguageGamesScreen(),
                  ),
                );
              },
              child: Text('See All'),
            ),
          ],
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Container(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 200.w,
                margin: EdgeInsets.only(right: PanAfricanSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? PanAfricanColors.cardDark
                      : PanAfricanColors.cardLight,
                  borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  boxShadow: PanAfricanShadows.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: PanAfricanGradients.sunset,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(PanAfricanRadius.lg),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.book,
                            size: 32.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lesson ${index + 1}',
                            style: PanAfricanTypography.titleSmall(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.xxs),
                          LinearProgressIndicator(
                            value: 0.6,
                            backgroundColor: PanAfricanColors.neutralLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              PanAfricanColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: (index * 100).ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: PanAfricanTypography.titleLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        ...List.generate(3, (index) {
          return Card(
            margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(PanAfricanSpacing.sm),
                decoration: BoxDecoration(
                  color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                child: Icon(
                  Icons.auto_stories,
                  color: PanAfricanColors.primary,
                ),
              ),
              title: Text('Cultural Story: ${index + 1}'),
              subtitle: Text('Learn about African traditions'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(child: CultureMagazineScreenEnhanced(),
                  ),
                );
              },
            ),
          )
              .animate(delay: (index * 100).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2);
        }),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            value,
            style: PanAfricanTypography.headlineSmall(context),
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Text(
            label,
            style: PanAfricanTypography.bodySmall(context),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          boxShadow: PanAfricanShadows.md,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32.sp),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              title,
              style: PanAfricanTypography.titleMedium(context)
                  .copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

