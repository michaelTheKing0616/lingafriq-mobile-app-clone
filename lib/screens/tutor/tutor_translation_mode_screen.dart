import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Translation Mode Screen with Literal/Adaptive Toggle
class TutorTranslationModeScreen extends HookConsumerWidget {
  const TutorTranslationModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final sourceLanguage = useState<AppLanguage>(AppLanguage.english);
    final targetLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final translationType = useState<String>('adaptive');
    final isLoading = useState(false);
    final translationResult = useState<Map<String, dynamic>?>(null);
    final localizationService = useMemoized(() => DynamicLocalizationService());
    final availableLanguages = AppLanguage.values;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> translate() async {
      if (textController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter text to translate')),
        );
        return;
      }

      isLoading.value = true;
      try {
        final response = await ApiService.post(
          AppConfig.tutorTranslate,
          data: {
            'text': textController.text,
            'sourceLang': sourceLanguage.value.name,
            'targetLang': targetLanguage.value.name,
            'translationType': translationType.value,
            // Enhanced translation options
            'includeContext': true,
            'includeLiteralTranslation': translationType.value == 'adaptive',
            'includeCulturalNotes': true,
            'includePronunciationGuide': true,
            'includeExampleUsage': true,
          },
        );

        if (response.statusCode == 200) {
          final data = response.data['data'] ?? response.data;
          translationResult.value = {
            'translation': data['translation'] ?? data['text'] ?? '',
            'literalTranslation': data['literalTranslation'],
            'culturalNotes': data['culturalNotes'],
            'pronunciationGuide': data['pronunciationGuide'],
            'exampleUsage': data['exampleUsage'],
            'confidence': data['confidence'] ?? 1.0,
            'alternatives': data['alternatives'],
            'wordBreakdown': data['wordBreakdown'],
          };
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
        translationResult.value = null;
      } finally {
        isLoading.value = false;
      }
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Translating...',
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Translation Type Toggle
            _buildTranslationTypeToggle(
              context,
              translationType.value,
              (type) => translationType.value = type,
              isDark,
            ),
            SizedBox(height: PanAfricanSpacing.lg),

            // Source Language
            _buildLanguageSelector(
              context,
              'From',
              sourceLanguage,
              availableLanguages,
              isDark,
            ),
            SizedBox(height: PanAfricanSpacing.md),

            // Target Language
            _buildLanguageSelector(
              context,
              'To',
              targetLanguage,
              availableLanguages,
              isDark,
            ),
            SizedBox(height: PanAfricanSpacing.lg),

            // Text Input
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Enter text to translate',
                hintText: 'Type your text here...',
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
            SizedBox(height: PanAfricanSpacing.lg),

            // Translate Button
            ElevatedButton(
              onPressed: isLoading.value ? null : translate,
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
                      'Translate',
                      style: PanAfricanTypography.labelLarge(context)
                          .copyWith(color: Colors.white),
                    ),
            ),
            SizedBox(height: PanAfricanSpacing.xl),

            // Translation Result
            if (translationResult.value != null)
              _buildTranslationResult(
                context,
                translationResult.value!,
                isDark,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationTypeToggle(
    BuildContext context,
    String currentType,
    Function(String) onChanged,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Adaptive',
              isSelected: currentType == 'adaptive',
              onTap: () => onChanged('adaptive'),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Literal',
              isSelected: currentType == 'literal',
              onTap: () => onChanged('literal'),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    String label,
    ValueNotifier<AppLanguage> selectedLanguageNotifier,
    List<AppLanguage> availableLanguages,
    bool isDark,
  ) {
    return DropdownButtonFormField<AppLanguage>(
      value: selectedLanguageNotifier.value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        ),
        filled: true,
        fillColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
      ),
      items: availableLanguages.map((lang) {
        return DropdownMenuItem<AppLanguage>(
          value: lang,
          child: Text(
            lang.name.substring(0, 1).toUpperCase() + lang.name.substring(1),
            style: PanAfricanTypography.bodyMedium(context),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          selectedLanguageNotifier.value = value;
        }
      },
    );
  }

  Widget _buildTranslationResult(
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
          Text(
            'Translation',
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            result['translation'] ?? result['adaptiveTranslation'] ?? '',
            style: PanAfricanTypography.bodyLarge(context),
          ),
          if (result['grammarNotes'] != null) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Grammar Notes',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              result['grammarNotes'],
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ],
          if (result['examples'] != null && (result['examples'] as List).isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Examples',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(result['examples'] as List).map((example) {
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                child: Text(
                  '• $example',
                  style: PanAfricanTypography.bodyMedium(context),
                ),
              );
            }),
          ],
        ],  // closes Column children
      ),  // closes Column
    );  // closes Container
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? PanAfricanColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: PanAfricanTypography.labelLarge(context).copyWith(
            color: isSelected
                ? Colors.white
                : (isDark
                    ? PanAfricanColors.textSecondaryDark
                    : PanAfricanColors.textSecondaryLight),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

