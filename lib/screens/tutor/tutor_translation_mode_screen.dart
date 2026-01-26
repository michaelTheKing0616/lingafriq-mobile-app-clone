import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, PolieMode, GroqChatProvider;
import 'package:lingafriq/services/hybrid_polie/hybrid_polie_orchestrator.dart';

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
        // World-class reliability: run translation locally via Hybrid Polie (NLLB-200 with caching + HF fallback),
        // so this mode does NOT depend on being authenticated or on our backend being up.
        final groqProvider = ref.read(groqChatProvider.notifier);
        final orchestrator = HybridPolieOrchestrator();
        final response = await orchestrator.orchestrate(
          userMessage: textController.text,
          mode: PolieMode.translation,
          targetLanguage: targetLanguage.value.name,
          sourceLanguage: sourceLanguage.value.name,
          groqProvider: groqProvider,
        );

        // If we couldn't translate (e.g., HF token missing and backend unavailable), surface a clear error.
        if (response.model == 'fallback' || response.output.trim().isEmpty) {
          throw Exception(
            'Translation is temporarily unavailable. Please ensure you are online and the AI services are configured.',
          );
        }

        translationResult.value = {
          'translation': response.output,
          'confidence': response.confidence,
          'model': response.model,
          'diacriticsCorrected': response.diacriticsCorrected,
          'metadata': response.metadata,
        };
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

