import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/performance/optimized_list_view.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/screens/tabs_view/home/language_detail_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:riverpod/riverpod.dart';

/// Beautiful Material 3 Courses Tab with Pan-African Design
class CoursesTabMaterial3 extends HookConsumerWidget {
  const CoursesTabMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);

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
                title: 'Your Courses',
                subtitle: user != null ? 'Hi ${user.fullName}' : null,
                showBackButton: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () {
                      ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                    },
                    tooltip: 'Menu',
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
                        padding: EdgeInsets.all(PanAfricanSpacing.lg),
                        child: Text(
                          'Your Progress',
                          style: PanAfricanTypography.headlineSmall(context),
                        ),
                      ),
                      Expanded(
                        child: languagesAsync.when(
                          data: (languages) {
                            final progressLanguages = languages.results
                                .where((e) => e.total_score > 0)
                                .toList();

                            if (progressLanguages.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 64.sp,
                                      color: PanAfricanColors.neutralMedium,
                                    ),
                                    SizedBox(height: PanAfricanSpacing.md),
                                    Text(
                                      'No Course started yet',
                                      style: PanAfricanTypography.titleMedium(context),
                                    ),
                                    SizedBox(height: PanAfricanSpacing.sm),
                                    Text(
                                      'Start a course to see your progress',
                                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                                        color: PanAfricanColors.neutralMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(languagesProvider);
                              },
                              color: PanAfricanColors.primary,
                              child: OptimizedListView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: PanAfricanSpacing.lg,
                                ),
                                itemCount: progressLanguages.length,
                                itemBuilder: (context, index) {
                                  final language = progressLanguages[index];
                                  return _ProgressCard(
                                    language: language,
                                    isDark: isDark,
                                    onTap: () {
                                      ref.read(navigationProvider).naviateTo(
                                        LanguageDetailScreen(language: language),
                                      );
                                    },
                                  )
                                      .animate(delay: (index * 50).ms)
                                      .fadeIn(duration: 300.ms)
                                      .slideX(begin: 0.1, duration: 300.ms);
                                },
                              ),
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
                            message: "Loading Courses...",
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

class _ProgressCard extends StatelessWidget {
  final Language language;
  final bool isDark;
  final VoidCallback onTap;

  const _ProgressCard({
    required this.language,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = language.total_count == 0
        ? 0.0
        : (language.completed / language.total_count).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Language Image
                  ClipRRect(
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
                  SizedBox(width: PanAfricanSpacing.md),
                  // Language Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.name ?? 'Unknown Language',
                          style: PanAfricanTypography.titleMedium(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          'Lessons completed: ${language.completed} • Points: ${language.total_score}',
                          style: PanAfricanTypography.bodySmall(context).copyWith(
                            color: PanAfricanColors.neutralMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: PanAfricanColors.neutralMedium,
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.md),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: PanAfricanTypography.labelSmall(context).copyWith(
                          color: PanAfricanColors.neutralMedium,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: PanAfricanTypography.labelSmall(context).copyWith(
                          color: PanAfricanColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: PanAfricanColors.neutralLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        PanAfricanColors.primary,
                      ),
                      minHeight: 8.h,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

