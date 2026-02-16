import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/models/daily_goal_model.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/screens/tabs_view/home/language_detail_screen.dart';
import 'package:lingafriq/screens/language/search_languages_page.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';

final languagesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(apiProvider.notifier).getLanguages();
});

final _timerProvider = Provider((ref) {
  final welcomeTexts = [
    'Sannu da zuwa', // Hausa
    'Wehcome o', // Pidgin
    'Karibu', // Swahili
    'Ẹ Káàbọ', // Yoruba
    'Wamukelekile', // Zulu
    'Nnọọ', // Igbo
    'Welcome', // English
  ];

  // CRITICAL FIX: Store timer reference for cleanup to prevent memory leak
  Timer? timer;
  
  timer = Timer.periodic(2.seconds, (tick) {
    final index = tick.tick % welcomeTexts.length;
    final greeting = welcomeTexts[index];
    ref.read(_titleProvider.notifier).setTitle(greeting);
  });

  // CRITICAL FIX: Clean up timer when provider is disposed to prevent memory leak
  ref.onDispose(() {
    timer?.cancel();
  });
});

class TitleNotifier extends Notifier<String> {
  @override
  String build() => "Welcome";

  void setTitle(String value) {
    state = value;
  }
}

final _titleProvider =
    NotifierProvider.autoDispose<TitleNotifier, String>(() {
  return TitleNotifier();
});

/// Beautiful Material 3 Home Tab with Pan-African Design
class HomeTabMaterial3 extends HookConsumerWidget {
  const HomeTabMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesProvider);
    ref.watch(_timerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);
    ref.watch(dailyGoalsProvider);
    final dailyGoals = ref.read(dailyGoalsProvider.notifier).goals;
    final title = ref.watch(_titleProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Pan-African App Bar
              PanAfricanAppBar(
                title: '$title, ${user?.username ?? "Learner"}',
                showBackButton: false,
                actions: [
                  Semantics(
                    label: 'Search languages',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchLanguagesPage(),
                          ),
                        );
                      },
                      tooltip: 'Search Languages',
                    ),
                  ),
                  Semantics(
                    label: 'Open menu',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                      },
                      tooltip: 'Menu',
                    ),
                  ),
                ],
              ),

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          PanAfricanSpacing.md,
                          PanAfricanSpacing.lg,
                          PanAfricanSpacing.md,
                          PanAfricanSpacing.sm,
                        ),
                        child: _buildHeroCard(
                          context,
                          isDark,
                          userName: user?.username ?? 'Learner',
                          dailyGoals: dailyGoals,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          PanAfricanSpacing.md,
                          PanAfricanSpacing.lg,
                          PanAfricanSpacing.md,
                          PanAfricanSpacing.sm,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                          'Featured Languages',
                          style: PanAfricanTypography.headlineMedium(context),
                        ),
                        ),
                      ),
                      Expanded(
                        child: languagesAsync.when(
                          data: (languages) {
                            if (languages.results.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.language_outlined,
                                      size: 64.sp,
                                      color: PanAfricanColors.neutralMedium,
                                    ),
                                    SizedBox(height: PanAfricanSpacing.md),
                                    Text(
                                      'No languages available',
                                      style: PanAfricanTypography.bodyLarge(context),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: PanAfricanSpacing.md,
                              ),
                              itemCount: languages.results.length,
                              itemBuilder: (context, index) {
                                final language = languages.results[index];
                                return _LanguageCard(
                                  language: language,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LanguageDetailScreen(
                                          language: language,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                    .animate(delay: (index * 50).ms)
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: 0.1, duration: 300.ms);
                              },
                            );
                          },
                          error: (e, s) {
                            return Center(
                              child: StreamErrorWidget(
                                error: e,
                                onTryAgain: () {
                                  ref.invalidate(languagesProvider);
                                },
                              ),
                            );
                          },
                          loading: () => const AdaptiveProgressIndicator(
                            message: "Loading Languages...",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Language language;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = language.total_score > 0
        ? (language.total_score / 100).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          label: '${language.name} language card${progress > 0 ? ', ${(progress * 100).toInt()}% complete' : ', start learning'}',
          button: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: PanAfricanRadius.lgBR,
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Row(
            children: [
              // Language Flag/Image
              Semantics(
                label: '${language.name} flag',
                excludeSemantics: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  child: CachedNetworkImage(
                    imageUrl: language.background ?? '',
                    width: 60.w,
                    height: 60.w,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60.w,
                      height: 60.w,
                      color: PanAfricanColors.neutralLight,
                      child: Icon(
                        Icons.language,
                        color: PanAfricanColors.neutralMedium,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60.w,
                      height: 60.w,
                      color: PanAfricanColors.neutralLight,
                      child: Icon(
                        Icons.language,
                        color: PanAfricanColors.neutralMedium,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.md),
              // Language Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.name,
                      style: PanAfricanTypography.titleMedium(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    if (progress > 0) ...[
                      Semantics(
                        label: 'Progress: ${(progress * 100).toInt()}%',
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: PanAfricanColors.neutralLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            PanAfricanColors.primary,
                          ),
                          minHeight: 6.h,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(height: PanAfricanSpacing.xs),
                      Text(
                        '${(progress * 100).toInt()}% Complete',
                        style: PanAfricanTypography.labelSmall(context).copyWith(
                          color: PanAfricanColors.neutralMedium,
                        ),
                      ),
                    ] else
                      Text(
                        'Start Learning',
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: PanAfricanColors.neutralMedium,
                        ),
                      ),
                  ],
                ),
              ),
              Semantics(
                excludeSemantics: true,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: PanAfricanColors.neutralMedium,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String userName;
  final List<DailyGoal> dailyGoals;
  final bool isDark;

  const _HeroCard({
    required this.userName,
    required this.dailyGoals,
    required this.isDark,
  });

  double _progress() {
    final todayGoals = dailyGoals.where((goal) => goal.isToday).toList();
    if (todayGoals.isEmpty) return 0;
    final total = todayGoals.fold<double>(0, (sum, goal) => sum + goal.progress);
    return (total / todayGoals.length).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress();
    return Container(
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.savannaGold,
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
                    'Welcome back, $userName',
                    style: PanAfricanTypography.titleLarge(context).copyWith(
                      color: PanAfricanColors.neutralDarkest,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    'Pick a language and keep your streak alive.',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: PanAfricanColors.neutralDark,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Row(
                    children: [
                      Semantics(
                        label: 'Daily goals',
                        child: PanAfricanBadge(
                          label: 'Daily goals',
                          color: PanAfricanColors.tertiary,
                          icon: Icons.flag_rounded,
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Semantics(
                        label: '${(progress * 100).toInt()}% complete',
                        child: PanAfricanBadge(
                          label: '${(progress * 100).toInt()}% complete',
                          color: PanAfricanColors.primary,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              ),
              child: Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: PanAfricanTypography.titleSmall(context),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

Widget _buildHeroCard(
  BuildContext context,
  bool isDark, {
  required String userName,
  required List<DailyGoal> dailyGoals,
}) {
  return _HeroCard(
    userName: userName,
    dailyGoals: dailyGoals,
    isDark: isDark,
  );
}
