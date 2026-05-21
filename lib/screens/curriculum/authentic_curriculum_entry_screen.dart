import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/curriculum/curriculum_screen_material3.dart';
import 'package:lingafriq/utils/curriculum_languages.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Entry hub for the bundled A1–C1 authentic curriculum (14 languages).
/// Separate from the original API lessons map ([LearningPathScreen]).
class AuthenticCurriculumEntryScreen extends StatelessWidget {
  const AuthenticCurriculumEntryScreen({
    super.key,
    this.initialLanguage,
    this.initialLevel,
  });

  /// When opened from a language map, pre-select study language.
  final String? initialLanguage;
  final String? initialLevel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langLabel = initialLanguage != null
        ? CurriculumLanguages.displayName(initialLanguage!)
        : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Authentic Path',
                        style: PanAfricanTypography.headlineSmall(context).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(PanAfricanSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 72.w,
                          height: 72.w,
                          decoration: BoxDecoration(
                            gradient: PanAfricanGradients.sunset,
                            shape: BoxShape.circle,
                            boxShadow: PanAfricanShadows.md,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 40.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: PanAfricanSpacing.lg),
                      Text(
                        'LingAfriq Authentic Path',
                        style: PanAfricanTypography.headlineMedium(context),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Text(
                        langLabel != null
                            ? 'Bundled lessons for $langLabel — levels A1 through C1, with Polie, culture, and offline content.'
                            : 'Bundled lessons for 14 African languages — levels A1 through C1. This is separate from your original Lessons map on the home language screen.',
                        style: PanAfricanTypography.bodyMedium(context),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: PanAfricanSpacing.lg),
                      PanAfricanCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FeatureRow(
                              icon: Icons.menu_book_outlined,
                              title: 'Original Lessons',
                              subtitle: 'Stays on the map under “Lessons” — your existing learning path from the server.',
                            ),
                            Divider(height: PanAfricanSpacing.lg),
                            _FeatureRow(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Authentic Path (this)',
                              subtitle: 'Ten-stage flow, unit quizzes, persona missions, magazine tie-ins — all from bundled curriculum.',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: PanAfricanSpacing.xl),
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              child: CurriculumScreenMaterial3(
                                initialLanguage: initialLanguage,
                                initialLevel: initialLevel,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          langLabel != null ? 'Start $langLabel path' : 'Open curriculum',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: PanAfricanColors.primary,
                          minimumSize: Size(double.infinity, 52.h),
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PanAfricanColors.primary, size: 28.sp),
        SizedBox(width: PanAfricanSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PanAfricanTypography.titleSmall(context)),
              SizedBox(height: 4.h),
              Text(subtitle, style: PanAfricanTypography.bodySmall(context)),
            ],
          ),
        ),
      ],
    );
  }
}
