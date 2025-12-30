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

/// Grammar Explanation Mode Screen
class TutorGrammarModeScreen extends HookConsumerWidget {
  const TutorGrammarModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicController = useTextEditingController();
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final userLevel = useState('A1');
    final isLoading = useState(false);
    final grammarResult = useState<Map<String, dynamic>?>(null);
    final localizationService = useMemoized(() => DynamicLocalizationService());
    final availableLanguages = AppLanguage.values;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> explainGrammar() async {
      if (topicController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a grammar topic')),
        );
        return;
      }

      isLoading.value = true;
      await safeAsync(
        context: context,
        operation: () async {
          final response = await ApiService.post(
            AppConfig.tutorGrammar,
            data: {
              'topic': topicController.text,
              'language': selectedLanguage.value.name,
              'userLevel': userLevel.value,
            },
          );

          if (response.statusCode == 200) {
            grammarResult.value = response.data;
          } else {
            throw Exception('Failed to get grammar explanation');
          }
        },
        errorContext: 'explainGrammar',
        showError: true,
      );
      isLoading.value = false;
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Generating grammar explanation...',
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Topic Input
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Grammar Topic',
                hintText: 'e.g., verb conjugation, noun cases, tenses',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
                filled: true,
                fillColor: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
              ),
              style: PanAfricanTypography.bodyLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),

            // Language and Level Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<AppLanguage>(
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
                ),
                SizedBox(width: PanAfricanSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: userLevel.value,
                    decoration: InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? PanAfricanColors.surfaceContainerDark
                          : PanAfricanColors.surfaceContainerLight,
                    ),
                    items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) userLevel.value = value;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.lg),

            // Explain Button
            ElevatedButton(
              onPressed: isLoading.value ? null : explainGrammar,
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
                      'Explain Grammar',
                      style: PanAfricanTypography.labelLarge(context)
                          .copyWith(color: Colors.white),
                    ),
            ),
            SizedBox(height: PanAfricanSpacing.xl),

            // Grammar Result
            if (grammarResult.value != null)
              _buildGrammarResult(
                context,
                grammarResult.value!,
                isDark,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarResult(
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
          // Canonical Rule
          Text(
            'Rule',
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            result['canonicalRule'] ?? '',
            style: PanAfricanTypography.bodyLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.lg),

          // Examples
          if (result['examples'] != null && (result['examples'] as List).isNotEmpty) ...[
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Examples',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['examples'] as List).map((example) {
              final ex = example as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                child: ListTile(
                  title: Text(
                    ex['target'] ?? '',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  subtitle: Text(
                    ex['translation'] ?? '',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ),
              );
            }),
          ],

          // Common Mistakes
          if (result['commonMistakes'] != null &&
              (result['commonMistakes'] as List).isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Common Mistakes',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['commonMistakes'] as List).map((mistake) {
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: PanAfricanColors.warning,
                      size: 20.sp,
                    ),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Expanded(
                      child: Text(
                        mistake,
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Practice Exercises
          if (result['practice'] != null && (result['practice'] as List).isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Practice',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['practice'] as List).map((exercise) {
              final ex = exercise as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex['prompt'] ?? '',
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.xs),
                      Text(
                        'Answer: ${ex['answer'] ?? ''}',
                        style: PanAfricanTypography.bodySmall(context)
                            .copyWith(color: PanAfricanColors.primary),
                      ),
                    ],
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

