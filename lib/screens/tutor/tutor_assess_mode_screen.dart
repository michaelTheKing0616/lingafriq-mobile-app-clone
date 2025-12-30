import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;

/// Comprehensive Proficiency Assessment Screen
class TutorAssessModeScreen extends HookConsumerWidget {
  const TutorAssessModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final assessmentType = useState('placement');
    final isLoading = useState(false);
    final assessmentResult = useState<Map<String, dynamic>?>(null);
    final localizationService = useMemoized(() => DynamicLocalizationService());
    final availableLanguages = AppLanguage.values;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> assessProficiency() async {
      isLoading.value = true;
      await safeAsync(
        context: context,
        operation: () async {
          final response = await ApiService.post(
            AppConfig.tutorAssess,
            data: {
              'language': selectedLanguage.value.name,
              'assessmentType': assessmentType.value,
            },
          );

          if (response.statusCode == 200) {
            assessmentResult.value = response.data;
          } else {
            throw Exception('Failed to generate assessment');
          }
        },
        errorContext: 'assessProficiency',
        showError: true,
      );
      isLoading.value = false;
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Generating assessment...',
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'Proficiency Assessment',
              style: PanAfricanTypography.headlineMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Get a comprehensive assessment of your language skills',
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.xl),

            // Language Input
            DropdownButtonFormField<AppLanguage>(
              value: selectedLanguage.value,
              decoration: InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                filled: true,
                fillColor: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
              ),
              items: availableLanguages.map((lang) => DropdownMenuItem<AppLanguage>(
                value: lang,
                child: Text(
                  lang.name.substring(0, 1).toUpperCase() + lang.name.substring(1),
                ),
              )).toList(),
              onChanged: (value) {
                if (value != null) selectedLanguage.value = value;
              },
            ),
            SizedBox(height: PanAfricanSpacing.md),

            // Assessment Type
            DropdownButtonFormField<String>(
              value: assessmentType.value,
              decoration: InputDecoration(
                labelText: 'Assessment Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                filled: true,
                fillColor: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
              ),
              items: [
                DropdownMenuItem(value: 'placement', child: Text('Placement Test')),
                DropdownMenuItem(value: 'progress', child: Text('Progress Check')),
                DropdownMenuItem(value: 'comprehensive', child: Text('Comprehensive')),
              ],
              onChanged: (value) {
                if (value != null) assessmentType.value = value;
              },
            ),
            SizedBox(height: PanAfricanSpacing.xl),

            // Assess Button
            ElevatedButton(
              onPressed: isLoading.value ? null : assessProficiency,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
              ),
              child: isLoading.value
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Start Assessment',
                      style: PanAfricanTypography.labelLarge(context)
                          .copyWith(color: Colors.white),
                    ),
            ),
            SizedBox(height: PanAfricanSpacing.xl),

            // Assessment Result
            if (assessmentResult.value != null)
              _buildAssessmentResult(
                context,
                assessmentResult.value!,
                isDark,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentResult(
    BuildContext context,
    Map<String, dynamic> result,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proficiency Level
          Center(
            child: Column(
              children: [
                Text(
                  'Your Level',
                  style: PanAfricanTypography.titleMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.xl,
                    vertical: PanAfricanSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: PanAfricanGradients.celebration,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                  ),
                  child: Text(
                    result['proficiencyLevel'] ?? 'A1',
                    style: PanAfricanTypography.displayMedium(context)
                        .copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xl),

          // Strengths
          if (result['strengths'] != null &&
              (result['strengths'] as List).isNotEmpty) ...[
            Text(
              'Strengths',
              style: PanAfricanTypography.titleLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['strengths'] as List).map((strength) {
              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                color: PanAfricanColors.success.withOpacity(0.1),
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: PanAfricanColors.success),
                  title: Text(
                    strength,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ),
              );
            }),
            SizedBox(height: PanAfricanSpacing.lg),
          ],

          // Weaknesses
          if (result['weaknesses'] != null &&
              (result['weaknesses'] as List).isNotEmpty) ...[
            Text(
              'Areas for Improvement',
              style: PanAfricanTypography.titleLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['weaknesses'] as List).map((weakness) {
              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                color: PanAfricanColors.warning.withOpacity(0.1),
                child: ListTile(
                  leading: Icon(Icons.trending_up, color: PanAfricanColors.warning),
                  title: Text(
                    weakness,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ),
              );
            }),
            SizedBox(height: PanAfricanSpacing.lg),
          ],

          // Recommendations
          if (result['recommendations'] != null &&
              (result['recommendations'] as List).isNotEmpty) ...[
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Recommendations',
              style: PanAfricanTypography.titleLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['recommendations'] as List).map((recommendation) {
              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                child: ListTile(
                  leading: Icon(Icons.lightbulb, color: PanAfricanColors.primary),
                  title: Text(
                    recommendation,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

