import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart' show languagesProvider;
import 'package:lingafriq/screens/tabs_view/home/language_detail_screen.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/adaptive_progress_indicator.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/error_widet.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Picks a language, then opens the Africa-map Lessons hub ([LanguageDetailScreen]).
/// Use this everywhere we previously pushed [CurriculumScreenMaterial3] for "lessons".
class LessonsMapEntryScreen extends ConsumerWidget {
  const LessonsMapEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(languagesProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: ResponsiveSafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.md,
                  vertical: PanAfricanSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).maybePop();
                      },
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Text(
                        'Lessons',
                        style: PanAfricanTypography.headlineSmall(context),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                child: Text(
                  'Choose a language to open the map, learning path, mannerisms, history, and quiz.',
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.md),
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
                  child: async.when(
                    data: (response) {
                      final list = response.results;
                      if (list.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(PanAfricanSpacing.lg),
                            child: Text(
                              'No languages available yet.',
                              style: PanAfricanTypography.bodyLarge(context),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.all(PanAfricanSpacing.md),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: PanAfricanSpacing.sm),
                        itemBuilder: (context, index) {
                          final language = list[index];
                          return Material(
                            color: isDark
                                ? PanAfricanColors.cardDark
                                : PanAfricanColors.cardLight,
                            borderRadius: PanAfricanRadius.lgBR,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(PanAfricanSpacing.md),
                              leading: ClipRRect(
                                borderRadius: PanAfricanRadius.mdBR,
                                child: CachedNetworkImage(
                                  imageUrl: language.background ?? '',
                                  width: 56.w,
                                  height: 56.w,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 56.w,
                                    height: 56.w,
                                    color: PanAfricanColors.neutralLight,
                                    child: Icon(
                                      Icons.public_rounded,
                                      color: PanAfricanColors.neutralMedium,
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 56.w,
                                    height: 56.w,
                                    color: PanAfricanColors.neutralLight,
                                    child: Icon(
                                      Icons.public_rounded,
                                      color: PanAfricanColors.neutralMedium,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                language.name,
                                style: PanAfricanTypography.titleMedium(context),
                              ),
                              subtitle: Text(
                                'Lessons, mannerisms, history & quiz',
                                style: PanAfricanTypography.bodySmall(context),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: PanAfricanColors.neutralMedium,
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  SmoothPageRoute(
                                    child: LanguageDetailScreen(language: language),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: AdaptiveProgressIndicator(
                        message: 'Loading languages…',
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: EdgeInsets.all(PanAfricanSpacing.lg),
                        child: StreamErrorWidget(
                          error: e,
                          onTryAgain: () => ref.invalidate(languagesProvider),
                        ),
                      ),
                    ),
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
