import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/widgets/performance/optimized_list_view.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/screens/tabs_view/home/language_detail_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/search_languages_page.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import '../../../detail_types/introduction_screen.dart';

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

  Timer.periodic(2.seconds, (tick) {
    final index = tick.tick % welcomeTexts.length;
    final greeting = welcomeTexts[index];
    ref.read(_titleProvider.notifier).setTitle(greeting);
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
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchLanguagesPage(),
                        ),
                      );
                    },
                    tooltip: 'Search Languages',
                  ),
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
                          'Featured Languages',
                          style: PanAfricanTypography.headlineSmall(context),
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
                                horizontal: PanAfricanSpacing.lg,
                              ),
                              itemCount: languages.results.length,
                              itemBuilder: (context, index) {
                                final language = languages.results[index];
                                return _LanguageCard(
                                  language: language,
                                  isDark: isDark,
                                  onTap: () {
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
          child: Row(
            children: [
              // Language Flag/Image
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
                    if (progress > 0) ...[
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: PanAfricanColors.neutralLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          PanAfricanColors.primary,
                        ),
                        minHeight: 6.h,
                        borderRadius: BorderRadius.circular(3),
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
              Icon(
                Icons.chevron_right_rounded,
                color: PanAfricanColors.neutralMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

