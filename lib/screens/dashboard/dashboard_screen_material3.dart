import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/tab_scaffold_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/daily_goal_model.dart';
import 'package:lingafriq/screens/tutor/tutor_dashboard_screen.dart';
import 'package:lingafriq/screens/ai_chat/ai_language_selection_screen.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen_enhanced.dart';
import 'package:lingafriq/screens/games/language_games_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart' show languagesProvider;
import 'package:lingafriq/screens/tabs_view/home/language_detail_screen.dart';
import 'package:lingafriq/widgets/offline/offline_indicator.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Beautiful Material 3 Dashboard with Pan-African Design
class DashboardScreenMaterial3 extends HookConsumerWidget {
  const DashboardScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch state so UI updates when gamification model changes.
    ref.watch(gamificationProvider);
    final gamification = ref.read(gamificationProvider.notifier).gamification;
    ref.watch(dailyGoalsProvider);
    final dailyGoals = ref.read(dailyGoalsProvider.notifier).goals;

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
        child: ResponsiveSafeArea(
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
                    padding: EdgeInsets.symmetric(
                      horizontal: AdaptiveLayout.sideMargin(context),
                      vertical: PanAfricanSpacingResponsive.verticalContent(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero section
                        _buildHeroSection(
                          context,
                          isDark,
                          greeting: greeting.value,
                          streak: gamification.dailyStreak,
                          level: gamification.level,
                          dailyGoals: dailyGoals,
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Daily goals
                        _buildDailyGoals(context, isDark, dailyGoals),
                        SizedBox(height: PanAfricanSpacing.lg),

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

                        // Continue Learning (real languages from API)
                        _buildContinueLearning(context, ref, isDark),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Featured Languages (Kiswahili, Pidgin, IsiZulu, Igbo, Yoruba, Hausa, etc.)
                        _buildFeaturedLanguages(context, ref, isDark),
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
    final user = ref.watch(userProvider);
    final displayName = user?.username?.isNotEmpty == true
        ? user!.username
        : (user?.first_name?.isNotEmpty == true
            ? '${user!.first_name} ${user.last_name}'.trim()
            : null) ?? 'there';
    final greetingLine = '$greeting, $displayName';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AdaptiveLayout.sideMargin(context),
        vertical: PanAfricanSpacingResponsive.screenPaddingVertical(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.menu_rounded, color: Colors.white, size: 24.sp),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                },
                tooltip: 'Menu',
              ).animate().fadeIn(duration: 250.ms),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greetingLine,
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
                radius: 24.r,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.person, color: Colors.white, size: 24.sp),
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
              title: 'AI Chat',
              icon: Icons.chat_bubble,
              color: PanAfricanColors.kenteBlue,
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(child: AILanguageSelectionScreen()),
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

  Widget _buildContinueLearning(
      BuildContext context, WidgetRef ref, bool isDark) {
    final languagesAsync = ref.watch(languagesProvider);
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
                ref.read(tabIndexProvider.notifier).setIndex(1);
              },
              child: const Text('See All'),
            ),
          ],
        ),
        SizedBox(height: PanAfricanSpacing.md),
        languagesAsync.when(
          data: (languages) {
            final list = languages.results;
            if (list.isEmpty) {
              return _placeholderContinueLearning(context, isDark);
            }
            return SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final language = list[index];
                  final progress = language.total_count > 0
                      ? (language.completed / language.total_count)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LanguageDetailScreen(language: language),
                        ),
                      );
                    },
                    child: Container(
                      width: 200.w,
                      margin: EdgeInsets.only(right: PanAfricanSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? PanAfricanColors.cardDark
                            : PanAfricanColors.cardLight,
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
                          Expanded(
                              child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(PanAfricanRadius.lg),
                                topRight: Radius.circular(PanAfricanRadius.lg),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: language.background ?? '',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: PanAfricanColors.neutralLight,
                                  child: Icon(
                                    Icons.language,
                                    color: PanAfricanColors.neutralMedium,
                                    size: 24.sp,
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: PanAfricanColors.neutralLight,
                                  child: Icon(
                                    Icons.language,
                                    color: PanAfricanColors.neutralMedium,
                                    size: 24.sp,
                                  ),
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
                                  language.name ?? 'Language',
                                  style:
                                      PanAfricanTypography.titleSmall(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: PanAfricanSpacing.xxs),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: PanAfricanColors.neutralLight,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    PanAfricanColors.primary,
                                  ),
                                  minHeight: 6.h,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: (index * 80).ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.2);
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 120.h,
            child: const Center(
                child: AdaptiveProgressIndicator(message: 'Loading...')),
          ),
          error: (e, _) => SizedBox(
            height: 120.h,
            child: Center(
              child: StreamErrorWidget(
                error: e,
                onTryAgain: () => ref.invalidate(languagesProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderContinueLearning(BuildContext context, bool isDark) {
    return Container(
      height: 120.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.cardDark
            : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
          width: 1,
        ),
      ),
      child: Text(
        'Start a course to see progress',
        style: PanAfricanTypography.bodyMedium(context),
      ),
    );
  }

  Widget _buildFeaturedLanguages(
      BuildContext context, WidgetRef ref, bool isDark) {
    final languagesAsync = ref.watch(languagesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Languages',
          style: PanAfricanTypography.titleLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        languagesAsync.when(
          data: (languages) {
            final list = languages.results;
            if (list.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                child: Text(
                  'No languages available yet.',
                  style: PanAfricanTypography.bodyMedium(context)
                      .copyWith(color: PanAfricanColors.neutralMedium),
                ),
              );
            }
            return Column(
              children: List.generate(list.length, (index) {
                final language = list[index];
                final progress = language.total_count > 0
                    ? (language.completed / language.total_count)
                        .clamp(0.0, 1.0)
                    : 0.0;
                return Container(
                  margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    borderRadius: PanAfricanRadius.lgBR,
                    boxShadow: PanAfricanShadows.sm,
                    border: Border.all(
                      color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
                    leading: ClipRRect(
                      borderRadius: PanAfricanRadius.mdBR,
                      child: CachedNetworkImage(
                        imageUrl: language.background ?? '',
                        width: 48.w,
                        height: 48.w,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: PanAfricanColors.neutralLight,
                          child: Icon(
                            Icons.language,
                            color: PanAfricanColors.neutralMedium,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: PanAfricanColors.neutralLight,
                          child: Icon(
                            Icons.language,
                            color: PanAfricanColors.neutralMedium,
                          ),
                        ),
                      ),
                    ),
                    title: Text(language.name ?? 'Language'),
                    subtitle: progress > 0
                        ? LinearProgressIndicator(
                            value: progress,
                            backgroundColor: PanAfricanColors.neutralLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              PanAfricanColors.primary,
                            ),
                            minHeight: 6,
                          )
                        : Text(
                            'Start Learning',
                            style: PanAfricanTypography.bodySmall(context)
                                .copyWith(
                                    color: PanAfricanColors.neutralMedium),
                          ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: PanAfricanColors.neutralMedium, size: 24.sp),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LanguageDetailScreen(language: language),
                        ),
                      );
                    },
                  ),
                )
                    .animate(delay: (index * 80).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1);
              }),
            );
          },
          loading: () => Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: const AdaptiveProgressIndicator(message: 'Loading languages...'),
          ),
          error: (e, _) => StreamErrorWidget(
            error: e,
            onTryAgain: () => ref.invalidate(languagesProvider),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeroSection(
    BuildContext context,
    bool isDark, {
    required String greeting,
    required int streak,
    required int level,
    required List<DailyGoal> dailyGoals,
  }) {
    final progress = _calculateDailyGoalProgress(dailyGoals);
    final progressLabel = '${(progress * 100).toInt()}%';
    return Container(
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.sunset,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: PanAfricanTypography.headlineMedium(context).copyWith(
                      color: PanAfricanColors.neutralDarkest,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    'Your village awaits. Let’s make progress today.',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: PanAfricanColors.neutralDark,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Wrap(
                    spacing: PanAfricanSpacing.sm,
                    runSpacing: PanAfricanSpacing.xxs,
                    children: [
                      PanAfricanBadge(
                        label: '$streak day streak',
                        color: PanAfricanColors.tertiary,
                        icon: Icons.local_fire_department,
                      ),
                      PanAfricanBadge(
                        label: 'Level $level',
                        color: PanAfricanColors.primary,
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  PanAfricanButton(
                    label: 'Start a lesson',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(child: const TutorDashboardScreen()),
                      );
                    },
                    backgroundColor: PanAfricanColors.neutralDarkest,
                    foregroundColor: PanAfricanColors.secondaryLight,
                  ),
                ],
              ),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            _ProgressRing(
              progress: progress,
              label: progressLabel,
              isDark: isDark,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1);
  }

  Widget _buildDailyGoals(
    BuildContext context,
    bool isDark,
    List<DailyGoal> dailyGoals,
  ) {
    final todayGoals = dailyGoals.where((goal) => goal.isToday).toList();
    if (todayGoals.isEmpty) {
      return PanAfricanCard(
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: PanAfricanColors.primary, size: 24.sp),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Text(
                'All set. Your daily goals will appear here.',
                style: PanAfricanTypography.bodyMedium(context),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Goals',
          style: PanAfricanTypography.titleLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Row(
          children: List.generate(todayGoals.length, (index) {
            final goal = todayGoals[index];
            final isLast = index == todayGoals.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : PanAfricanSpacing.sm),
                child: _GoalRing(goal: goal, isDark: isDark),
              ),
            );
          }),
        ),
      ],
    );
  }

  double _calculateDailyGoalProgress(List<DailyGoal> goals) {
    final todayGoals = goals.where((goal) => goal.isToday).toList();
    if (todayGoals.isEmpty) return 0;
    final total = todayGoals.fold<double>(0, (sum, goal) => sum + goal.progress);
    return (total / todayGoals.length).clamp(0.0, 1.0);
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final String label;
  final bool isDark;

  const _ProgressRing({
    required this.progress,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isDark ? PanAfricanColors.secondary : PanAfricanColors.primary;
    final bgColor = isDark
        ? PanAfricanColors.surfaceContainerDark
        : PanAfricanColors.surfaceContainerLight;
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72.w,
            height: 72.w,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: PanAfricanTypography.titleMedium(context).copyWith(
                  color: PanAfricanColors.neutralDarkest,
                ),
              ),
              Text(
                'Today',
                style: PanAfricanTypography.labelSmall(context).copyWith(
                  color: PanAfricanColors.neutralMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  final DailyGoal goal;
  final bool isDark;

  const _GoalRing({
    required this.goal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _GoalMeta.fromType(goal.type);
    final progressLabel = '${goal.current}/${goal.target}';
    final bgColor = isDark
        ? PanAfricanColors.surfaceContainerDark
        : PanAfricanColors.surfaceContainerLight;

    return PanAfricanCard(
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60.w,
                height: 60.w,
                child: CircularProgressIndicator(
                  value: goal.progress,
                  strokeWidth: 6,
                  backgroundColor: bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                ),
              ),
              Icon(meta.icon, color: meta.color, size: 20.sp),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            meta.label,
            style: PanAfricanTypography.labelSmall(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Text(
            progressLabel,
            style: PanAfricanTypography.bodySmall(context).copyWith(
              color: PanAfricanColors.neutralMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMeta {
  final String label;
  final IconData icon;
  final Color color;

  const _GoalMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  static _GoalMeta fromType(String type) {
    switch (type) {
      case 'lessons':
        return _GoalMeta(
          label: 'Lessons',
          icon: Icons.menu_book_rounded,
          color: PanAfricanColors.primary,
        );
      case 'quizzes':
        return _GoalMeta(
          label: 'Quizzes',
          icon: Icons.quiz_rounded,
          color: PanAfricanColors.secondary,
        );
      case 'games':
        return _GoalMeta(
          label: 'Games',
          icon: Icons.sports_esports_rounded,
          color: PanAfricanColors.tertiary,
        );
      case 'chat_minutes':
        return _GoalMeta(
          label: 'Chat',
          icon: Icons.chat_bubble_rounded,
          color: PanAfricanColors.kenteBlue,
        );
      case 'words_learned':
        return _GoalMeta(
          label: 'Words',
          icon: Icons.translate_rounded,
          color: PanAfricanColors.kitengeTeal,
        );
      default:
        return _GoalMeta(
          label: 'Goal',
          icon: Icons.check_circle_rounded,
          color: PanAfricanColors.primary,
        );
    }
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
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
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
        HapticFeedback.lightImpact();
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
          borderRadius: PanAfricanRadius.lgBR,
          boxShadow: PanAfricanShadows.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24.sp),
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

